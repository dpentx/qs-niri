# Targeted run (CI_FOCUS=ci/focus.sh): discovery only — niri cast actions.
for c in "niri msg action stop-cast --help" "niri msg action set-dynamic-cast-window --help" "niri msg action set-dynamic-cast-monitor --help" "niri msg action clear-dynamic-cast-target --help" "niri msg action --help" "niri msg --help"; do
  log "== $c"; (eval "$c" 2>&1 | head -40 | while IFS= read -r l; do log "   $l"; done)
done
