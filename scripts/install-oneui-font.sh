#!/usr/bin/env bash
#
# install-oneui-font.sh — OneUISans-VF.ttf'i kullanıcı font dizinine kurar
#
# NOT (lisans): OneUISans Samsung'un proprietary fontudur. Bu script
# fontu repo içine KOPYALAMAZ / dağıtmaz — sadece SENİN kendi ROM'undan
# çıkardığın dosyayı sistemine kurmana yardımcı olur. Font dosyasını
# bu repoya commit ETME.
#
# Kullanım:
#   ./install-oneui-font.sh /path/to/OneUISans-VF.ttf
#
set -euo pipefail
export LC_ALL=C
export LANG=C

SRC="${1:-}"
DEST_DIR="${HOME}/.local/share/fonts/oneui"

if [[ -z "$SRC" || ! -f "$SRC" ]]; then
  echo "Kullanım: $0 /path/to/OneUISans-VF.ttf"
  echo ""
  echo "Dosyayı bulmak için (ROM unpack edilmiş klasöründe):"
  echo "  find ~/rom/exracted -iname 'OneUISans-VF.ttf'"
  exit 1
fi

mkdir -p "$DEST_DIR"
cp "$SRC" "$DEST_DIR/OneUISans-VF.ttf"

echo "==> Kopyalandı: $DEST_DIR/OneUISans-VF.ttf"

echo "==> Font cache güncelleniyor..."
if command -v fc-cache >/dev/null 2>&1; then
  fc-cache -f "$DEST_DIR"
else
  nix-shell -p fontconfig --run "LC_ALL=C LANG=C fc-cache -f '$DEST_DIR'"
fi

echo ""
echo "==> Kontrol:"
if command -v fc-list >/dev/null 2>&1; then
  fc-list | grep -i "oneui" || echo "    UYARI: fc-list'te görünmüyor, fontconfig yeniden başlatma gerektirebilir."
else
  nix-shell -p fontconfig --run "LC_ALL=C LANG=C fc-list" | grep -i "oneui" || true
fi

echo ""
echo "==> Bitti. qs-niri'yi yeniden başlatınca 'OneUI Sans' font.family olarak kullanılabilir olmalı."
