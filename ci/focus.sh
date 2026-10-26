# Targeted shots (CI_FOCUS=ci/focus.sh): only what the current change needs. Sourced by screenshots.sh,
# so shot / toggle / log are available. Edit this file for the next question and push it.
# Now: taskbar pin / unpin (menu entry, persisted list) and the launcher's pin action.

sleep 1
foot -a firefox sleep 600 >/dev/null 2>&1 &
FOOT_PID=$!
sleep 3

# right-click menu of the firefox icon: it is pinned by default, so it offers "Unpin from taskbar"
touch /tmp/qs-ci-taskmenu
shot h1-taskbar-menu 2

# unpin: the list is written to user.json
touch /tmp/qs-ci-pintoggle
sleep 2
log "user.json after unpin: $(tr -d '\n ' <"$HOME/.config/quickshell-local/user.json" | head -c 600)"
kill "$FOOT_PID" 2>/dev/null
shot h2-unpinned-and-closed 3        # firefox is neither pinned nor running: gone from the bar

# launcher: Shift/Ctrl on the selected app lists its actions; the last one is the pin toggle
# (screenshots.sh patches a timer that enters the actions view 4.5 s after the launcher opens)
toggle launcher
shot h3-launcher-pin-action 6
toggle launcher
