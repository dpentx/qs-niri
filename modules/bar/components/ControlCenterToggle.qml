import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import "../../../services" as QsServices

Item {
    id: root
    
    property var controlCenter
    
    readonly property var pywal: QsServices.Pywal
    readonly property bool isActive: controlCenter?.shouldShow ?? false
    
    implicitWidth: controlCenterIcon.implicitWidth + 16
    implicitHeight: controlCenterIcon.implicitHeight
    
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        
        onClicked: {
            if (controlCenter) {
                controlCenter.shouldShow = !controlCenter.shouldShow
            }
        }
        
        Rectangle {
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            radius: 8
            color: isActive ? 
                   Qt.rgba(pywal.color2.r, pywal.color2.g, pywal.color2.b, 0.15) : 
                   parent.containsMouse ? 
                   Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.05) : 
                   "transparent"
            
            Behavior on color {
                ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
            }
        }
        
        Text {
            id: controlCenterIcon
            anchors.centerIn: parent
            text: "󰒓"
            font.family: "Material Design Icons"
            font.pixelSize: 18
            color: isActive ? pywal.color2 : pywal.foreground
            
            Behavior on color {
                ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
            }
            
            // Subtle rotation animation when active
            rotation: isActive ? 90 : 0
            
            Behavior on rotation {
                NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
            }
        }
    }
}
