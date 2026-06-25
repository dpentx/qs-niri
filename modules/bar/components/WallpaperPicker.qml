import QtQuick 6.10
import QtQuick.Layouts 6.10
import "../../../services" as QsServices
import "../../../components/effects"

// Bar icon that opens/closes the wallpaper picker popup.
Item {
    id: root

    property var bar   // set by Bar.qml via Binding

    readonly property var pywal: QsServices.Pywal
    readonly property bool isActive: bar?.activePopup === "wallpaper"
    readonly property bool isHovered: mouseArea.containsMouse

    implicitWidth: row.implicitWidth
    implicitHeight: 20

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: "󰸉"
            font.family: "Material Design Icons"
            font.pixelSize: 14
            color: root.isActive
                ? root.pywal.primary
                : root.isHovered
                    ? root.pywal.primary
                    : Qt.rgba(root.pywal.foreground.r, root.pywal.foreground.g, root.pywal.foreground.b, 0.7)

            Behavior on color { ColorAnimation { duration: 150 } }

            scale: root.isActive ? 1.1 : root.isHovered ? 1.05 : 1.0
            Behavior on scale { NumberAnimation { duration: 120 } }
        }

        Text {
            text: "WP"
            font.family: "Inter"
            font.pixelSize: 10
            font.weight: Font.Medium
            color: root.isActive
                ? root.pywal.primary
                : Qt.rgba(root.pywal.foreground.r, root.pywal.foreground.g, root.pywal.foreground.b, 0.75)

            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: bar?.togglePopup("wallpaper")
    }
}
