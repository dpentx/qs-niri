# Runs before quickshell starts (CI_PREPARE): patch the checkout so the panel under test opens directly.
sed -i 's/property string selectedTab: "network"/property string selectedTab: "wallpaper"/' "$REPO/modules/systools/SystemToolsWindow.qml"
