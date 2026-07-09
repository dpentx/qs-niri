#!/usr/bin/env bash
# ~/.config/quickshell/scripts/restore-wallpaper.sh
#
# niri "spawn-at-startup" ile her girişte çalışır. WallpaperPanel.qml'in
# yazdığı ~/.cache/qs-wallpaper-last.json dosyasını okuyup, en son hangi
# araçla (mpvpaper ya da awww) duvar kağıdı uygulandıysa onunla geri yükler.
# Bu olmadan niri her zaman sabit "awww-daemon" başlatıyordu ama en son
# mpvpaper kullanılmış olsa bile hiçbir video geri yüklenmiyordu.
set -uo pipefail

STATE_FILE="$HOME/.cache/qs-wallpaper-last.json"
PID_FILE="$HOME/.cache/qs-mpvpaper.pid"
LOG_FILE="/tmp/restore-wallpaper.log"

exec >>"$LOG_FILE" 2>&1
echo "== $(date) restore-wallpaper.sh çalıştı =="

[ -f "$STATE_FILE" ] || { echo "state dosyası yok, çıkılıyor"; exit 0; }

SERVICE=$(python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(d.get('service',''))" "$STATE_FILE" 2>/dev/null)
WPATH=$(python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(d.get('path',''))" "$STATE_FILE" 2>/dev/null)

if [ -z "$WPATH" ] || [ ! -f "$WPATH" ]; then
    echo "kayıtlı yol boş ya da dosya yok: '$WPATH'"
    exit 0
fi

echo "service=$SERVICE path=$WPATH"

if [ "$SERVICE" = "mpvpaper" ]; then
    # Zaten çalışan bir mpvpaper varsa (örn. panel session'ı hayatta kaldıysa) öldür.
    [ -f "$PID_FILE" ] && kill -9 "$(cat "$PID_FILE")" 2>/dev/null
    pkill -x mpvpaper 2>/dev/null
    sleep 0.3
    setsid nohup mpvpaper -o "no-audio loop no-border panscan=1.0" '*' "$WPATH" \
        >/tmp/mpvpaper.log 2>&1 </dev/null &
    echo $! > "$PID_FILE"
    echo "mpvpaper başlatıldı, pid=$!"
else
    # awww-daemon systemd servisinin socket'i açmasını bekle (spawn sırası
    # garanti değil; servis henüz tam ayağa kalkmamış olabilir).
    SOCK="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/${WAYLAND_DISPLAY:-wayland-1}-awww-daemon.sock"
    for _ in $(seq 1 25); do
        [ -S "$SOCK" ] && break
        sleep 0.2
    done
    if [ -S "$SOCK" ]; then
        awww img "$WPATH" --transition-type none
        echo "awww img uygulandı"
    else
        echo "awww-daemon socket'i $SOCK 5sn içinde açılmadı, atlanıyor"
    fi
fi
