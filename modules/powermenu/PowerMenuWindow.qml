import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../services" as QsServices
import "../../components"
import "../../components/effects"
import "../../config" as QsConfig

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

    BackgroundEffect.blurRegion: QsConfig.Appearance.blur ? _blur : null
    Region { id: _blur; item: card; radius: card.radius }

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
        radius: QsConfig.Appearance.radius.xl
        color: pywal.panelBackground
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
                duration: OneUIMotion.medium2
                easing.bezierCurve: OneUIMotion.emphasizedDecelerate
            }
        }
        Behavior on opacity { NumberAnimation { duration: 150 } }

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
                        ? pywal.error
                        : (tileMouse.containsMouse ? Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.14) : Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.08))

                    Behavior on color { ColorAnimation { duration: 120 } }

                    scale: tileMouse.pressed ? 0.92 : 1.0
                    Behavior on scale {
                        NumberAnimation {
                            duration: OneUIMotion.short2
                            easing.bezierCurve: OneUIMotion.springGentle
                        }
                    }

                    OneUIIcon {
                        anchors.centerIn: parent
                        name: tileRoot.icon
                        size: tileRoot.icon === "quick_panel_icon_sync" ? 44 : 26  // that SVG has a 42-unit canvas with small art
                        color: tileRoot.armed ? pywal.readableOn(pywal.error) : (tileRoot.destructive ? pywal.error : pywal.foreground)
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
                    color: tileRoot.armed ? pywal.error : pywal.foreground
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                PowerTile {
                    icon: "ic_lock_locked"
                    label: "Lock"
                    onActivated: root.runAction("lock", ["loginctl", "lock-session"])
                }

                PowerTile {
                    icon: "moon"
                    label: "Sleep"
                    onActivated: root.runAction("sleep", ["systemctl", "suspend"])
                }

                PowerTile {
                    icon: "ic_samsung_sysbar_back"
                    label: "Log Out"
                    onActivated: root.runAction("logout", ["niri", "msg", "action", "quit", "--skip-confirmation"])
                }

                PowerTile {
                    icon: "quick_panel_icon_sync"
                    label: "Restart"
                    armedLabel: "Tap again"
                    destructive: true
                    armed: root.armedAction === "restart"
                    onActivated: root.runAction("restart", ["systemctl", "reboot"])
                }

                PowerTile {
                    icon: "ic_qs_footer_power"
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
