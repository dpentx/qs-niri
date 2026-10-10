import QtQuick 6.10
import QtQuick.Layouts 6.10
import "../../../components"
import "../../../config" as QsConfig

// One UI quick-panel brightness bar: a full-width pill track whose fill
// grows from the left (clipped by the pill, no thumb), sun glyph inside.
Item {
    id: root

    required property var brightness
    property var pywal

    readonly property real level: brightness ? Math.max(0, Math.min(1, brightness.brightness ?? 0)) : 0
    readonly property color fillColor: pywal.primary
    readonly property bool iconOnFill: level * track.width > icon.x + icon.width / 2

    Layout.fillWidth: true
    Layout.preferredHeight: 40
    implicitHeight: 40
    activeFocusOnTab: true

    Keys.onLeftPressed: root.brightness.setBrightness(root.level - 0.05)
    Keys.onRightPressed: root.brightness.setBrightness(root.level + 0.05)

    function setFromX(x) {
        root.brightness.setBrightness(Math.max(0, Math.min(1, x / track.width)))
    }

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Qt.rgba(root.pywal.foreground.r, root.pywal.foreground.g, root.pywal.foreground.b, 0.18)
        clip: true
        border.width: root.activeFocus ? QsConfig.Appearance.border.focus : 0
        border.color: root.pywal.primary

        // Fill: wider than the visible part so the pill clips its right edge
        // flat, like One UI. No width animation, so dragging stays 1:1.
        Rectangle {
            width: root.level * track.width
            height: parent.height
            color: root.fillColor
        }

        OneUIIcon {
            id: icon
            x: 12
            anchors.verticalCenter: parent.verticalCenter
            name: "sun"
            size: 20
            color: root.iconOnFill ? root.pywal.readableOn(root.fillColor) : root.pywal.foreground
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => { root.forceActiveFocus(); root.setFromX(mouse.x) }
        onPositionChanged: mouse => { if (pressed) root.setFromX(mouse.x) }
        onWheel: wheel => root.brightness.setBrightness(root.level + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))
    }
}
