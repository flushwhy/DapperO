#!/usr/bin/env sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
DEST="$ROOT/vendor/Gamejoltodin"
PINNED_COMMIT="2f49e315220f29d88f51648bf5f1757771f36d84"

if [ ! -d "$DEST/.git" ]; then
    mkdir -p "$ROOT/vendor"
    git clone https://github.com/flushwhy/Gamejoltodin.git "$DEST"
fi

git -C "$DEST" fetch origin "$PINNED_COMMIT"
git -C "$DEST" checkout --detach "$PINNED_COMMIT"
