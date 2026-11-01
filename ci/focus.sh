# Targeted shots (CI_FOCUS=ci/focus.sh): only what the current change needs. Sourced by screenshots.sh,
# so shot / toggle / log / click are available. Edit this file for the next question and push it.
# Now: settings rail icons + clicking through the new pages.

sleep 3
mkdir -p "$HOME/.config/quickshell-local"
echo '{}' >"$HOME/.config/quickshell-local/user.json"
toggle systools; sleep 3
click 740 240
shot st1-sounds 1
click 740 290
shot st2-battery 1
click 740 440
shot st3-lock 1
click 740 540
shot st4-general 1
toggle systools; sleep 1

grep -iE "ERROR|is not a type|Cannot assign|Unable to assign|ReferenceError|TypeError|is not defined|binding loop" "$OUT"/quickshell-*.log | tail -20 | tee -a "$OUT/pipeline.log"
