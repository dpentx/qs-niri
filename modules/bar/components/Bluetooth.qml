import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import Quickshell.Bluetooth
import "../../../services" as QsServices

Item {
    id: root
    
    property var barWindow
    property var bluetoothPopup
    
    readonly property var pywal: QsServices.Pywal
    readonly property bool isHovered: mouseArea.containsMouse
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var connectedDevices: Bluetooth.devices.values.filter(d => d.connected)
    readonly property bool hasConnection: connectedDevices.length > 0
    readonly property string displayName: hasConnection ? connectedDevices[0].name : "Bluetooth"
    readonly property bool isEnabled: adapter?.enabled ?? false
    
    implicitWidth: bluetoothRow.implicitWidth
    implicitHeight: bluetoothRow.implicitHeight
    
    // Show/hide popup timers
    Timer {
        id: showTimer
        interval: 300
        onTriggered: {
            console.log("Bluetooth timer triggered - barWindow:", barWindow, "popup:", bluetoothPopup)
            if (!barWindow) {
                console.log("ERROR: barWindow is null/undefined")
                return
            }
            if (!barWindow.screen) {
                console.log("ERROR: barWindow.screen is null/undefined")
                return
            }
            if (!bluetoothPopup) {
                console.log("ERROR: bluetoothPopup is null/undefined")
                return
            }
            
            const pos = root.mapToItem(barWindow.contentItem, 0, 0)
            // Position from right edge to avoid cutoff
            const rightEdge = pos.x + root.width
            const screenWidth = barWindow.screen.width
            bluetoothPopup.margins.right = Math.round(screenWidth - rightEdge)
            bluetoothPopup.margins.top = Math.round(barWindow.height + 6)  // Closer gap
            bluetoothPopup.shouldShow = true
            console.log("Bluetooth popup showing at right:", bluetoothPopup.margins.right, "top:", bluetoothPopup.margins.top)
        }
    }
    
    // Hover detection
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        
        onEntered: {
            console.log("Bluetooth hover entered")
            showTimer.start()
        }
        
        onExited: {
            console.log("Bluetooth hover exited")
            showTimer.stop()
        }
        
        onClicked: {
            if (adapter) {
                adapter.enabled = !adapter.enabled
            }
        }
    }
    
    RowLayout {
        id: bluetoothRow
        anchors.centerIn: parent
        spacing: 6
        
        // Bluetooth icon with state indication
        Text {
            id: bluetoothIcon
            Layout.alignment: Qt.AlignVCenter
            
            text: {
                if (!isEnabled) return "󰂲"  // bluetooth disabled
                if (hasConnection) return "󰂱"  // bluetooth connected
                return "󰂯"  // bluetooth enabled
            }
            
            font.family: "Material Design Icons"
            font.pixelSize: 16
            
            color: {
                if (!isEnabled) return Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.4)
                if (hasConnection) return pywal.color2  // Connected - green
                return pywal.foreground
            }
            
            Behavior on color {
                ColorAnimation { duration: 300; easing.type: Easing.OutCubic }
            }
            
            // Pulse animation when connecting/disconnecting
            SequentialAnimation on scale {
                running: adapter?.discovering ?? false
                loops: Animation.Infinite
                NumberAnimation { to: 1.15; duration: 600; easing.type: Easing.InOutCubic }
                NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutCubic }
            }
        }
        
        // Device name with truncation
        Text {
            id: deviceText
            Layout.alignment: Qt.AlignVCenter
            Layout.maximumWidth: 120  // Maximum width to prevent expansion
            
            text: displayName
            font.family: "Inter"
            font.pixelSize: 12
            font.weight: Font.Medium
            
            color: {
                if (!isEnabled) return Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.4)
                if (hasConnection) return pywal.color2
                return pywal.foreground
            }
            
            elide: Text.ElideRight
            
            Behavior on color {
                ColorAnimation { duration: 300; easing.type: Easing.OutCubic }
            }
            
            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }
        }
        
        // Connection indicator dot
        Rectangle {
            visible: hasConnection
            Layout.alignment: Qt.AlignVCenter
            width: 4
            height: 4
            radius: 2
            color: pywal.color2
            
            opacity: 0
            scale: 0
            
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
            
            // Subtle pulse
            SequentialAnimation on opacity {
                running: hasConnection
                loops: Animation.Infinite
                NumberAnimation { to: 0.6; duration: 1500; easing.type: Easing.InOutCubic }
                NumberAnimation { to: 1.0; duration: 1500; easing.type: Easing.InOutCubic }
            }
        }
    }
}
