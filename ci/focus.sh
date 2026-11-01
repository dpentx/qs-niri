# Targeted shots (CI_FOCUS=ci/focus.sh): only what the current change needs. Sourced by screenshots.sh,
# so shot / toggle / log / click are available. Edit this file for the next question and push it.
# Now: staged start - the staged panels must still open, and the stage log lines must show up.

sleep 4
mkdir -p "$HOME/.config/quickshell-local"
echo '{}' >"$HOME/.config/quickshell-local/user.json"
log "stages: $(grep -h 'start stage' "$OUT"/quickshell-*.log | tr '\n' ' ' | cut -c1-300)"
for p in controlcenter launcher sidebar dashboard powermenu; do toggle $p; sleep 1.5; shot sg-$p 0.5; toggle $p; sleep 1; done

grep -iE "ERROR|is not a type|Cannot assign|Unable to assign|ReferenceError|TypeError|is not defined|binding loop" "$OUT"/quickshell-*.log | tail -20 | tee -a "$OUT/pipeline.log"
