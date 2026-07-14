import QtQuick 6.10
import Quickshell.Io
import "../../../services" as QsServices

Row {
    id: root
    property var bar  // Reference to Bar.qml root for inline popup toggle
    spacing: 4

    readonly property var pywal: QsServices.Pywal

    Process {
        id: localsendProc
        command: ["localsend"]
    }

    // Clipboard history
    Text {
        text: "󰅍"
        font.family: "Material Design Icons"
        font.pixelSize: 15
        color: clipHover.containsMouse ? pywal.primary : Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.8)
        anchors.verticalCenter: parent.verticalCenter

        Behavior on color { ColorAnimation { duration: 120 } }

        MouseArea {
            id: clipHover
            anchors.fill: parent
            anchors.margins: -5
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: if (root.bar) root.bar.togglePopup("clipboard")
        }
    }

    // Emoji picker
    Text {
        text: "󰱨"
        font.family: "Material Design Icons"
        font.pixelSize: 15
        color: emojiHover.containsMouse ? pywal.primary : Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.8)
        anchors.verticalCenter: parent.verticalCenter

        Behavior on color { ColorAnimation { duration: 120 } }

        MouseArea {
            id: emojiHover
            anchors.fill: parent
            anchors.margins: -5
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: if (root.bar) root.bar.togglePopup("emoji")
        }
    }

    // LocalSend quick-launch (no reliable official CLI — opens the GUI app)
    Text {
        text: "󰒺"
        font.family: "Material Design Icons"
        font.pixelSize: 15
        color: localsendHover.containsMouse ? pywal.primary : Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.8)
        anchors.verticalCenter: parent.verticalCenter

        Behavior on color { ColorAnimation { duration: 120 } }

        MouseArea {
            id: localsendHover
            anchors.fill: parent
            anchors.margins: -5
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: localsendProc.running = true
        }
    }
}
