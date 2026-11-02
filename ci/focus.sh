# Classic layout: apps button and wifi popup (window resize once, not per frame).
sleep 4
mkdir -p "$HOME/.config/quickshell-local"
echo '{"bar":{"layout":"classic"}}' >"$HOME/.config/quickshell-local/user.json"; sleep 6
shot cl0-bar 1
click 40 1058; sleep 2
shot cl1-apps 1
click 40 1058; sleep 2
click 1612 1058; sleep 2
shot cl2-wifi 1
grep -iE "ERROR|is not a type|Cannot assign|Unable to assign|ReferenceError|TypeError|is not defined|binding loop|Expected|WARN.*(Bar|Launcher)" "$OUT"/quickshell-*.log | sort | uniq -c | tail -20 | tee -a "$OUT/pipeline.log"
