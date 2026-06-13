import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell.Io
import "../../../services" as QsServices

// Caps Lock indicator — only visible while Caps Lock is active
Item {
    id: root

    readonly property var pywal: QsServices.Pywal
    property bool capsActive: false

    implicitWidth: capsActive ? pill.implicitWidth + 4 : 0
    implicitHeight: 20
    visible: capsActive
    opacity: capsActive ? 1 : 0

    Behavior on implicitWidth {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }
    Behavior on opacity {
        NumberAnimation { duration: 150 }
    }

    // Poll caps lock state via hyprctl/niri-compatible approach:
    // LED state is exposed through /sys, works regardless of compositor.
    Process {
        id: capsProc
        command: ["/bin/sh", "-c", "cat /sys/class/leds/*::capslock/brightness 2>/dev/null | head -1"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const v = text.trim()
                root.capsActive = v === "1"
            }
        }
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: capsProc.running = true
    }

    Rectangle {
        id: pill
        anchors.centerIn: parent
        implicitWidth: pillRow.implicitWidth + 14
        height: 20
        radius: 10
        color: Qt.rgba(root.pywal.warning.r, root.pywal.warning.g, root.pywal.warning.b, 0.18)

        RowLayout {
            id: pillRow
            anchors.centerIn: parent
            spacing: 4

            Text {
                text: "󰪛"
                font.family: "Material Design Icons"
                font.pixelSize: 12
                color: root.pywal.warning
            }

            Text {
                text: "CAPS"
                font.family: "Inter"
                font.pixelSize: 10
                font.weight: Font.Bold
                color: root.pywal.warning
            }
        }
    }
}
