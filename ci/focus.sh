# Clock window font + size from the settings, bar right-click actions. Now: settings theme page, then the clock at 150% serif.
sleep 4
mkdir -p "$HOME/.config/quickshell-local"
echo '{"clock":{"font":"serif","scale":1.5}}' >"$HOME/.config/quickshell-local/user.json"
sleep 2
toggle clock; sleep 4
shot ck0-big 1
toggle clock; sleep 2
toggle systools; sleep 3
shot ck1-settings 1
grep -iE "ERROR|is not a type|Cannot assign|Unable to assign|ReferenceError|TypeError|is not defined|binding loop|Expected|WARN.*(Clock|Workspaces|TopBar|BarIcon|Notification)" "$OUT"/quickshell-*.log | tail -20 | tee -a "$OUT/pipeline.log"
