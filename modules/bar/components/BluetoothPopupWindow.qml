import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Bluetooth
import "../../../services" as QsServices

// Material 3 Expressive Bluetooth Popup
PanelWindow {
    id: popupWindow
    
    property bool shouldShow: false
    property bool isHovered: false
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var pywal: QsServices.Pywal
    readonly property var devices: [...Bluetooth.devices.values].sort((a, b) => {
        // Sort: connected first, then paired, then by name
        if (a.connected !== b.connected) return b.connected - a.connected
        if (a.bonded !== b.bonded) return b.bonded - a.bonded
        return a.name.localeCompare(b.name)
    })
    
    // Material 3 colors
    readonly property color m3Surface: Qt.rgba(pywal.background.r, pywal.background.g, pywal.background.b, 1.0)
    readonly property color m3Primary: pywal.color6 ?? "#cba6f7"
    readonly property color m3OnSurface: pywal.foreground
    
    screen: Quickshell.screens[0]
    
    anchors {
        top: true
        right: true
    }
    
    margins {
        right: 4
        top: 4
    }
    
    width: 360
    height: contentColumn.implicitHeight + 24
    color: "transparent"
    visible: shouldShow || container.opacity > 0
    
    // Material 3 animated container (single animation for smooth appearance)
    Item {
        id: container
        anchors.fill: parent
        scale: 0.85
        opacity: 0
        transformOrigin: Item.TopRight
        
        SequentialAnimation {
            running: popupWindow.shouldShow
            ParallelAnimation {
                NumberAnimation { target: container; property: "scale"; from: 0.85; to: 1.05; duration: 250; easing.type: Easing.OutCubic }
                NumberAnimation { target: container; property: "opacity"; from: 0; to: 1; duration: 200 }
            }
            NumberAnimation { target: container; property: "scale"; to: 1.0; duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.3 }
        }
        
        ParallelAnimation {
            running: !popupWindow.shouldShow && container.opacity > 0
            NumberAnimation { target: container; property: "scale"; to: 0.9; duration: 180; easing.type: Easing.InCubic }
            NumberAnimation { target: container; property: "opacity"; to: 0; duration: 180 }
        }
        
        // Shadow layer (renders behind)
        Rectangle {
            anchors.fill: backgroundRect
            anchors.margins: -6
            radius: backgroundRect.radius + 3
            color: "transparent"
            z: 0
            
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.35)
                shadowBlur: 0.8
                shadowVerticalOffset: 8
            }
        }
        
        // Background and content layer (renders on top)
        Rectangle {
            id: backgroundRect
            anchors.fill: parent
            color: m3Surface
            radius: 16
            border.color: Qt.rgba(m3Primary.r, m3Primary.g, m3Primary.b, 0.2)
            border.width: 1
            z: 1
            
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: popupWindow.isHovered = true
                onExited: {
                    popupWindow.isHovered = false
                    popupWindow.shouldShow = false
                }
            }
            
            ColumnLayout {
                id: contentColumn
                anchors.fill: parent
                z: 2
                anchors.margins: 12
                spacing: 12
        
        // Header with title and toggle
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            
            Text {
                text: "Bluetooth"
                font.family: "Inter"
                font.pixelSize: 16
                font.weight: Font.Bold
                color: pywal.foreground
            }
            
            Item { Layout.fillWidth: true }
            
            // Enable/Disable toggle
            Rectangle {
                Layout.preferredWidth: 48
                Layout.preferredHeight: 24
                radius: 12
                
                color: adapter?.enabled ? pywal.color2 : Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.2)
                
                Behavior on color {
                    ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
                }
                
                Rectangle {
                    width: 20
                    height: 20
                    radius: 10
                    x: adapter?.enabled ? parent.width - width - 2 : 2
                    y: 2
                    color: "white"
                    
                    Behavior on x {
                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (adapter) adapter.enabled = !adapter.enabled
                    }
                }
            }
        }
        
        // Scan button
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            radius: 8
            color: adapter?.discovering ? pywal.color3 : Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.1)
            
            Behavior on color {
                ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
            }
            
            RowLayout {
                anchors.centerIn: parent
                spacing: 8
                
                Text {
                    text: adapter?.discovering ? "󰑐" : "󰑓"  // scanning vs search icon
                    font.family: "Material Design Icons"
                    font.pixelSize: 18
                    color: pywal.foreground
                    
                    NumberAnimation on rotation {
                        running: adapter?.discovering ?? false
                        from: 0
                        to: 360
                        duration: 1500
                        loops: Animation.Infinite
                        easing.type: Easing.Linear
                    }
                }
                
                Text {
                    text: adapter?.discovering ? "Scanning..." : "Scan for devices"
                    font.family: "Inter"
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: pywal.foreground
                }
            }
            
            MouseArea {
                anchors.fill: parent
                enabled: adapter?.enabled ?? false
                onClicked: {
                    if (adapter) adapter.discovering = !adapter.discovering
                }
            }
        }
        
        // Separator
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.1)
        }
        
        // Device list
        ListView {
            id: deviceList
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 300)
            
            spacing: 8
            clip: true
            interactive: contentHeight > 300
            
            model: devices
            
            delegate: Rectangle {
                id: deviceItem
                width: deviceList.width
                height: 48
                radius: 8
                
                required property var modelData
                readonly property bool isConnecting: modelData.state === BluetoothDeviceState.Connecting
                readonly property bool isDisconnecting: modelData.state === BluetoothDeviceState.Disconnecting
                
                color: modelData.connected 
                    ? Qt.rgba(pywal.color2.r, pywal.color2.g, pywal.color2.b, 0.15)
                    : Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.05)
                
                border.color: modelData.connected 
                    ? Qt.rgba(pywal.color2.r, pywal.color2.g, pywal.color2.b, 0.3)
                    : "transparent"
                border.width: 1
                
                Behavior on color {
                    ColorAnimation { duration: 300; easing.type: Easing.OutCubic }
                }
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 12
                    
                    // Device icon
                    Text {
                        text: {
                            const icon = modelData.icon || "generic"
                            if (icon.includes("audio")) return "󰋋"  // headphones
                            if (icon.includes("phone")) return "󰄜"  // phone
                            if (icon.includes("computer")) return "󰌢"  // computer
                            if (icon.includes("mouse")) return "󰍽"  // mouse
                            if (icon.includes("keyboard")) return "󰌌"  // keyboard
                            return "󰂯"  // bluetooth
                        }
                        font.family: "Material Design Icons"
                        font.pixelSize: 20
                        color: modelData.connected ? pywal.color2 : pywal.foreground
                        
                        Behavior on color {
                            ColorAnimation { duration: 300; easing.type: Easing.OutCubic }
                        }
                    }
                    
                    // Device info
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        
                        Text {
                            Layout.fillWidth: true
                            text: modelData.name
                            font.family: "Inter"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: pywal.foreground
                            elide: Text.ElideRight
                        }
                        
                        Text {
                            text: {
                                if (deviceItem.isConnecting) return "Connecting..."
                                if (deviceItem.isDisconnecting) return "Disconnecting..."
                                if (modelData.connected) return "Connected"
                                if (modelData.bonded) return "Paired"
                                return "Available"
                            }
                            font.family: "Inter"
                            font.pixelSize: 11
                            color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.6)
                        }
                    }
                    
                    // Connect/Disconnect button
                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 18
                        
                        color: modelData.connected 
                            ? Qt.rgba(pywal.color1.r, pywal.color1.g, pywal.color1.b, 0.2)
                            : Qt.rgba(pywal.color2.r, pywal.color2.g, pywal.color2.b, 0.2)
                        
                        Behavior on color {
                            ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }
                        
                        // Loading spinner when connecting/disconnecting
                        Rectangle {
                            visible: deviceItem.isConnecting || deviceItem.isDisconnecting
                            anchors.centerIn: parent
                            width: 20
                            height: 20
                            radius: 10
                            color: "transparent"
                            border.color: pywal.foreground
                            border.width: 2
                            
                            Rectangle {
                                width: parent.width
                                height: parent.height / 2
                                anchors.top: parent.top
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: pywal.background
                            }
                            
                            NumberAnimation on rotation {
                                running: deviceItem.isConnecting || deviceItem.isDisconnecting
                                from: 0
                                to: 360
                                duration: 1200
                                loops: Animation.Infinite
                                easing.type: Easing.Linear
                            }
                        }
                        
                        Text {
                            visible: !deviceItem.isConnecting && !deviceItem.isDisconnecting
                            anchors.centerIn: parent
                            text: modelData.connected ? "󰌊" : "󰌘"  // link-off vs link
                            font.family: "Material Design Icons"
                            font.pixelSize: 18
                            color: modelData.connected ? pywal.color1 : pywal.color2
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            enabled: !deviceItem.isConnecting && !deviceItem.isDisconnecting
                            onClicked: {
                                modelData.connected = !modelData.connected
                            }
                        }
                    }
                }
                
                // Appear animation
                opacity: 0
                scale: 0.9
                
                Component.onCompleted: {
                    opacity = 1
                    scale = 1
                }
                
                Behavior on opacity {
                    NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                }
                
                Behavior on scale {
                    NumberAnimation { duration: 250; easing.type: Easing.OutBack }
                }
            }
        }
        
        // Empty state
        Item {
            visible: devices.length === 0
            Layout.fillWidth: true
            Layout.preferredHeight: 100
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 8
                
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "󰂲"
                    font.family: "Material Design Icons"
                    font.pixelSize: 32
                    color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.3)
                }
                
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: adapter?.enabled ? "No devices found" : "Bluetooth is disabled"
                    font.family: "Inter"
                    font.pixelSize: 12
                    color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.5)
                }
            }
        }
            } // contentColumn
        } // backgroundRect
    } // container
}
