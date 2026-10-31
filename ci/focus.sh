# Targeted shots (CI_FOCUS=ci/focus.sh): only what the current change needs. Sourced by screenshots.sh,
# so shot / toggle / log / click are available. Edit this file for the next question and push it.
# Now: control center tile edit mode + media output row.

sleep 3
mkdir -p "$HOME/.config/quickshell-local"
echo '{}' >"$HOME/.config/quickshell-local/user.json"
toggle controlcenter; sleep 2
shot cc0-controlcenter 1
click 1864 424
shot cc1-edit-mode 1
click 1614 237
shot cc2-dnd-hidden-in-edit 1
click 1864 424
shot cc3-after-done 1
log "user.json after edit: $(cat "$HOME/.config/quickshell-local/user.json")"
toggle controlcenter; sleep 1

grep -iE "ERROR|is not a type|Cannot assign|Unable to assign|ReferenceError|TypeError|is not defined|binding loop" "$OUT"/quickshell-*.log | tail -20 | tee -a "$OUT/pipeline.log"
