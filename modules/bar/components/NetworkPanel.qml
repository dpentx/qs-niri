import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10 as QQC
import QtQuick.Effects
import Quickshell.Io
import "../../../services" as QsServices

// Inline Network Panel - hosted inside bar window
FocusScope {
    id: popupPanel
    
    property bool shouldShow: false
    signal closeRequested()
    readonly property var pywal: QsServices.Pywal
    readonly property var network: QsServices.Network
    readonly property var sortedNetworks: [...network.networks].sort((a, b) => {
        if (a.active !== b.active) return b.active - a.active
        return b.strength - a.strength
    })
    
    // Solid colors like Control Center
    readonly property color cSurface: pywal.background
    readonly property color cSurfaceContainer: Qt.lighter(pywal.background, 1.15)
    readonly property color cPrimary: pywal.primary
    readonly property color cText: pywal.foreground
    readonly property color cSubText: Qt.rgba(cText.r, cText.g, cText.b, 0.6)
    readonly property color cBorder: Qt.rgba(cText.r, cText.g, cText.b, 0.08)
    readonly property color cHover: Qt.rgba(cText.r, cText.g, cText.b, 0.06)
    
    // Settings launcher
    Process {
        id: settingsProcess
        command: ["nm-connection-editor"]
        onStarted: popupPanel.closeRequested()
    }
    
    implicitWidth: 340
    implicitHeight: contentColumn.implicitHeight + 32
    focus: true
    
    Keys.onEscapePressed: {
        if (!passwordDialog.isOpen) closeRequested()
    }

    Connections {
        target: network
        function onConnectFailed(ssid, reason) {
            const friendly = reason && reason.length > 0 ? reason : "Bağlantı başarısız — şifre yanlış olabilir"
            errorBanner.show(`${ssid}: ${friendly}`)
            // If we silently tried a saved profile and it failed, most likely cause
            // is a stale/wrong password — reopen the dialog so the user can retype it.
            const wasSecure = network.networks.find(n => n.ssid === ssid)?.isSecure ?? false
            if (wasSecure) {
                passwordDialog.networkSSID = ssid
                passwordDialog.errorText = friendly
                passwordDialog.wasSavedAttempt = network.savedNetworks.includes(ssid)
                passwordDialog.open()
            }
        }
        function onConnectSucceeded(ssid) {
            errorBanner.hide()
        }
    }
        
        // Background with shadow
        Rectangle {
            id: backgroundRect
            anchors.fill: parent
            color: cSurface
            radius: 16
            border.color: cBorder
            border.width: 1
            
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.35)
                shadowBlur: 1.0
                shadowVerticalOffset: 6
            }
            
            ColumnLayout {
                id: contentColumn
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12
        
                // Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    Rectangle {
                        width: 36
                        height: 36
                        radius: 12
                        color: Qt.rgba(cPrimary.r, cPrimary.g, cPrimary.b, 0.15)
                        
                        Text {
                            anchors.centerIn: parent
                            text: "󰖩"
                            font.family: "Material Design Icons"
                            font.pixelSize: 18
                            color: cPrimary
                        }
                    }
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        
                        Text {
                            text: "WiFi Networks"
                            font.family: "Inter"
                            font.pixelSize: 15
                            font.weight: Font.Bold
                            color: cText
                        }
                        
                        Text {
                            text: network.connectingSsid.length > 0
                                ? `Connecting to ${network.connectingSsid}...`
                                : (network.active ? `Connected: ${network.active.ssid}` : "Not connected")
                            font.family: "Inter"
                            font.pixelSize: 11
                            font.weight: network.active && network.connectingSsid.length === 0 ? Font.Medium : Font.Normal
                            color: network.connectingSsid.length > 0 ? cPrimary : (network.active ? cPrimary : cSubText)
                        }
                    }
                    
                    // Toggle
                    Rectangle {
                        width: 44
                        height: 24
                        radius: 12
                        color: network.wifiEnabled ? cPrimary : Qt.rgba(cText.r, cText.g, cText.b, 0.15)
                        
                        Behavior on color { ColorAnimation { duration: 150 } }
                        
                        Rectangle {
                            width: 18
                            height: 18
                            radius: 9
                            anchors.verticalCenter: parent.verticalCenter
                            x: network.wifiEnabled ? parent.width - width - 3 : 3
                            color: "#ffffff"
                            
                            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: network.toggleWifi()
                        }
                    }
                }
                
                // Scan button
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    radius: 10
                    color: scanArea.containsMouse ? cHover : cSurfaceContainer
                    
                    Behavior on color { ColorAnimation { duration: 100 } }
                    
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        
                        Text {
                            text: network.scanning ? "󰑐" : "󰑓"
                            font.family: "Material Design Icons"
                            font.pixelSize: 16
                            color: network.scanning ? cPrimary : cText
                            
                            RotationAnimation on rotation {
                                running: network.scanning
                                from: 0; to: 360; duration: 1000; loops: Animation.Infinite
                            }
                        }
                        
                        Text {
                            text: network.scanning ? "Scanning..." : "Scan networks"
                            font.family: "Inter"
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: cText
                        }
                    }
                    
                    MouseArea {
                        id: scanArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: network.wifiEnabled
                        onClicked: network.rescanWifi()
                    }
                }
                
                // Error banner — surfaces failed connection attempts instead of silence
                Rectangle {
                    id: errorBanner
                    Layout.fillWidth: true
                    Layout.preferredHeight: hasError ? errorText.implicitHeight + 20 : 0
                    visible: hasError
                    radius: 10
                    color: Qt.rgba(0.86, 0.3, 0.3, 0.15)
                    border.width: 1
                    border.color: Qt.rgba(0.86, 0.3, 0.3, 0.4)
                    clip: true

                    Behavior on Layout.preferredHeight { NumberAnimation { duration: 150 } }

                    property bool hasError: false
                    property string message: ""

                    function show(msg) {
                        message = msg
                        hasError = true
                        hideTimer.restart()
                    }
                    function hide() { hasError = false }

                    Timer { id: hideTimer; interval: 6000; onTriggered: errorBanner.hide() }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        Text {
                            text: "󰀦"
                            font.family: "Material Design Icons"
                            font.pixelSize: 14
                            color: "#e57373"
                        }

                        Text {
                            id: errorText
                            Layout.fillWidth: true
                            text: errorBanner.message
                            font.family: "Inter"
                            font.pixelSize: 11
                            color: cText
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            text: "✕"
                            font.pixelSize: 11
                            color: cSubText
                            MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: errorBanner.hide() }
                        }
                    }
                }
                
                // Network List
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(networkList.contentHeight + 8, 280)
                    radius: 12
                    color: cSurfaceContainer
                    clip: true
                    
                    ListView {
                        id: networkList
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 2
                        model: sortedNetworks
                        clip: true
                        
                        delegate: Rectangle {
                            id: networkItem
                            width: networkList.width
                            height: 52
                            radius: 10
                            color: itemArea.containsMouse ? cHover : "transparent"
                            
                            required property var modelData
                            property bool isActive: modelData.active
                            property bool isConnecting: network.connectingSsid === modelData.ssid
                            property bool isSaved: network.savedNetworks.includes(modelData.ssid)
                            
                            Behavior on color { ColorAnimation { duration: 80 } }
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10
                                
                                // Signal
                                Text {
                                    text: {
                                        const s = networkItem.modelData.strength
                                        if (s >= 75) return "󰤨"
                                        if (s >= 50) return "󰤥"
                                        if (s >= 25) return "󰤢"
                                        return "󰤟"
                                    }
                                    font.family: "Material Design Icons"
                                    font.pixelSize: 18
                                    color: isActive ? cPrimary : cText
                                }
                                
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    
                                    RowLayout {
                                        spacing: 4
                                        Text {
                                            text: networkItem.modelData.ssid
                                            font.family: "Inter"
                                            font.pixelSize: 12
                                            font.weight: Font.Medium
                                            color: cText
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                        Text {
                                            visible: networkItem.modelData.isSecure
                                            text: "󰌾"
                                            font.family: "Material Design Icons"
                                            font.pixelSize: 10
                                            color: cSubText
                                        }
                                        Text {
                                            visible: isActive
                                            text: "󰄬"
                                            font.family: "Material Design Icons"
                                            font.pixelSize: 12
                                            color: cPrimary
                                        }
                                    }
                                    
                                    Text {
                                        text: isConnecting ? "Connecting..." : (isActive ? "Connected" : `${networkItem.modelData.strength}%`)
                                        font.family: "Inter"
                                        font.pixelSize: 10
                                        color: (isActive || isConnecting) ? cPrimary : cSubText
                                    }
                                }
                                
                                // Forget (only for saved, non-active networks)
                                Rectangle {
                                    width: 28
                                    height: 28
                                    radius: 14
                                    visible: isSaved && !isActive
                                    color: forgetArea.containsMouse ? Qt.rgba(0.86, 0.3, 0.3, 0.15) : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰆴"
                                        font.family: "Material Design Icons"
                                        font.pixelSize: 14
                                        color: forgetArea.containsMouse ? "#e57373" : cSubText
                                    }

                                    MouseArea {
                                        id: forgetArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: network.forgetNetwork(networkItem.modelData.ssid)
                                    }
                                }

                                // Action
                                Rectangle {
                                    width: 28
                                    height: 28
                                    radius: 14
                                    color: actionArea.containsMouse ? Qt.rgba(cPrimary.r, cPrimary.g, cPrimary.b, 0.15) : "transparent"
                                    border.width: 1
                                    border.color: isActive ? cPrimary : Qt.rgba(cText.r, cText.g, cText.b, 0.15)
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: isConnecting ? "󰑐" : (isActive ? "󰌊" : "󰌘")
                                        font.family: "Material Design Icons"
                                        font.pixelSize: 14
                                        color: isActive ? cPrimary : cSubText

                                        RotationAnimation on rotation {
                                            running: isConnecting
                                            from: 0; to: 360; duration: 900; loops: Animation.Infinite
                                        }
                                    }
                                    
                                    MouseArea {
                                        id: actionArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        enabled: !isConnecting
                                        onClicked: {
                                            if (isActive) {
                                                network.disconnectFromNetwork()
                                            } else if (isSaved) {
                                                network.connectToNetwork(networkItem.modelData.ssid, "")
                                            } else if (networkItem.modelData.isSecure) {
                                                passwordDialog.networkSSID = networkItem.modelData.ssid
                                                passwordDialog.open()
                                            } else {
                                                network.connectToNetwork(networkItem.modelData.ssid, "")
                                            }
                                        }
                                    }
                                }
                            }
                            
                            MouseArea {
                                id: itemArea
                                anchors.fill: parent
                                hoverEnabled: true
                                z: -1
                            }
                        }
                    }
                    
                    // Empty state
                    ColumnLayout {
                        anchors.centerIn: parent
                        visible: sortedNetworks.length === 0
                        spacing: 6
                        
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "󰖪"
                            font.family: "Material Design Icons"
                            font.pixelSize: 32
                            color: Qt.rgba(cText.r, cText.g, cText.b, 0.2)
                        }
                        
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: network.wifiEnabled ? "No networks found" : "WiFi disabled"
                            font.family: "Inter"
                            font.pixelSize: 12
                            color: cSubText
                        }
                    }
                }
                
                // Settings button
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    radius: 10
                    color: settingsArea.containsMouse ? cHover : "transparent"
                    
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        
                        Text {
                            text: "󰒓"
                            font.family: "Material Design Icons"
                            font.pixelSize: 14
                            color: cSubText
                        }
                        
                        Text {
                            text: "Network Settings"
                            font.family: "Inter"
                            font.pixelSize: 12
                            color: cSubText
                        }
                    }
                    
                    MouseArea {
                        id: settingsArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: settingsProcess.running = true
                    }
                }
            }
        }
    
    // Password Dialog
    Item {
        id: passwordDialog
        anchors.fill: parent
        visible: opacity > 0
        z: 100
        
        property string networkSSID: ""
        property bool isOpen: false
        property string errorText: ""
        property bool wasSavedAttempt: false
        
        opacity: 0
        
        function open() { isOpen = true; passwordInput.forceActiveFocus() }
        function close() { isOpen = false; passwordInput.text = ""; errorText = ""; wasSavedAttempt = false }
        
        states: State {
            name: "open"; when: passwordDialog.isOpen
            PropertyChanges { target: passwordDialog; opacity: 1 }
            PropertyChanges { target: dialogCard; scale: 1.0 }
        }
        
        transitions: [
            Transition { to: "open"
                ParallelAnimation {
                    NumberAnimation { target: passwordDialog; property: "opacity"; duration: 150 }
                    NumberAnimation { target: dialogCard; property: "scale"; duration: 200; easing.type: Easing.OutBack }
                }
            },
            Transition { from: "open"
                ParallelAnimation {
                    NumberAnimation { target: passwordDialog; property: "opacity"; duration: 100 }
                    NumberAnimation { target: dialogCard; property: "scale"; to: 0.9; duration: 100 }
                }
            }
        ]
        
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.5)
            radius: 16
            MouseArea { anchors.fill: parent; onClicked: passwordDialog.close() }
        }
        
        Rectangle {
            id: dialogCard
            anchors.centerIn: parent
            width: 300
            height: dialogColumn.implicitHeight + 40
            radius: 16
            color: cSurface
            scale: 0.9
            border.color: cBorder
            
            ColumnLayout {
                id: dialogColumn
                anchors.fill: parent
                anchors.margins: 20
                spacing: 14
                
                Text {
                    text: "Enter Password"
                    font.family: "Inter"
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    color: cText
                }
                
                Text {
                    text: passwordDialog.networkSSID
                    font.family: "Inter"
                    font.pixelSize: 11
                    color: cSubText
                }

                Text {
                    visible: passwordDialog.errorText.length > 0
                    Layout.fillWidth: true
                    text: passwordDialog.wasSavedAttempt
                        ? `Kayıtlı bağlantı başarısız oldu (şifre değişmiş olabilir): ${passwordDialog.errorText}`
                        : passwordDialog.errorText
                    font.family: "Inter"
                    font.pixelSize: 10
                    color: "#e57373"
                    wrapMode: Text.WordWrap
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    radius: 10
                    color: cSurfaceContainer
                    border.color: passwordInput.activeFocus ? cPrimary : "transparent"
                    border.width: 1
                    
                    QQC.TextField {
                        id: passwordInput
                        anchors.fill: parent
                        anchors.margins: 10
                        placeholderText: "Password"
                        echoMode: QQC.TextField.Password
                        color: cText
                        background: Item {}
                        font.family: "Inter"
                        font.pixelSize: 13
                        
                        onAccepted: {
                            if (text.length > 0) {
                                network.connectToNetwork(passwordDialog.networkSSID, text)
                                passwordDialog.close()
                            }
                        }
                    }
                }
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    
                    Text {
                        visible: passwordDialog.wasSavedAttempt
                        text: "Kayıtlı profili unut"
                        font.family: "Inter"
                        font.pixelSize: 11
                        color: forgetProfileArea.containsMouse ? "#e57373" : cSubText

                        MouseArea {
                            id: forgetProfileArea
                            anchors.fill: parent
                            anchors.margins: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: network.forgetNetwork(passwordDialog.networkSSID)
                        }
                    }

                    Item { Layout.fillWidth: true }
                    
                    Rectangle {
                        width: 70
                        height: 32
                        radius: 16
                        color: cancelBtn.containsMouse ? cHover : "transparent"
                        border.width: 1
                        border.color: Qt.rgba(cText.r, cText.g, cText.b, 0.15)
                        
                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            font.family: "Inter"
                            font.pixelSize: 12
                            color: cText
                        }
                        
                        MouseArea {
                            id: cancelBtn
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: passwordDialog.close()
                        }
                    }
                    
                    Rectangle {
                        width: 80
                        height: 32
                        radius: 16
                        color: passwordInput.text.length > 0 ? cPrimary : Qt.rgba(cPrimary.r, cPrimary.g, cPrimary.b, 0.4)
                        
                        Text {
                            anchors.centerIn: parent
                            text: "Connect"
                            font.family: "Inter"
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: "#ffffff"
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            enabled: passwordInput.text.length > 0
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                network.connectToNetwork(passwordDialog.networkSSID, passwordInput.text)
                                passwordDialog.close()
                            }
                        }
                    }
                }
            }
        }
    }
}
