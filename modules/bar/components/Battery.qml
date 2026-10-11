import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import Quickshell.Services.UPower
import "../../../services" as QsServices
import "../../../components"
import "../../../components/effects"

// One UI 7 style battery: a pill whose fill is the charge level, with the
// percentage inside it. Charging swaps the fill to green and puts the bolt in
// the pill. The number is drawn twice — light on the track, dark on the fill —
// and the dark copy is clipped to the fill, so it stays legible across the edge.
Item {
    id: root

    readonly property var battery: UPower.displayDevice
    readonly property var pywal: QsServices.Pywal
    readonly property real percentage: battery?.percentage ?? 0
    readonly property int batteryLevel: Math.round(percentage * 100)
    readonly property bool isCharging: battery?.state === UPowerDevice.Charging
    readonly property bool isFullyCharged: battery?.state === UPowerDevice.FullyCharged
    readonly property bool isPluggedIn: isCharging || isFullyCharged
    readonly property bool isWarning: batteryLevel <= 25 && batteryLevel > 15
    readonly property bool isLow: batteryLevel <= 15

    // Set via Binding from Bar.qml — tapping the battery opens the quick menu.
    property var controlCenter

    readonly property bool powerSaver: QsServices.PowerProfiles.activeProfile === "power-saver"

    // Target fill colour for the current state.
    readonly property color targetFill: isPluggedIn ? pywal.success
        : isLow ? pywal.error
        : isWarning ? pywal.warning
        : pywal.foreground

    // Plug-in animation: the fill starts blue, then flows to charging green.
    // `chargeStage` 0 = blue, 1 = settled on the target colour. When the shell
    // starts while already charging the animation is skipped.
    property int chargeStage: 1
    property bool _ready: false
    property color fillColor: chargeStage === 0 ? pywal.primary : targetFill
    Behavior on fillColor { ColorAnimation { duration: 700; easing.type: Easing.OutCubic } }

    Component.onCompleted: _ready = true
    onIsPluggedInChanged: {
        if (!_ready) return
        if (isPluggedIn) {
            chargeStage = 0
            chargeDelay.restart()
            sweepAnim.restart()
        } else {
            chargeStage = 1
            chargeDelay.stop()
        }
    }
    Timer {
        id: chargeDelay
        interval: 350
        onTriggered: root.chargeStage = 1
    }
    readonly property color onFill: pywal.readableOn(fillColor)
    readonly property color trackColor: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.28)
    readonly property color onTrack: pywal.foreground

    implicitWidth: pill.width
    implicitHeight: 24

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.controlCenter)
                root.controlCenter.shouldShow = !root.controlCenter.shouldShow
        }
    }

    Rectangle {
        id: pill
        anchors.centerIn: parent
        height: 20
        width: (root.isPluggedIn || root.powerSaver) ? 50 : 40
        radius: height / 2
        color: root.trackColor
        clip: true
        Behavior on width { NumberAnimation { duration: OneUIMotion.medium2; easing.bezierCurve: OneUIMotion.standard } }

        // Content row: bolt (charging) + number, centered in the pill
        component Content: Row {
            property color tint
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
            x: (pill.width - width) / 2
            spacing: 2
            OneUIIcon {
                visible: root.isPluggedIn || root.powerSaver
                anchors.verticalCenter: parent.verticalCenter
                name: root.isPluggedIn ? "battery_unified_attr_charging" : "stat_sys_power_saving_mode"
                size: root.isPluggedIn ? 10 : 11
                color: parent.tint
                // small pop when charging starts
                SequentialAnimation on scale {
                    id: boltPop
                    running: false
                    NumberAnimation { to: 1.45; duration: 180; easing.type: Easing.OutCubic }
                    NumberAnimation { to: 1.0; duration: 320; easing.type: Easing.OutBack }
                }
                Connections {
                    target: root
                    function onIsPluggedInChanged() { if (root.isPluggedIn && root._ready) boltPop.restart() }
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.batteryLevel
                font.family: "OneUI Sans"
                font.pixelSize: 12
                font.weight: Font.Bold
                color: parent.tint
            }
        }

        // Light copy over the track (full pill)
        Content { tint: root.onTrack; anchors.verticalCenter: parent.verticalCenter }

        // Fill: the pill-shaped bar clipped to the charge width, so the left end is
        // rounded and the right end flat until full
        readonly property real fillW: root.percentage * width
        Item {
            width: pill.fillW
            height: pill.height
            clip: true
            Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

            Rectangle {
                width: pill.width
                height: pill.height
                radius: height / 2
                color: root.fillColor
            }
            // One-shot highlight sweep when charging starts
            Rectangle {
                id: sweep
                width: 10
                height: pill.height
                opacity: 0
                color: Qt.rgba(1, 1, 1, 0.45)
                rotation: 0
                x: -width
                SequentialAnimation {
                    id: sweepAnim
                    PropertyAction { target: sweep; property: "opacity"; value: 1 }
                    NumberAnimation { target: sweep; property: "x"; from: -10; to: pill.width + 10; duration: 650; easing.type: Easing.InOutQuad }
                    PropertyAction { target: sweep; property: "opacity"; value: 0 }
                }
            }
            // Dark copy, clipped to the fill
            Content { tint: root.onFill; anchors.verticalCenter: parent.verticalCenter }
        }
    }
}
