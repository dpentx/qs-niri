# New features: shortcut list (needs a niri config with binds), alt-tab with a few windows, dashboard cards.
sleep 4
mkdir -p "$HOME/.config/niri"
cat >"$HOME/.config/niri/config.kdl" <<'KDL'
binds {
    Mod+D hotkey-overlay-title="Launcher" { spawn "touch" "/tmp/qs-launcher"; }
    Mod+Shift+E { quit; }
    Alt+Tab { spawn "touch" "/tmp/qs-alttab"; }
    Mod+Q { close-window; }
}
KDL
toggle keys; sleep 3
shot nf0-keys 1
toggle keys; sleep 2
toggle dashboard; sleep 3
shot nf1-dash 1
toggle dashboard; sleep 2
grep -iE "ERROR|is not a type|Cannot assign|Unable to assign|ReferenceError|TypeError|is not defined|binding loop|Expected|not installed" "$OUT"/quickshell-*.log | sort | uniq -c | tail -20 | tee -a "$OUT/pipeline.log"
