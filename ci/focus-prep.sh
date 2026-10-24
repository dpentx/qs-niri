# Runs before quickshell starts (CI_PREPARE): patch the checkout so the panel under test opens directly.
sed -i 's/selectedTab = "network"/selectedTab = "wallpaper"/' "$REPO/modules/systools/SystemToolsWindow.qml"
