# Targeted shots (CI_FOCUS=ci/focus.sh): only what the current change needs. Sourced by screenshots.sh,
# (rerun: system page order)
# so shot / toggle / log are available. Edit this file for the next question and push it.
# Now: merged settings pages, classic bar with the shared StatusPills.

sleep 3
toggle systools
sleep 2
shot s0-system-page 1.5
touch /tmp/qs-ci-abouttab
sleep 1.5
shot s1-general-page 1.5
toggle systools
mkdir -p "$HOME/.config/quickshell-local"
echo '{"bar":{"layout":"classic"}}' >"$HOME/.config/quickshell-local/user.json"
sleep 4
shot s2-classic-pills 2
echo '{"bar":{"layout":"dex"},"appearance":{"screenScale":{"winit":0.8}}}' >"$HOME/.config/quickshell-local/user.json"
sleep 4
shot s3-dex-scale-80 2
grep -iE "ERROR|is not a type|Cannot assign|Unable to assign|ReferenceError|TypeError|is not defined" "$OUT"/quickshell-*.log | tail -20 | tee -a "$OUT/pipeline.log"
