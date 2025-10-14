import QtQuick 6.10import QtQuick 6.10import QtQuick 6.10

import QtQuick.Layouts 6.10

import QtQuick.Effectsimport QtQuick.Layouts 6.10import QtQuick.Layouts 6.10

import Quickshell

import Quickshell.Waylandimport QtQuick.Effectsimport QtQuick.Effects

import "../../services" as QsServices

import Quickshellimport Quickshell

// Material 3 Expressive System Dashboard

PanelWindow {import Quickshell.Waylandimport Quickshell.Wayland

    id: root

    import "../../services" as QsServicesimport "../../services" as QsServices

    property bool shouldShow: false

    readonly property var pywal: QsServices.Pywal

    readonly property var network: QsServices.Network

    readonly property var audio: QsServices.Audio// Material 3 Expressive System Dashboard// Material 3 Expressive System Dashboard

    readonly property var brightness: QsServices.Brightness

    readonly property var systemUsage: QsServices.SystemUsagePanelWindow {PanelWindow {

    readonly property var time: QsServices.Time

    readonly property var notifs: QsServices.Notifs    id: root    id: root

    readonly property var players: QsServices.Players

            

    // Material 3 colors

    readonly property color m3Surface: Qt.rgba(pywal.background.r, pywal.background.g, pywal.background.b, 1.0)    property bool shouldShow: false    property bool shouldShow: false

    readonly property color m3SurfaceContainer: Qt.rgba(

        pywal.background.r * 1.08,    readonly property var pywal: QsServices.Pywal    readonly property var pywal: QsServices.Pywal

        pywal.background.g * 1.08,

        pywal.background.b * 1.08,    readonly property var network: QsServices.Network    readonly property var network: QsServices.Network

        1.0

    )    readonly property var audio: QsServices.Audio    readonly property var audio: QsServices.Audio

    readonly property color m3Primary: pywal.color4 ?? "#a6e3a1"

    readonly property color m3OnSurface: pywal.foreground    readonly property var brightness: QsServices.Brightness    readonly property var brightness: QsServices.Brightness

    readonly property color m3OnSurfaceVariant: Qt.rgba(

        pywal.foreground.r * 0.7,    readonly property var systemUsage: QsServices.SystemUsage    readonly property var systemUsage: QsServices.SystemUsage

        pywal.foreground.g * 0.7,

        pywal.foreground.b * 0.7,    readonly property var time: QsServices.Time    readonly property var time: QsServices.Time

        1.0

    )    readonly property var notifs: QsServices.Notifs    readonly property var notifs: QsServices.Notifs

    

    screen: Quickshell.screens[0]    readonly property var players: QsServices.Players    readonly property var players: QsServices.Players

    

    anchors {        

        top: true

        left: true    // Material 3 colors    // Material 3 colors

        right: true

        bottom: true    readonly property color m3Surface: Qt.rgba(pywal.background.r, pywal.background.g, pywal.background.b, 1.0)    readonly property color m3Surface: Qt.rgba(pywal.background.r, pywal.background.g, pywal.background.b, 1.0)

    }

        readonly property color m3SurfaceContainer: Qt.rgba(    readonly property color m3SurfaceContainer: Qt.rgba(

    color: "transparent"

    visible: shouldShow        pywal.background.r * 1.08,        pywal.background.r * 1.08,

    

    // Click outside to close        pywal.background.g * 1.08,        pywal.background.g * 1.08,

    MouseArea {

        anchors.fill: parent        pywal.background.b * 1.08,        pywal.background.b * 1.08,

        onClicked: root.shouldShow = false

        enabled: root.shouldShow        1.0        1.0

    }

        )    )

    // Dashboard Panel

    Item {    readonly property color m3Primary: pywal.color4 ?? "#a6e3a1"    readonly property color m3Primary: pywal.color4 ?? "#a6e3a1"

        id: dashboardContainer

            readonly property color m3OnSurface: pywal.foreground    readonly property color m3OnSurface: pywal.foreground

        implicitWidth: 700

        implicitHeight: 820    readonly property color m3OnSurfaceVariant: Qt.rgba(    readonly property color m3OnSurfaceVariant: Qt.rgba(

        

        anchors.top: parent.top        pywal.foreground.r * 0.7,        pywal.foreground.r * 0.7,

        anchors.right: parent.right

        anchors.topMargin: 4        pywal.foreground.g * 0.7,        pywal.foreground.g * 0.7,

        anchors.rightMargin: 4

                pywal.foreground.b * 0.7,        pywal.foreground.b * 0.7,

        transformOrigin: Item.TopRight

        scale: 0.85        1.0        1.0

        opacity: 0

            )    )

        // Material 3 Expressive entrance animation

        SequentialAnimation {        

            running: root.shouldShow

            ParallelAnimation {    screen: Quickshell.screens[0]    screen: Quickshell.screens[0]

                NumberAnimation {

                    target: dashboardContainer        

                    property: "scale"

                    from: 0.7    anchors {    anchors {

                    to: 1.08

                    duration: 320        top: true        top: true

                    easing.type: Easing.OutCubic

                }        left: true        left: true

                NumberAnimation {

                    target: dashboardContainer        right: true        right: true

                    property: "opacity"

                    from: 0        bottom: true        bottom: true

                    to: 1

                    duration: 280    }    }

                }

            }        

            NumberAnimation {

                target: dashboardContainer    color: "transparent"    color: "transparent"

                property: "scale"

                to: 1.0    visible: shouldShow    visible: shouldShow

                duration: 260

                easing.type: Easing.OutBack        

                easing.overshoot: 1.9

            }    // Click outside to close    // Click outside to close

        }

            MouseArea {    MouseArea {

        ParallelAnimation {

            running: !root.shouldShow && dashboardContainer.opacity > 0        anchors.fill: parent        anchors.fill: parent

            NumberAnimation { target: dashboardContainer; property: "scale"; to: 0.85; duration: 240; easing.type: Easing.InCubic }

            NumberAnimation { target: dashboardContainer; property: "opacity"; to: 0; duration: 240 }        onClicked: root.shouldShow = false        onClicked: root.shouldShow = false

        }

                enabled: root.shouldShow        enabled: root.shouldShow

        // Elevated shadow

        Rectangle {    }    }

            anchors.fill: dashboard

            anchors.margins: -10        

            radius: dashboard.radius + 5

            color: "transparent"    // Dashboard Panel    // Dashboard Panel

            

            layer.enabled: true    Item {    Item {

            layer.effect: MultiEffect {

                shadowEnabled: true        id: dashboardContainer        id: dashboardContainer

                shadowColor: Qt.rgba(0, 0, 0, 0.45)

                shadowBlur: 1.2                

                shadowVerticalOffset: 14

            }        width: 700        width: 700

        }

            height: 820        height: 820

        Rectangle {

            id: dashboard                

            anchors.fill: parent

            color: root.m3Surface        anchors.top: parent.top        anchors.top: parent.top

            radius: 24

                    anchors.right: parent.right        anchors.right: parent.right

            border.color: Qt.rgba(root.m3Primary.r, root.m3Primary.g, root.m3Primary.b, 0.3)

            border.width: 1        anchors.topMargin: 4        anchors.topMargin: 4

            

            // Main content        anchors.rightMargin: 4        anchors.rightMargin: 4

            ColumnLayout {

                anchors.fill: parent                

                anchors.margins: 20

                spacing: 16        transformOrigin: Item.TopRight        transformOrigin: Item.TopRight

                

                // Header with time and close button        scale: 0.85        scale: 0.85

                RowLayout {

                    Layout.fillWidth: true        opacity: 0        opacity: 0

                    spacing: 16

                                    

                    ColumnLayout {

                        spacing: 2        // Material 3 Expressive entrance animation        // Material 3 Expressive entrance animation

                        

                        Text {        SequentialAnimation {        SequentialAnimation {

                            text: Qt.formatTime(time.date, "hh:mm")

                            font.family: "Inter"            running: root.shouldShow            running: root.shouldShow

                            font.pixelSize: 42

                            font.weight: Font.Bold            ParallelAnimation {            ParallelAnimation {

                            color: root.m3OnSurface

                        }                NumberAnimation {                NumberAnimation {

                        

                        Text {                    target: dashboardContainer                    target: dashboardContainer

                            text: Qt.formatDate(time.date, "dddd, MMMM d")

                            font.family: "Inter"                    property: "scale"                    property: "scale"

                            font.pixelSize: 14

                            font.weight: Font.Medium                    from: 0.7                    from: 0.7

                            color: root.m3OnSurfaceVariant

                        }                    to: 1.08                    to: 1.08

                    }

                                        duration: 320                    duration: 320

                    Item { Layout.fillWidth: true }

                                        easing.type: Easing.OutCubic                    easing.type: Easing.OutCubic

                    // Close button

                    Rectangle {                }                }

                        Layout.preferredWidth: 44

                        Layout.preferredHeight: 44                NumberAnimation {                NumberAnimation {

                        radius: 22

                        color: hoverArea.containsMouse ?                     target: dashboardContainer                    target: dashboardContainer

                               Qt.rgba(root.m3Primary.r, root.m3Primary.g, root.m3Primary.b, 0.15) : 

                               "transparent"                    property: "opacity"                    property: "opacity"

                        

                        Behavior on color {                    from: 0                    from: 0

                            ColorAnimation { duration: 200; easing.type: Easing.OutCubic }

                        }                    to: 1                    to: 1

                        

                        Text {                    duration: 280                    duration: 280

                            anchors.centerIn: parent

                            text: "󰅖"                }                }

                            font.family: "Material Design Icons"

                            font.pixelSize: 24            }            }

                            color: root.m3OnSurface

                        }            NumberAnimation {            NumberAnimation {

                        

                        MouseArea {                target: dashboardContainer                target: dashboardContainer

                            id: hoverArea

                            anchors.fill: parent                property: "scale"                property: "scale"

                            hoverEnabled: true

                            cursorShape: Qt.PointingHandCursor                to: 1.0                to: 1.0

                            onClicked: root.shouldShow = false

                        }                duration: 260                duration: 260

                    }

                }                easing.type: Easing.OutBack                easing.type: Easing.OutBack

                

                // Quick toggles row                easing.overshoot: 1.9                easing.overshoot: 1.9

                RowLayout {

                    Layout.fillWidth: true            }            }

                    spacing: 12

                            }        }

                    // WiFi toggle

                    QuickToggle {                

                        Layout.fillWidth: true

                        icon: "󰖩"        ParallelAnimation {        ParallelAnimation {

                        label: "WiFi"

                        active: network.wifiEnabled            running: !root.shouldShow && dashboardContainer.opacity > 0            running: !root.shouldShow && dashboardContainer.opacity > 0

                        primaryColor: pywal.color5

                        onClicked: network.toggleWifi()            NumberAnimation { target: dashboardContainer; property: "scale"; to: 0.85; duration: 240; easing.type: Easing.InCubic }            NumberAnimation { target: dashboardContainer; property: "scale"; to: 0.85; duration: 240; easing.type: Easing.InCubic }

                    }

                                NumberAnimation { target: dashboardContainer; property: "opacity"; to: 0; duration: 240 }            NumberAnimation { target: dashboardContainer; property: "opacity"; to: 0; duration: 240 }

                    // Bluetooth toggle (placeholder)

                    QuickToggle {        }        }

                        Layout.fillWidth: true

                        icon: "󰂯"                

                        label: "Bluetooth"

                        active: false        // Elevated shadow        // Elevated shadow

                        primaryColor: pywal.color6

                        onClicked: console.log("Bluetooth toggle")        Rectangle {        Rectangle {

                    }

                                anchors.fill: dashboard            anchors.fill: dashboard

                    // DND toggle

                    QuickToggle {            anchors.margins: -10            anchors.margins: -10

                        Layout.fillWidth: true

                        icon: notifs.dnd ? "󰂛" : "󰂚"            radius: dashboard.radius + 5            radius: dashboard.radius + 5

                        label: "DND"

                        active: notifs.dnd            color: "transparent"            color: "transparent"

                        primaryColor: pywal.color1

                        onClicked: notifs.toggleDnd()                        

                    }

                                layer.enabled: true            layer.enabled: true

                    // Night Light toggle (placeholder)

                    QuickToggle {            layer.effect: MultiEffect {            layer.effect: MultiEffect {

                        Layout.fillWidth: true

                        icon: "󰖔"                shadowEnabled: true                shadowEnabled: true

                        label: "Night"

                        active: false                shadowColor: Qt.rgba(0, 0, 0, 0.45)                shadowColor: Qt.rgba(0, 0, 0, 0.45)

                        primaryColor: pywal.color3

                        onClicked: console.log("Night light toggle")                shadowBlur: 1.2                shadowBlur: 1.2

                    }

                }                shadowVerticalOffset: 14                shadowVerticalOffset: 14

                

                // Volume and Brightness sliders            }            }

                RowLayout {

                    Layout.fillWidth: true        }        }

                    spacing: 12

                            

                    // Volume slider card

                    SliderCard {        Rectangle {        Rectangle {

                        Layout.fillWidth: true

                        icon: audio.defaultSink?.muted ? "󰖁" : "󰕾"            id: dashboard            id: dashboard

                        label: "Volume"

                        value: audio.defaultSink?.volume ?? 0            anchors.fill: parent            anchors.fill: parent

                        primaryColor: pywal.color4

                        onValueChanged: newValue => {            color: root.m3Surface            color: root.m3Surface

                            if (audio.defaultSink) audio.defaultSink.volume = newValue

                        }            radius: 24            radius: 24

                        onIconClicked: {

                            if (audio.defaultSink) audio.defaultSink.muted = !audio.defaultSink.muted                        

                        }

                    }            border.color: Qt.rgba(root.m3Primary.r, root.m3Primary.g, root.m3Primary.b, 0.3)            border.color: Qt.rgba(root.m3Primary.r, root.m3Primary.g, root.m3Primary.b, 0.3)

                    

                    // Brightness slider card            border.width: 1            border.width: 1

                    SliderCard {

                        Layout.fillWidth: true                        

                        icon: "󰃠"

                        label: "Brightness"            // Main content            // Main content

                        value: brightness.level

                        primaryColor: pywal.color3            ColumnLayout {            ColumnLayout {

                        onValueChanged: newValue => { brightness.level = newValue }

                    }                anchors.fill: parent                anchors.fill: parent

                }

                                anchors.margins: 20                anchors.margins: 20

                // System resources row

                RowLayout {                spacing: 16                spacing: 16

                    Layout.fillWidth: true

                    spacing: 12                                

                    

                    // CPU card                // Header with time and close button                // Header with time and close button

                    SystemCard {

                        Layout.fillWidth: true                RowLayout {                RowLayout {

                        icon: "󰘚"

                        label: "CPU"                    Layout.fillWidth: true                    Layout.fillWidth: true

                        value: Math.round(systemUsage.cpuPerc * 100)

                        unit: "%"                    spacing: 16                    spacing: 16

                        progress: systemUsage.cpuPerc

                        primaryColor: pywal.color1                                        

                    }

                                        ColumnLayout {                    ColumnLayout {

                    // Memory card

                    SystemCard {                        spacing: 2                        spacing: 2

                        Layout.fillWidth: true

                        icon: "󰍛"                                                

                        label: "RAM"

                        value: Math.round(systemUsage.memPerc * 100)                        Text {                        Text {

                        unit: "%"

                        progress: systemUsage.memPerc                            text: Qt.formatTime(time.date, "hh:mm")                            text: Qt.formatTime(time.date, "hh:mm")

                        primaryColor: pywal.color2

                    }                            font.family: "Inter"                            font.family: "Inter"

                    

                    // Storage card                            font.pixelSize: 42                            font.pixelSize: 42

                    SystemCard {

                        Layout.fillWidth: true                            font.weight: Font.Bold                            font.weight: Font.Bold

                        icon: "󰋊"

                        label: "Disk"                            color: root.m3OnSurface                            color: root.m3OnSurface

                        value: Math.round(systemUsage.storagePerc * 100)

                        unit: "%"                        }                        }

                        progress: systemUsage.storagePerc

                        primaryColor: pywal.color3                                                

                    }

                }                        Text {                        Text {

                

                // Media player section                            text: Qt.formatDate(time.date, "dddd, MMMM d")                            text: Qt.formatDate(time.date, "dddd, MMMM d")

                Rectangle {

                    Layout.fillWidth: true                            font.family: "Inter"                            font.family: "Inter"

                    Layout.preferredHeight: 140

                    radius: 16                            font.pixelSize: 14                            font.pixelSize: 14

                    color: root.m3SurfaceContainer

                    border.color: Qt.rgba(root.m3Primary.r, root.m3Primary.g, root.m3Primary.b, 0.15)                            font.weight: Font.Medium                            font.weight: Font.Medium

                    border.width: 1

                    visible: players.activePlayer                            color: root.m3OnSurfaceVariant                            color: root.m3OnSurfaceVariant

                    

                    RowLayout {                        }                        }

                        anchors.fill: parent

                        anchors.margins: 16                    }                    }

                        spacing: 16

                                                                

                        // Album art

                        Rectangle {                    Item { Layout.fillWidth: true }                    Item { Layout.fillWidth: true }

                            Layout.preferredWidth: 108

                            Layout.preferredHeight: 108                                        

                            radius: 12

                            color: Qt.rgba(root.m3OnSurface.r, root.m3OnSurface.g, root.m3OnSurface.b, 0.1)                    // Close button                    // Close button

                            

                            Image {                    Rectangle {                    Rectangle {

                                anchors.fill: parent

                                anchors.margins: 0                        Layout.preferredWidth: 44                        Layout.preferredWidth: 44

                                source: players.activePlayer?.artUrl ?? ""

                                fillMode: Image.PreserveAspectCrop                        Layout.preferredHeight: 44                        Layout.preferredHeight: 44

                                asynchronous: true

                                visible: status === Image.Ready                        radius: 22                        radius: 22

                            }

                                                    color: hoverArea.containsMouse ?                         color: hoverArea.containsMouse ? 

                            Text {

                                anchors.centerIn: parent                               Qt.rgba(root.m3Primary.r, root.m3Primary.g, root.m3Primary.b, 0.15) :                                Qt.rgba(root.m3Primary.r, root.m3Primary.g, root.m3Primary.b, 0.15) : 

                                text: "󰝚"

                                font.family: "Material Design Icons"                               "transparent"                               "transparent"

                                font.pixelSize: 36

                                color: root.m3OnSurfaceVariant                                                

                                visible: !players.activePlayer?.artUrl

                            }                        Behavior on color {                        Behavior on color {

                        }

                                                    ColorAnimation { duration: 200; easing.type: Easing.OutCubic }                            ColorAnimation { duration: 200; easing.type: Easing.OutCubic }

                        // Track info and controls

                        ColumnLayout {                        }                        }

                            Layout.fillWidth: true

                            Layout.fillHeight: true                                                

                            spacing: 8

                                                    Text {                        Text {

                            ColumnLayout {

                                Layout.fillWidth: true                            anchors.centerIn: parent                            anchors.centerIn: parent

                                spacing: 4

                                                            text: "󰅖"                            text: "󰅖"

                                Text {

                                    Layout.fillWidth: true                            font.family: "Material Design Icons"                            font.family: "Material Design Icons"

                                    text: players.activePlayer?.title ?? "No media playing"

                                    font.family: "Inter"                            font.pixelSize: 24                            font.pixelSize: 24

                                    font.pixelSize: 16

                                    font.weight: Font.Bold                            color: root.m3OnSurface                            color: root.m3OnSurface

                                    color: root.m3OnSurface

                                    elide: Text.ElideRight                        }                        }

                                }

                                                                                

                                Text {

                                    Layout.fillWidth: true                        MouseArea {                        MouseArea {

                                    text: players.activePlayer?.artist ?? ""

                                    font.family: "Inter"                            id: hoverArea                            id: hoverArea

                                    font.pixelSize: 13

                                    color: root.m3OnSurfaceVariant                            anchors.fill: parent                            anchors.fill: parent

                                    elide: Text.ElideRight

                                }                            hoverEnabled: true                            hoverEnabled: true

                            }

                                                        cursorShape: Qt.PointingHandCursor                            cursorShape: Qt.PointingHandCursor

                            Item { Layout.fillHeight: true }

                                                        onClicked: root.shouldShow = false                            onClicked: root.shouldShow = false

                            // Playback controls

                            RowLayout {                        }                        }

                                Layout.fillWidth: true

                                spacing: 8                    }                    }

                                

                                MediaButton {                }                }

                                    icon: "󰒮"

                                    onClicked: players.activePlayer?.previous()                                

                                }

                                                // Quick toggles row                // Quick toggles row

                                MediaButton {

                                    icon: players.activePlayer?.playbackStatus === "Playing" ? "󰏤" : "󰐊"                RowLayout {                RowLayout {

                                    primary: true

                                    onClicked: players.activePlayer?.playPause()                    Layout.fillWidth: true                    Layout.fillWidth: true

                                }

                                                    spacing: 12                    spacing: 12

                                MediaButton {

                                    icon: "󰒭"                                        

                                    onClicked: players.activePlayer?.next()

                                }                    // WiFi toggle                    // WiFi toggle

                                

                                Item { Layout.fillWidth: true }                    QuickToggle {                    QuickToggle {

                            }

                        }                        Layout.fillWidth: true                        Layout.fillWidth: true

                    }

                }                        icon: "󰖩"                        icon: "󰖩"

                

                // Notifications section                        label: "WiFi"                        label: "WiFi"

                Rectangle {

                    Layout.fillWidth: true                        active: network.wifiEnabled                        active: network.wifiEnabled

                    Layout.fillHeight: true

                    radius: 16                        primaryColor: pywal.color5                        primaryColor: pywal.color5

                    color: root.m3SurfaceContainer

                    border.color: Qt.rgba(root.m3Primary.r, root.m3Primary.g, root.m3Primary.b, 0.15)                        onClicked: network.toggleWifi()                        onClicked: network.toggleWifi()

                    border.width: 1

                                        }                    }

                    ColumnLayout {

                        anchors.fill: parent                                        

                        anchors.margins: 16

                        spacing: 12                    // Bluetooth toggle (placeholder)                    // Bluetooth toggle (placeholder)

                        

                        RowLayout {                    QuickToggle {                    QuickToggle {

                            Layout.fillWidth: true

                                                    Layout.fillWidth: true                        Layout.fillWidth: true

                            Text {

                                text: "Notifications"                        icon: "󰂯"                        icon: "󰂯"

                                font.family: "Inter"

                                font.pixelSize: 16                        label: "Bluetooth"                        label: "Bluetooth"

                                font.weight: Font.Bold

                                color: root.m3OnSurface                        active: false                        active: false

                            }

                                                    primaryColor: pywal.color6                        primaryColor: pywal.color6

                            Item { Layout.fillWidth: true }

                                                    onClicked: console.log("Bluetooth toggle")                        onClicked: console.log("Bluetooth toggle")

                            Rectangle {

                                Layout.preferredWidth: 30                    }                    }

                                Layout.preferredHeight: 30

                                radius: 15                                        

                                color: clearHover.containsMouse ? 

                                       Qt.rgba(root.m3Primary.r, root.m3Primary.g, root.m3Primary.b, 0.15) :                     // DND toggle                    // DND toggle

                                       "transparent"

                                                    QuickToggle {                    QuickToggle {

                                Behavior on color {

                                    ColorAnimation { duration: 200; easing.type: Easing.OutCubic }                        Layout.fillWidth: true                        Layout.fillWidth: true

                                }

                                                        icon: notifs.dnd ? "󰂛" : "󰂚"                        icon: notifs.dnd ? "󰂛" : "󰂚"

                                Text {

                                    anchors.centerIn: parent                        label: "DND"                        label: "DND"

                                    text: "󰎟"

                                    font.family: "Material Design Icons"                        active: notifs.dnd                        active: notifs.dnd

                                    font.pixelSize: 16

                                    color: root.m3OnSurface                        primaryColor: pywal.color1                        primaryColor: pywal.color1

                                }

                                                        onClicked: notifs.toggleDnd()                        onClicked: notifs.toggleDnd()

                                MouseArea {

                                    id: clearHover                    }                    }

                                    anchors.fill: parent

                                    hoverEnabled: true                                        

                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: notifs.clearAll()                    // Night Light toggle (placeholder)                    // Night Light toggle (placeholder)

                                }

                            }                    QuickToggle {                    QuickToggle {

                        }

                                                Layout.fillWidth: true                        Layout.fillWidth: true

                        ScrollView {

                            Layout.fillWidth: true                        icon: "󰖔"                        icon: "󰖔"

                            Layout.fillHeight: true

                            clip: true                        label: "Night"                        label: "Night"

                            

                            ListView {                        active: false                        active: false

                                model: notifs.recentNotifications

                                spacing: 8                        primaryColor: pywal.color3                        primaryColor: pywal.color3

                                

                                delegate: Rectangle {                        onClicked: console.log("Night light toggle")                        onClicked: console.log("Night light toggle")

                                    required property var modelData

                                                        }                    }

                                    width: ListView.view.width

                                    height: 60                }                }

                                    radius: 12

                                    color: Qt.rgba(root.m3OnSurface.r, root.m3OnSurface.g, root.m3OnSurface.b, modelData.dismissed ? 0.05 : 0.08)                                

                                    opacity: modelData.dismissed ? 0.6 : 1.0

                                                    // Volume and Brightness sliders                // Volume and Brightness sliders

                                    RowLayout {

                                        anchors.fill: parent                RowLayout {                RowLayout {

                                        anchors.margins: 12

                                        spacing: 12                    Layout.fillWidth: true                    Layout.fillWidth: true

                                        

                                        Rectangle {                    spacing: 12                    spacing: 12

                                            Layout.preferredWidth: 36

                                            Layout.preferredHeight: 36                                        

                                            radius: 8

                                            color: Qt.rgba(root.m3Primary.r, root.m3Primary.g, root.m3Primary.b, 0.2)                    // Volume slider card                    // Volume slider card

                                            

                                            Text {                    SliderCard {                    SliderCard {

                                                anchors.centerIn: parent

                                                text: "󰂚"                        Layout.fillWidth: true                        Layout.fillWidth: true

                                                font.family: "Material Design Icons"

                                                font.pixelSize: 18                        icon: audio.defaultSink?.muted ? "󰖁" : "󰕾"                        icon: audio.defaultSink?.muted ? "󰖁" : "󰕾"

                                                color: root.m3Primary

                                            }                        label: "Volume"                        label: "Volume"

                                        }

                                                                value: audio.defaultSink?.volume ?? 0                        value: audio.defaultSink?.volume ?? 0

                                        ColumnLayout {

                                            Layout.fillWidth: true                        primaryColor: pywal.color4                        primaryColor: pywal.color4

                                            spacing: 2

                                                                    onValueChanged: newValue => {                        onValueChanged: newValue => {

                                            Text {

                                                Layout.fillWidth: true                            if (audio.defaultSink) audio.defaultSink.volume = newValue                            if (audio.defaultSink) audio.defaultSink.volume = newValue

                                                text: modelData.summary

                                                font.family: "Inter"                        }                        }

                                                font.pixelSize: 13

                                                font.weight: Font.Medium                        onIconClicked: {                        onIconClicked: {

                                                color: root.m3OnSurface

                                                elide: Text.ElideRight                            if (audio.defaultSink) audio.defaultSink.muted = !audio.defaultSink.muted                            if (audio.defaultSink) audio.defaultSink.muted = !audio.defaultSink.muted

                                            }

                                                                    }                        }

                                            Text {

                                                Layout.fillWidth: true                    }                    }

                                                text: modelData.body

                                                font.family: "Inter"                                        

                                                font.pixelSize: 11

                                                color: root.m3OnSurfaceVariant                    // Brightness slider card                    // Brightness slider card

                                                elide: Text.ElideRight

                                            }                    SliderCard {                    SliderCard {

                                        }

                                    }                        Layout.fillWidth: true                        Layout.fillWidth: true

                                }

                            }                        icon: "󰃠"                        icon: "󰃠"

                        }

                    }                        label: "Brightness"                        label: "Brightness"

                }

            }                        value: brightness.level                        value: brightness.level

        }

    }                        primaryColor: pywal.color3                        primaryColor: pywal.color3

    

    // Quick toggle component                        onValueChanged: newValue => { brightness.level = newValue }                        onValueChanged: newValue => { brightness.level = newValue }

    component QuickToggle: Rectangle {

        id: toggle                    }                    }

        

        property string icon: ""                }                }

        property string label: ""

        property bool active: false                                

        property color primaryColor: root.m3Primary

                        // System resources row                // System resources row

        signal clicked()

                        RowLayout {                RowLayout {

        Layout.preferredHeight: 90

        radius: 16                    Layout.fillWidth: true                    Layout.fillWidth: true

        

        color: active ?                     spacing: 12                    spacing: 12

               Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.18) : 

               root.m3SurfaceContainer                                        

        

        border.color: active ?                     // CPU card                    // CPU card

                      Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.4) : 

                      Qt.rgba(root.m3OnSurface.r, root.m3OnSurface.g, root.m3OnSurface.b, 0.1)                    SystemCard {                    SystemCard {

        border.width: 1

                                Layout.fillWidth: true                        Layout.fillWidth: true

        scale: toggleMouse.pressed ? 0.95 : (toggleMouse.containsMouse ? 1.02 : 1.0)

                                icon: "󰘚"                        icon: "󰘚"

        Behavior on color {

            ColorAnimation { duration: 250; easing.type: Easing.OutCubic }                        label: "CPU"                        label: "CPU"

        }

                                value: Math.round(systemUsage.cpuPerc * 100)                        value: Math.round(systemUsage.cpuPerc * 100)

        Behavior on border.color {

            ColorAnimation { duration: 250; easing.type: Easing.OutCubic }                        unit: "%"                        unit: "%"

        }

                                progress: systemUsage.cpuPerc                        progress: systemUsage.cpuPerc

        Behavior on scale {

            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }                        primaryColor: pywal.color1                        primaryColor: pywal.color1

        }

                            }                    }

        ColumnLayout {

            anchors.fill: parent                                        

            anchors.margins: 14

            spacing: 8                    // Memory card                    // Memory card

            

            Text {                    SystemCard {                    SystemCard {

                Layout.alignment: Qt.AlignLeft

                text: toggle.icon                        Layout.fillWidth: true                        Layout.fillWidth: true

                font.family: "Material Design Icons"

                font.pixelSize: 28                        icon: "󰍛"                        icon: "󰍛"

                color: toggle.active ? toggle.primaryColor : root.m3OnSurface

                                        label: "RAM"                        label: "RAM"

                Behavior on color {

                    ColorAnimation { duration: 250; easing.type: Easing.OutCubic }                        value: Math.round(systemUsage.memPerc * 100)                        value: Math.round(systemUsage.memPerc * 100)

                }

            }                        unit: "%"                        unit: "%"

            

            Item { Layout.fillHeight: true }                        progress: systemUsage.memPerc                        progress: systemUsage.memPerc

            

            Text {                        primaryColor: pywal.color2                        primaryColor: pywal.color2

                Layout.alignment: Qt.AlignLeft

                text: toggle.label                    }                    }

                font.family: "Inter"

                font.pixelSize: 12                                        

                font.weight: Font.Medium

                color: toggle.active ? toggle.primaryColor : root.m3OnSurfaceVariant                    // Storage card                    // Storage card

                

                Behavior on color {                    SystemCard {                    SystemCard {

                    ColorAnimation { duration: 250; easing.type: Easing.OutCubic }

                }                        Layout.fillWidth: true                        Layout.fillWidth: true

            }

        }                        icon: "󰋊"                        icon: "󰋊"

        

        MouseArea {                        label: "Disk"                        label: "Disk"

            id: toggleMouse

            anchors.fill: parent                        value: Math.round(systemUsage.storagePerc * 100)                        value: Math.round(systemUsage.storagePerc * 100)

            hoverEnabled: true

            cursorShape: Qt.PointingHandCursor                        unit: "%"                        unit: "%"

            onClicked: toggle.clicked()

        }                        progress: systemUsage.storagePerc                        progress: systemUsage.storagePerc

    }

                            primaryColor: pywal.color3                        primaryColor: pywal.color3

    // Slider card component

    component SliderCard: Rectangle {                    }                    }

        id: sliderCard

                        }                }

        property string icon: ""

        property string label: ""                                

        property real value: 0

        property color primaryColor: root.m3Primary                // Media player section                // Media player section

        

        signal valueChanged(real newValue)                Rectangle {                Rectangle {

        signal iconClicked()

                            Layout.fillWidth: true                    Layout.fillWidth: true

        Layout.preferredHeight: 90

        radius: 16                    Layout.preferredHeight: 140                    Layout.preferredHeight: 140

        color: root.m3SurfaceContainer

        border.color: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.2)                    radius: 16                    radius: 16

        border.width: 1

                            color: root.m3SurfaceContainer                    color: root.m3SurfaceContainer

        ColumnLayout {

            anchors.fill: parent                    border.color: Qt.rgba(root.m3Primary.r, root.m3Primary.g, root.m3Primary.b, 0.15)                    border.color: Qt.rgba(root.m3Primary.r, root.m3Primary.g, root.m3Primary.b, 0.15)

            anchors.margins: 14

            spacing: 10                    border.width: 1                    border.width: 1

            

            RowLayout {                    visible: players.activePlayer                    visible: players.activePlayer

                Layout.fillWidth: true

                spacing: 8                                        

                

                Rectangle {                    RowLayout {                    RowLayout {

                    Layout.preferredWidth: 32

                    Layout.preferredHeight: 32                        anchors.fill: parent                        anchors.fill: parent

                    radius: 16

                    color: Qt.rgba(sliderCard.primaryColor.r, sliderCard.primaryColor.g, sliderCard.primaryColor.b, 0.2)                        anchors.margins: 16                        anchors.margins: 16

                    

                    Text {                        spacing: 16                        spacing: 16

                        anchors.centerIn: parent

                        text: sliderCard.icon                                                

                        font.family: "Material Design Icons"

                        font.pixelSize: 18                        // Album art                        // Album art

                        color: sliderCard.primaryColor

                    }                        Rectangle {                        Rectangle {

                    

                    MouseArea {                            Layout.preferredWidth: 108                            Layout.preferredWidth: 108

                        anchors.fill: parent

                        cursorShape: Qt.PointingHandCursor                            Layout.preferredHeight: 108                            Layout.preferredHeight: 108

                        onClicked: sliderCard.iconClicked()

                    }                            radius: 12                            radius: 12

                }

                                            color: Qt.rgba(root.m3OnSurface.r, root.m3OnSurface.g, root.m3OnSurface.b, 0.1)                            color: Qt.rgba(root.m3OnSurface.r, root.m3OnSurface.g, root.m3OnSurface.b, 0.1)

                Text {

                    text: sliderCard.label                                                        

                    font.family: "Inter"

                    font.pixelSize: 12                            Image {                            Image {

                    font.weight: Font.Medium

                    color: root.m3OnSurfaceVariant                                anchors.fill: parent                                anchors.fill: parent

                }

                                                anchors.margins: 0                                anchors.margins: 0

                Item { Layout.fillWidth: true }

                                                source: players.activePlayer?.artUrl ?? ""                                source: players.activePlayer?.artUrl ?? ""

                Text {

                    text: Math.round(sliderCard.value * 100) + "%"                                fillMode: Image.PreserveAspectCrop                                fillMode: Image.PreserveAspectCrop

                    font.family: "Inter"

                    font.pixelSize: 13                                asynchronous: true                                asynchronous: true

                    font.weight: Font.Bold

                    color: root.m3OnSurface                                visible: status === Image.Ready                                visible: status === Image.Ready

                }

            }                            }                            }

            

            // Custom slider                                                        

            Rectangle {

                Layout.fillWidth: true                            Text {                            Text {

                Layout.preferredHeight: 6

                radius: 3                                anchors.centerIn: parent                                anchors.centerIn: parent

                color: Qt.rgba(root.m3OnSurface.r, root.m3OnSurface.g, root.m3OnSurface.b, 0.1)

                                                text: "󰝚"                                text: "󰝚"

                Rectangle {

                    width: parent.width * sliderCard.value                                font.family: "Material Design Icons"                                font.family: "Material Design Icons"

                    height: parent.height

                    radius: parent.radius                                font.pixelSize: 36                                font.pixelSize: 36

                    color: sliderCard.primaryColor

                                                    color: root.m3OnSurfaceVariant                                color: root.m3OnSurfaceVariant

                    Behavior on width {

                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }                                visible: !players.activePlayer?.artUrl                                visible: !players.activePlayer?.artUrl

                    }

                }                            }                            }

                

                MouseArea {                        }                        }

                    anchors.fill: parent

                    cursorShape: Qt.PointingHandCursor                                                

                    onClicked: mouse => {

                        const newValue = Math.max(0, Math.min(1, mouse.x / width))                        // Track info and controls                        // Track info and controls

                        sliderCard.valueChanged(newValue)

                    }                        ColumnLayout {                        ColumnLayout {

                    onPositionChanged: mouse => {

                        if (pressed) {                            Layout.fillWidth: true                            Layout.fillWidth: true

                            const newValue = Math.max(0, Math.min(1, mouse.x / width))

                            sliderCard.valueChanged(newValue)                            Layout.fillHeight: true                            Layout.fillHeight: true

                        }

                    }                            spacing: 8                            spacing: 8

                }

            }                                                        

        }

    }                            ColumnLayout {                            ColumnLayout {

    

    // System card component                                Layout.fillWidth: true                                Layout.fillWidth: true

    component SystemCard: Rectangle {

        id: sysCard                                spacing: 4                                spacing: 4

        

        property string icon: ""                                                                

        property string label: ""

        property int value: 0                                Text {                                Text {

        property string unit: ""

        property real progress: 0                                    Layout.fillWidth: true                                    Layout.fillWidth: true

        property color primaryColor: root.m3Primary

                                            text: players.activePlayer?.title ?? "No media playing"                                    text: players.activePlayer?.title ?? "No media playing"

        Layout.preferredHeight: 100

        radius: 16                                    font.family: "Inter"                                    font.family: "Inter"

        color: root.m3SurfaceContainer

        border.color: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.2)                                    font.pixelSize: 16                                    font.pixelSize: 16

        border.width: 1

                                            font.weight: Font.Bold                                    font.weight: Font.Bold

        ColumnLayout {

            anchors.fill: parent                                    color: root.m3OnSurface                                    color: root.m3OnSurface

            anchors.margins: 14

            spacing: 10                                    elide: Text.ElideRight                                    elide: Text.ElideRight

            

            RowLayout {                                }                                }

                Layout.fillWidth: true

                spacing: 8                                                                

                

                Text {                                Text {                                Text {

                    text: sysCard.icon

                    font.family: "Material Design Icons"                                    Layout.fillWidth: true                                    Layout.fillWidth: true

                    font.pixelSize: 24

                    color: sysCard.primaryColor                                    text: players.activePlayer?.artist ?? ""                                    text: players.activePlayer?.artist ?? ""

                }

                                                    font.family: "Inter"                                    font.family: "Inter"

                Text {

                    text: sysCard.label                                    font.pixelSize: 13                                    font.pixelSize: 13

                    font.family: "Inter"

                    font.pixelSize: 11                                    color: root.m3OnSurfaceVariant                                    color: root.m3OnSurfaceVariant

                    font.weight: Font.Medium

                    color: root.m3OnSurfaceVariant                                    elide: Text.ElideRight                                    elide: Text.ElideRight

                }

            }                                }                                }

            

            Item { Layout.fillHeight: true }                            }                            }

            

            Text {                                                        

                text: sysCard.value + sysCard.unit

                font.family: "Inter"                            Item { Layout.fillHeight: true }                            Item { Layout.fillHeight: true }

                font.pixelSize: 26

                font.weight: Font.Bold                                                        

                color: root.m3OnSurface

            }                            // Playback controls                            // Playback controls

            

            // Progress bar                            RowLayout {                            RowLayout {

            Rectangle {

                Layout.fillWidth: true                                Layout.fillWidth: true                                Layout.fillWidth: true

                Layout.preferredHeight: 5

                radius: 2.5                                spacing: 8                                spacing: 8

                color: Qt.rgba(root.m3OnSurface.r, root.m3OnSurface.g, root.m3OnSurface.b, 0.1)

                                                                                

                Rectangle {

                    width: parent.width * sysCard.progress                                MediaButton {                                MediaButton {

                    height: parent.height

                    radius: parent.radius                                    icon: "󰒮"                                    icon: "󰒮"

                    color: sysCard.primaryColor

                                                        onClicked: players.activePlayer?.previous()                                    onClicked: players.activePlayer?.previous()

                    Behavior on width {

                        NumberAnimation { duration: 500; easing.type: Easing.OutCubic }                                }                                }

                    }

                }                                                                

            }

        }                                MediaButton {                                MediaButton {

    }

                                        icon: players.activePlayer?.playbackStatus === "Playing" ? "󰏤" : "󰐊"                                    icon: players.activePlayer?.playbackStatus === "Playing" ? "󰏤" : "󰐊"

    // Media button component

    component MediaButton: Rectangle {                                    primary: true                                    primary: true

        id: btn

                                            onClicked: players.activePlayer?.playPause()                                    onClicked: players.activePlayer?.playPause()

        property string icon: ""

        property bool primary: false                                }                                }

        

        signal clicked()                                                                

        

        Layout.preferredWidth: primary ? 52 : 44                                MediaButton {                                MediaButton {

        Layout.preferredHeight: primary ? 52 : 44

        radius: (primary ? 26 : 22)                                    icon: "󰒭"                                    icon: "󰒭"

        

        color: primary ?                                     onClicked: players.activePlayer?.next()                                    onClicked: players.activePlayer?.next()

               root.m3Primary : 

               (btnMouse.containsMouse ? Qt.rgba(root.m3OnSurface.r, root.m3OnSurface.g, root.m3OnSurface.b, 0.1) : "transparent")                                }                                }

        

        border.color: primary ? "transparent" : Qt.rgba(root.m3OnSurface.r, root.m3OnSurface.g, root.m3OnSurface.b, 0.2)                                                                

        border.width: primary ? 0 : 1

                                        Item { Layout.fillWidth: true }                                Item { Layout.fillWidth: true }

        scale: btnMouse.pressed ? 0.9 : (btnMouse.containsMouse ? 1.05 : 1.0)

                                    }                            }

        Behavior on color {

            ColorAnimation { duration: 200; easing.type: Easing.OutCubic }                        }                        }

        }

                            }                    }

        Behavior on scale {

            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }                }                }

        }

                                        

        Text {

            anchors.centerIn: parent                // Notifications section                // Notifications section

            text: btn.icon

            font.family: "Material Design Icons"                Rectangle {                Rectangle {

            font.pixelSize: primary ? 28 : 22

            color: primary ? Qt.rgba(0, 0, 0, 0.9) : root.m3OnSurface                    Layout.fillWidth: true                    Layout.fillWidth: true

        }

                            Layout.fillHeight: true                    Layout.fillHeight: true

        MouseArea {

            id: btnMouse                    radius: 16                    radius: 16

            anchors.fill: parent

            hoverEnabled: true                    color: root.m3SurfaceContainer                    color: root.m3SurfaceContainer

            cursorShape: Qt.PointingHandCursor

            onClicked: btn.clicked()                    border.color: Qt.rgba(root.m3Primary.r, root.m3Primary.g, root.m3Primary.b, 0.15)                    border.color: Qt.rgba(root.m3Primary.r, root.m3Primary.g, root.m3Primary.b, 0.15)

        }

    }                    border.width: 1                    border.width: 1

}

                                        

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

