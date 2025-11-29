import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import "../../../services" as QsServices
import "../../../components/effects"

Item {
    id: root
    
    property var controlCenter
    
    readonly property var pywal: QsServices.Pywal
    readonly property bool isActive: controlCenter?.shouldShow ?? false
    readonly property bool isHovered: toggleMouse.containsMouse
    
    implicitWidth: controlCenterIcon.implicitWidth + 8
    implicitHeight: controlCenterIcon.implicitHeight
    
    MouseArea {
        id: toggleMouse
        anchors.fill: parent
        anchors.margins: -4  // Larger hit area
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        
        onClicked: {
            if (controlCenter) {
                controlCenter.shouldShow = !controlCenter.shouldShow
            }
        }
    }
    
    // Modern settings icon with rotation effect
    Text {
        id: controlCenterIcon
        anchors.centerIn: parent
        text: "󰒓"
        font.family: "Material Design Icons"
        font.pixelSize: 18
        
        color: {
            if (isActive) return pywal.primary
            if (isHovered) return pywal.primary
            return pywal.foreground
        }
        
        Behavior on color {
            ColorAnimation { 
                duration: Material3Anim.short3
                easing.bezierCurve: Material3Anim.standard
            }
        }
        
        // Smooth rotation when active
        rotation: isActive ? 90 : 0
        
        Behavior on rotation {
            NumberAnimation { 
                duration: Material3Anim.medium4
                easing.bezierCurve: Material3Anim.emphasizedDecelerate
            }
        }
        
        // Hover/active scale
        scale: {
            if (toggleMouse.pressed) return 0.9
            if (isHovered || isActive) return 1.1
            return 1.0
        }
        
        Behavior on scale {
            NumberAnimation {
                duration: Material3Anim.short2
                easing.bezierCurve: Material3Anim.standard
            }
        }
    }
    
    // Active glow ring
    Rectangle {
        visible: isActive
        anchors.centerIn: parent
        width: controlCenterIcon.implicitWidth + 10
        height: controlCenterIcon.implicitHeight + 10
        radius: 8
        color: "transparent"
        border.width: 1.5
        border.color: Qt.rgba(pywal.primary.r, pywal.primary.g, pywal.primary.b, 0.3)
        
        // Gentle pulse when active
        SequentialAnimation on opacity {
            running: isActive
            loops: Animation.Infinite
            NumberAnimation { to: 0.5; duration: 1000; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0; duration: 1000; easing.type: Easing.InOutSine }
        }
    }
}
