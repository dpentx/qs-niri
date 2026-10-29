# Targeted shots (CI_FOCUS=ci/focus.sh): only what the current change needs. Sourced by screenshots.sh,
# so shot / toggle / log are available. Edit this file for the next question and push it.
# Now: a notification with an image-path hint (like the screenshot notification) must show its picture.

sleep 3
notify-send -a "Screenshot" -h "string:image-path:$WORK/bg.png" "Screenshot saved" "bg.png" 2>>"$OUT/pipeline.log"
shot n0-image-notification 2.5
grep -iE "Could not load icon|dismiss|Notifs" "$OUT"/quickshell-*.log | tail -5 | tee -a "$OUT/pipeline.log"
