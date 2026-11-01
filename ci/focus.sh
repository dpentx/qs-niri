# Cold first toggle: lazy panels used to drop the first request while loading; then a bar layout switch.
# Now: files opened by ONE touch, then bar.layout classic written at runtime.

sleep 4
mkdir -p "$HOME/.config/quickshell-local"
echo '{}' >"$HOME/.config/quickshell-local/user.json"
toggle files; sleep 4
shot lz0-files 1
toggle files; sleep 2
echo '{"bar":{"layout":"classic"}}' >"$HOME/.config/quickshell-local/user.json"; sleep 5
shot lz1-classic 1
toggle systools; sleep 4
shot lz2-systools 1

grep -iE "ERROR|is not a type|Cannot assign|Unable to assign|ReferenceError|TypeError|is not defined|binding loop" "$OUT"/quickshell-*.log | tail -20 | tee -a "$OUT/pipeline.log"
# r2
