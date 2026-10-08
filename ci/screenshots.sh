#!/usr/bin/env bash
# Headless screenshot pipeline: Sway (headless backend) + Quickshell + grim.
#
# Runs inside a nix-shell that provides quickshell, sway, grim, dbus,
# libnotify and imagemagick (see .github/workflows/screenshots.yml):
#   nix-shell -p quickshell sway grim dbus libnotify imagemagick \
#     --run "dbus-run-session -- bash ci/screenshots.sh"
#
# Output (ci/out): numbered PNGs, logs, info.txt. The script never aborts on a
# single failed step so the logs always make it out; it exits 1 only when no
# screenshot was produced at all.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$REPO/ci/out"
rm -rf "$OUT"
mkdir -p "$OUT"

log() { echo "[ci $(date +%H:%M:%S)] $*" | tee -a "$OUT/pipeline.log"; }

WORK="$(mktemp -d)"
export XDG_RUNTIME_DIR="$WORK/run"
mkdir -p "$XDG_RUNTIME_DIR" && chmod 700 "$XDG_RUNTIME_DIR"
export HOME="$WORK/home"
export XDG_CONFIG_HOME="$HOME/.config" XDG_CACHE_HOME="$HOME/.cache"
mkdir -p "$XDG_CONFIG_HOME/quickshell" "$XDG_CACHE_HOME"
cp "$REPO/shell.json" "$XDG_CONFIG_HOME/quickshell/shell.json"
# Fake applications so the launcher has something to list.
APPS="$WORK/share/applications"; mkdir -p "$APPS"
for a in Firefox Terminal Files Settings Calculator Music Calendar Camera; do
  printf '[Desktop Entry]\nType=Application\nName=%s\nExec=true\nIcon=%s\nCategories=Utility;\n' "$a" "${a,,}" >"$APPS/${a,,}.desktop"
done
export XDG_DATA_DIRS="$WORK/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
# niri is not available in CI; the shim answers the few `niri msg` queries.
export PATH="$REPO/ci/shims:$PATH"

# --- fonts ------------------------------------------------------------------
# "OneUI Sans" is proprietary, so CI renders it with Inter (see the alias
# below): glyph shapes and text widths differ slightly from a real setup.
# Icons are Material Design Icons glyphs and need their font installed.
font_dirs=()
for attr in inter dejavu_fonts material-design-icons nerd-fonts.symbols-only; do
  while read -r p; do
    [ -d "$p/share/fonts" ] && font_dirs+=("$p")
  done < <(nix-build '<nixpkgs>' -A "$attr" --no-out-link 2>>"$OUT/nix-build.log")
done
log "font packages: ${#font_dirs[@]}"
{
  echo '<?xml version="1.0"?>'
  echo '<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">'
  echo '<fontconfig>'
  for d in "${font_dirs[@]}"; do echo "  <dir>$d/share/fonts</dir>"; done
  echo "  <cachedir>$WORK/fontcache</cachedir>"
  echo '  <alias binding="same"><family>OneUI Sans</family><prefer><family>Inter</family></prefer></alias>'
  echo '  <alias><family>sans-serif</family><prefer><family>Inter</family><family>DejaVu Sans</family></prefer></alias>'
  echo '</fontconfig>'
} >"$WORK/fonts.conf"
export FONTCONFIG_FILE="$WORK/fonts.conf"

# --- software GL (Mesa llvmpipe from nixpkgs; the runner is not NixOS) --------
EGL_VENDOR="" DRI_PATH=""
while read -r p; do
  [ -f "$p/share/glvnd/egl_vendor.d/50_mesa.json" ] && EGL_VENDOR="$p/share/glvnd/egl_vendor.d/50_mesa.json"
  [ -d "$p/lib/dri" ] && DRI_PATH="$p/lib/dri"
done < <(nix-build '<nixpkgs>' -A mesa --no-out-link 2>>"$OUT/nix-build.log")
log "mesa egl vendor: ${EGL_VENDOR:-none}  dri: ${DRI_PATH:-none}"

# --- headless Sway ----------------------------------------------------------
export WLR_BACKENDS=headless WLR_LIBINPUT_NO_DEVICES=1 WLR_RENDERER=pixman
cp "$REPO/ci/sway.conf" "$WORK/sway.conf"
# A gradient wallpaper, so translucent surfaces have something behind them.
if magick -size 1920x1080 gradient:'#34568b-#10141f' "$WORK/bg.png" 2>>"$OUT/pipeline.log"; then
  sed -i "s|^output \* bg .*|output * bg $WORK/bg.png fill|" "$WORK/sway.conf"
fi
sway -c "$WORK/sway.conf" >"$OUT/sway.log" 2>&1 &
SWAY_PID=$!

for _ in $(seq 1 60); do
  ls "$XDG_RUNTIME_DIR"/wayland-* >/dev/null 2>&1 && break
  sleep 0.5
