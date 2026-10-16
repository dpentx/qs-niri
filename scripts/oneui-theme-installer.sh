#!/usr/bin/env bash
#
# oneui-theme-installer.sh — "Hex Installer"-like OneUI palette picker
#
# Replaces the ~/.cache/wal/colors.json file read by qs-niri with one of the
# ready-made OneUI palette presets in this folder. Since Pywal.qml already
# watches this file with watchChanges: true, the change is applied INSTANTLY,
# without restarting the shell.
#
# Usage:
#   ./oneui-theme-installer.sh            # interactive selection (with fzf if available)
#   ./oneui-theme-installer.sh blue        # apply directly by name
#   ./oneui-theme-installer.sh --list      # list available palette names
#   ./oneui-theme-installer.sh --custom "#ff0000" "#00ff00" "#0000ff"
#                                           # with your own accent/secondary/tertiary colors
#
set -euo pipefail
export LC_ALL=C
export LANG=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEMES_DIR="$SCRIPT_DIR/oneui-themes"
TARGET="${HOME}/.cache/wal/colors.json"

mkdir -p "$(dirname "$TARGET")"

list_themes() {
  find "$THEMES_DIR" -maxdepth 1 -name "*.json" -exec basename {} .json \; | sort
}

apply_theme_file() {
  local src="$1"
  cp "$src" "$TARGET"
  echo "==> Applied: $(basename "$src" .json) -> $TARGET"
  echo "    (if Quickshell is running, the change should show up instantly)"
}

# --list
if [[ "${1:-}" == "--list" ]]; then
  echo "Available OneUI palettes:"
  list_themes
  exit 0
fi

# --custom accent secondary tertiary
if [[ "${1:-}" == "--custom" ]]; then
  ACCENT="${2:-#598fff}"
  SECONDARY="${3:-#8fa8d6}"
  TERTIARY="${4:-#a6b8e0}"
  cat > "$TARGET" << EOF
{
  "special": {
    "background": "#000000",
    "foreground": "#fcfcff",
    "cursor": "#fcfcff"
  },
  "colors": {
    "color0": "#000000",
    "color1": "#ff453a",
    "color2": "#37B679",
    "color3": "#FF9F00",
    "color4": "${ACCENT}",
    "color5": "${SECONDARY}",
    "color6": "${TERTIARY}",
    "color7": "#fcfcff",
    "color8": "#8e8e93",
    "color9": "#ff453a",
    "color10": "#37B679",
    "color11": "#BE5052",
    "color12": "${ACCENT}",
    "color13": "${SECONDARY}",
    "color14": "${TERTIARY}",
    "color15": "#fcfcff"
  }
}
EOF
  echo "==> Custom palette applied: accent=${ACCENT} secondary=${SECONDARY} tertiary=${TERTIARY}"
  exit 0
fi

# If called directly by name (e.g. ./oneui-theme-installer.sh blue)
if [[ -n "${1:-}" ]]; then
  CANDIDATE="$THEMES_DIR/${1}.json"
  if [[ -f "$CANDIDATE" ]]; then
    apply_theme_file "$CANDIDATE"
    exit 0
  else
    echo "Palette not found: $1"
    echo "Available palettes:"
    list_themes
    exit 1
  fi
fi

# Interactive selection
THEMES=($(list_themes))

if [[ ${#THEMES[@]} -eq 0 ]]; then
  echo "No palettes found: $THEMES_DIR"
  exit 1
fi

if command -v fzf >/dev/null 2>&1; then
  SELECTED="$(printf '%s\n' "${THEMES[@]}" | fzf --prompt="Select OneUI palette > " --height=15 --border)"
else
  echo "Available OneUI palettes:"
  select SELECTED in "${THEMES[@]}"; do
    [[ -n "$SELECTED" ]] && break
  done
fi

if [[ -z "${SELECTED:-}" ]]; then
  echo "No selection made, exiting."
  exit 1
fi

apply_theme_file "$THEMES_DIR/${SELECTED}.json"
