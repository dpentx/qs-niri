import QtQuick 6.10
import QtQuick.Layouts 6.10
import "../../../components/effects"
import "../../../services" as QsServices

// Simple focus/pomodoro timer. Integrates with Settings.qml
// (focusModeEnabled / focusModeMinutesLeft) so state persists.
Rectangle {
    id: root

    property var pywal
    readonly property var settings: QsServices.Settings

    readonly property color surfaceColor: pywal ? pywal.surfaceContainerHighest : "#1a1a1a"
    readonly property color textColor: pywal ? pywal.foreground : "#dddddd"
    readonly property color accentColor: pywal ? pywal.primary : "#88cc88"

    readonly property bool running: settings.focusModeEnabled
    readonly property int minutesLeft: settings.focusModeMinutesLeft

    Layout.fillWidth: true
    Layout.preferredHeight: 64

    radius: 22
    color: surfaceColor
    border.width: 1
    border.color: pywal ? pywal.outlineVariant : Qt.rgba(1, 1, 1, 0.12)

    Behavior on color {
        ColorAnimation {
            duration: Material3Anim.medium2
            easing.bezierCurve: Material3Anim.standard
        }
    }

    // Ticks down every minute while running
    Timer {
        interval: 60000
        running: root.running && root.minutesLeft > 0
        repeat: true
        onTriggered: {
            if (settings.focusModeMinutesLeft > 0)
                settings.focusModeMinutesLeft -= 1
            if (settings.focusModeMinutesLeft <= 0)
                settings.focusModeEnabled = false
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 12
        spacing: 12

        // Icon
        Rectangle {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            radius: 20
            color: root.running
                ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.18)
                : Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.08)

            Behavior on color { ColorAnimation { duration: 200 } }

            Text {
                anchors.centerIn: parent
                text: "󰔟"
                font.family: "Material Design Icons"
                font.pixelSize: 20
                color: root.running ? root.accentColor : root.textColor
            }

            // Slow pulse while running
            SequentialAnimation on opacity {
                running: root.running
                loops: Animation.Infinite
                NumberAnimation { to: 0.6; duration: 1200; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 1200; easing.type: Easing.InOutSine }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: "Focus Mode"
                font.family: "Inter"
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: root.textColor
            }

            Text {
                text: root.running
                    ? `${root.minutesLeft} dakika kaldı`
                    : "Kapalı"
                font.family: "Inter"
                font.pixelSize: 11
                color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.6)
            }
        }

        // -5 / +5 minute adjust (only while running)
        RowLayout {
            visible: root.running
            spacing: 4

            Rectangle {
                width: 26; height: 26; radius: 13
                color: minusArea.containsMouse ? Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.12) : "transparent"
                Text { anchors.centerIn: parent; text: "−"; font.pixelSize: 16; color: root.textColor }
                MouseArea {
                    id: minusArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: settings.focusModeMinutesLeft = Math.max(1, settings.focusModeMinutesLeft - 5)
                }
            }

            Rectangle {
                width: 26; height: 26; radius: 13
                color: plusArea.containsMouse ? Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.12) : "transparent"
                Text { anchors.centerIn: parent; text: "+"; font.pixelSize: 16; color: root.textColor }
                MouseArea {
                    id: plusArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: settings.focusModeMinutesLeft += 5
                }
            }
        }

        // Start/Stop toggle
        Rectangle {
            Layout.preferredWidth: toggleText.implicitWidth + 24
            Layout.preferredHeight: 32
            radius: 16
            color: root.running
                ? Qt.rgba(root.pywal.error.r, root.pywal.error.g, root.pywal.error.b, 0.16)
                : Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.18)

            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                id: toggleText
                anchors.centerIn: parent
                text: root.running ? "Durdur" : "Başlat (25dk)"
                font.family: "Inter"
                font.pixelSize: 11
                font.weight: Font.Medium
                color: root.running ? root.pywal.error : root.accentColor
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.running) {
                        settings.focusModeEnabled = false
                    } else {
                        settings.focusModeMinutesLeft = 25
                        settings.focusModeEnabled = true
                    }
                }
            }
        }
    }
}
