# Targeted shots (CI_FOCUS=ci/focus.sh): only what the current change needs. Sourced by screenshots.sh,
# so shot / toggle / log are available. Edit this file for the next question and push it.
# Now: every panel on a small screen (CI_RES in focus-prep.sh), to find what overflows or runs under the bars.

sleep 2
for p in launcher controlcenter sidebar dashboard systools taskmanager speedtest powermenu files hotspotqr cast clipboard emoji media wallswitch volume; do
  toggle "$p"
  shot "p-$p" 3
  toggle "$p"
  sleep 1.5
done
