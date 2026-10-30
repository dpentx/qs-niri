# Targeted shots (CI_FOCUS=ci/focus.sh): only what the current change needs. Sourced by screenshots.sh,
# (rerun: agenda loaded through Loader)
# so shot / toggle / log are available. Edit this file for the next question and push it.
# Now: agenda + reminders, system settings page, clipboard pins, screenshot editor.

sleep 3
mkdir -p "$HOME/.config/quickshell-local"
AT=$(( ($(date +%s) + 7200) * 1000 )); LATE=$(( ($(date +%s) - 600) * 1000 ))
echo "{\"clipboard\":{\"pins\":[\"ssh user@host -p 2222\",\"Pinned snippet\"]},\"reminders\":[{\"id\":\"1\",\"text\":\"Call the bank\",\"at\":$AT,\"fired\":false},{\"id\":\"2\",\"text\":\"Past one\",\"at\":$LATE,\"fired\":true}]}" >"$HOME/.config/quickshell-local/user.json"
sleep 2
toggle clock
sleep 1.5
shot f0-agenda 1.5
toggle clock
toggle systools
sleep 2
shot f1-system-settings 1.5
toggle systools
toggle clipboard
sleep 1.5
shot f2-clipboard-pins 1.5
toggle clipboard
: >/tmp/qs-ci-edit; sleep 3
shot f3-editor 1.5
: >/tmp/qs-ci-save; sleep 3
file "$(dirname "$WORK"/bg.png)"/bg-edited.png 2>&1 | tee -a "$OUT/pipeline.log"
grep -iE "ERROR|is not a type|Cannot assign|Unable to assign|ReferenceError|TypeError|is not defined" "$OUT"/quickshell-*.log | tail -20 | tee -a "$OUT/pipeline.log"
