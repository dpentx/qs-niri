# Targeted shots (CI_FOCUS=ci/focus.sh): only what the current change needs. Sourced by screenshots.sh,
# so shot / toggle / log are available. Edit this file for the next question and push it.
# Now: files and task manager are real toplevel windows (FloatingWindow), not layer-shell panels.

sleep 3
toggle files
sleep 2
shot w0-files 1.5
toggle taskmanager
sleep 2
shot w1-files-and-taskmanager 1.5
niri msg windows 2>&1 | grep -E "Title|App ID" | tee -a "$OUT/pipeline.log"
grep -iE "ERROR|is not a type|Cannot assign|Unable to assign|minimumSize" "$OUT"/quickshell-*.log | tail -15 | tee -a "$OUT/pipeline.log"
