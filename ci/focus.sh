# Targeted shots (CI_FOCUS=ci/focus.sh): only what the current change needs. Sourced by screenshots.sh,
# so shot / toggle / log are available. Edit this file for the next question and push it.
# Now: the DeX-style bottom taskbar (strip, pinned + open apps, app drawer, quick panels, popup above the bar).

sleep 1
shot e1-bar-idle 2

# "firefox" is a pinned favourite (fake desktop entry), qs-ci-term is not: one running pinned app + one unpinned
foot -a firefox sleep 600 >/dev/null 2>&1 &
foot -a qs-ci-term sleep 600 >/dev/null 2>&1 &
sleep 3
shot e2-bar-windows 2

toggle launcher
shot e3-launcher 3
toggle launcher
sleep 1

toggle controlcenter
shot e4-controlcenter 3
toggle controlcenter
sleep 1

toggle sidebar
shot e5-sidebar 3
toggle sidebar
sleep 1

toggle emoji
shot e6-popup-above-bar 3
toggle emoji
