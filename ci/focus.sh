# Targeted shots (CI_FOCUS=ci/focus.sh): only what the current change needs. Sourced by screenshots.sh,
# (rerun: caption icons)
# so shot / toggle / log are available. Edit this file for the next question and push it.
# Now: launcher favorite stars, DeX caption on the Files / Task manager / editor windows.

sleep 3
toggle launcher
sleep 1.5
shot d0-launcher-favorites 1.5
toggle launcher
toggle files
sleep 2
shot d1-files-caption 1.5
toggle files
toggle taskmanager
sleep 2
shot d2-taskmanager-caption 1.5
toggle taskmanager
: >/tmp/qs-ci-edit; sleep 3
shot d3-editor-caption 1.5
grep -iE "ERROR|is not a type|Cannot assign|Unable to assign|ReferenceError|TypeError|is not defined" "$OUT"/quickshell-*.log | tail -20 | tee -a "$OUT/pipeline.log"
