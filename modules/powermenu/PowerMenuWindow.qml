import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../services" as QsServices
import "../../components/effects"

// OneUI-styled power menu — replaces the external `wlogout` popup (which
// had its own unstyled window and, via its own config, launched hyprlock
// for the lock option) and the standalone bar power button's previous
// behavior of running `systemctl poweroff` with zero confirmation.
//
// Destructive actions (Restart, Shut Down) require a second tap to
// confirm ("arm" on first tap, execute on second, auto-disarms after a
// few seconds of no follow-up) so a stray click can't take the machine
// down.
PanelWindow {
    id: root

    readonly property var pywal: QsServices.Pywal
    readonly property var uiState: QsServices.UIState
    readonly property bool shouldShow: uiState.powerMenuOpen

    property string armedAction: ""

    visible: shouldShow || scrim.opacity > 0

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shouldShow ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell:powermenu"

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    Timer {
        id: disarmTimer
        interval: 3000
        onTriggered: root.armedAction = ""
    }

    function runAction(name, command) {
        if (name === "restart" || name === "shutdown") {
            if (root.armedAction === name) {
                disarmTimer.stop()
                root.armedAction = ""
                uiState.powerMenuOpen = false
                Quickshell.execDetached(command)
            } else {
                root.armedAction = name
                disarmTimer.restart()
            }
            return
        }
        uiState.powerMenuOpen = false
        Quickshell.execDetached(command)
    }

    // Dimming scrim behind the menu card — also the click-outside-to-close target
    Rectangle {
        id: scrim
        anchors.fill: parent
        color: "#000000"
        opacity: root.shouldShow ? 0.5 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: uiState.powerMenuOpen = false
        }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 440
        radius: 24
        color: "#000000"
        clip: true

        implicitHeight: cardColumn.implicitHeight + 32

        focus: true
        Keys.onEscapePressed: uiState.powerMenuOpen = false

        // Fresh state every time the menu opens — otherwise arming
        // Restart/Shut Down, closing without confirming, and reopening
        // later would still show the stale "Tap again" state.
        Connections {
            target: root
            function onShouldShowChanged() {
                if (root.shouldShow) {
                    root.armedAction = ""
                    disarmTimer.stop()
                    card.forceActiveFocus()
                }
            }
        }

        scale: root.shouldShow ? 1.0 : 0.92
        opacity: root.shouldShow ? 1.0 : 0.0

        Behavior on scale {
            NumberAnimation {
                duration: Material3Anim.medium2
                easing.bezierCurve: Material3Anim.emphasizedDecelerate
            }
        }
        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }

        // Swallow clicks so tapping the card itself doesn't close via the scrim
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: cardColumn
            anchors.centerIn: parent
            width: parent.width - 32
            spacing: 14

            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 4
                text: "Power"
                font.family: "OneUI Sans"
                font.pixelSize: 15
                font.weight: Font.DemiBold
                color: pywal.foreground
            }

            // Icon-above-label tile — matches the real OneUI power menu
            // (big circular icon, label underneath, no row background)
            // rather than the earlier list-row treatment.
            component PowerTile: ColumnLayout {
                id: tileRoot
                property string icon: ""
                property string label: ""
                property string armedLabel: ""
                property bool destructive: false
                property bool armed: false
                signal activated()

                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 60
                    Layout.preferredHeight: 60
                    radius: 30
                    color: tileRoot.armed
                        ? "#ff453a"
                        : (tileMouse.containsMouse ? Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.14) : Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.08))

                    Behavior on color { ColorAnimation { duration: 120 } }

                    scale: tileMouse.pressed ? 0.92 : 1.0
                    Behavior on scale {
                        NumberAnimation {
                            duration: Material3Anim.short2
                            easing.bezierCurve: Material3Anim.springGentle
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: tileRoot.icon
                        font.family: "Material Design Icons"
                        font.pixelSize: 24
                        color: tileRoot.armed ? "#000000" : (tileRoot.destructive ? "#ff453a" : pywal.foreground)
                    }

                    MouseArea {
                        id: tileMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: tileRoot.activated()
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: tileRoot.armed && tileRoot.armedLabel !== "" ? tileRoot.armedLabel : tileRoot.label
                    font.family: "OneUI Sans"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: tileRoot.armed ? "#ff453a" : pywal.foreground
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                PowerTile {
                    icon: "󰍁"
                    label: "Lock"
                    onActivated: root.runAction("lock", ["loginctl", "lock-session"])
                }

                PowerTile {
                    icon: "󰤄"
                    label: "Sleep"
                    onActivated: root.runAction("sleep", ["systemctl", "suspend"])
                }

                PowerTile {
                    icon: "󰗽"
                    label: "Log Out"
                    onActivated: root.runAction("logout", ["niri", "msg", "action", "quit", "--skip-confirmation"])
                }

                PowerTile {
                    icon: "󰜉"
                    label: "Restart"
                    armedLabel: "Tap again"
                    destructive: true
                    armed: root.armedAction === "restart"
                    onActivated: root.runAction("restart", ["systemctl", "reboot"])
                }

                PowerTile {
                    icon: "󰐥"
                    label: "Shut Down"
                    armedLabel: "Tap again"
                    destructive: true
                    armed: root.armedAction === "shutdown"
                    onActivated: root.runAction("shutdown", ["systemctl", "poweroff"])
                }
            }
        }
    }

    Component.onCompleted: QsServices.Logger.debug("PowerMenu", "Loaded")
}
