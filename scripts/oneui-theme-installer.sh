#!/usr/bin/env bash
#
# oneui-theme-installer.sh — "Hex Installer" benzeri OneUI palet seçici
#
# qs-niri'nin okuduğu ~/.cache/wal/colors.json dosyasını, bu klasördeki
# hazır OneUI palet preset'lerinden biriyle değiştirir. Pywal.qml zaten
# bu dosyayı watchChanges: true ile izlediği için değişiklik ANINDA,
# shell'i yeniden başlatmadan uygulanır.
#
# Kullanım:
#   ./oneui-theme-installer.sh            # interaktif seçim (fzf varsa onunla)
#   ./oneui-theme-installer.sh blue        # doğrudan isimle uygula
#   ./oneui-theme-installer.sh --list      # mevcut palet isimlerini listele
#   ./oneui-theme-installer.sh --custom "#ff0000" "#00ff00" "#0000ff"
#                                           # kendi accent/secondary/tertiary renklerinle
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
  echo "==> Uygulandı: $(basename "$src" .json) -> $TARGET"
  echo "    (Quickshell açıksa değişiklik anında yansımalı)"
}

# --list
if [[ "${1:-}" == "--list" ]]; then
  echo "Mevcut OneUI paletleri:"
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
  echo "==> Özel palet uygulandı: accent=${ACCENT} secondary=${SECONDARY} tertiary=${TERTIARY}"
  exit 0
fi

# Doğrudan isimle çağrıldıysa (örn: ./oneui-theme-installer.sh blue)
if [[ -n "${1:-}" ]]; then
  CANDIDATE="$THEMES_DIR/${1}.json"
  if [[ -f "$CANDIDATE" ]]; then
    apply_theme_file "$CANDIDATE"
    exit 0
  else
    echo "Palet bulunamadı: $1"
    echo "Mevcut paletler:"
    list_themes
    exit 1
  fi
fi

# İnteraktif seçim
THEMES=($(list_themes))

if [[ ${#THEMES[@]} -eq 0 ]]; then
  echo "Hiç palet bulunamadı: $THEMES_DIR"
  exit 1
fi

if command -v fzf >/dev/null 2>&1; then
  SELECTED="$(printf '%s\n' "${THEMES[@]}" | fzf --prompt="OneUI palet seç > " --height=15 --border)"
else
  echo "Mevcut OneUI paletleri:"
  select SELECTED in "${THEMES[@]}"; do
    [[ -n "$SELECTED" ]] && break
  done
fi

if [[ -z "${SELECTED:-}" ]]; then
  echo "Seçim yapılmadı, çıkılıyor."
  exit 1
fi

apply_theme_file "$THEMES_DIR/${SELECTED}.json"
