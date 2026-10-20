import QtQuick 6.10
import "../../../services" as QsServices
import "../../../components"
import "../../../config" as QsConfig

// Active keyboard layout (TR, EN, ...); click switches to the next one. Hidden with a single layout.
Item {
    id: root

    readonly property var pywal: QsServices.Pywal
    readonly property var kb: QsServices.KeyboardLayout

    visible: kb.multiple
    implicitWidth: kb.multiple ? label.implicitWidth + 14 : 0
    implicitHeight: 22

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, hover.hovered ? 0.16 : 0.08)
    }
    Text {
        id: label
        anchors.centerIn: parent
        text: root.kb.code
        color: pywal.foreground
        font.family: QsConfig.Config.appearance.fontFamily
        font.pixelSize: QsConfig.Appearance.fontSize.s
        font.weight: Font.DemiBold
    }
    HoverHandler { id: hover }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.kb.next()
    }
}
