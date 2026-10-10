import QtQuick 6.10
import "../../../components"
import "../../../components/effects"
import "../../../config" as QsConfig
import "../../../services" as QsServices

// Compact icon button for the bar pills: SVG glyph, hover state layer,
// "open" state (while its popup is showing), keyboard focus ring and
// Enter/Space activation.
Item {
    id: root

    property string iconName: ""
    property color tint: pywal.foreground
    property bool open: false
    property string tooltip: ""
    signal clicked()

    readonly property var pywal: QsServices.Pywal
    readonly property bool hovered: mouse.containsMouse

    implicitWidth: 28
    implicitHeight: 28
    activeFocusOnTab: true
    Keys.onReturnPressed: root.clicked()
    Keys.onEnterPressed: root.clicked()
    Keys.onSpacePressed: root.clicked()

    Rectangle {
        anchors.fill: parent
        radius: QsConfig.Appearance.radius.s
        color: root.open ? pywal.primary : pywal.foreground
        opacity: root.open ? 0.22 : (root.hovered ? OneUIMotion.hoverOpacity + 0.04 : 0)
        border.width: root.activeFocus ? QsConfig.Appearance.border.focus : 0
        border.color: pywal.primary
        Behavior on opacity { NumberAnimation { duration: OneUIMotion.short3 } }
    }

    OneUIIcon {
        anchors.centerIn: parent
        name: root.iconName
        size: 18
        color: root.open || root.hovered ? pywal.primary : root.tint
        scale: mouse.pressed ? OneUIMotion.pressedScale : 1.0
        Behavior on color { ColorAnimation { duration: OneUIMotion.short2 } }
        Behavior on scale { NumberAnimation { duration: OneUIMotion.short2 } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.forceActiveFocus()
            root.clicked()
        }
    }
}
