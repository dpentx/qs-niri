import QtQuick 6.10import QtQuick 6.10

import QtQuick.Layouts 6.10import QtQuick.Layouts 6.10

import QtQuick.Effectsimport QtQuick.Effects

import Quickshellimport Quickshell

import Quickshell.Waylandimport Quickshell.Wayland

import "../../services" as QsServicesimport "../../services" as QsServices



// Material 3 Expressive System Dashboard// Material 3 Expressive System Dashboard

PanelWindow {PanelWindow {

    id: root    id: root

        

    property bool shouldShow: false    property bool shouldShow: false

    readonly property var pywal: QsServices.Pywal    readonly property var pywal: QsServices.Pywal

    readonly property var network: QsServices.Network    readonly property var network: QsServices.Network

    readonly property var audio: QsServices.Audio    readonly property var audio: QsServices.Audio

    readonly property var brightness: QsServices.Brightness    readonly property var brightness: QsServices.Brightness

    readonly property var systemUsage: QsServices.SystemUsage    readonly property var systemUsage: QsServices.SystemUsage

    readonly property var time: QsServices.Time    readonly property var time: QsServices.Time

    readonly property var notifs: QsServices.Notifs    readonly property var notifs: QsServices.Notifs

    readonly property var players: QsServices.Players    readonly property var players: QsServices.Players

        

    // Material 3 colors    // Material 3 colors

    readonly property color m3Surface: Qt.rgba(pywal.background.r, pywal.background.g, pywal.background.b, 1.0)    readonly property color m3Surface: Qt.rgba(pywal.background.r, pywal.background.g, pywal.background.b, 1.0)

    readonly property color m3SurfaceContainer: Qt.rgba(    readonly property color m3SurfaceContainer: Qt.rgba(

        pywal.background.r * 1.08,        pywal.background.r * 1.08,

        pywal.background.g * 1.08,        pywal.background.g * 1.08,

        pywal.background.b * 1.08,        pywal.background.b * 1.08,

        1.0        1.0

    )    )

    readonly property color m3Primary: pywal.color4 ?? "#a6e3a1"    readonly property color m3Primary: pywal.color4 ?? "#a6e3a1"

    readonly property color m3OnSurface: pywal.foreground    readonly property color m3OnSurface: pywal.foreground

    readonly property color m3OnSurfaceVariant: Qt.rgba(    readonly property color m3OnSurfaceVariant: Qt.rgba(

        pywal.foreground.r * 0.7,        pywal.foreground.r * 0.7,

        pywal.foreground.g * 0.7,        pywal.foreground.g * 0.7,

        pywal.foreground.b * 0.7,        pywal.foreground.b * 0.7,

        1.0        1.0

    )    )

        

    screen: Quickshell.screens[0]    screen: Quickshell.screens[0]

        

    anchors {    anchors {

        top: true        top: true

        left: true        left: true

        right: true        right: true

        bottom: true        bottom: true

    }    }

        

    color: "transparent"    color: "transparent"

    visible: shouldShow    visible: shouldShow

        

    // Click outside to close    // Click outside to close

    MouseArea {    MouseArea {

        anchors.fill: parent        anchors.fill: parent

        onClicked: root.shouldShow = false        onClicked: root.shouldShow = false

        enabled: root.shouldShow        enabled: root.shouldShow

    }    }

        

    // Dashboard Panel    // Dashboard Panel

    Item {    Item {

        id: dashboardContainer        id: dashboardContainer

                

        width: 700        width: 700

        height: 820        height: 820

                

        anchors.top: parent.top        anchors.top: parent.top

        anchors.right: parent.right        anchors.right: parent.right

        anchors.topMargin: 4        anchors.topMargin: 4

        anchors.rightMargin: 4        anchors.rightMargin: 4

                

        transformOrigin: Item.TopRight        transformOrigin: Item.TopRight

        scale: 0.85        scale: 0.85

        opacity: 0        opacity: 0

                

        // Material 3 Expressive entrance animation        // Material 3 Expressive entrance animation

        SequentialAnimation {        SequentialAnimation {

            running: root.shouldShow            running: root.shouldShow

            ParallelAnimation {            ParallelAnimation {

                NumberAnimation {                NumberAnimation {

                    target: dashboardContainer                    target: dashboardContainer

                    property: "scale"                    property: "scale"

                    from: 0.7                    from: 0.7

                    to: 1.08                    to: 1.08

                    duration: 320                    duration: 320

                    easing.type: Easing.OutCubic                    easing.type: Easing.OutCubic

                }                }

                NumberAnimation {                NumberAnimation {

                    target: dashboardContainer                    target: dashboardContainer

                    property: "opacity"                    property: "opacity"

                    from: 0                    from: 0

                    to: 1                    to: 1

                    duration: 280                    duration: 280

                }                }

            }            }

            NumberAnimation {            NumberAnimation {

                target: dashboardContainer                target: dashboardContainer

                property: "scale"                property: "scale"

                to: 1.0                to: 1.0

                duration: 260                duration: 260

                easing.type: Easing.OutBack                easing.type: Easing.OutBack

                easing.overshoot: 1.9                easing.overshoot: 1.9

            }            }

        }        }

                

        ParallelAnimation {        ParallelAnimation {

            running: !root.shouldShow && dashboardContainer.opacity > 0            running: !root.shouldShow && dashboardContainer.opacity > 0

            NumberAnimation { target: dashboardContainer; property: "scale"; to: 0.85; duration: 240; easing.type: Easing.InCubic }            NumberAnimation { target: dashboardContainer; property: "scale"; to: 0.85; duration: 240; easing.type: Easing.InCubic }

            NumberAnimation { target: dashboardContainer; property: "opacity"; to: 0; duration: 240 }            NumberAnimation { target: dashboardContainer; property: "opacity"; to: 0; duration: 240 }

        }        }

                

        // Elevated shadow        // Elevated shadow

        Rectangle {        Rectangle {

            anchors.fill: dashboard            anchors.fill: dashboard

            anchors.margins: -10            anchors.margins: -10

            radius: dashboard.radius + 5            radius: dashboard.radius + 5

            color: "transparent"            color: "transparent"

                        

            layer.enabled: true            layer.enabled: true

            layer.effect: MultiEffect {            layer.effect: MultiEffect {

                shadowEnabled: true                shadowEnabled: true

                shadowColor: Qt.rgba(0, 0, 0, 0.45)                shadowColor: Qt.rgba(0, 0, 0, 0.45)

                shadowBlur: 1.2                shadowBlur: 1.2

                shadowVerticalOffset: 14                shadowVerticalOffset: 14

            }            }

        }        }

        

        Rectangle {        Rectangle {

            id: dashboard            id: dashboard

            anchors.fill: parent            anchors.fill: parent

            color: root.m3Surface            color: root.m3Surface

            radius: 24            radius: 24

                        

            border.color: Qt.rgba(root.m3Primary.r, root.m3Primary.g, root.m3Primary.b, 0.3)            border.color: Qt.rgba(root.m3Primary.r, root.m3Primary.g, root.m3Primary.b, 0.3)

            border.width: 1            border.width: 1

                        

            // Main content            // Main content

            ColumnLayout {            ColumnLayout {

                anchors.fill: parent                anchors.fill: parent

                anchors.margins: 20                anchors.margins: 20

                spacing: 16                spacing: 16

                                

                // Header with time and close button                // Header with time and close button

                RowLayout {                RowLayout {

                    Layout.fillWidth: true                    Layout.fillWidth: true

                    spacing: 16                    spacing: 16

                                        

                    ColumnLayout {                    ColumnLayout {

                        spacing: 2                        spacing: 2

                                                

                        Text {                        Text {

                            text: Qt.formatTime(time.date, "hh:mm")                            text: Qt.formatTime(time.date, "hh:mm")

                            font.family: "Inter"                            font.family: "Inter"

                            font.pixelSize: 42                            font.pixelSize: 42

                            font.weight: Font.Bold                            font.weight: Font.Bold

                            color: root.m3OnSurface                            color: root.m3OnSurface

                        }                        }

                                                

                        Text {                        Text {

                            text: Qt.formatDate(time.date, "dddd, MMMM d")                            text: Qt.formatDate(time.date, "dddd, MMMM d")

                            font.family: "Inter"                            font.family: "Inter"

                            font.pixelSize: 14                            font.pixelSize: 14

                            font.weight: Font.Medium                            font.weight: Font.Medium

                            color: root.m3OnSurfaceVariant                            color: root.m3OnSurfaceVariant

                        }                        }

                    }                    }

                                        

                    Item { Layout.fillWidth: true }                    Item { Layout.fillWidth: true }

                                        

                    // Close button                    // Close button

                    Rectangle {                    Rectangle {

                        Layout.preferredWidth: 44                        Layout.preferredWidth: 44

                        Layout.preferredHeight: 44                        Layout.preferredHeight: 44

                        radius: 22                        radius: 22

                        color: hoverArea.containsMouse ?                         color: hoverArea.containsMouse ? 

                               Qt.rgba(root.m3Primary.r, root.m3Primary.g, root.m3Primary.b, 0.15) :                                Qt.rgba(root.m3Primary.r, root.m3Primary.g, root.m3Primary.b, 0.15) : 

                               "transparent"                               "transparent"

                                                

                        Behavior on color {                        Behavior on color {

                            ColorAnimation { duration: 200; easing.type: Easing.OutCubic }                            ColorAnimation { duration: 200; easing.type: Easing.OutCubic }

                        }                        }

                                                

                        Text {                        Text {

                            anchors.centerIn: parent                            anchors.centerIn: parent

                            text: "󰅖"                            text: "󰅖"

                            font.family: "Material Design Icons"                            font.family: "Material Design Icons"

                            font.pixelSize: 24                            font.pixelSize: 24

                            color: root.m3OnSurface                            color: root.m3OnSurface

                        }                        }

                                                

                        MouseArea {                        MouseArea {

                            id: hoverArea                            id: hoverArea

                            anchors.fill: parent                            anchors.fill: parent

                            hoverEnabled: true                            hoverEnabled: true

                            cursorShape: Qt.PointingHandCursor                            cursorShape: Qt.PointingHandCursor

                            onClicked: root.shouldShow = false                            onClicked: root.shouldShow = false

                        }                        }

                    }                    }

                }                }

                                

                // Quick toggles row                // Quick toggles row

                RowLayout {                RowLayout {

                    Layout.fillWidth: true                    Layout.fillWidth: true

                    spacing: 12                    spacing: 12

                                        

                    // WiFi toggle                    // WiFi toggle

                    QuickToggle {                    QuickToggle {

                        Layout.fillWidth: true                        Layout.fillWidth: true

                        icon: "󰖩"                        icon: "󰖩"

                        label: "WiFi"                        label: "WiFi"

                        active: network.wifiEnabled                        active: network.wifiEnabled

                        primaryColor: pywal.color5                        primaryColor: pywal.color5

                        onClicked: network.toggleWifi()                        onClicked: network.toggleWifi()

                    }                    }

                                        

                    // Bluetooth toggle (placeholder)                    // Bluetooth toggle (placeholder)

                    QuickToggle {                    QuickToggle {

                        Layout.fillWidth: true                        Layout.fillWidth: true

                        icon: "󰂯"                        icon: "󰂯"

                        label: "Bluetooth"                        label: "Bluetooth"

                        active: false                        active: false

                        primaryColor: pywal.color6                        primaryColor: pywal.color6

                        onClicked: console.log("Bluetooth toggle")                        onClicked: console.log("Bluetooth toggle")

                    }                    }

                                        

                    // DND toggle                    // DND toggle

                    QuickToggle {                    QuickToggle {

                        Layout.fillWidth: true                        Layout.fillWidth: true

                        icon: notifs.dnd ? "󰂛" : "󰂚"                        icon: notifs.dnd ? "󰂛" : "󰂚"

                        label: "DND"                        label: "DND"

                        active: notifs.dnd                        active: notifs.dnd

                        primaryColor: pywal.color1                        primaryColor: pywal.color1

                        onClicked: notifs.toggleDnd()                        onClicked: notifs.toggleDnd()

                    }                    }

                                        

                    // Night Light toggle (placeholder)                    // Night Light toggle (placeholder)

                    QuickToggle {                    QuickToggle {

                        Layout.fillWidth: true                        Layout.fillWidth: true

                        icon: "󰖔"                        icon: "󰖔"

                        label: "Night"                        label: "Night"

                        active: false                        active: false

                        primaryColor: pywal.color3                        primaryColor: pywal.color3

                        onClicked: console.log("Night light toggle")                        onClicked: console.log("Night light toggle")

                    }                    }

                }                }

                                

                // Volume and Brightness sliders                // Volume and Brightness sliders

                RowLayout {                RowLayout {

                    Layout.fillWidth: true                    Layout.fillWidth: true

                    spacing: 12                    spacing: 12

                                        

                    // Volume slider card                    // Volume slider card

                    SliderCard {                    SliderCard {

                        Layout.fillWidth: true                        Layout.fillWidth: true

                        icon: audio.defaultSink?.muted ? "󰖁" : "󰕾"                        icon: audio.defaultSink?.muted ? "󰖁" : "󰕾"

                        label: "Volume"                        label: "Volume"

                        value: audio.defaultSink?.volume ?? 0                        value: audio.defaultSink?.volume ?? 0

                        primaryColor: pywal.color4                        primaryColor: pywal.color4

                        onValueChanged: newValue => {                        onValueChanged: newValue => {

                            if (audio.defaultSink) audio.defaultSink.volume = newValue                            if (audio.defaultSink) audio.defaultSink.volume = newValue

                        }                        }

                        onIconClicked: {                        onIconClicked: {

                            if (audio.defaultSink) audio.defaultSink.muted = !audio.defaultSink.muted                            if (audio.defaultSink) audio.defaultSink.muted = !audio.defaultSink.muted

                        }                        }

                    }                    }

                                        

                    // Brightness slider card                    // Brightness slider card

                    SliderCard {                    SliderCard {

                        Layout.fillWidth: true                        Layout.fillWidth: true

                        icon: "󰃠"                        icon: "󰃠"

                        label: "Brightness"                        label: "Brightness"

                        value: brightness.level                        value: brightness.level

                        primaryColor: pywal.color3                        primaryColor: pywal.color3

                        onValueChanged: newValue => { brightness.level = newValue }                        onValueChanged: newValue => { brightness.level = newValue }

                    }                    }

                }                }

                                

                // System resources row                // System resources row

                RowLayout {                RowLayout {

                    Layout.fillWidth: true                    Layout.fillWidth: true

                    spacing: 12                    spacing: 12

                                        

                    // CPU card                    // CPU card

                    SystemCard {                    SystemCard {

                        Layout.fillWidth: true                        Layout.fillWidth: true

                        icon: "󰘚"                        icon: "󰘚"

                        label: "CPU"                        label: "CPU"

                        value: Math.round(systemUsage.cpuPerc * 100)                        value: Math.round(systemUsage.cpuPerc * 100)

                        unit: "%"                        unit: "%"

                        progress: systemUsage.cpuPerc                        progress: systemUsage.cpuPerc

                        primaryColor: pywal.color1                        primaryColor: pywal.color1

                    }                    }

                                        

                    // Memory card                    // Memory card

                    SystemCard {                    SystemCard {

                        Layout.fillWidth: true                        Layout.fillWidth: true

                        icon: "󰍛"                        icon: "󰍛"

                        label: "RAM"                        label: "RAM"

                        value: Math.round(systemUsage.memPerc * 100)                        value: Math.round(systemUsage.memPerc * 100)

                        unit: "%"                        unit: "%"

                        progress: systemUsage.memPerc                        progress: systemUsage.memPerc

                        primaryColor: pywal.color2                        primaryColor: pywal.color2

                    }                    }

                                        

                    // Storage card                    // Storage card

                    SystemCard {                    SystemCard {

                        Layout.fillWidth: true                        Layout.fillWidth: true

                        icon: "󰋊"                        icon: "󰋊"

                        label: "Disk"                        label: "Disk"

                        value: Math.round(systemUsage.storagePerc * 100)                        value: Math.round(systemUsage.storagePerc * 100)

                        unit: "%"                        unit: "%"

                        progress: systemUsage.storagePerc                        progress: systemUsage.storagePerc

                        primaryColor: pywal.color3                        primaryColor: pywal.color3

                    }                    }

                }                }

                                

                // Media player section                // Media player section

                Rectangle {                Rectangle {

                    Layout.fillWidth: true                    Layout.fillWidth: true

                    Layout.preferredHeight: 140                    Layout.preferredHeight: 140

                    radius: 16                    radius: 16

                    color: root.m3SurfaceContainer                    color: root.m3SurfaceContainer

                    border.color: Qt.rgba(root.m3Primary.r, root.m3Primary.g, root.m3Primary.b, 0.15)                    border.color: Qt.rgba(root.m3Primary.r, root.m3Primary.g, root.m3Primary.b, 0.15)

                    border.width: 1                    border.width: 1

                    visible: players.activePlayer                    visible: players.activePlayer

                                        

                    RowLayout {                    RowLayout {

                        anchors.fill: parent                        anchors.fill: parent

                        anchors.margins: 16                        anchors.margins: 16

                        spacing: 16                        spacing: 16

                                                

                        // Album art                        // Album art

                        Rectangle {                        Rectangle {

                            Layout.preferredWidth: 108                            Layout.preferredWidth: 108

                            Layout.preferredHeight: 108                            Layout.preferredHeight: 108

                            radius: 12                            radius: 12

                            color: Qt.rgba(root.m3OnSurface.r, root.m3OnSurface.g, root.m3OnSurface.b, 0.1)                            color: Qt.rgba(root.m3OnSurface.r, root.m3OnSurface.g, root.m3OnSurface.b, 0.1)

                                                        

                            Image {                            Image {

                                anchors.fill: parent                                anchors.fill: parent

                                anchors.margins: 0                                anchors.margins: 0

                                source: players.activePlayer?.artUrl ?? ""                                source: players.activePlayer?.artUrl ?? ""

                                fillMode: Image.PreserveAspectCrop                                fillMode: Image.PreserveAspectCrop

                                asynchronous: true                                asynchronous: true

                                visible: status === Image.Ready                                visible: status === Image.Ready

                            }                            }

                                                        

                            Text {                            Text {

                                anchors.centerIn: parent                                anchors.centerIn: parent

                                text: "󰝚"                                text: "󰝚"

                                font.family: "Material Design Icons"                                font.family: "Material Design Icons"

                                font.pixelSize: 36                                font.pixelSize: 36

                                color: root.m3OnSurfaceVariant                                color: root.m3OnSurfaceVariant

                                visible: !players.activePlayer?.artUrl                                visible: !players.activePlayer?.artUrl

                            }                            }

                        }                        }

                                                

                        // Track info and controls                        // Track info and controls

                        ColumnLayout {                        ColumnLayout {

                            Layout.fillWidth: true                            Layout.fillWidth: true

                            Layout.fillHeight: true                            Layout.fillHeight: true

                            spacing: 8                            spacing: 8

                                                        

                            ColumnLayout {                            ColumnLayout {

                                Layout.fillWidth: true                                Layout.fillWidth: true

                                spacing: 4                                spacing: 4

                                                                

                                Text {                                Text {

                                    Layout.fillWidth: true                                    Layout.fillWidth: true

                                    text: players.activePlayer?.title ?? "No media playing"                                    text: players.activePlayer?.title ?? "No media playing"

                                    font.family: "Inter"                                    font.family: "Inter"

                                    font.pixelSize: 16                                    font.pixelSize: 16

                                    font.weight: Font.Bold                                    font.weight: Font.Bold

                                    color: root.m3OnSurface                                    color: root.m3OnSurface

                                    elide: Text.ElideRight                                    elide: Text.ElideRight

                                }                                }

                                                                

                                Text {                                Text {

                                    Layout.fillWidth: true                                    Layout.fillWidth: true

                                    text: players.activePlayer?.artist ?? ""                                    text: players.activePlayer?.artist ?? ""

                                    font.family: "Inter"                                    font.family: "Inter"

                                    font.pixelSize: 13                                    font.pixelSize: 13

                                    color: root.m3OnSurfaceVariant                                    color: root.m3OnSurfaceVariant

                                    elide: Text.ElideRight                                    elide: Text.ElideRight

                                }                                }

                            }                            }

                                                        

                            Item { Layout.fillHeight: true }                            Item { Layout.fillHeight: true }

                                                        

                            // Playback controls                            // Playback controls

                            RowLayout {                            RowLayout {

                                Layout.fillWidth: true                                Layout.fillWidth: true

                                spacing: 8                                spacing: 8

                                                                

                                MediaButton {                                MediaButton {

                                    icon: "󰒮"                                    icon: "󰒮"

                                    onClicked: players.activePlayer?.previous()                                    onClicked: players.activePlayer?.previous()

                                }                                }

                                                                

                                MediaButton {                                MediaButton {

                                    icon: players.activePlayer?.playbackStatus === "Playing" ? "󰏤" : "󰐊"                                    icon: players.activePlayer?.playbackStatus === "Playing" ? "󰏤" : "󰐊"

                                    primary: true                                    primary: true

                                    onClicked: players.activePlayer?.playPause()                                    onClicked: players.activePlayer?.playPause()

                                }                                }

                                                                

                                MediaButton {                                MediaButton {

                                    icon: "󰒭"                                    icon: "󰒭"

                                    onClicked: players.activePlayer?.next()                                    onClicked: players.activePlayer?.next()

                                }                                }

                                                                

                                Item { Layout.fillWidth: true }                                Item { Layout.fillWidth: true }

                            }                            }

                        }                        }

                    }                    }

                }                }

                                

                // Notifications section                // Notifications section

                Rectangle {                Rectangle {

                    Layout.fillWidth: true                    Layout.fillWidth: true

                    Layout.fillHeight: true                    Layout.fillHeight: true

                    radius: 16                    radius: 16

                    color: root.m3SurfaceContainer                    color: root.m3SurfaceContainer

                    border.color: Qt.rgba(root.m3Primary.r, root.m3Primary.g, root.m3Primary.b, 0.15)                    border.color: Qt.rgba(root.m3Primary.r, root.m3Primary.g, root.m3Primary.b, 0.15)

                    border.width: 1                    border.width: 1

                                        

                    ColumnLayout {                    ColumnLayout {

                        anchors.fill: parent                        anchors.fill: parent

                        anchors.margins: 16                        anchors.margins: 16

                        spacing: 12                        spacing: 12

                                                

                        RowLayout {                        RowLayout {

                            Layout.fillWidth: true                            Layout.fillWidth: true

                                                        

                            Text {                            Text {

                                text: "Notifications"                                text: "Notifications"

                                font.family: "Inter"                                font.family: "Inter"

                                font.pixelSize: 16                                font.pixelSize: 16

                                font.weight: Font.Bold                                font.weight: Font.Bold

                                color: root.m3OnSurface                                color: root.m3OnSurface

                            }                            }

                                                        

                            Item { Layout.fillWidth: true }                            Item { Layout.fillWidth: true }

                                                        

                            Rectangle {                            Rectangle {

                                Layout.preferredWidth: 30                                Layout.preferredWidth: 30

                                Layout.preferredHeight: 30                                Layout.preferredHeight: 30

                                radius: 15                                radius: 15

                                color: clearHover.containsMouse ?                                 color: clearHover.containsMouse ? 

                                       Qt.rgba(root.m3Primary.r, root.m3Primary.g, root.m3Primary.b, 0.15) :                                        Qt.rgba(root.m3Primary.r, root.m3Primary.g, root.m3Primary.b, 0.15) : 

                                       "transparent"                                       "transparent"

                                                                

                                Behavior on color {                                Behavior on color {

                                    ColorAnimation { duration: 200; easing.type: Easing.OutCubic }                                    ColorAnimation { duration: 200; easing.type: Easing.OutCubic }

                                }                                }

                                                                

                                Text {                                Text {

                                    anchors.centerIn: parent                                    anchors.centerIn: parent

                                    text: "󰎟"                                    text: "󰎟"

                                    font.family: "Material Design Icons"                                    font.family: "Material Design Icons"

                                    font.pixelSize: 16                                    font.pixelSize: 16

                                    color: root.m3OnSurface                                    color: root.m3OnSurface

                                }                                }

                                                                

                                MouseArea {                                MouseArea {

                                    id: clearHover                                    id: clearHover

                                    anchors.fill: parent                                    anchors.fill: parent

                                    hoverEnabled: true                                    hoverEnabled: true

                                    cursorShape: Qt.PointingHandCursor                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: notifs.clearAll()                                    onClicked: notifs.clearAll()

                                }                                }

                            }                            }

                        }                        }

                                                

                        ScrollView {                        ScrollView {

                            Layout.fillWidth: true                            Layout.fillWidth: true

                            Layout.fillHeight: true                            Layout.fillHeight: true

                            clip: true                            clip: true

                                                        

                            ListView {                            ListView {

                                model: notifs.recentNotifications                                model: notifs.recentNotifications

                                spacing: 8                                spacing: 8

                                                                

                                delegate: Rectangle {                                delegate: Rectangle {

                                    required property var modelData                                    required property var modelData

                                                                        

                                    width: ListView.view.width                                    width: ListView.view.width

                                    height: 60                                    height: 60

                                    radius: 12                                    radius: 12

                                    color: Qt.rgba(root.m3OnSurface.r, root.m3OnSurface.g, root.m3OnSurface.b, modelData.dismissed ? 0.05 : 0.08)                                    color: Qt.rgba(root.m3OnSurface.r, root.m3OnSurface.g, root.m3OnSurface.b, modelData.dismissed ? 0.05 : 0.08)

                                    opacity: modelData.dismissed ? 0.6 : 1.0                                    opacity: modelData.dismissed ? 0.6 : 1.0

                                                                        

                                    RowLayout {                                    RowLayout {

                                        anchors.fill: parent                                        anchors.fill: parent

                                        anchors.margins: 12                                        anchors.margins: 12

                                        spacing: 12                                        spacing: 12

                                                                                

                                        Rectangle {                                        Rectangle {

                                            Layout.preferredWidth: 36                                            Layout.preferredWidth: 36

                                            Layout.preferredHeight: 36                                            Layout.preferredHeight: 36

                                            radius: 8                                            radius: 8

                                            color: Qt.rgba(root.m3Primary.r, root.m3Primary.g, root.m3Primary.b, 0.2)                                            color: Qt.rgba(root.m3Primary.r, root.m3Primary.g, root.m3Primary.b, 0.2)

                                                                                        

                                            Text {                                            Text {

                                                anchors.centerIn: parent                                                anchors.centerIn: parent

                                                text: "󰂚"                                                text: "󰂚"

                                                font.family: "Material Design Icons"                                                font.family: "Material Design Icons"

                                                font.pixelSize: 18                                                font.pixelSize: 18

                                                color: root.m3Primary                                                color: root.m3Primary

                                            }                                            }

                                        }                                        }

                                                                                

                                        ColumnLayout {                                        ColumnLayout {

                                            Layout.fillWidth: true                                            Layout.fillWidth: true

                                            spacing: 2                                            spacing: 2

                                                                                        

                                            Text {                                            Text {

                                                Layout.fillWidth: true                                                Layout.fillWidth: true

                                                text: modelData.summary                                                text: modelData.summary

                                                font.family: "Inter"                                                font.family: "Inter"

                                                font.pixelSize: 13                                                font.pixelSize: 13

                                                font.weight: Font.Medium                                                font.weight: Font.Medium

                                                color: root.m3OnSurface                                                color: root.m3OnSurface

                                                elide: Text.ElideRight                                                elide: Text.ElideRight

                                            }                                            }

                                                                                        

                                            Text {                                            Text {

                                                Layout.fillWidth: true                                                Layout.fillWidth: true

                                                text: modelData.body                                                text: modelData.body

                                                font.family: "Inter"                                                font.family: "Inter"

                                                font.pixelSize: 11                                                font.pixelSize: 11

                                                color: root.m3OnSurfaceVariant                                                color: root.m3OnSurfaceVariant

                                                elide: Text.ElideRight                                                elide: Text.ElideRight

                                            }                                            }

                                        }                                        }

                                    }                                    }

                                }                                }

                            }                            }

                        }                        }

                    }                    }

                }                }

            }            }

        }        }

    }    }

        

    // Quick toggle component    // Quick toggle component

    component QuickToggle: Rectangle {    component QuickToggle: Rectangle {

        id: toggle        id: toggle

                

        property string icon: ""        property string icon: ""

        property string label: ""        property string label: ""

        property bool active: false        property bool active: false

        property color primaryColor: root.m3Primary        property color primaryColor: root.m3Primary

                

        signal clicked()        signal clicked()

                

        Layout.preferredHeight: 90        Layout.preferredHeight: 90

        radius: 16        radius: 16

                

        color: active ?         color: active ? 

               Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.18) :                Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.18) : 

               root.m3SurfaceContainer               root.m3SurfaceContainer

                

        border.color: active ?         border.color: active ? 

                      Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.4) :                       Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.4) : 

                      Qt.rgba(root.m3OnSurface.r, root.m3OnSurface.g, root.m3OnSurface.b, 0.1)                      Qt.rgba(root.m3OnSurface.r, root.m3OnSurface.g, root.m3OnSurface.b, 0.1)

        border.width: 1        border.width: 1

                

        scale: toggleMouse.pressed ? 0.95 : (toggleMouse.containsMouse ? 1.02 : 1.0)        scale: toggleMouse.pressed ? 0.95 : (toggleMouse.containsMouse ? 1.02 : 1.0)

                

        Behavior on color {        Behavior on color {

            ColorAnimation { duration: 250; easing.type: Easing.OutCubic }            ColorAnimation { duration: 250; easing.type: Easing.OutCubic }

        }        }

                

        Behavior on border.color {        Behavior on border.color {

            ColorAnimation { duration: 250; easing.type: Easing.OutCubic }            ColorAnimation { duration: 250; easing.type: Easing.OutCubic }

        }        }

                

        Behavior on scale {        Behavior on scale {

            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }

        }        }

                

        ColumnLayout {        ColumnLayout {

            anchors.fill: parent            anchors.fill: parent

            anchors.margins: 14            anchors.margins: 14

            spacing: 8            spacing: 8

                        

            Text {            Text {

                Layout.alignment: Qt.AlignLeft                Layout.alignment: Qt.AlignLeft

                text: toggle.icon                text: toggle.icon

                font.family: "Material Design Icons"                font.family: "Material Design Icons"

                font.pixelSize: 28                font.pixelSize: 28

                color: toggle.active ? toggle.primaryColor : root.m3OnSurface                color: toggle.active ? toggle.primaryColor : root.m3OnSurface

                                

                Behavior on color {                Behavior on color {

                    ColorAnimation { duration: 250; easing.type: Easing.OutCubic }                    ColorAnimation { duration: 250; easing.type: Easing.OutCubic }

                }                }

            }            }

                        

            Item { Layout.fillHeight: true }            Item { Layout.fillHeight: true }

                        

            Text {            Text {

                Layout.alignment: Qt.AlignLeft                Layout.alignment: Qt.AlignLeft

                text: toggle.label                text: toggle.label

                font.family: "Inter"                font.family: "Inter"

                font.pixelSize: 12                font.pixelSize: 12

                font.weight: Font.Medium                font.weight: Font.Medium

                color: toggle.active ? toggle.primaryColor : root.m3OnSurfaceVariant                color: toggle.active ? toggle.primaryColor : root.m3OnSurfaceVariant

                                

                Behavior on color {                Behavior on color {

                    ColorAnimation { duration: 250; easing.type: Easing.OutCubic }                    ColorAnimation { duration: 250; easing.type: Easing.OutCubic }

                }                }

            }            }

        }        }

                

        MouseArea {        MouseArea {

            id: toggleMouse            id: toggleMouse

            anchors.fill: parent            anchors.fill: parent

            hoverEnabled: true            hoverEnabled: true

            cursorShape: Qt.PointingHandCursor            cursorShape: Qt.PointingHandCursor

            onClicked: toggle.clicked()            onClicked: toggle.clicked()

        }        }

    }    }

        

    // Slider card component    // Slider card component

    component SliderCard: Rectangle {    component SliderCard: Rectangle {

        id: sliderCard        id: sliderCard

                

        property string icon: ""        property string icon: ""

        property string label: ""        property string label: ""

        property real value: 0        property real value: 0

        property color primaryColor: root.m3Primary        property color primaryColor: root.m3Primary

                

        signal valueChanged(real newValue)        signal valueChanged(real newValue)

        signal iconClicked()        signal iconClicked()

                

        Layout.preferredHeight: 90        Layout.preferredHeight: 90

        radius: 16        radius: 16

        color: root.m3SurfaceContainer        color: root.m3SurfaceContainer

        border.color: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.2)        border.color: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.2)

        border.width: 1        border.width: 1

                

        ColumnLayout {        ColumnLayout {

            anchors.fill: parent            anchors.fill: parent

            anchors.margins: 14            anchors.margins: 14

            spacing: 10            spacing: 10

                        

            RowLayout {            RowLayout {

                Layout.fillWidth: true                Layout.fillWidth: true

                spacing: 8                spacing: 8

                                

                Rectangle {                Rectangle {

                    Layout.preferredWidth: 32                    Layout.preferredWidth: 32

                    Layout.preferredHeight: 32                    Layout.preferredHeight: 32

                    radius: 16                    radius: 16

                    color: Qt.rgba(sliderCard.primaryColor.r, sliderCard.primaryColor.g, sliderCard.primaryColor.b, 0.2)                    color: Qt.rgba(sliderCard.primaryColor.r, sliderCard.primaryColor.g, sliderCard.primaryColor.b, 0.2)

                                        

                    Text {                    Text {

                        anchors.centerIn: parent                        anchors.centerIn: parent

                        text: sliderCard.icon                        text: sliderCard.icon

                        font.family: "Material Design Icons"                        font.family: "Material Design Icons"

                        font.pixelSize: 18                        font.pixelSize: 18

                        color: sliderCard.primaryColor                        color: sliderCard.primaryColor

                    }                    }

                                        

                    MouseArea {                    MouseArea {

                        anchors.fill: parent                        anchors.fill: parent

                        cursorShape: Qt.PointingHandCursor                        cursorShape: Qt.PointingHandCursor

                        onClicked: sliderCard.iconClicked()                        onClicked: sliderCard.iconClicked()

                    }                    }

                }                }

                                

                Text {                Text {

                    text: sliderCard.label                    text: sliderCard.label

                    font.family: "Inter"                    font.family: "Inter"

                    font.pixelSize: 12                    font.pixelSize: 12

                    font.weight: Font.Medium                    font.weight: Font.Medium

                    color: root.m3OnSurfaceVariant                    color: root.m3OnSurfaceVariant

                }                }

                                

                Item { Layout.fillWidth: true }                Item { Layout.fillWidth: true }

                                

                Text {                Text {

                    text: Math.round(sliderCard.value * 100) + "%"                    text: Math.round(sliderCard.value * 100) + "%"

                    font.family: "Inter"                    font.family: "Inter"

                    font.pixelSize: 13                    font.pixelSize: 13

                    font.weight: Font.Bold                    font.weight: Font.Bold

                    color: root.m3OnSurface                    color: root.m3OnSurface

                }                }

            }            }

                        

            // Custom slider            // Custom slider

            Rectangle {            Rectangle {

                Layout.fillWidth: true                Layout.fillWidth: true

                Layout.preferredHeight: 6                Layout.preferredHeight: 6

                radius: 3                radius: 3

                color: Qt.rgba(root.m3OnSurface.r, root.m3OnSurface.g, root.m3OnSurface.b, 0.1)                color: Qt.rgba(root.m3OnSurface.r, root.m3OnSurface.g, root.m3OnSurface.b, 0.1)

                                

                Rectangle {                Rectangle {

                    width: parent.width * sliderCard.value                    width: parent.width * sliderCard.value

                    height: parent.height                    height: parent.height

                    radius: parent.radius                    radius: parent.radius

                    color: sliderCard.primaryColor                    color: sliderCard.primaryColor

                                        

                    Behavior on width {                    Behavior on width {

                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }

                    }                    }

                }                }

                                

                MouseArea {                MouseArea {

                    anchors.fill: parent                    anchors.fill: parent

                    cursorShape: Qt.PointingHandCursor                    cursorShape: Qt.PointingHandCursor

                    onClicked: mouse => {                    onClicked: mouse => {

                        const newValue = Math.max(0, Math.min(1, mouse.x / width))                        const newValue = Math.max(0, Math.min(1, mouse.x / width))

                        sliderCard.valueChanged(newValue)                        sliderCard.valueChanged(newValue)

                    }                    }

                    onPositionChanged: mouse => {                    onPositionChanged: mouse => {

                        if (pressed) {                        if (pressed) {

                            const newValue = Math.max(0, Math.min(1, mouse.x / width))                            const newValue = Math.max(0, Math.min(1, mouse.x / width))

                            sliderCard.valueChanged(newValue)                            sliderCard.valueChanged(newValue)

                        }                        }

                    }                    }

                }                }

            }            }

        }        }

    }    }

        

    // System card component    // System card component

    component SystemCard: Rectangle {    component SystemCard: Rectangle {

        id: sysCard        id: sysCard

                

        property string icon: ""        property string icon: ""

        property string label: ""        property string label: ""

        property int value: 0        property int value: 0

        property string unit: ""        property string unit: ""

        property real progress: 0        property real progress: 0

        property color primaryColor: root.m3Primary        property color primaryColor: root.m3Primary

                

        Layout.preferredHeight: 100        Layout.preferredHeight: 100

        radius: 16        radius: 16

        color: root.m3SurfaceContainer        color: root.m3SurfaceContainer

        border.color: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.2)        border.color: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.2)

        border.width: 1        border.width: 1

                

        ColumnLayout {        ColumnLayout {

            anchors.fill: parent            anchors.fill: parent

            anchors.margins: 14            anchors.margins: 14

            spacing: 10            spacing: 10

                        

            RowLayout {            RowLayout {

                Layout.fillWidth: true                Layout.fillWidth: true

                spacing: 8                spacing: 8

                                

                Text {                Text {

                    text: sysCard.icon                    text: sysCard.icon

                    font.family: "Material Design Icons"                    font.family: "Material Design Icons"

                    font.pixelSize: 24                    font.pixelSize: 24

                    color: sysCard.primaryColor                    color: sysCard.primaryColor

                }                }

                                

                Text {                Text {

                    text: sysCard.label                    text: sysCard.label

                    font.family: "Inter"                    font.family: "Inter"

                    font.pixelSize: 11                    font.pixelSize: 11

                    font.weight: Font.Medium                    font.weight: Font.Medium

                    color: root.m3OnSurfaceVariant                    color: root.m3OnSurfaceVariant

                }                }

            }            }

                        

            Item { Layout.fillHeight: true }            Item { Layout.fillHeight: true }

                        

            Text {            Text {

                text: sysCard.value + sysCard.unit                text: sysCard.value + sysCard.unit

                font.family: "Inter"                font.family: "Inter"

                font.pixelSize: 26                font.pixelSize: 26

                font.weight: Font.Bold                font.weight: Font.Bold

                color: root.m3OnSurface                color: root.m3OnSurface

            }            }

                        

            // Progress bar            // Progress bar

            Rectangle {            Rectangle {

                Layout.fillWidth: true                Layout.fillWidth: true

                Layout.preferredHeight: 5                Layout.preferredHeight: 5

                radius: 2.5                radius: 2.5

                color: Qt.rgba(root.m3OnSurface.r, root.m3OnSurface.g, root.m3OnSurface.b, 0.1)                color: Qt.rgba(root.m3OnSurface.r, root.m3OnSurface.g, root.m3OnSurface.b, 0.1)

                                

                Rectangle {                Rectangle {

                    width: parent.width * sysCard.progress                    width: parent.width * sysCard.progress

                    height: parent.height                    height: parent.height

                    radius: parent.radius                    radius: parent.radius

                    color: sysCard.primaryColor                    color: sysCard.primaryColor

                                        

                    Behavior on width {                    Behavior on width {

                        NumberAnimation { duration: 500; easing.type: Easing.OutCubic }                        NumberAnimation { duration: 500; easing.type: Easing.OutCubic }

                    }                    }

                }                }

            }            }

        }        }

    }    }

        

    // Media button component    // Media button component

    component MediaButton: Rectangle {    component MediaButton: Rectangle {

        id: btn        id: btn

                

        property string icon: ""        property string icon: ""

        property bool primary: false        property bool primary: false

                

        signal clicked()        signal clicked()

                

        Layout.preferredWidth: primary ? 52 : 44        Layout.preferredWidth: primary ? 52 : 44

        Layout.preferredHeight: primary ? 52 : 44        Layout.preferredHeight: primary ? 52 : 44

        radius: (primary ? 26 : 22)        radius: (primary ? 26 : 22)

                

        color: primary ?         color: primary ? 

               root.m3Primary :                root.m3Primary : 

               (btnMouse.containsMouse ? Qt.rgba(root.m3OnSurface.r, root.m3OnSurface.g, root.m3OnSurface.b, 0.1) : "transparent")               (btnMouse.containsMouse ? Qt.rgba(root.m3OnSurface.r, root.m3OnSurface.g, root.m3OnSurface.b, 0.1) : "transparent")

                

        border.color: primary ? "transparent" : Qt.rgba(root.m3OnSurface.r, root.m3OnSurface.g, root.m3OnSurface.b, 0.2)        border.color: primary ? "transparent" : Qt.rgba(root.m3OnSurface.r, root.m3OnSurface.g, root.m3OnSurface.b, 0.2)

        border.width: primary ? 0 : 1        border.width: primary ? 0 : 1

                

        scale: btnMouse.pressed ? 0.9 : (btnMouse.containsMouse ? 1.05 : 1.0)        scale: btnMouse.pressed ? 0.9 : (btnMouse.containsMouse ? 1.05 : 1.0)

                

        Behavior on color {        Behavior on color {

            ColorAnimation { duration: 200; easing.type: Easing.OutCubic }            ColorAnimation { duration: 200; easing.type: Easing.OutCubic }

        }        }

                

        Behavior on scale {        Behavior on scale {

            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }

        }        }

                

        Text {        Text {

            anchors.centerIn: parent            anchors.centerIn: parent

            text: btn.icon            text: btn.icon

            font.family: "Material Design Icons"            font.family: "Material Design Icons"

            font.pixelSize: primary ? 28 : 22            font.pixelSize: primary ? 28 : 22

            color: primary ? Qt.rgba(0, 0, 0, 0.9) : root.m3OnSurface            color: primary ? Qt.rgba(0, 0, 0, 0.9) : root.m3OnSurface

        }        }

                

        MouseArea {        MouseArea {

            id: btnMouse            id: btnMouse

            anchors.fill: parent            anchors.fill: parent

            hoverEnabled: true            hoverEnabled: true

            cursorShape: Qt.PointingHandCursor            cursorShape: Qt.PointingHandCursor

            onClicked: btn.clicked()            onClicked: btn.clicked()

        }        }

    }    }

}}

