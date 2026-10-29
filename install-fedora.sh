#!/usr/bin/env bash
# Forest Dusk -- Fedora bootstrap.
#
# Installs everything the config actually calls, applies the GSettings that really
# decide the GTK theme, then hands off to ./install.sh to link the files.
#
# Works on Fedora Workstation (dnf) and on Fedora Atomic -- Silverblue, Bazzite,
# Kinoite -- where packages are layered with rpm-ostree and need a reboot.
#
#   ./install-fedora.sh              packages, fonts, gsettings, link
#   ./install-fedora.sh --packages   dependencies only
#   ./install-fedora.sh --link       gsettings + link only, no package manager
#   ./install-fedora.sh --no-fonts   skip the Nerd Font download
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
NERD_VER=v3.2.1
do_packages=1 do_fonts=1 do_link=1

for a in "$@"; do
    case "$a" in
        --packages) do_fonts=0; do_link=0 ;;
        --link)     do_packages=0 ;;
        --no-fonts) do_fonts=0 ;;
        -h|--help)  sed -n '2,14p' "$0"; exit 0 ;;
        *) echo "unknown option: $a" >&2; exit 2 ;;
    esac
done

# Each group is derived from what the config and scripts actually invoke, not a
# wish list. Every name here was checked against the Fedora 43 repositories.

# compositor and its daemons -- hyprland.conf's exec-once starts all of these
PKGS=(hyprland hyprpaper hyprlock hypridle hyprpolkitagent hyprshot uwsm)
# the shell: bar, notifications, launcher, terminal, $files, fetch
PKGS+=(waybar SwayNotificationCenter wofi kitty fastfetch nautilus)
# called by local/bin/* and by waybar's modules: gum drives the TUIs, jq the JSON
PKGS+=(wl-clipboard cliphist brightnessctl playerctl jq socat gum libnotify)
# audio -- wpctl ships with wireplumber; pavucontrol is waybar's click action
PKGS+=(pipewire pipewire-pulseaudio wireplumber pavucontrol)
# network and bluetooth: nmcli/bluetoothctl in the scripts, applets in exec-once
PKGS+=(NetworkManager network-manager-applet bluez blueman)
# portals: file dialogs and screencast under Hyprland (see config/xdg-desktop-portal)
PKGS+=(xdg-desktop-portal-hyprland xdg-desktop-portal-gtk polkit)
# theming -- adw-gtk3-dark is the only theme here shipping real gtk-3.0 CSS,
# and the configs ask for Inter by name
PKGS+=(adw-gtk3-theme papirus-icon-theme rsms-inter-fonts google-noto-emoji-fonts)

atomic() { [ -f /run/ostree-booted ]; }
needs_reboot=0

install_packages() {
    echo "==> dependencies (${#PKGS[@]} packages)"
    if atomic; then
        echo "    Fedora Atomic detected: layering with rpm-ostree."
        sudo rpm-ostree install --idempotent "${PKGS[@]}"
        needs_reboot=1
    else
        sudo dnf install -y "${PKGS[@]}"
    fi
}

install_fonts() {
    echo "==> JetBrainsMono Nerd Font"
    # Fedora ships no Nerd Font packages, and waybar's stylesheet asks for
    # "JetBrainsMono Nerd Font" by name -- without it every icon is a blank box.
    local dir="$HOME/.local/share/fonts/JetBrainsMonoNerd"
    if [ -d "$dir" ] && [ -n "$(ls -A "$dir" 2>/dev/null)" ]; then
        echo "    already installed"
        return
    fi
    local tmp; tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' RETURN
    if curl -fsSL -o "$tmp/jbm.tar.xz" \
        "https://github.com/ryanoasis/nerd-fonts/releases/download/$NERD_VER/JetBrainsMono.tar.xz"
    then
        mkdir -p "$dir"
        tar -xJf "$tmp/jbm.tar.xz" -C "$dir"
        fc-cache -f "$dir" >/dev/null
        echo "    installed to ${dir/#$HOME/~}"
    else
        echo "    download failed -- icons will render as boxes until it is installed" >&2
    fi
}

apply_gsettings() {
    echo "==> GTK theme via GSettings"
    # install.sh links config/gtk-3.0/settings.ini, but under Wayland with no
    # XSettings daemon GTK3 takes the theme from GSettings instead, and those live
    # in dconf, which no linked file can restore. This is why the portal's file
    # dialog came up light no matter what settings.ini said.
    command -v gsettings >/dev/null || { echo "    gsettings missing, skipped"; return; }
    gsettings set org.gnome.desktop.interface gtk-theme     'adw-gtk3-dark'
    gsettings set org.gnome.desktop.interface icon-theme    'Adwaita'
    gsettings set org.gnome.desktop.interface color-scheme  'prefer-dark'
    gsettings set org.gnome.desktop.interface cursor-theme  'catppuccin-mocha-mauve-cursors'
    gsettings set org.gnome.desktop.interface cursor-size   24
}

[ "$do_packages" = 1 ] && install_packages
[ "$do_fonts" = 1 ] && install_fonts
[ "$do_link" = 1 ] && { apply_gsettings; echo "==> linking"; "$repo/install.sh"; }

cat <<NOTE

Two things this script deliberately does not fetch:

  Cursor theme  The config asks for catppuccin-mocha-mauve-cursors, which Fedora
                does not package. Grab it from github.com/catppuccin/cursors and
                unpack into ~/.local/share/icons, or change the name in
                config/gtk-3.0/settings.ini and hyprland.conf's setcursor line.

  Wallpaper     hyprpaper.conf and hyprlock.conf expect
                ~/Pictures/Wallpapers/forest-dusk.png

local/bin/de-switcher writes SDDM's autologin session, so it needs SDDM as the
display manager to do anything.
NOTE

if [ "$needs_reboot" = 1 ]; then
    cat <<'NOTE'
Packages were layered, so they are not live yet -- reboot when you are ready:
  systemctl reboot
NOTE
fi