done
WAYLAND_DISPLAY="$(basename "$(ls "$XDG_RUNTIME_DIR"/wayland-[0-9]* 2>/dev/null | grep -v '\.lock$' | head -1)")"
export WAYLAND_DISPLAY
SWAYSOCK="$(ls "$XDG_RUNTIME_DIR"/sway-ipc.*.sock 2>/dev/null | head -1)"
export SWAYSOCK
log "wayland display: ${WAYLAND_DISPLAY:-none}  swaysock: ${SWAYSOCK:-none}"
if [ -z "${WAYLAND_DISPLAY:-}" ]; then
  log "sway did not come up"; tail -30 "$OUT/sway.log" | tee -a "$OUT/pipeline.log"; exit 1
fi
swaymsg -t get_outputs >"$OUT/outputs.json" 2>&1 || true

# --- helpers ----------------------------------------------------------------
grim "$WORK/baseline.png" 2>>"$OUT/pipeline.log" || log "baseline grim failed"

# true when the image differs from the empty-wallpaper baseline
changed() {
  local n
  n="$(magick compare -metric AE "$WORK/baseline.png" "$1" null: 2>&1 | awk '{printf "%d", $1}')"
  [ "${n:-0}" -gt 2000 ]
}

shot() {  # shot <name> [delay-seconds]
  sleep "${2:-1.5}"
  if grim "$OUT/$1.png" 2>>"$OUT/pipeline.log"; then log "captured $1"; else log "grim failed for $1"; fi
}

# `touch` matches the keybind convention (one inotify attribute event); a
# shell redirect produces several modify events and toggled twice.
toggle() { touch "/tmp/qs-$1"; }

# Quickshell watches these files (BarWrapper.qml); they must exist up front.
for f in launcher systools controlcenter sidebar dashboard powermenu record; do : >"/tmp/qs-$f"; done

QS_PID=""
try_mode() {
  local mode="$1"
  log "starting quickshell, render mode: $mode"
  if [ "$mode" = gl ]; then
    env QT_QPA_PLATFORM=wayland LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=llvmpipe \
      ${EGL_VENDOR:+__EGL_VENDOR_LIBRARY_FILENAMES=$EGL_VENDOR} \
      ${DRI_PATH:+LIBGL_DRIVERS_PATH=$DRI_PATH} \
      quickshell -p "$REPO" >"$OUT/quickshell-$mode.log" 2>&1 &
  else
    env QT_QPA_PLATFORM=wayland QT_QUICK_BACKEND=software \
      quickshell -p "$REPO" >"$OUT/quickshell-$mode.log" 2>&1 &
  fi
  QS_PID=$!
  for i in $(seq 1 60); do
    if ! kill -0 "$QS_PID" 2>/dev/null; then log "quickshell exited early ($mode)"; return 1; fi
    if grim "$WORK/probe.png" 2>/dev/null && changed "$WORK/probe.png"; then
      log "shell visible after ${i}s ($mode)"; MODE="$mode"; return 0
    fi
    sleep 1
  done
  log "nothing drawn within 60s ($mode)"
  kill "$QS_PID" 2>/dev/null; wait "$QS_PID" 2>/dev/null
  return 1
}

MODE=""
for m in ${QS_RENDER_MODES:-gl software}; do
  try_mode "$m" && break
done

{
  echo "render mode: ${MODE:-none}"
  echo "nixpkgs: $(nix-instantiate --eval -E '(import <nixpkgs> {}).lib.version' 2>/dev/null)"
  echo "quickshell: $(quickshell --version 2>&1 | head -1)"
  echo "sway: $(sway --version 2>&1 | head -1)"
  echo "commit: $(git -C "$REPO" rev-parse --short HEAD 2>/dev/null)"
  echo "fonts: ${#font_dirs[@]} packages"
} >"$OUT/info.txt"

if [ -n "$MODE" ]; then
  sleep 6   # let asynchronous Loaders finish
  shot 01-bar 0

  # Notifications: Quickshell registers the freedesktop notification server on
  # the session bus, so libnotify can feed it realistic content.
  notify-send -a "Messages" "Aylin" "Akşam buluşuyor muyuz? Yer ayırttım." 2>>"$OUT/pipeline.log"
  notify-send -a "Calendar" "Toplantı 15:00" "Haftalık değerlendirme · Oda 3" 2>>"$OUT/pipeline.log"
  notify-send -a "System" -u critical "Pil azalıyor" "Şarj cihazını takın (%12)" 2>>"$OUT/pipeline.log"
  shot 02-notification-popups 1.5
  sleep 9   # let the popups expire so they do not cover the surfaces below

  for state in controlcenter launcher sidebar dashboard systools powermenu; do
    toggle "$state"
    shot "03-$state" 2.5
    toggle "$state"
    sleep 1.5
  done
fi

kill "$QS_PID" 2>/dev/null
kill "$SWAY_PID" 2>/dev/null
wait 2>/dev/null

n="$(ls "$OUT"/*.png 2>/dev/null | wc -l)"
log "done: $n screenshot(s)"
[ "$n" -gt 0 ]
