# Targeted shots (CI_FOCUS=ci/focus.sh): only what the current change needs. Sourced by screenshots.sh,
# so shot / toggle / log are available. Edit this file for the next question and push it.
# Now: the IP settings dialog of the Wi-Fi tab (opened by focus-prep.sh).

sleep 1
toggle systools
shot n1-ip-dialog 3
