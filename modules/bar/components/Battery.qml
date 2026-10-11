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

    readonly property color fillColor: isPluggedIn ? pywal.success
        : isLow ? pywal.error
        : isWarning ? pywal.warning
        : pywal.foreground
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
        width: root.isPluggedIn ? 50 : 40
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
                visible: root.isPluggedIn
                anchors.verticalCenter: parent.verticalCenter
                name: "battery_unified_attr_charging"
                size: 10
                color: parent.tint
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

        // Fill: rounded left end, flat right end until full
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
            // square off the right edge while partial
            Rectangle {
                x: Math.max(0, parent.width - pill.height / 2)
                width: parent.width >= pill.width - 0.5 ? 0 : Math.min(pill.height / 2, parent.width)
                height: pill.height
                color: root.fillColor
            }
            // Dark copy, clipped to the fill
            Content { tint: root.onFill; anchors.verticalCenter: parent.verticalCenter }
        }
    }
}
