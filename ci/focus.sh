# Targeted shots (CI_FOCUS=ci/focus.sh): only what the current change needs. Sourced by screenshots.sh,
# so shot / toggle / log / click are available. Edit this file for the next question and push it.
# Now: appearance.blur = false must make the panels near-opaque (live, no restart).

sleep 4
mkdir -p "$HOME/.config/quickshell-local"
echo '{}' >"$HOME/.config/quickshell-local/user.json"
sleep 1
toggle controlcenter; sleep 2; shot bl0-blur-default 0.5; toggle controlcenter; sleep 1
echo '{"appearance":{"blur":false}}' >"$HOME/.config/quickshell-local/user.json"
sleep 3
toggle controlcenter; sleep 2; shot bl1-blur-off 0.5; toggle controlcenter; sleep 1

grep -iE "ERROR|is not a type|Cannot assign|Unable to assign|ReferenceError|TypeError|is not defined|binding loop" "$OUT"/quickshell-*.log | tail -20 | tee -a "$OUT/pipeline.log"
