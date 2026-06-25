#!/usr/bin/env bash
# restore-wallpaper.sh
# Reads ~/.cache/qs-wallpaper-last.json and re-applies the last wallpaper
# using the correct service (awww or mpvpaper).
#
# Add to niri.nix:
#   spawn-at-startup "sh" "-c" "sleep 2 && ~/.config/quickshell/restore-wallpaper.sh"
# (Adjust the path if your quickshell config lives elsewhere.)

CACHE="$HOME/.cache/qs-wallpaper-last.json"

[ -f "$CACHE" ] || exit 0

SERVICE=$(python3 -c "import json; d=json.load(open('$CACHE')); print(d.get('service',''))" 2>/dev/null)
WALL=$(python3 -c "import json; d=json.load(open('$CACHE')); print(d.get('path',''))" 2>/dev/null)

[ -z "$SERVICE" ] && exit 1
[ -z "$WALL"    ] && exit 1
[ -f "$WALL"    ] || { echo "restore-wallpaper: file not found: $WALL" >&2; exit 1; }

case "$SERVICE" in
    awww)
        # Poll until awww-daemon is ready (max 10s)
        for i in $(seq 1 20); do
            awww query &>/dev/null && break
            sleep 0.5
        done
        awww img "$WALL" --transition-type none
        ;;
    mpvpaper)
        pkill -x mpvpaper 2>/dev/null
        sleep 0.3
        mpvpaper -o "no-audio loop" '*' "$WALL"
        ;;
    *)
        echo "restore-wallpaper: unknown service '$SERVICE'" >&2
        exit 1
        ;;
esac
