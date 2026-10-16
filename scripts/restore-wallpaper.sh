#!/usr/bin/env bash
# ~/.config/quickshell/scripts/restore-wallpaper.sh
#
# Runs on every login via niri "spawn-at-startup". Reads the
# ~/.cache/qs-wallpaper-last.json file written by WallpaperPanel.qml and restores
# the wallpaper with whichever tool (mpvpaper or awww) was used last.
# Without this, niri always started a fixed "awww-daemon", but even if
# mpvpaper was used last, no video was restored.
set -uo pipefail

STATE_FILE="$HOME/.cache/qs-wallpaper-last.json"
PID_FILE="$HOME/.cache/qs-mpvpaper.pid"
LOG_FILE="/tmp/restore-wallpaper.log"

exec >>"$LOG_FILE" 2>&1
echo "== $(date) restore-wallpaper.sh ran =="

[ -f "$STATE_FILE" ] || { echo "no state file, exiting"; exit 0; }

SERVICE=$(python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(d.get('service',''))" "$STATE_FILE" 2>/dev/null)
WPATH=$(python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(d.get('path',''))" "$STATE_FILE" 2>/dev/null)

if [ -z "$WPATH" ] || [ ! -f "$WPATH" ]; then
    echo "saved path is empty or file missing: '$WPATH'"
    exit 0
fi

echo "service=$SERVICE path=$WPATH"

if [ "$SERVICE" = "mpvpaper" ]; then
    # If an mpvpaper is already running (e.g. the panel session survived), kill it.
    [ -f "$PID_FILE" ] && kill -9 "$(cat "$PID_FILE")" 2>/dev/null
    pkill -x mpvpaper 2>/dev/null
    sleep 0.3
    setsid nohup mpvpaper -o "no-audio loop no-border panscan=1.0" '*' "$WPATH" \
        >/tmp/mpvpaper.log 2>&1 </dev/null &
    echo $! > "$PID_FILE"
    echo "mpvpaper started, pid=$!"
else
    # Wait for the awww-daemon systemd service to open its socket (spawn order
    # is not guaranteed; the service may not be fully up yet).
    SOCK="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/${WAYLAND_DISPLAY:-wayland-1}-awww-daemon.sock"
    for _ in $(seq 1 25); do
        [ -S "$SOCK" ] && break
        sleep 0.2
    done
    if [ -S "$SOCK" ]; then
        awww img "$WPATH" --transition-type none
        echo "awww img applied"
    else
        echo "awww-daemon socket $SOCK did not open within 5s, skipping"
    fi
fi
