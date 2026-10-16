#!/usr/bin/env bash
# Prints a Material You palette (matugen JSON, hex) for an image or video.
# Usage: matugen-theme.sh <image|video> <dark|light|smart> <scheme-type>
# Videos are reduced to one frame with ffmpeg first. matugen also runs any
# templates configured in ~/.config/matugen/config.toml.
set -euo pipefail

src="$1" mode="$2" scheme="$3"

case "${src,,}" in
  *.mp4|*.webm|*.mkv|*.mov|*.gif)
    frame="${XDG_RUNTIME_DIR:-/tmp}/qs-matugen-frame.png"
    ffmpeg -y -loglevel error -ss 1 -i "$src" -frames:v 1 "$frame"
    src="$frame" ;;
esac

# --prefer: matugen otherwise asks which source colour to use when it finds several
exec matugen image "$src" --prefer saturation -m "$mode" -t "$scheme" -j hex
