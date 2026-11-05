# alt-tab with the open windows, and the debug report.
sleep 4
toggle alttab; sleep 3
shot nf2-alttab 1
toggle diag; sleep 5
{ echo "--- diag"; ls -la /tmp/qs-diag* 2>&1; cat /tmp/qs-diag.txt 2>&1 | head -30; } | tee -a "$OUT/pipeline.log"
grep -iE "ERROR|is not a type|Cannot assign|Unable to assign|ReferenceError|TypeError|is not defined|binding loop|Expected|diag" "$OUT"/quickshell-*.log | sort | uniq -c | tail -20 | tee -a "$OUT/pipeline.log"
