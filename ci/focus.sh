# Targeted shots (CI_FOCUS=ci/focus.sh): only what the current change needs. Sourced by screenshots.sh,
# so shot / toggle / log are available. Edit this file for the next question and push it.
# Now: the Shift+Delete confirmation in the file manager (preset by focus-prep.sh).

sleep 1
toggle files
shot d1-files-delete-confirm 3
