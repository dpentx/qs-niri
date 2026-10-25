# Runs before quickshell starts (CI_PREPARE): patch the checkout so the panel under test opens as needed.
# Show the Shift+Delete confirmation without a keyboard: preset the list it asks about.
sed -i "s|property var deleteAsk: \[\]|property var deleteAsk: [\"$HOME/Pictures\"]|" "$REPO/modules/files/FilesWindow.qml"
