# Forest Dusk

Hyprland rice for a Steam Deck running [Bazzite](https://bazzite.gg)
(`bazzite-deck-gnome`, Silverblue base), with Hyprland layered on via rpm-ostree.

Moss green, deep green and gold on a near-black forest background:

| role        | hex       |
|-------------|-----------|
| accent      | `#7fae6a` |
| accent deep | `#4a7c3f` |
| gold        | `#d4b86a` |
| background  | `#141f16` |
| surface     | `#1c2a1e` |
| text        | `#e8e4d0` |

## What's in here

| path | what it is |
|------|------------|
| `config/hypr/` | compositor, idle, lock and wallpaper config |
| `config/waybar/` | bar, plus a Fleasion status module |
| `config/wofi/` | launcher, and the Alt-Tab switcher's own theme |
| `config/kitty/` | terminal colours |
| `config/swaync/` | notification centre and control panel |
| `config/gtk-4.0/`, `config/fastfetch/` | GTK4 accents, fastfetch layout |
| `local/bin/settings` | gum TUI for display/audio/bluetooth/network/brightness/power (`$mod+S`) |
| `local/bin/powermenu` | wofi power menu (`$mod+Escape`) |
| `local/bin/osd` | volume/brightness feedback, drawn as swaync notifications |
| `local/bin/window-switcher` | Alt-Tab menu in most-recently-used order |
| `local/bin/deck-dock-watch` | disables the Deck panel while docked, restores it on unplug |

## Install

```sh
git clone https://github.com/<you>/forest-dusk-dotfiles ~/forest-dusk-dotfiles
cd ~/forest-dusk-dotfiles && ./install-fedora.sh
```

`install-fedora.sh` installs the dependencies, fetches the Nerd Font, applies the
GSettings that actually decide the GTK theme, then links everything. It handles
both Fedora Workstation (`dnf`) and Fedora Atomic (`rpm-ostree`, needs a reboot).

`./install.sh` on its own only links files -- use it when the dependencies are
already in place. `--copy` copies instead of symlinking.

Wallpapers are not tracked here; `hyprpaper.conf` and `hyprlock.conf` expect
`~/Pictures/Wallpapers/forest-dusk.png`.

### Dependencies

The package list lives in `install-fedora.sh`, grouped by what calls each one, so
there is one list rather than two that drift apart. Every name in it is checked
against the Fedora 43 repositories.

Two things it deliberately does not fetch:

- **`catppuccin-mocha-mauve-cursors`** -- not packaged by Fedora. Take it from
  [catppuccin/cursors](https://github.com/catppuccin/cursors) into
  `~/.local/share/icons`, or change the name in `config/gtk-3.0/settings.ini` and
  in `hyprland.conf`'s `setcursor` line.
- **Wallpapers** -- see above.

`local/bin/de-switcher` writes SDDM's autologin session, so it only does anything
with SDDM as the display manager.

## Notes for this machine

Things that cost real time to work out, kept here so they don't have to be
rediscovered:

- **Blurred corners.** Hyprland blurs the whole rectangular layer surface,
  transparent pixels included, so rounded panels get square blur blocks in their
  corners. `layerrule = blur true, ignore_alpha 0.4, match:namespace <ns>` fixes
  it; keep the threshold under each panel's real background alpha.
- **Rule syntax.** Hyprland ≥ 0.56 wants `key value` with a space, commas
  between rules and a `match:` prefix on match properties, and effect names are
  snake_case (`ignore_alpha`, `blur_popups`, `no_anim`). `dwindle:pseudotile` is
  gone. The source of truth is `src/config/legacy/ConfigManager.cpp`, not the
  wiki. `hyprctl configerrors` returning nothing is how you confirm a rule
  parsed — `hyprctl rules` is not a request.
- **Autologin.** `bazzite-autologin.service` rewrites `Session=` in
  `/etc/sddm.conf.d/steamos.conf` on every boot, hardcoded to
  `gnome-wayland.desktop`. Mask it and set `Session=hyprland-uwsm.desktop`.
- **Leftover GNOME session.** While one lives on tty1 it owns
  `org.kde.StatusNotifierWatcher` (waybar's tray breaks) and
  `org.freedesktop.Notifications` (swaync won't start), and its socket makes
  Hyprland invent a phantom `WAYLAND-1` output that screen sharing captures
  instead of the real monitor. `loginctl terminate-session <id>`, then
  `hyprctl output remove WAYLAND-1`.
- **Display tooling.** This build has no `wlr-output-management`, so
  `wlr-randr`, `nwg-displays` and `wdisplays` all fail. Use `hyprctl monitors`
  and `hyprctl keyword monitor`.
- **swaync notifications.** It honours `-h boolean:transient:true` (not
  `byte:transient:1`) to stay out of the history, and
  `x-canonical-private-synchronous` to replace in place. `osd` needs both so
  holding a volume key doesn't bury real notifications.
