#!/usr/bin/env bash
# Exports one platform of the full game or the demo with tools/steam/publish.py's export, then packs it into dist/:
#   bash .github/scripts/export.sh <windows|macos|linux> <full|demo>
# Windows becomes a .zip and Linux a .tar.gz, which keeps the executable permissions that artifacts drop. macOS stays
# Godot's own .zip beside the credits, for the signing job to open on a Mac.
set -euo pipefail

PLATFORM="$1"
EDITION="$2"
ROOT="$(pwd)"
source "$ROOT/.github/scripts/names.sh"
STAGE="$ROOT/builds/ci/$EDITION-$PLATFORM"
DIST="$ROOT/dist"

rm -rf "$STAGE" "$DIST"
mkdir -p "$STAGE" "$DIST"
GODOT="${GODOT:-godot}" python3 - "$PLATFORM" "$STAGE/$GAME_NAME" "$EDITION" <<'PY'
import sys
from pathlib import Path

sys.path.insert(0, "tools/steam")
import publish

publish.export(sys.argv[1], Path(sys.argv[2]), sys.argv[3] == "demo")
PY

case "$PLATFORM" in
  windows)
    (cd "$STAGE" && zip -q -r -9 "$DIST/$SLUG-$LABEL-windows.zip" "$GAME_NAME")
    ;;
  linux)
    chmod 644 "$STAGE/$GAME_NAME/"*
    chmod 755 "$STAGE/$GAME_NAME/"*.x86_64 "$STAGE/$GAME_NAME/"*.so
    tar -czf "$DIST/$SLUG-$LABEL-linux.tar.gz" -C "$STAGE" "$GAME_NAME"
    ;;
  macos)
    cp "$STAGE/$GAME_NAME/"* "$DIST/"
    ;;
esac
ls -l "$DIST"
