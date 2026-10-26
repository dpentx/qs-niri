import QtQuick 6.10
import QtQuick.Layouts 6.10
import "../../../components"
import "../../../config" as QsConfig

// One UI quick-panel volume bar: a full-width pill track whose fill
// grows from the left (clipped by the pill, no thumb), speaker glyph inside.
Item {
    id: root

    required property var audio
    property var pywal

    readonly property real level: audio ? Math.max(0, Math.min(1.0, audio.volume ?? 0)) : 0
    readonly property bool isMuted: audio ? (audio.muted || level <= 0.001) : false
    readonly property color fillColor: isMuted ? Qt.rgba(root.pywal.foreground.r, root.pywal.foreground.g, root.pywal.foreground.b, 0.35) : root.pywal.primary
    readonly property bool iconOnFill: !isMuted && (level * track.width > icon.x + icon.width / 2)

    Layout.fillWidth: true
    Layout.preferredHeight: 40
    implicitHeight: 40
    activeFocusOnTab: true

    Keys.onLeftPressed: if (root.audio) root.audio.decreaseVolume()
    Keys.onRightPressed: if (root.audio) root.audio.increaseVolume()
    Keys.onSpacePressed: if (root.audio) root.audio.toggleMute()

    function setFromX(x) {
        if (!root.audio) return
        const val = Math.max(0, Math.min(1.0, x / track.width))
        root.audio.setVolume(val)
    }

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Qt.rgba(root.pywal.foreground.r, root.pywal.foreground.g, root.pywal.foreground.b, 0.18)
        border.width: root.activeFocus ? QsConfig.Appearance.border.focus : 0
        border.color: root.pywal.primary

        // Fill: rounded left end; cover squares off the right end
        readonly property real fillW: root.isMuted ? 0 : root.level * track.width
        Rectangle {
            width: track.fillW
            height: parent.height
            radius: height / 2
            color: root.fillColor
            visible: width > 0
        }
        Rectangle {
            readonly property real x0: Math.max(0, track.fillW - parent.height / 2)
            x: x0
            width: track.fillW >= track.width - 0.5 ? 0 : Math.max(0, track.fillW - x0)
            height: parent.height
            color: root.fillColor
            visible: track.fillW > 0
        }

        OneUIIcon {
            id: icon
            x: 12
            anchors.verticalCenter: parent.verticalCenter
            name: root.isMuted ? "ic_speaker_mute" : "ic_speaker_on"
            size: 20
            color: root.iconOnFill ? root.pywal.readableOn(root.fillColor) : (root.isMuted ? Qt.rgba(root.pywal.foreground.r, root.pywal.foreground.g, root.pywal.foreground.b, 0.4) : root.pywal.foreground)
            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => {
            root.forceActiveFocus()
            // Click on the speaker icon toggles mute
            if (mouse.x <= 36) {
                if (root.audio) root.audio.toggleMute()
            } else {
                root.setFromX(mouse.x)
            }
        }
        onPositionChanged: mouse => {
            if (pressed && mouse.x > 36) root.setFromX(mouse.x)
        }
        onWheel: wheel => {
            if (!root.audio) return
            if (wheel.angleDelta.y > 0) root.audio.increaseVolume()
            else root.audio.decreaseVolume()
        }
    }
}
