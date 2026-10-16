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
# CI runs the "bloated" profile so every feature is on screen
python3 - "$XDG_CONFIG_HOME/quickshell/shell.json" "$WORK/bg.png" <<'PYC'
import json, sys
p = sys.argv[1]; d = json.load(open(p)); d["profile"] = "bloated"; d["lock"] = {"wallpaper": sys.argv[2]}; json.dump(d, open(p, "w"), indent=2)
PYC
# Lock screen: a patched-in hook stands in for typing the password (the real
# screen only unlocks through PAM, which CI cannot drive).
python3 - "$REPO/modules/lock/LockScreen.qml" <<'PYC'
import sys
p = sys.argv[1]; s = open(p).read()
s = s.replace("Scope {\n    id: root\n", "Scope {\n    id: root\n    FileView { path: \"/tmp/qs-ci-unlock\"; watchChanges: true; onFileChanged: root.shouldShow = false }\n", 1)
open(p, "w").write(s)
PYC
grep -q qs-ci-unlock "$REPO/modules/lock/LockScreen.qml" || echo "lock patch FAILED" >>"$OUT/pipeline.log"
# Settings panel: a hook selects the Shell tab (the real one is a click).
python3 - "$REPO/modules/systools/SystemToolsWindow.qml" <<'PYC'
import sys
p = sys.argv[1]; s = open(p).read()
s = s.replace("    id: root\n", "    id: root\n    FileView { path: \"/tmp/qs-ci-shelltab\"; watchChanges: true; onFileChanged: root.selectedTab = \"shell\" }\n", 1)
open(p, "w").write(s)
PYC
grep -q qs-ci-shelltab "$REPO/modules/systools/SystemToolsWindow.qml" || echo "systools patch FAILED" >>"$OUT/pipeline.log"
# Fake applications so the launcher has something to list.
APPS="$WORK/share/applications"; mkdir -p "$APPS"
# Real Papirus icon names, as on the user's machine.
declare -A ICONNAME=([Firefox]=firefox [Terminal]=utilities-terminal [Files]=system-file-manager [Settings]=preferences-system [Calculator]=accessories-calculator [Music]=multimedia-audio-player [Calendar]=office-calendar [Camera]=camera-photo)
for a in Firefox Terminal Files Settings Calculator Music Calendar Camera; do
  printf '[Desktop Entry]\nType=Application\nName=%s\nExec=true\nIcon=%s\nCategories=Utility;\n' "$a" "${ICONNAME[$a]}" >"$APPS/${a,,}.desktop"
