# Targeted run (CI_FOCUS=ci/focus.sh): discovery only — what the nested niri offers for screencasts.
for c in "niri --version" "niri msg --help" "niri msg action --help" "niri msg casts" "niri msg --json casts" "niri msg --json outputs"; do
  log "== $c"; (eval "$c" 2>&1 | head -80 | while IFS= read -r l; do log "   $l"; done)
done
log "== wl-mirror / gnome-network-displays on nixpkgs"
for p in wl-mirror gnome-network-displays; do nix-shell -p $p --run "which ${p/gnome-network-displays/gnome-network-displays}" 2>&1 | tail -2 | while IFS= read -r l; do log "   $p: $l"; done; done
