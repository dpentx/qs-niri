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
        border.width: root.activeFocus ? QsConfig.Appearance.border.focus : 0
        border.color: root.pywal.primary

        // Fill: rounded left end; the cover below squares off the right end
        // (like One UI) until the bar is full, where the pill shape shows.
        readonly property real fillW: root.level * track.width
        Rectangle {
            width: track.fillW
            height: parent.height
            radius: height / 2
            color: root.fillColor
        }
        Rectangle {
            readonly property real x0: Math.max(0, track.fillW - parent.height / 2)
            x: x0
            width: track.fillW >= track.width - 0.5 ? 0 : track.fillW - x0
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
