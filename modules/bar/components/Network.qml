import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import "../../../services" as QsServices

// Clean Network indicator - No shadows, proper alignment
Item {
    id: root
    
    property var barWindow
    property var networkPopup
    
    readonly property var pywal: QsServices.Pywal
    readonly property var network: QsServices.Network
    readonly property bool isHovered: mouseArea.containsMouse
    readonly property bool isConnected: network.active !== null
    readonly property bool isEnabled: network.wifiEnabled
    readonly property int signalStrength: isConnected ? network.active.strength : 0
    readonly property string networkName: isConnected ? (network.active.ssid ?? "Connected") : ""
    
    implicitWidth: networkRow.implicitWidth
    implicitHeight: 20
    
    RowLayout {
        id: networkRow
        anchors.centerIn: parent
        spacing: 5
        
        // WiFi icon
        Text {
            id: wifiIcon
            Layout.alignment: Qt.AlignVCenter
            
            text: {
                if (!isEnabled) return "󰖪"
                if (!isConnected) return "󰖪"
                if (signalStrength >= 75) return "󰤨"
                if (signalStrength >= 50) return "󰤥"
                if (signalStrength >= 25) return "󰤢"
                return "󰤟"
            }
            
            font.family: "Material Design Icons"
            font.pixelSize: 14
            
            color: {
                if (!isEnabled) return Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.3)
                if (!isConnected) return Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.4)
                if (isHovered) return pywal.primary
                return Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.8)
            }
            
            Behavior on color { ColorAnimation { duration: 150 } }
            
            scale: isHovered ? 1.05 : 1.0
            Behavior on scale { NumberAnimation { duration: 100 } }
        }
        
        // Network name - simple text, no gradient overlay
        Text {
            id: networkText
            Layout.alignment: Qt.AlignVCenter
            Layout.maximumWidth: 70
            
            text: {
                if (!isEnabled) return "Off"
                if (!isConnected) return "No WiFi"
                return networkName
            }
            
            font.family: "Inter"
            font.pixelSize: 10
            font.weight: isConnected ? Font.Medium : Font.Normal
            elide: Text.ElideRight
            
            color: {
                if (!isEnabled || !isConnected) return Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.4)
                if (isHovered) return pywal.foreground
                return Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.75)
            }
            
            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }
    
    // Click handler
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        anchors.margins: -4
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        
        onClicked: {
            if (!networkPopup) return
            
            if (networkPopup.shouldShow) {
                networkPopup.shouldShow = false
            } else {
                if (!barWindow || !barWindow.screen) return
                
                const pos = root.mapToItem(barWindow.contentItem, 0, 0)
                const rightEdge = pos.x + root.width
                const screenWidth = barWindow.screen.width
                
                // Position popup below the bar
                // Bar anchors to screen top, so margins.top = bar_height + gap
                const barHeight = barWindow.implicitHeight || 36
                networkPopup.margins.right = Math.round(screenWidth - rightEdge - 8)
                networkPopup.margins.top = barHeight + 6  // Just below bar with small gap
                networkPopup.shouldShow = true
            }
        }
    }
}