done
# Desktop actions (the launcher's Shift/Ctrl "right-click menu") on Firefox.
printf 'Actions=new-window;new-private-window;profile-manager;\n\n[Desktop Action new-window]\nName=New Window\nExec=true\n\n[Desktop Action new-private-window]\nName=New Private Window\nExec=true\n\n[Desktop Action profile-manager]\nName=Profile Manager\nExec=true\n' >>"$APPS/firefox.desktop"
# The launcher's actions view needs a held Shift/Ctrl, which CI cannot send.
# Patch a throw-away timer in: 4.5 s after the launcher opens it enters actions
# mode on the first app and picks the second action (03-launcher is shot earlier).
sed -i '0,/readonly property var currentActions/s//Timer { running: root.shouldShow; interval: 4500; onTriggered: { root.selectedIndex = 0; root.enterActions(); root.actionIndex = 1 } }\n    Timer { running: root.shouldShow; interval: 9000; onTriggered: { root.leaveActions(); root.query = "e" } }\n    readonly property var currentActions/' "$REPO/modules/launcher/LauncherWindow.qml"
# Media pill hover: force the hover state when /tmp/qs-mediahover is touched.
python3 - "$REPO/modules/bar/components/MediaPlayer.qml" <<'PYX'
import sys
p = sys.argv[1]; s = open(p).read()
s = s.replace("import Quickshell\n", "import Quickshell\nimport Quickshell.Io\n", 1)
s = s.replace("readonly property bool hovered: hoverHandler.hovered", "property bool forceHover: false\n    readonly property bool hovered: hoverHandler.hovered || forceHover\n    FileView { path: \"/tmp/qs-mediahover\"; watchChanges: true; onFileChanged: root.forceHover = true }", 1)
open(p, "w").write(s)
PYX
: >/tmp/qs-mediahover
# Task manager performance tab: switch to it 3.5 s after the panel opens.
sed -i 's/^    property int tab: 0 .*/    property int tab: 0\n    Timer { running: root.shouldShow; interval: 3500; onTriggered: root.tab = 1 }/' "$REPO/modules/taskmanager/TaskManagerWindow.qml"
# Record pill preview: pretend a recording runs when /tmp/qs-recpreview is touched.
python3 - "$REPO/modules/bar/Bar.qml" <<'PYX'
import sys
p = sys.argv[1]; s = open(p).read()
s = s.replace("readonly property bool recording: QsServices.Screenshot.isRecording", "property bool forced: false\n            FileView { path: \"/tmp/qs-recpreview\"; watchChanges: true; onFileChanged: recordPill.forced = true }\n            readonly property bool recording: QsServices.Screenshot.isRecording || forced", 1)
s = s.replace("(now - QsServices.Screenshot.recordStart)", "(now - (QsServices.Screenshot.recordStart || (now - 83000)))", 1)
open(p, "w").write(s)
PYX
: >/tmp/qs-recpreview
# Tray menu: open the first item's menu when /tmp/qs-traymenu is touched.
python3 - "$REPO/modules/bar/components/SystemTray.qml" <<'PYX'
import sys
p = sys.argv[1]; s = open(p).read()
s = s.replace("import Quickshell.Widgets\n", "import Quickshell.Widgets\nimport Quickshell.Io\n", 1)
s = s.replace("                MouseArea {\n                    id: itemMouse", "                FileView { path: \"/tmp/qs-traymenu\"; watchChanges: true; onFileChanged: { if (trayItem.modelData.id === \"fake-files\") trayMenu.visible = true } }\n                MouseArea {\n                    id: itemMouse", 1)
open(p, "w").write(s)
PYX
: >/tmp/qs-traymenu
grep -q "interval: 4500" "$REPO/modules/launcher/LauncherWindow.qml" || echo "actions patch FAILED" >>"$OUT/pipeline.log"
# Icon theme: the real Papirus from nixpkgs (the squircle mask has to cope with it).
PAPIRUS="$(nix-build '<nixpkgs>' -A papirus-icon-theme --no-out-link 2>>"$OUT/nix-build.log" | tail -1)"
mkdir -p "$WORK/share/icons"
for t in Papirus Papirus-Dark; do [ -d "$PAPIRUS/share/icons/$t" ] && ln -sfn "$PAPIRUS/share/icons/$t" "$WORK/share/icons/$t"; done
export QS_ICON_THEME=Papirus-Dark
log "papirus: ${PAPIRUS:-missing}"
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
# Wallhaven round trip, with the exact curl calls WallpaperPanel.qml uses
# (search API, then CDN download). A real photo replaces the gradient.
WH_ID="${WALLHAVEN_ID:-0p8q6j}"
WH_UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
{
  echo "== search id:$WH_ID"
  curl -sf --max-time 12 "https://wallhaven.cc/api/v1/search?q=id:$WH_ID&categories=111&purity=100" | head -c 600; echo "  [exit ${PIPESTATUS[0]}]"
  echo "== download"
  curl -Lf --max-time 60 --retry 3 --retry-delay 1 -A "$WH_UA" -o "$WORK/wh.jpg" "https://w.wallhaven.cc/full/${WH_ID:0:2}/wallhaven-$WH_ID.jpg"; echo "  [exit $?]"
  file "$WORK/wh.jpg" 2>&1 || true
} >"$OUT/wallhaven.log" 2>&1
if [ -s "$WORK/wh.jpg" ] && magick "$WORK/wh.jpg" -resize 1920x1080^ -gravity center -extent 1920x1080 "$WORK/bg.png" 2>>"$OUT/pipeline.log"; then
  log "wallpaper: wallhaven $WH_ID"
  sed -i "s|^output \* bg .*|output * bg $WORK/bg.png fill|" "$WORK/sway.conf"
