#!/usr/bin/env bash
# One-time: compiles mw-tool.go into a static binary. Once the build is done,
# afterwards go and nix are no longer needed -- the binary runs on its own.
#
# Usage (once, from a terminal):
#   bash ~/.config/quickshell/scripts/build-mw-tool.sh

set -euo pipefail

SCRIPTS_DIR="$HOME/.config/quickshell/scripts"
SRC="$SCRIPTS_DIR/mw-tool.go"
OUT="$SCRIPTS_DIR/mw-tool"

echo "==> Building: $SRC -> $OUT"
LC_ALL=C nix-shell -p go --run "
    cd '$SCRIPTS_DIR'
    CGO_ENABLED=0 go build -ldflags='-s -w' -o '$OUT' mw-tool.go
"
chmod +x "$OUT"

echo "==> Testing..."
"$OUT" fetch "https://moewalls.com/page/1/" | head -c 200
echo
echo "==> Done. mw-tool now runs directly without python/venv/nix-shell."
echo "    You can now delete: mw_fetch.py, mw_resolve.py, mw-venv-setup.sh,"
echo "    ~/.cache/mw-venv, and the python dependencies in shell.nix."
