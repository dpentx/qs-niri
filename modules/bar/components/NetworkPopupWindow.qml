import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10 as QQC
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../../../services" as QsServices

// Material 3 Expressive Network Popup
PanelWindow {
    id: popupWindow
    
    property bool shouldShow: false
    property bool isHovered: false
    readonly property var pywal: QsServices.Pywal
    readonly property var network: QsServices.Network
    readonly property var sortedNetworks: [...network.networks].sort((a, b) => {
        if (a.active !== b.active) return b.active - a.active
        return b.strength - a.strength
    })
    
    // Material 3 colors
    readonly property color m3Surface: Qt.rgba(pywal.background.r, pywal.background.g, pywal.background.b, 1.0)
    readonly property color m3Primary: pywal.color5 ?? "#89b4fa"
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
    
    width: 380
    height: contentColumn.implicitHeight + 32
    color: "transparent"
    visible: shouldShow || container.opacity > 0
    
    // Material 3 animated container (single animation for both shadow and content)
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
        
        // Shadow layer (renders behind content)
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
    
        // Background layer (renders on top of shadow)
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
            
            // Content layer (renders on top of background)
            ColumnLayout {
                id: contentColumn
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12
                z: 2
        
        // Header with title and toggle
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            
            Text {
                text: "WiFi"
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
                
                color: network.wifiEnabled ? pywal.color2 : Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.2)
                
                Behavior on color {
                    ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
                }
                
                Rectangle {
                    width: 20
                    height: 20
                    radius: 10
                    x: network.wifiEnabled ? parent.width - width - 2 : 2
                    y: 2
                    color: "white"
                    
                    Behavior on x {
                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: network.toggleWifi()
                }
            }
        }
        
        // Scan button
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            radius: 8
            color: network.scanning ? pywal.color3 : Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.1)
            
            Behavior on color {
                ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
            }
            
            RowLayout {
                anchors.centerIn: parent
                spacing: 8
                
                Text {
                    text: network.scanning ? "󰑐" : "󰑓"  // scanning vs search icon
                    font.family: "Material Design Icons"
                    font.pixelSize: 18
                    color: pywal.foreground
                    
                    NumberAnimation on rotation {
                        running: network.scanning
                        from: 0
                        to: 360
                        duration: 1500
                        loops: Animation.Infinite
                        easing.type: Easing.Linear
                    }
                }
                
                Text {
                    text: network.scanning ? "Scanning..." : "Scan networks"
                    font.family: "Inter"
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: pywal.foreground
                }
            }
            
            MouseArea {
                anchors.fill: parent
                enabled: network.wifiEnabled
                onClicked: network.rescanWifi()
            }
        }
        
        // Separator
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.1)
        }
        
        // Network list
        ListView {
            id: networkList
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 300)
            
            spacing: 8
            clip: true
            interactive: contentHeight > 300
            
            model: sortedNetworks
            
            delegate: Rectangle {
                id: networkItem
                width: networkList.width
                height: 48
                radius: 8
                
                required property var modelData
                
                color: modelData.active 
                    ? Qt.rgba(pywal.color2.r, pywal.color2.g, pywal.color2.b, 0.15)
                    : Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.05)
                
                border.color: modelData.active 
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
                    
                    // Signal strength icon
                    Text {
                        text: {
                            const strength = networkItem.modelData.strength
                            if (strength >= 75) return "󰤨"  // wifi full
                            if (strength >= 50) return "󰤥"  // wifi good
                            if (strength >= 25) return "󰤢"  // wifi ok
                            return "󰤟"  // wifi weak
                        }
                        font.family: "Material Design Icons"
                        font.pixelSize: 20
                        color: {
                            if (networkItem.modelData.active) return pywal.color2
                            const strength = networkItem.modelData.strength
                            if (strength >= 50) return pywal.foreground
                            if (strength >= 25) return pywal.color3
                            return Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.6)
                        }
                        
                        Behavior on color {
                            ColorAnimation { duration: 300; easing.type: Easing.OutCubic }
                        }
                    }
                    
                    // Network info
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            
                            Text {
                                Layout.fillWidth: true
                                text: networkItem.modelData.ssid
                                font.family: "Inter"
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                color: pywal.foreground
                                elide: Text.ElideRight
                            }
                            
                            // Security lock icon
                            Text {
                                visible: networkItem.modelData.isSecure
                                text: "󰌾"  // lock icon
                                font.family: "Material Design Icons"
                                font.pixelSize: 14
                                color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.5)
                            }
                        }
                        
                        Text {
                            text: {
                                if (networkItem.modelData.active) return "Connected"
                                return `${networkItem.modelData.frequency} MHz • ${networkItem.modelData.strength}%`
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
                        
                        color: networkItem.modelData.active 
                            ? Qt.rgba(pywal.color1.r, pywal.color1.g, pywal.color1.b, 0.2)
                            : Qt.rgba(pywal.color2.r, pywal.color2.g, pywal.color2.b, 0.2)
                        
                        Behavior on color {
                            ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }
                        
                        Text {
                            anchors.centerIn: parent
                            text: networkItem.modelData.active ? "󰌊" : "󰌘"  // link-off vs link
                            font.family: "Material Design Icons"
                            font.pixelSize: 18
                            color: networkItem.modelData.active ? pywal.color1 : pywal.color2
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (networkItem.modelData.active) {
                                    network.disconnectFromNetwork()
                                } else {
                                    // For secure networks, prompt for password
                                    if (networkItem.modelData.isSecure && !networkItem.modelData.active) {
                                        passwordDialog.networkSSID = networkItem.modelData.ssid
                                        passwordDialog.visible = true
                                    } else {
                                        network.connectToNetwork(networkItem.modelData.ssid, "")
                                    }
                                }
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
            visible: sortedNetworks.length === 0
            Layout.fillWidth: true
            Layout.preferredHeight: 100
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 8
                
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "󰖪"
                    font.family: "Material Design Icons"
                    font.pixelSize: 32
                    color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.3)
                }
                
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: network.wifiEnabled ? "No networks found" : "WiFi is disabled"
                    font.family: "Inter"
                    font.pixelSize: 12
                    color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.5)
                }
            }
        }
    }
    
    // Password dialog overlay
    Rectangle {
        id: passwordDialog
        anchors.fill: parent
        visible: false
        color: Qt.rgba(0, 0, 0, 0.7)
        radius: 12
        
        property string networkSSID: ""
        
        MouseArea {
            anchors.fill: parent
            onClicked: passwordDialog.visible = false
        }
        
        Rectangle {
            anchors.centerIn: parent
            width: 280
            height: passwordColumn.implicitHeight + 32
            radius: 12
            color: pywal.background
            border.color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.2)
            border.width: 1
            
            ColumnLayout {
                id: passwordColumn
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12
                
                Text {
                    text: "Connect to WiFi"
                    font.family: "Inter"
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    color: pywal.foreground
                }
                
                Text {
                    Layout.fillWidth: true
                    text: passwordDialog.networkSSID
                    font.family: "Inter"
                    font.pixelSize: 12
                    color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.7)
                    elide: Text.ElideRight
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    radius: 6
                    color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.05)
                    border.color: passwordInput.activeFocus 
                        ? pywal.color2 
                        : Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.2)
                    border.width: 1
                    
                    Behavior on border.color {
                        ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }
                    
                    QQC.TextField {
                        id: passwordInput
                        anchors.fill: parent
                        anchors.margins: 8
                        
                        placeholderText: "Password"
                        echoMode: QQC.TextField.Password
                        
                        color: pywal.foreground
                        background: Item {}
                        
                        font.family: "Inter"
                        font.pixelSize: 12
                        
                        onAccepted: {
                            network.connectToNetwork(passwordDialog.networkSSID, text)
                            passwordDialog.visible = false
                            text = ""
                        }
                    }
                }
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    Item { Layout.fillWidth: true }
                    
                    Rectangle {
                        Layout.preferredWidth: 70
                        Layout.preferredHeight: 32
                        radius: 6
                        color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.1)
                        
                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            font.family: "Inter"
                            font.pixelSize: 12
                            color: pywal.foreground
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                passwordDialog.visible = false
                                passwordInput.text = ""
                            }
                        }
                    }
                    
                    Rectangle {
                        Layout.preferredWidth: 70
                        Layout.preferredHeight: 32
                        radius: 6
                        color: pywal.color2
                        
                        Text {
                            anchors.centerIn: parent
                            text: "Connect"
                            font.family: "Inter"
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: pywal.background
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                network.connectToNetwork(passwordDialog.networkSSID, passwordInput.text)
                                passwordDialog.visible = false
                                passwordInput.text = ""
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
