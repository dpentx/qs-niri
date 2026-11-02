# Classic apps button debug.
sleep 4
mkdir -p "$HOME/.config/quickshell-local"
echo '{"bar":{"layout":"classic"}}' >"$HOME/.config/quickshell-local/user.json"; sleep 6
click 40 1058; sleep 2
shot cl1-apps 1
grep -a "DBG" "$OUT"/quickshell-*.log | tee -a "$OUT/pipeline.log"
