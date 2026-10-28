# Targeted shots (CI_FOCUS=ci/focus.sh): only what the current change needs. Sourced by screenshots.sh,
# so shot / toggle / log are available. Edit this file for the next question and push it.
# Now: task manager performance tab with hardware details (CPU, disk, Ethernet, Wi-Fi, GPU).

sleep 1
toggle taskmanager
sleep 6                                   # the CI switches to the performance tab after 3.5 s
shot t0-cpu 1
for k in disk eth wifi gpu; do
  touch /tmp/qs-ci-pk-$k
  shot t1-$k 2
done
toggle taskmanager
