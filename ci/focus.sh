# Targeted shots (CI_FOCUS=ci/focus.sh): only what the current change needs. Sourced by screenshots.sh,
# so shot / toggle / log / click are available. Edit this file for the next question and push it.
# Now: photo viewer - grid, then a photo opened through /tmp/qs-viewer-open (the path Files uses).

sleep 4
mkdir -p "$HOME/.config/quickshell-local" "$HOME/Pictures"
echo '{}' >"$HOME/.config/quickshell-local/user.json"
python3 - <<'PY'
import os, struct, zlib
d = os.path.expanduser("~/Pictures")
def png(path, w, h, f):
    raw = b"".join(b"\x00" + b"".join(bytes(f(x, y)) for x in range(w)) for y in range(h))
    def ch(t, b): c = struct.pack(">I", len(b)) + t + b; return c + struct.pack(">I", zlib.crc32(t + b) & 0xffffffff)
    open(path, "wb").write(b"\x89PNG\r\n\x1a\n" + ch(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)) + ch(b"IDAT", zlib.compress(raw)) + ch(b"IEND", b""))
for i, (w, h) in enumerate([(640, 400), (640, 400), (400, 640), (640, 400), (640, 400), (400, 640), (640, 400), (640, 400)]):
    png(f"{d}/photo{i+1}.png", w, h, lambda x, y, i=i: ((x * 255 // w + i * 30) % 256, (y * 255 // h + i * 50) % 256, (i * 40 + 90) % 256))
    os.utime(f"{d}/photo{i+1}.png", (1700000000 + i * 86400, 1700000000 + i * 86400))
PY
ls "$HOME/Pictures" | tr '\n' ' ' | tee -a "$OUT/pipeline.log"
toggle viewer; sleep 3
shot vw0-grid 1
printf '%s' "$HOME/Pictures/photo3.png" >/tmp/qs-viewer-open; sleep 3
shot vw1-photo 1

grep -iE "ERROR|is not a type|Cannot assign|Unable to assign|ReferenceError|TypeError|is not defined|binding loop" "$OUT"/quickshell-*.log | tail -20 | tee -a "$OUT/pipeline.log"
