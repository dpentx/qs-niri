# Agenda: pick a day, add on that day. Now: open the clock window to see where the Agenda tab is.
sleep 4
mkdir -p "$HOME/.config/quickshell-local"
echo '{}' >"$HOME/.config/quickshell-local/user.json"
toggle clock; sleep 4
click 763 574; sleep 1
shot ag1-day 1
click 763 574; sleep 1
shot ag2-unsel 1
grep -iE "ERROR|is not a type|Cannot assign|Unable to assign|ReferenceError|TypeError|is not defined|binding loop|Expected" "$OUT"/quickshell-*.log | tail -20 | tee -a "$OUT/pipeline.log"
