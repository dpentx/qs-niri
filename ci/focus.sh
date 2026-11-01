# Targeted shots (CI_FOCUS=ci/focus.sh): only what the current change needs. Sourced by screenshots.sh,
# so shot / toggle / log / click are available. Edit this file for the next question and push it.
# Now: lazy-loaded panels - quickshell RSS before / while open / after the 60 s keep-alive.

rss() { log "quickshell RSS $1: $(ps -o rss= --ppid "$QS_PID" -p "$QS_PID" | sort -n | tail -1 | awk '{printf "%.0f MB", $1/1024}')"; }
sleep 3
mkdir -p "$HOME/.config/quickshell-local"
echo '{}' >"$HOME/.config/quickshell-local/user.json"
sleep 5; rss "idle at start"
for p in systools taskmanager speedtest files; do toggle $p; sleep 2; done
shot lz1-all-open 1
rss "four panels open"
for p in systools taskmanager speedtest files; do toggle $p; sleep 1; done
sleep 75
rss "75 s after closing"
toggle systools; sleep 2
shot lz2-systools-reopened 1
toggle systools

grep -iE "ERROR|is not a type|Cannot assign|Unable to assign|ReferenceError|TypeError|is not defined|binding loop" "$OUT"/quickshell-*.log | tail -20 | tee -a "$OUT/pipeline.log"
