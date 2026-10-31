# Targeted shots (CI_FOCUS=ci/focus.sh): only what the current change needs. Sourced by screenshots.sh,
# so shot / toggle / log / click / typekeys are available. Edit this file for the next question and push it.
# Now: real pointer + keyboard input (wlrctl / wtype through Sway): launcher star, Files caption menu, reminder form.

sleep 3
mkdir -p "$HOME/.config/quickshell-local"
UJ="$HOME/.config/quickshell-local/user.json"
echo '{}' >"$UJ"

# 1. launcher: click the star of the Firefox favourite -> it must leave launcher.favorites
toggle launcher; sleep 1.5
shot i0-launcher-before 0.5
click 178 843
shot i1-launcher-after-star 1
log "user.json after star: $(cat "$UJ")"
toggle launcher; sleep 1

# 2. Files window: open the handle menu, snap to the right
toggle files; sleep 2.5
click 33 55
shot i2-files-handle-menu 1
click 60 126
sleep 1
shot i3-files-snapped 1
niri msg --json windows 2>&1 | python3 -c 'import json,sys; [print(w["title"], w["layout"]["window_size"], w["layout"]["pos_in_scrolling_layout"]) for w in json.load(sys.stdin)]' | tee -a "$OUT/pipeline.log"
toggle files; sleep 1

# 3. reminder form: type text, a time, Enter
toggle clock; sleep 2
click 1095 483
typekeys "Real typed reminder"
click 1205 483
typekeys "+30"
typekeys -k Return
shot i4-reminder-added 1
log "user.json after reminder: $(cat "$UJ")"
grep -iE "ERROR|is not a type|Cannot assign|Unable to assign|ReferenceError|TypeError|is not defined" "$OUT"/quickshell-*.log | tail -20 | tee -a "$OUT/pipeline.log"
