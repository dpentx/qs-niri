#!/usr/bin/env bash
#
# install-oneui-font.sh — installs OneUISans-VF.ttf into the user font directory
#
# NOTE (license): OneUISans is Samsung's proprietary font. This script
# does NOT copy / distribute the font into the repo — it only helps you install the file
# you extracted from YOUR OWN ROM onto your system. The font file
# DO NOT commit to this repo.
#
# Usage:
#   ./install-oneui-font.sh /path/to/OneUISans-VF.ttf
#
set -euo pipefail
export LC_ALL=C
export LANG=C

SRC="${1:-}"
DEST_DIR="${HOME}/.local/share/fonts/oneui"

if [[ -z "$SRC" || ! -f "$SRC" ]]; then
  echo "Usage: $0 /path/to/OneUISans-VF.ttf"
  echo ""
  echo "To find the file (in the unpacked ROM folder):"
  echo "  find ~/rom/exracted -iname 'OneUISans-VF.ttf'"
  exit 1
fi

mkdir -p "$DEST_DIR"
cp "$SRC" "$DEST_DIR/OneUISans-VF.ttf"

echo "==> Copied: $DEST_DIR/OneUISans-VF.ttf"

echo "==> Updating font cache..."
if command -v fc-cache >/dev/null 2>&1; then
  fc-cache -f "$DEST_DIR"
else
  nix-shell -p fontconfig --run "LC_ALL=C LANG=C fc-cache -f '$DEST_DIR'"
fi

echo ""
echo "==> Check:"
if command -v fc-list >/dev/null 2>&1; then
  fc-list | grep -i "oneui" || echo "    WARNING: not shown in fc-list, fontconfig may need a restart."
else
  nix-shell -p fontconfig --run "LC_ALL=C LANG=C fc-list" | grep -i "oneui" || true
fi

echo ""
echo "==> Done. After restarting qs-niri, 'OneUI Sans' should be usable as font.family."
