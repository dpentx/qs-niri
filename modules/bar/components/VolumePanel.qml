import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Effects
import "../../../services" as QsServices
import "../../../config" as QsConfig
import "../../../components"
import "../../../components/effects"

// Inline volume panel (bar popup): a single pill with mute button, level track and percentage.
FocusScope {
    id: panel

    property bool shouldShow: false
    signal closeRequested()

    readonly property var pywal: QsServices.Pywal
    readonly property var audio: QsServices.Audio
    readonly property color cText: pywal.foreground
    readonly property real level: Math.max(0, Math.min(1, audio.volume))

    implicitWidth: 300
    implicitHeight: 56
    focus: true

    Keys.onEscapePressed: closeRequested()
    Keys.onLeftPressed: audio.decreaseVolume()
    Keys.onDownPressed: audio.decreaseVolume()
    Keys.onRightPressed: audio.increaseVolume()
    Keys.onUpPressed: audio.increaseVolume()

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        // denser than popupSurface: this popup has no compositor blur behind it
        color: pywal.notificationSurface

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.35)
            shadowBlur: 1.0
            shadowVerticalOffset: 6
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 20
            spacing: 12

            // mute button
            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: width / 2
                color: muteMouse.containsMouse ? Qt.rgba(panel.cText.r, panel.cText.g, panel.cText.b, 0.12) : "transparent"
                Behavior on color { ColorAnimation { duration: OneUIMotion.short3 } }

                OneUIIcon {
                    anchors.centerIn: parent
                    size: 20
                    name: panel.audio.muted ? "ic_speaker_mute" : "ic_speaker_on"
                    color: panel.cText
                }
                MouseArea {
                    id: muteMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: panel.audio.toggleMute()
                }
            }

            // level track: drag, click or wheel
            Item {
                id: trackBox
                Layout.fillWidth: true
                Layout.preferredHeight: 24

                function setFromX(x) { panel.audio.setVolume(Math.max(0, Math.min(1, x / width))) }

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Qt.rgba(panel.cText.r, panel.cText.g, panel.cText.b, 0.18)
                    Rectangle {
                        width: panel.level * parent.width
                        height: parent.height
                        radius: height / 2
                        color: panel.audio.muted ? Qt.rgba(panel.cText.r, panel.cText.g, panel.cText.b, 0.35) : panel.pywal.primary
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onPressed: mouse => trackBox.setFromX(mouse.x)
                    onPositionChanged: mouse => { if (pressed) trackBox.setFromX(mouse.x) }
                    onWheel: wheel => wheel.angleDelta.y > 0 ? panel.audio.increaseVolume() : panel.audio.decreaseVolume()
                }
            }

            Text {
                Layout.preferredWidth: 30
                horizontalAlignment: Text.AlignRight
                text: panel.audio.percentage
                color: Qt.rgba(panel.cText.r, panel.cText.g, panel.cText.b, panel.audio.muted ? 0.4 : 0.85)
                font.family: QsConfig.Config.appearance.fontFamily
                font.pixelSize: QsConfig.Appearance.fontSize.m
                font.weight: Font.Medium
            }
        }
    }
}
