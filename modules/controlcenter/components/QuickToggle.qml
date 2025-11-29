import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10
import Quickshell
import "../../../components/effects"

Rectangle {
    id: root
    
    property string icon: ""
    property string label: ""
    property string subLabel: ""
    property bool active: false
    property color activeColor: "#a6e3a1"
    property color surfaceColor: Qt.rgba(1, 1, 1, 0.08)
    property color textColor: "#e6e6e6"
    signal clicked()
    
    Layout.fillWidth: true
    Layout.preferredHeight: 64
    
    radius: 32
    
    // Solid colors - no transparency
    color: active ? activeColor : surfaceColor
    
    // Smooth M3 color transition
    Behavior on color {
        ColorAnimation { 
            duration: Material3Anim.medium2
            easing.bezierCurve: Material3Anim.standard
        }
    }
    
    // Press scale animation
    scale: toggleMouse.pressed ? 0.96 : 1.0
    Behavior on scale {
        NumberAnimation {
            duration: Material3Anim.short2
            easing.bezierCurve: Material3Anim.standard
        }
    }
    
    // Hover state overlay
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: root.active 
            ? Qt.rgba(0, 0, 0, 0.08)
            : Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.08)
        opacity: toggleMouse.containsMouse && !toggleMouse.pressed ? 1 : 0
        
        Behavior on opacity {
            NumberAnimation {
                duration: Material3Anim.short3
                easing.bezierCurve: Material3Anim.standard
            }
        }
    }
    
    MouseArea {
        id: toggleMouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: root.clicked()
    }
    
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        spacing: 14
        
        // Icon Circle
        Rectangle {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            radius: 20
            color: active 
                ? Qt.rgba(1, 1, 1, 0.25) 
                : Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.1)
            
            Behavior on color {
                ColorAnimation {
                    duration: Material3Anim.short4
                    easing.bezierCurve: Material3Anim.standard
                }
            }
            
            Text {
                anchors.centerIn: parent
                text: root.icon
                font.family: "Material Design Icons"
                font.pixelSize: 22
                color: active 
                    ? Qt.rgba(0, 0, 0, 0.87)  // Dark on light active bg
                    : root.textColor
                
                Behavior on color {
                    ColorAnimation {
                        duration: Material3Anim.short4
                        easing.bezierCurve: Material3Anim.standard
                    }
                }
            }
        }
        
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            
            Text {
                text: root.label
                font.family: "Inter"
                font.pixelSize: 14
                font.weight: Font.DemiBold
                color: active 
                    ? Qt.rgba(0, 0, 0, 0.87)
                    : root.textColor
                elide: Text.ElideRight
                Layout.fillWidth: true
                
                Behavior on color {
                    ColorAnimation {
                        duration: Material3Anim.short4
                        easing.bezierCurve: Material3Anim.standard
                    }
                }
            }
            
            Text {
                text: root.subLabel
                font.family: "Inter"
                font.pixelSize: 12
                color: active 
                    ? Qt.rgba(0, 0, 0, 0.6)
                    : Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.6)
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text !== ""
                
                Behavior on color {
                    ColorAnimation {
                        duration: Material3Anim.short4
                        easing.bezierCurve: Material3Anim.standard
                    }
                }
            }
        }
    }
}
