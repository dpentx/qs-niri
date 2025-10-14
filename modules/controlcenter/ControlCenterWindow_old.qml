import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../../services" as QsServices

// Material 3 Expressive System Dashboard
PanelWindow {
    id: root
    
    property bool shouldShow: false
    readonly property var pywal: QsServices.Pywal
    readonly property var network: QsServices.Network
    readonly property var audio: QsServices.Audio
    readonly property var brightness: QsServices.Brightness
    readonly property var systemUsage: QsServices.SystemUsage
    readonly property var time: QsServices.Time
    readonly property var notifs: QsServices.Notifs
    readonly property var players: QsServices.Players
    
    // Material 3 colors
    readonly property color m3Surface: Qt.rgba(pywal.background.r, pywal.background.g, pywal.background.b, 1.0)
    readonly property color m3SurfaceContainer: Qt.rgba(
        pywal.background.r * 1.08,
        pywal.background.g * 1.08,
        pywal.background.b * 1.08,
        1.0
    )
    readonly property color m3Primary: pywal.color4 ?? "#a6e3a1"
    readonly property color m3OnSurface: pywal.foreground
    readonly property color m3OnSurfaceVariant: Qt.rgba(
        pywal.foreground.r * 0.7,
        pywal.foreground.g * 0.7,
        pywal.foreground.b * 0.7,
        1.0
    )
    
    screen: Quickshell.screens[0]
    
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    
    color: "transparent"
    visible: shouldShow
    
    // Click outside to close
    MouseArea {
        anchors.fill: parent
        onClicked: root.shouldShow = false
        enabled: root.shouldShow
    }
    
    // Dashboard Panel
    Item {
        id: dashboardContainer
        
        width: 700
        height: 820
        
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 4
        anchors.rightMargin: 4
        
        transformOrigin: Item.TopRight
        scale: 0.85
        opacity: 0
        
        // Material 3 Expressive entrance animation
        SequentialAnimation {
            running: root.shouldShow
            ParallelAnimation {
                NumberAnimation {
                    target: dashboardContainer
                    property: "scale"
                    from: 0.7
                    to: 1.08
                    duration: 320
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: dashboardContainer
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 280
                }
            }
            NumberAnimation {
                target: dashboardContainer
                property: "scale"
                to: 1.0
                duration: 260
                easing.type: Easing.OutBack
                easing.overshoot: 1.9
            }
        }
        
        ParallelAnimation {
            running: !root.shouldShow && dashboardContainer.opacity > 0
            NumberAnimation { target: dashboardContainer; property: "scale"; to: 0.85; duration: 240; easing.type: Easing.InCubic }
            NumberAnimation { target: dashboardContainer; property: "opacity"; to: 0; duration: 240 }
        }
        
        // Elevated shadow
        Rectangle {
            anchors.fill: dashboard
            anchors.margins: -10
            radius: dashboard.radius + 5
            color: "transparent"
            
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.45)
                shadowBlur: 1.2
                shadowVerticalOffset: 14
            }
        }
    
        Rectangle {
            id: dashboard
            anchors.fill: parent
            color: root.m3Surface
            radius: 24
            
            border.color: Qt.rgba(root.m3Primary.r, root.m3Primary.g, root.m3Primary.b, 0.3)
            border.width: 1
            
            // Main content
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16
                
                // Header with time and close button
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16
                    
                    ColumnLayout {
                        spacing: 2
                        
                        Text {
                            text: Qt.formatTime(time.date, "hh:mm")
                            font.family: "Inter"
                            font.pixelSize: 42
                            font.weight: Font.Bold
                            color: root.m3OnSurface
                        }
                        
                        Text {
                            text: Qt.formatDate(time.date, "dddd, MMMM d")
                            font.family: "Inter"
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: root.m3OnSurfaceVariant
                        }
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    // Close button
                    Rectangle {
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 44
                        radius: 22
                        color: hoverArea.containsMouse ? 
                               Qt.rgba(root.m3Primary.r, root.m3Primary.g, root.m3Primary.b, 0.15) : 
                               "transparent"
                        
                        Behavior on color {
                            ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }
                        
                        Text {
                            anchors.centerIn: parent
                            text: "󰅖"
                            font.family: "Material Design Icons"
                            font.pixelSize: 24
                            color: root.m3OnSurface
                        }
                        
                        MouseArea {
                            id: hoverArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.shouldShow = false
                        }
                    }
                }
                
                // Quick toggles row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    // WiFi toggle
                    QuickToggle {
                        Layout.fillWidth: true
                        icon: "󰖩"
                        label: "WiFi"
                        active: network.wifiEnabled
                        primaryColor: pywal.color5
                        onClicked: network.toggleWifi()
                    }
                    
                    // Bluetooth toggle (placeholder)
                    QuickToggle {
                        Layout.fillWidth: true
                        icon: "󰂯"
                        label: "Bluetooth"
                        active: false
                        primaryColor: pywal.color6
                        onClicked: console.log("Bluetooth toggle")
                    }
                    
                    // DND toggle
                    QuickToggle {
                        Layout.fillWidth: true
                        icon: notifs.dnd ? "󰂛" : "󰂚"
                        label: "DND"
                        active: notifs.dnd
                        primaryColor: pywal.color1
                        onClicked: notifs.toggleDnd()
                    }
                    
                    // Night Light toggle (placeholder)
                    QuickToggle {
                        Layout.fillWidth: true
                        icon: "󰖔"
                        label: "Night"
                        active: false
                        primaryColor: pywal.color3
                        onClicked: console.log("Night light toggle")
                    }
                }
                
                // Volume and Brightness sliders
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    // Volume slider card
                    SliderCard {
                        Layout.fillWidth: true
                        icon: audio.defaultSink?.muted ? "󰖁" : "󰕾"
                        label: "Volume"
                        value: audio.defaultSink?.volume ?? 0
                        primaryColor: pywal.color4
                        onValueChanged: newValue => {
                            if (audio.defaultSink) audio.defaultSink.volume = newValue
                        }
                        onIconClicked: {
                            if (audio.defaultSink) audio.defaultSink.muted = !audio.defaultSink.muted
                        }
                    }
                    
                    // Brightness slider card
                    SliderCard {
                        Layout.fillWidth: true
                        icon: "󰃠"
                        label: "Brightness"
                        value: brightness.level
                        primaryColor: pywal.color3
                        onValueChanged: newValue => { brightness.level = newValue }
                    }
                }
                
                // System resources row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    // CPU card
                    SystemCard {
                        Layout.fillWidth: true
                        icon: "󰘚"
                        label: "CPU"
                        value: Math.round(systemUsage.cpuPerc * 100)
                        unit: "%"
                        progress: systemUsage.cpuPerc
                        primaryColor: pywal.color1
                    }
                    
                    // Memory card
                    SystemCard {
                        Layout.fillWidth: true
                        icon: "󰍛"
                        label: "RAM"
                        value: Math.round(systemUsage.memPerc * 100)
                        unit: "%"
                        progress: systemUsage.memPerc
                        primaryColor: pywal.color2
                    }
                    
                    // Storage card
                    SystemCard {
                        Layout.fillWidth: true
                        icon: "󰋊"
                        label: "Disk"
                        value: Math.round(systemUsage.storagePerc * 100)
                        unit: "%"
                        progress: systemUsage.storagePerc
                        primaryColor: pywal.color3
                    }
                }
                
                // Media player section
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 140
                    radius: 16
                    color: root.m3SurfaceContainer
                    border.color: Qt.rgba(root.m3Primary.r, root.m3Primary.g, root.m3Primary.b, 0.15)
                    border.width: 1
                    visible: players.activePlayer
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 16
                        
                        // Album art
                        Rectangle {
                            Layout.preferredWidth: 108
                            Layout.preferredHeight: 108
                            radius: 12
                            color: Qt.rgba(root.m3OnSurface.r, root.m3OnSurface.g, root.m3OnSurface.b, 0.1)
                            
                            Image {
                                anchors.fill: parent
                                anchors.margins: 0
                                source: players.activePlayer?.artUrl ?? ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                visible: status === Image.Ready
                            }
                            
                            Text {
                                anchors.centerIn: parent
                                text: "󰝚"
                                font.family: "Material Design Icons"
                                font.pixelSize: 36
                                color: root.m3OnSurfaceVariant
                                visible: !players.activePlayer?.artUrl
                            }
                        }
                        
                        // Track info and controls
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 8
                            
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                
                                Text {
                                    Layout.fillWidth: true
                                    text: players.activePlayer?.title ?? "No media playing"
                                    font.family: "Inter"
                                    font.pixelSize: 16
                                    font.weight: Font.Bold
                                    color: root.m3OnSurface
                                    elide: Text.ElideRight
                                }
                                
                                Text {
                                    Layout.fillWidth: true
                                    text: players.activePlayer?.artist ?? ""
                                    font.family: "Inter"
                                    font.pixelSize: 13
                                    color: root.m3OnSurfaceVariant
                                    elide: Text.ElideRight
                                }
                            }
                            
                            Item { Layout.fillHeight: true }
                            
                            // Playback controls
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                
                                MediaButton {
                                    icon: "󰒮"
                                    onClicked: players.activePlayer?.previous()
                                }
                                
                                MediaButton {
                                    icon: players.activePlayer?.playbackStatus === "Playing" ? "󰏤" : "󰐊"
                                    primary: true
                                    onClicked: players.activePlayer?.playPause()
                                }
                                
                                MediaButton {
                                    icon: "󰒭"
                                    onClicked: players.activePlayer?.next()
                                }
                                
                                Item { Layout.fillWidth: true }
                            }
                        }
                    }
                }
                
                // Notifications section
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 16
                    color: root.m3SurfaceContainer
                    border.color: Qt.rgba(root.m3Primary.r, root.m3Primary.g, root.m3Primary.b, 0.15)
                    border.width: 1
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12
                        
                        RowLayout {
                            Layout.fillWidth: true
                            
                            Text {
                                text: "Notifications"
                                font.family: "Inter"
                                font.pixelSize: 16
                                font.weight: Font.Bold
                                color: root.m3OnSurface
                            }
                            
                            Item { Layout.fillWidth: true }
                            
                            Rectangle {
                                Layout.preferredWidth: 30
                                Layout.preferredHeight: 30
                                radius: 15
                                color: clearHover.containsMouse ? 
                                       Qt.rgba(root.m3Primary.r, root.m3Primary.g, root.m3Primary.b, 0.15) : 
                                       "transparent"
                                
                                Behavior on color {
                                    ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
                                }
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰎟"
                                    font.family: "Material Design Icons"
                                    font.pixelSize: 16
                                    color: root.m3OnSurface
                                }
                                
                                MouseArea {
                                    id: clearHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: notifs.clearAll()
                                }
                            }
                        }
                        
                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            
                            ListView {
                                model: notifs.recentNotifications
                                spacing: 8
                                
                                delegate: Rectangle {
                                    required property var modelData
                                    
                                    width: ListView.view.width
                                    height: 60
                                    radius: 12
                                    color: Qt.rgba(root.m3OnSurface.r, root.m3OnSurface.g, root.m3OnSurface.b, modelData.dismissed ? 0.05 : 0.08)
                                    opacity: modelData.dismissed ? 0.6 : 1.0
                                    
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 12
                                        
                                        Rectangle {
                                            Layout.preferredWidth: 36
                                            Layout.preferredHeight: 36
                                            radius: 8
                                            color: Qt.rgba(root.m3Primary.r, root.m3Primary.g, root.m3Primary.b, 0.2)
                                            
                                            Text {
                                                anchors.centerIn: parent
                                                text: "󰂚"
                                                font.family: "Material Design Icons"
                                                font.pixelSize: 18
                                                color: root.m3Primary
                                            }
                                        }
                                        
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 2
                                            
                                            Text {
                                                Layout.fillWidth: true
                                                text: modelData.summary
                                                font.family: "Inter"
                                                font.pixelSize: 13
                                                font.weight: Font.Medium
                                                color: root.m3OnSurface
                                                elide: Text.ElideRight
                                            }
                                            
                                            Text {
                                                Layout.fillWidth: true
                                                text: modelData.body
                                                font.family: "Inter"
                                                font.pixelSize: 11
                                                color: root.m3OnSurfaceVariant
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Quick toggle component
    component QuickToggle: Rectangle {
        id: toggle
        
        property string icon: ""
        property string label: ""
        property bool active: false
        property color primaryColor: root.m3Primary
        
        signal clicked()
        
        Layout.preferredHeight: 90
        radius: 16
        
        color: active ? 
               Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.18) : 
               root.m3SurfaceContainer
        
        border.color: active ? 
                      Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.4) : 
                      Qt.rgba(root.m3OnSurface.r, root.m3OnSurface.g, root.m3OnSurface.b, 0.1)
        border.width: 1
        
        scale: toggleMouse.pressed ? 0.95 : (toggleMouse.containsMouse ? 1.02 : 1.0)
        
        Behavior on color {
            ColorAnimation { duration: 250; easing.type: Easing.OutCubic }
        }
        
        Behavior on border.color {
            ColorAnimation { duration: 250; easing.type: Easing.OutCubic }
        }
        
        Behavior on scale {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8
            
            Text {
                Layout.alignment: Qt.AlignLeft
                text: toggle.icon
                font.family: "Material Design Icons"
                font.pixelSize: 28
                color: toggle.active ? toggle.primaryColor : root.m3OnSurface
                
                Behavior on color {
                    ColorAnimation { duration: 250; easing.type: Easing.OutCubic }
                }
            }
            
            Item { Layout.fillHeight: true }
            
            Text {
                Layout.alignment: Qt.AlignLeft
                text: toggle.label
                font.family: "Inter"
                font.pixelSize: 12
                font.weight: Font.Medium
                color: toggle.active ? toggle.primaryColor : root.m3OnSurfaceVariant
                
                Behavior on color {
                    ColorAnimation { duration: 250; easing.type: Easing.OutCubic }
                }
            }
        }
        
        MouseArea {
            id: toggleMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: toggle.clicked()
        }
    }
    
    // Slider card component
    component SliderCard: Rectangle {
        id: sliderCard
        
        property string icon: ""
        property string label: ""
        property real value: 0
        property color primaryColor: root.m3Primary
        
        signal valueChanged(real newValue)
        signal iconClicked()
        
        Layout.preferredHeight: 90
        radius: 16
        color: root.m3SurfaceContainer
        border.color: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.2)
        border.width: 1
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                
                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: 16
                    color: Qt.rgba(sliderCard.primaryColor.r, sliderCard.primaryColor.g, sliderCard.primaryColor.b, 0.2)
                    
                    Text {
                        anchors.centerIn: parent
                        text: sliderCard.icon
                        font.family: "Material Design Icons"
                        font.pixelSize: 18
                        color: sliderCard.primaryColor
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sliderCard.iconClicked()
                    }
                }
                
                Text {
                    text: sliderCard.label
                    font.family: "Inter"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: root.m3OnSurfaceVariant
                }
                
                Item { Layout.fillWidth: true }
                
                Text {
                    text: Math.round(sliderCard.value * 100) + "%"
                    font.family: "Inter"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    color: root.m3OnSurface
                }
            }
            
            // Custom slider
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 6
                radius: 3
                color: Qt.rgba(root.m3OnSurface.r, root.m3OnSurface.g, root.m3OnSurface.b, 0.1)
                
                Rectangle {
                    width: parent.width * sliderCard.value
                    height: parent.height
                    radius: parent.radius
                    color: sliderCard.primaryColor
                    
                    Behavior on width {
                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        const newValue = Math.max(0, Math.min(1, mouse.x / width))
                        sliderCard.valueChanged(newValue)
                    }
                    onPositionChanged: mouse => {
                        if (pressed) {
                            const newValue = Math.max(0, Math.min(1, mouse.x / width))
                            sliderCard.valueChanged(newValue)
                        }
                    }
                }
            }
        }
    }
    
    // System card component
    component SystemCard: Rectangle {
        id: sysCard
        
        property string icon: ""
        property string label: ""
        property int value: 0
        property string unit: ""
        property real progress: 0
        property color primaryColor: root.m3Primary
        
        Layout.preferredHeight: 100
        radius: 16
        color: root.m3SurfaceContainer
        border.color: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.2)
        border.width: 1
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                
                Text {
                    text: sysCard.icon
                    font.family: "Material Design Icons"
                    font.pixelSize: 24
                    color: sysCard.primaryColor
                }
                
                Text {
                    text: sysCard.label
                    font.family: "Inter"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: root.m3OnSurfaceVariant
                }
            }
            
            Item { Layout.fillHeight: true }
            
            Text {
                text: sysCard.value + sysCard.unit
                font.family: "Inter"
                font.pixelSize: 26
                font.weight: Font.Bold
                color: root.m3OnSurface
            }
            
            // Progress bar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 5
                radius: 2.5
                color: Qt.rgba(root.m3OnSurface.r, root.m3OnSurface.g, root.m3OnSurface.b, 0.1)
                
                Rectangle {
                    width: parent.width * sysCard.progress
                    height: parent.height
                    radius: parent.radius
                    color: sysCard.primaryColor
                    
                    Behavior on width {
                        NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
                    }
                }
            }
        }
    }
    
    // Media button component
    component MediaButton: Rectangle {
        id: btn
        
        property string icon: ""
        property bool primary: false
        
        signal clicked()
        
        Layout.preferredWidth: primary ? 52 : 44
        Layout.preferredHeight: primary ? 52 : 44
        radius: (primary ? 26 : 22)
        
        color: primary ? 
               root.m3Primary : 
               (btnMouse.containsMouse ? Qt.rgba(root.m3OnSurface.r, root.m3OnSurface.g, root.m3OnSurface.b, 0.1) : "transparent")
        
        border.color: primary ? "transparent" : Qt.rgba(root.m3OnSurface.r, root.m3OnSurface.g, root.m3OnSurface.b, 0.2)
        border.width: primary ? 0 : 1
        
        scale: btnMouse.pressed ? 0.9 : (btnMouse.containsMouse ? 1.05 : 1.0)
        
        Behavior on color {
            ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
        
        Behavior on scale {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }
        
        Text {
            anchors.centerIn: parent
            text: btn.icon
            font.family: "Material Design Icons"
            font.pixelSize: primary ? 28 : 22
            color: primary ? Qt.rgba(0, 0, 0, 0.9) : root.m3OnSurface
        }
        
        MouseArea {
            id: btnMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }
}
