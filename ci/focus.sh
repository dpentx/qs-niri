# Targeted shots (CI_FOCUS=ci/focus.sh): only what the current change needs. Sourced by screenshots.sh,
# so shot / toggle / log are available. Edit this file for the next question and push it.
# Now: long notifications (Show more / chevron) and a big unread count next to the bell.

LONG="This is a long notification body that goes on for several lines so it cannot fit in the collapsed pill or in the two lines a list card shows. It keeps going: build finished with 3 warnings, 12 files changed, and a very long path /home/user/projects/example/src/components/notifications/LongNotificationExample.qml needs a look."
notify-send -a "Mail" "Weekly newsletter" "$LONG"
shot f1-popup-long 2

# the same text in the sidebar list, collapsed
toggle sidebar
shot f2-sidebar-collapsed 3
toggle sidebar
sleep 1.5

# many unread: the bell badge must stay inside the bar pill
for i in $(seq 1 25); do notify-send -a "Chat" "Message $i" "hello $i"; done
sleep 4
shot f3-bell-many 2

# expanded rendering: flip the default in the checkout (Quickshell reloads on file changes)
sed -i 's/property bool expanded: false/property bool expanded: true/' "$REPO/modules/sidebar/SidebarWindow.qml"
sleep 6
toggle sidebar
shot f4-sidebar-expanded 3
toggle sidebar
