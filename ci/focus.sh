# Targeted shots (CI_FOCUS=ci/focus.sh): only what the current change needs. Sourced by screenshots.sh,
# so shot / toggle / log are available. Edit this file for the next question and push it.
# Now: the lock screen shows what PAM says when it rejects a password (wrong password sent to the real PAM).

sleep 1
toggle lock
shot i1-lock 3
touch /tmp/qs-ci-wrongpw
shot i2-lock-rejected 5          # pam_unix delays a failure by ~2 s
touch /tmp/qs-ci-unlock
