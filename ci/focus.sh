# Layout switch at runtime: the apps button must still open the launcher in classic.
sleep 4
mkdir -p "$HOME/.config/quickshell-local"
echo '{"bar":{"layout":"classic"}}' >"$HOME/.config/quickshell-local/user.json"; sleep 6
click 40 1058; sleep 2
shot cl1-apps 1
click 40 1058; sleep 1
click 1608 1058; sleep 2
shot cl2-wifi 1
# done
