# Targeted shots (CI_FOCUS=ci/focus.sh): only what the current change needs. Sourced by screenshots.sh,
# so shot / toggle / log are available. Edit this file for the next question and push it.
# Now: Control Center with the new microphone / camera access tiles (no camera in CI: only the mic tile can show).

sleep 1
toggle controlcenter
shot m1-controlcenter 3
# re-run: icons fixed
