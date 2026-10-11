#!/usr/bin/env bash
# Starts a private D-Bus session bus and runs ci/screenshots.sh inside it.
# Nix's dbus looks for /etc/dbus-1/session.conf, which does not exist on a
# non-NixOS runner, so point it at the config shipped in the package.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Make the fake UPower (ci/fake_upower.py) D-Bus-activatable: Quickshell calls
# StartServiceByName for it, which fails when no .service file exists.
DBUS_DATA="$(mktemp -d)"; mkdir -p "$DBUS_DATA/dbus-1/services"
printf '[D-BUS Service]\nName=org.freedesktop.UPower\nExec=%s %s\n' "$(command -v python3)" "$HERE/fake_upower.py" \
  >"$DBUS_DATA/dbus-1/services/org.freedesktop.UPower.service"
export XDG_DATA_DIRS="$DBUS_DATA:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
PREFIX="$(dirname "$(dirname "$(readlink -f "$(command -v dbus-daemon)")")")"
CONF="$PREFIX/share/dbus-1/session.conf"
if [ -f "$CONF" ]; then
  exec dbus-run-session --config-file="$CONF" -- bash "$HERE/screenshots.sh"
fi
echo "[ci] no session.conf in $PREFIX, falling back to default" >&2
exec dbus-run-session -- bash "$HERE/screenshots.sh"
