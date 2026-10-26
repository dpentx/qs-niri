# Targeted shots (CI_FOCUS=ci/focus.sh): only what the current change needs. Sourced by screenshots.sh,
# so shot / toggle / log are available. Edit this file for the next question and push it.
# Now: shell size on a 1366x768 screen (Config.uiScale): bars, notification panel, control center, volume panel.

sleep 1
shot u0-bars 2
toggle sidebar
shot u1-sidebar 2
toggle sidebar
sleep 1
toggle controlcenter
shot u2-controlcenter 2
toggle controlcenter
sleep 1
toggle launcher
shot u3-launcher 2
toggle launcher
