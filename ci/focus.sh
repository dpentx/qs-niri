# Targeted shots (CI_FOCUS=ci/focus.sh): only what the current change needs. Sourced by screenshots.sh,
# so shot / toggle / log are available. Edit this file for the next question and push it.
# Now: the bar without the brightness item, and the volume pill panel above it.

sleep 1
shot f1-bar-no-brightness 2

toggle volume
shot f2-volume-panel 3
toggle volume
