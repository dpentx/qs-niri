#!/usr/bin/env bash
# Tek seferlik: mw-tool.go'yu statik binary'ye derler. Derleme bittikten
# sonra go veya nix'e artık ihtiyaç yok — binary tek başına çalışır.
#
# Kullanım (bir kere, terminalden):
#   bash ~/.config/quickshell/scripts/build-mw-tool.sh

set -euo pipefail

SCRIPTS_DIR="$HOME/.config/quickshell/scripts"
SRC="$SCRIPTS_DIR/mw-tool.go"
OUT="$SCRIPTS_DIR/mw-tool"

echo "==> Derleniyor: $SRC -> $OUT"
LC_ALL=C nix-shell -p go --run "
    cd '$SCRIPTS_DIR'
    CGO_ENABLED=0 go build -ldflags='-s -w' -o '$OUT' mw-tool.go
"
chmod +x "$OUT"

echo "==> Test ediliyor..."
"$OUT" fetch "https://moewalls.com/page/1/" | head -c 200
echo
echo "==> Tamam. mw-tool artık python/venv/nix-shell olmadan direkt çalışıyor."
echo "    Artık şunlar silinebilir: mw_fetch.py, mw_resolve.py, mw-venv-setup.sh,"
echo "    ~/.cache/mw-venv, ve shell.nix'teki python bağımlılıkları."
