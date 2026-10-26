# Targeted shots (CI_FOCUS=ci/focus.sh): only what the current change needs. Sourced by screenshots.sh,
# so shot / toggle / log are available. Edit this file for the next question and push it.
# Now: the volume OSD pill, bottom-centre just above the taskbar (keyboard volume keys).

sleep 1
# the fake wpctl reads this file; Audio.qml polls every second, the OSD stays 2 s
echo 0.30 >/tmp/qs-ci-vol
shot g2-volume-osd-bottom 2.2
