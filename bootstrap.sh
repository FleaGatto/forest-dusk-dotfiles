#!/usr/bin/env bash
# Forest Dusk -- one-line bootstrap. Clones the repo, then runs install-fedora.sh.
#
#   curl -fsSL https://raw.githubusercontent.com/FleaGatto/forest-dusk-dotfiles/master/bootstrap.sh | bash
#
# Arguments pass straight through to install-fedora.sh:
#   curl -fsSL .../bootstrap.sh | bash -s -- --no-fonts
#
# This exists because install-fedora.sh resolves its own directory to find
# install.sh and the config tree. Piped into bash there is no file on disk, so
# that lookup lands in the wrong place -- the repo has to be cloned first.
set -euo pipefail

REPO=${FOREST_DUSK_REPO:-https://github.com/FleaGatto/forest-dusk-dotfiles.git}
DEST=${FOREST_DUSK_DEST:-$HOME/forest-dusk-dotfiles}

command -v git >/dev/null || { echo "git is required and was not found" >&2; exit 1; }

if [ -d "$DEST/.git" ]; then
    echo "==> updating ${DEST/#$HOME/~}"
    git -C "$DEST" pull --ff-only
else
    echo "==> cloning into ${DEST/#$HOME/~}"
    git clone --depth 1 "$REPO" "$DEST"
fi

cd "$DEST"
exec ./install-fedora.sh "$@"
