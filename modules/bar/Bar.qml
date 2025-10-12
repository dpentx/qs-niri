import Quickshell
import QtQuick 6.10
import QtQuick.Layouts 6.10
import "components" as BarComponents
import "../../config" as QsConfig
import "../../services" as QsServices

Item {
    id: root
    
    property var screen
    property var barWindow
    property var mediaPopup  // Reference to media popup window
    property var bluetoothPopup  // Reference to bluetooth popup window
    property var networkPopup  // Reference to network popup window
    
    readonly property var config: QsConfig.Config
    readonly property var pywal: QsServices.Pywal
    
    // Minimal, clean background with pywal colors
    Rectangle {
        anchors.fill: parent
        color: pywal.background
        opacity: config.bar.backgroundOpacity
        
        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
    }
    
    // Left section - Workspaces and Media Player
    RowLayout {
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 16
        
        // Minimal Workspaces
        Loader {
            Layout.alignment: Qt.AlignVCenter
            source: "components/Workspaces.qml"
            onStatusChanged: {
                if (status === Loader.Ready) {
                    item.screen = Qt.binding(() => root.screen)
                }
            }
        }
        
        // Media Player
        Loader {
            id: mediaPlayerLoader
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 8
            Layout.minimumWidth: 120
            Layout.preferredWidth: item ? item.implicitWidth : 120
            source: "components/MediaPlayer.qml"
            
            onStatusChanged: {
                if (status === Loader.Ready) {
                    item.barWindow = Qt.binding(() => root.barWindow)
                    item.mediaPopup = Qt.binding(() => root.mediaPopup)
                }
            }
        }
    }
    
    // Center section - Clock (absolutely centered)
    Loader {
        anchors.centerIn: parent
        source: "components/Clock.qml"
    }
    
    // Right section - Network, Bluetooth, Battery
    RowLayout {
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 16
        
        // Network module
        Loader {
            id: networkLoader
            Layout.alignment: Qt.AlignVCenter
            source: "components/Network.qml"
            
            onStatusChanged: {
                if (status === Loader.Ready) {
                    item.barWindow = Qt.binding(() => root.barWindow)
                    item.networkPopup = Qt.binding(() => root.networkPopup)
                }
            }
        }
        
        // Bluetooth module
        Loader {
            id: bluetoothLoader
            Layout.alignment: Qt.AlignVCenter
            source: "components/Bluetooth.qml"
            
            onStatusChanged: {
                if (status === Loader.Ready) {
                    item.barWindow = Qt.binding(() => root.barWindow)
                    item.bluetoothPopup = Qt.binding(() => root.bluetoothPopup)
                }
            }
        }
        
        // Battery module
        Loader {
            Layout.alignment: Qt.AlignVCenter
            source: "components/Battery.qml"
        }
    }
}
