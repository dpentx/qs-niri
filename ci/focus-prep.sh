# Runs before quickshell starts (CI_PREPARE): patch the checkout / config so the panel under test opens as needed.
mkdir -p "$HOME/.config/quickshell-local"
echo '{"profile":"bloated","panels":{"files":{"x":0,"y":60,"w":840,"h":520}}}' >"$HOME/.config/quickshell-local/user.json"
