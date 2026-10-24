# Targeted shots (CI_FOCUS=ci/focus.sh): only what the current change needs. Sourced by screenshots.sh,
# so shot / toggle / log are available. Edit this file for the next question and push it.
# Now: the quick wallpaper switcher (opens, then steps on with a second press).

sleep 1
toggle wallswitch
shot s1-wallswitch-open 3
sleep 1
toggle wallswitch
shot s2-wallswitch-next 2