elif magick -size 1920x1080 gradient:'#34568b-#10141f' "$WORK/bg.png" 2>>"$OUT/pipeline.log"; then
  log "wallpaper: gradient (wallhaven unavailable)"
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
for f in launcher systools taskmanager speedtest hotspotqr clipboard lock ci-unlock ci-shelltab controlcenter sidebar dashboard powermenu record; do : >"/tmp/qs-$f"; done

# Fake UPower battery. UPower lives on the *system* bus, so start a private
# bus for it and point DBUS_SYSTEM_BUS_ADDRESS there; the battery state is
# switched through /tmp/qs-battery ("<percent> <state>", state 1 = charging).
echo "62 2" >/tmp/qs-battery
echo power-saver >/tmp/qs-profile   # leaf in the battery pill (PowerProfiles reads it once at start)
SYSDIR="$WORK/sysbus"; mkdir -p "$SYSDIR"
cat >"$SYSDIR/bus.conf" <<CONFEND
<!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-Bus Bus Configuration 1.0//EN" "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
<busconfig>
  <type>session</type>
  <listen>unix:path=$SYSDIR/sys.sock</listen>
  <auth>EXTERNAL</auth>
  <policy context="default">
    <allow send_destination="*" eavesdrop="true"/>
    <allow eavesdrop="true"/>
    <allow own="*"/>
  </policy>
</busconfig>
CONFEND
if dbus-daemon --config-file="$SYSDIR/bus.conf" --fork --print-pid >"$SYSDIR/pid" 2>>"$OUT/pipeline.log" \
   && python3 -c "import dbus_next" 2>/dev/null; then
  export DBUS_SYSTEM_BUS_ADDRESS="unix:path=$SYSDIR/sys.sock"
  python3 "$REPO/ci/fake_upower.py" >"$OUT/fake-upower.log" 2>&1 &
  UPOWER_PID=$!
  for _ in $(seq 1 30); do
    dbus-send --bus="$DBUS_SYSTEM_BUS_ADDRESS" --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus \
      org.freedesktop.DBus.NameHasOwner string:org.freedesktop.UPower 2>/dev/null | grep -q true && break
    sleep 0.5
  done
  log "upower mock: $(head -1 "$OUT/fake-upower.log")"
else
  log "system bus or dbus_next unavailable; battery mock skipped"
