# Targeted shots (CI_FOCUS=ci/focus.sh): only what the current change needs. Sourced by screenshots.sh,
# so shot / toggle / log are available. Edit this file for the next question and push it.
# Now: the One UI 8 wallpaper panel (Tools > Wallpaper) with local images, one applied.

mkdir -p "$HOME/Pictures/Wallpapers"
i=0
for c in "#2b5876-#4e4376" "#f2994a-#f2c94c" "#11998e-#38ef7d" "#cb2d3e-#ef473a" "#005c97-#363795" "#614385-#516395" "#0f2027-#2c5364"; do
  i=$((i+1)); convert -size 1600x900 "gradient:${c}" "$HOME/Pictures/Wallpapers/wall-$i.jpg"
done
sleep 1
toggle systools
shot w1-wallpaper-local 3
