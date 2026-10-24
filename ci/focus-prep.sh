# Runs before quickshell starts (CI_PREPARE): patch the checkout so the panel under test opens directly.
mkdir -p "$HOME/Pictures/Wallpapers"
i=0
for c in "#2b5876-#4e4376" "#f2994a-#f2c94c" "#11998e-#38ef7d" "#cb2d3e-#ef473a" "#005c97-#363795" "#614385-#516395" "#0f2027-#2c5364"; do
  i=$((i+1)); magick -size 1600x900 "gradient:${c}" "$HOME/Pictures/Wallpapers/wall-$i.jpg"
done
sed -i 's/property string selectedTab: "network"/property string selectedTab: "wallpaper"/' "$REPO/modules/systools/SystemToolsWindow.qml"
