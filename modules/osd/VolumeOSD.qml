import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "../../services" as QsServices
import "../../config" as QsConfig
import "../../components/effects"

PanelWindow {
    id: root

    required property var pywal
    property bool showing: false

    readonly property var audio: QsServices.Audio
    property int currentVolume: 0
    property bool currentMuted: false
    property int prevVolume: -1
    property bool prevMuted: false

    readonly property var appearance: QsConfig.AppearanceConfig
    readonly property var config: QsConfig.Config

    visible: showing

    // Stay visible over fullscreen apps/games — see BarWrapper.qml for the
    // full explanation of Top vs Overlay layer-shell layers.
    WlrLayershell.layer: WlrLayer.Overlay

    anchors {
        top: true
        right: true
    }

    margins {
        top: 20
        right: 12
    }

    implicitWidth: 286
    implicitHeight: 60
    color: "transparent"

    mask: Region { item: container }

    Timer {
        id: hideTimer
        interval: config.osd.volumeTimeoutMs
        onTriggered: root.showing = false
    }

    Connections {
        target: audio

        function onPercentageChanged() {
            root.currentVolume = audio.percentage
            if (prevVolume !== -1 && root.currentVolume !== prevVolume)
                root.show()
            prevVolume = root.currentVolume
        }

        function onMutedChanged() {
            root.currentMuted = audio.muted
            if (root.currentMuted !== prevMuted)
                root.show()
            prevMuted = root.currentMuted
        }
    }

    Timer {
        interval: 150
        running: true
        repeat: true
        onTriggered: {
            const volume = audio.percentage
            const muted = audio.muted

            root.currentVolume = volume
            root.currentMuted = muted

            if (prevVolume !== -1 && volume !== prevVolume)
                root.show()
            if (muted !== prevMuted)
                root.show()

            prevVolume = volume
            prevMuted = muted
        }
    }

    Component.onCompleted: {
        root.currentVolume = audio.percentage
        root.currentMuted = audio.muted
        prevVolume = root.currentVolume
        prevMuted = root.currentMuted
    }

    function show() {
        showing = true
        hideTimer.restart()
    }

    Rectangle {
        id: container
        anchors.fill: parent
        radius: height / 2  // full pill — OneUI toast/OSD chips aren't just rounded, they're capsule-shaped
        color: pywal.surfaceContainerHighest
        // OneUI panels read flat — no outline stroke (consistent with the
        // rest of the shell's AuroraSurface panels, which dropped their
        // border for the same reason)

        opacity: root.showing ? 1.0 : 0.0
        scale: root.showing ? 1.0 : 0.94
        transformOrigin: Item.Center

        Behavior on opacity {
            NumberAnimation {
                duration: OneUIMotion.short4
                easing.bezierCurve: root.showing ? OneUIMotion.emphasizedDecelerate : OneUIMotion.emphasizedAccelerate
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: OneUIMotion.short4
                easing.bezierCurve: root.showing ? OneUIMotion.emphasizedDecelerate : OneUIMotion.emphasizedAccelerate
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 14

            Text {
                text: root.currentMuted ? "󰆁" : (root.currentVolume > 66 ? "󰅞" : (root.currentVolume > 33 ? "󰅠" : "󰅟"))
                font.family: "Material Design Icons"
                color: root.currentMuted ? Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.5) : pywal.primary
                font.pixelSize: 22
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 10
                radius: 5
                color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.12)

                Rectangle {
                    width: parent.width * (root.currentVolume / 100)
                    height: parent.height
                    radius: 5
                    color: root.currentMuted ? Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.4) : pywal.primary

                    Behavior on width {
                        NumberAnimation {
                            duration: 100
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on color {
                        ColorAnimation { duration: 100 }
                    }
                }

                Rectangle {
                    width: 12
                    height: 12
                    radius: 6
                    x: Math.max(0, Math.min(parent.width - width, parent.width * (root.currentVolume / 100) - width / 2))
                    y: (parent.height - height) / 2
                    color: root.currentMuted ? Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.55) : pywal.primary
                    // no border — OneUI's own slider thumb is a plain filled
                    // dot, not a OneUI-style outlined handle
                }
            }

            Text {
                text: root.currentVolume + "%"
                color: pywal.foreground
                font.family: "OneUI Sans"
                font.pixelSize: 14
                font.weight: Font.DemiBold
                Layout.preferredWidth: 42
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