fi

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
  # Two fake StatusNotifierItems, so the bar's system tray has something to show
  if command -v python3 >/dev/null && python3 -c "import dbus_next" 2>/dev/null; then
    python3 "$REPO/ci/fake_tray.py" >"$OUT/fake-tray.log" 2>&1 &
    TRAY_PID=$!
    # Fake MPRIS player with generated album art (media pill)
    convert -size 300x300 gradient:'#ff5f6d-#6a3df0' -fill '#ffffff55' -draw 'circle 150,150 150,60' "$WORK/art.png" 2>>"$OUT/pipeline.log" || true
    python3 "$REPO/ci/fake_mpris.py" "$WORK/art.png" >"$OUT/fake-mpris.log" 2>&1 &
    MPRIS_PID=$!
  else
    log "dbus_next missing; tray test skipped"
  fi
  sleep 6   # let asynchronous Loaders finish
  dbus-send --session --print-reply --dest=org.kde.StatusNotifierWatcher /StatusNotifierWatcher \
    org.freedesktop.DBus.Properties.Get string:org.kde.StatusNotifierWatcher string:RegisteredStatusNotifierItems \
    >"$OUT/tray-registered.log" 2>&1 || true
  dbus-send --session --print-reply --dest=org.kde.StatusNotifierItem-1000-1 /StatusNotifierItem \
    org.freedesktop.DBus.Properties.GetAll string:org.kde.StatusNotifierItem >>"$OUT/tray-registered.log" 2>&1 || true
  shot 01-bar 0
  # charge animation: one frame mid-transition (blue -> green), then settled
  echo "62 1" >/tmp/qs-battery; sleep 0.9; shot 01-bar-charging-anim 0
  sleep 2; shot 01-bar-charging 0
  echo "12 2" >/tmp/qs-battery; sleep 2; shot 01-bar-low 0
  echo "62 2" >/tmp/qs-battery

  # Notifications: Quickshell registers the freedesktop notification server on
  # the session bus, so libnotify can feed it realistic content.
  notify-send -a "Messages" "Aylin" "Akşam buluşuyor muyuz? Yer ayırttım." 2>>"$OUT/pipeline.log"
  notify-send -a "Calendar" "Toplantı 15:00" "Haftalık değerlendirme · Oda 3" 2>>"$OUT/pipeline.log"
  notify-send -a "System" -u critical "Pil azalıyor" "Şarj cihazını takın (%12)" 2>>"$OUT/pipeline.log"
  shot 02-notification-popups 1.5
  sleep 24  # popups are queued one at a time (7s each); wait them out

  for state in controlcenter launcher sidebar dashboard systools taskmanager speedtest powermenu; do
    toggle "$state"
    shot "03-$state" 2.5
    toggle "$state"
    sleep 1.5
  done

  # Actions view (patched in at start-up, fires 4.5 s after the launcher opens).
  sleep 1
  toggle launcher
  shot "04-launcher-actions" 6.5
  toggle launcher
  sleep 1.5
  toggle launcher
  shot "05-launcher-many-icons" 10.5
  toggle launcher
  sleep 1
  toggle taskmanager
  shot "08-taskmanager-perf" 6
  toggle taskmanager
  sleep 1
  toggle recpreview
  shot "09-recording-pill" 2.5
  # Gaming mode: the niri shim reports a Steam game as focused while this file exists.
  : >/tmp/qs-fakegame
  shot "10-gaming-pill" 5
  rm -f /tmp/qs-fakegame
  sleep 1
  # Lock screen
  toggle lock
  shot "16-lock-screen" 4
  touch /tmp/qs-ci-unlock
  sleep 2.5
  shot "17-after-unlock" 1

  # Hotspot QR panel and clipboard history popup
  : >/tmp/qs-hotspoton
  sleep 10
  toggle hotspotqr
  shot "13-hotspot-qr" 3
  toggle hotspotqr
  rm -f /tmp/qs-hotspoton
  sleep 1
  toggle clipboard
  shot "14-clipboard" 2.5
  toggle clipboard
  sleep 1
  # Wired-only machine: Ethernet button instead of Wi-Fi/Hotspot
  : >/tmp/qs-nowifi
  sleep 10
  shot "11-no-wifi" 2
  toggle controlcenter
  shot "12-no-wifi-controlcenter" 2.5
  toggle controlcenter
  rm -f /tmp/qs-nowifi
  sleep 1
  # Profile switch at runtime: minimal hides the extra tiles/pills
  python3 - "$XDG_CONFIG_HOME/quickshell/shell.json" <<'PYC'
import json, sys
p = sys.argv[1]; d = json.load(open(p)); d["profile"] = "minimal"; json.dump(d, open(p, "w"), indent=2)
PYC
  sleep 3
  toggle controlcenter
  shot "15-minimal-controlcenter" 3
  toggle controlcenter
  sleep 1
  toggle traymenu
  shot "06-tray-menu" 2
  toggle mediahover
  shot "07-media-hover" 2
  # user.json overrides shell.json (which is "minimal" now): bloated, clipboard off
  mkdir -p "$HOME/.config/quickshell-local"
  echo '{"profile":"bloated","features":{"clipboard":false}}' >"$HOME/.config/quickshell-local/user.json"
  sleep 3
  toggle systools
  sleep 1
  touch /tmp/qs-ci-shelltab
  shot "18-settings-shell" 2.5
  toggle systools
fi

kill "${TRAY_PID:-}" "${MPRIS_PID:-}" "${UPOWER_PID:-}" "$(cat "$SYSDIR/pid" 2>/dev/null)" 2>/dev/null
kill "$QS_PID" 2>/dev/null
kill "$SWAY_PID" 2>/dev/null
wait 2>/dev/null

n="$(ls "$OUT"/*.png 2>/dev/null | wc -l)"
log "done: $n screenshot(s)"
[ "$n" -gt 0 ]
