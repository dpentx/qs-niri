# Targeted shots (CI_FOCUS=ci/focus.sh): only what the current change needs. Sourced by screenshots.sh,
# so shot / toggle / log are available. Edit this file for the next question and push it.
# Now: bar.layout "dex" (top bar + dock) vs "classic" (one bottom bar), switched live through user.json.

sleep 3
shot l0-dex 2
mkdir -p "$HOME/.config/quickshell-local"
echo '{"bar":{"layout":"classic"}}' >"$HOME/.config/quickshell-local/user.json"
sleep 4
shot l1-classic 2
toggle volume
shot l2-classic-popup 2
toggle volume
echo '{"bar":{"layout":"dex"}}' >"$HOME/.config/quickshell-local/user.json"
sleep 4
shot l3-back-to-dex 2
grep -iE "ERROR|WARN.*qml|is not a type|unavailable" "$OUT"/quickshell-*.log | tail -15 | tee -a "$OUT/pipeline.log"
