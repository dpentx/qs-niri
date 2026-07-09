import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell.Io
import "../../../services" as QsServices

// Shows the active keyboard layout (e.g. "TR", "US") and switches
// to the next layout on click via `niri msg action switch-layout next`.
Item {
    id: root

    readonly property var pywal: QsServices.Pywal
    readonly property bool isHovered: mouseArea.containsMouse

    property string layoutName: "??"

    implicitWidth: row.implicitWidth
    implicitHeight: 20

    function shortName(name) {
        // niri reports full XKB layout names, e.g. "English (US)", "Turkish"
        const map = {
            "English (US)": "US",
            "English (UK)": "UK",
            "Turkish": "TR",
            "Turkish (F)": "TR-F",
            "German": "DE",
            "Russian": "RU"
        }
        if (map[name]) return map[name]
        // fallback: take first 2 letters, uppercase
        const cleaned = name.replace(/\(.*?\)/g, "").trim()
        return cleaned.slice(0, 2).toUpperCase()
    }

    Process {
        id: layoutProc
        command: ["niri", "msg", "-j", "keyboard-layouts"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text)
                    const idx = data.current_idx ?? 0
                    const names = data.names ?? []
                    if (names.length > 0) {
                        root.layoutName = root.shortName(names[idx] ?? names[0])
                    }
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: layoutProc.running = true
    }

    Process {
        id: switchProc
        command: ["niri", "msg", "action", "switch-layout", "next"]
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: "󰌌"
            font.family: "Material Design Icons"
            font.pixelSize: 13
            color: root.isHovered ? root.pywal.primary : Qt.rgba(root.pywal.foreground.r, root.pywal.foreground.g, root.pywal.foreground.b, 0.7)

            Behavior on color { ColorAnimation { duration: 150 } }
        }

        Text {
            text: root.layoutName
            font.family: "Inter"
            font.pixelSize: 10
            font.weight: Font.Medium
            color: root.isHovered ? root.pywal.foreground : Qt.rgba(root.pywal.foreground.r, root.pywal.foreground.g, root.pywal.foreground.b, 0.75)

            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            switchProc.running = true
            layoutProc.running = true
        }
    }
}
