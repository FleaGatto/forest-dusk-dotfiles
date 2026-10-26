#!/usr/bin/env bash
# Links Forest Dusk into place. Every target is symlinked back to this repo, so
# editing a file here changes the live config; anything already sitting at a
# target path is moved aside to <name>.pre-forest-dusk first.
#
#   ./install.sh            link everything
#   ./install.sh --copy     copy instead of linking
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
mode=link
[ "${1:-}" = '--copy' ] && mode=copy

link_one() {
    local src=$1 dest=$2
    mkdir -p "$(dirname "$dest")"
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        mv "$dest" "$dest.pre-forest-dusk"
        echo "  kept  $dest.pre-forest-dusk"
    fi
    rm -f "$dest"
    if [ "$mode" = copy ]; then
        cp "$src" "$dest"
    else
        ln -s "$src" "$dest"
    fi
    echo "  $mode  ${dest/#$HOME/~}"
}

while IFS= read -r -d '' f; do
    link_one "$f" "$HOME/.config/${f#"$repo"/config/}"
done < <(find "$repo/config" -type f -print0)

while IFS= read -r -d '' f; do
    link_one "$f" "$HOME/.local/bin/${f#"$repo"/local/bin/}"
    chmod +x "$f"
done < <(find "$repo/local/bin" -type f -print0)

mkdir -p "$HOME/Pictures/Screenshots"

cat <<'NOTE'

Linked. To apply without logging out:
  hyprctl reload
  pkill waybar; waybar >/dev/null 2>&1 &
  pkill swaync;  swaync >/dev/null 2>&1 &
  pkill hyprpaper; hyprpaper >/dev/null 2>&1 &

Wallpapers are not in this repo -- hyprpaper.conf and hyprlock.conf expect
~/Pictures/Wallpapers/forest-dusk.png.
NOTE
