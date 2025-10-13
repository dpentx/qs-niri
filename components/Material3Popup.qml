// Material 3 Expressive Popup Component
// Reusable bouncy animated popup with modern Material 3 styling

import QtQuick 6.10
import QtQuick.Effects

Item {
    id: root
    
    // Public properties
    property bool show: false
    property int animDuration: 400
    property real overshoot: 1.7
    property color surfaceColor: Qt.rgba(0.11, 0.11, 0.12, 1.0)
    property color primaryColor: "#a6e3a1"
    property real cornerRadius: 16
    property bool enableShadow: true
    
    // Animation progress for external use
    readonly property real animProgress: show ? 1.0 : 0.0
    
    // Content container
    default property alias content: contentItem.children
    
    // Bouncy entrance animation
    SequentialAnimation {
        id: entranceAnim
        running: root.show
        
        ParallelAnimation {
            NumberAnimation {
                target: container
                property: "scale"
                from: 0.7
                to: 1.05
                duration: root.animDuration * 0.6
                easing.type: Easing.OutCubic
            }
            
            NumberAnimation {
                target: container
                property: "opacity"
                from: 0
                to: 1
                duration: root.animDuration * 0.5
            }
        }
        
        NumberAnimation {
            target: container
            property: "scale"
            from: 1.05
            to: 1.0
            duration: root.animDuration * 0.4
            easing.type: Easing.OutBack
            easing.overshoot: root.overshoot
        }
    }
    
    // Exit animation
    ParallelAnimation {
        id: exitAnim
        running: !root.show && container.opacity > 0
        
        NumberAnimation {
            target: container
            property: "scale"
            to: 0.85
            duration: root.animDuration * 0.6
            easing.type: Easing.InCubic
        }
        
        NumberAnimation {
            target: container
            property: "opacity"
            to: 0
            duration: root.animDuration * 0.6
        }
    }
    
    // Main container
    Item {
        id: container
        anchors.fill: parent
        scale: 0.7
        opacity: 0
        transformOrigin: Item.Center
        
        // Shadow layer
        Rectangle {
            id: shadowRect
            anchors.fill: surface
            anchors.margins: -6
            radius: surface.radius + 3
            color: "transparent"
            visible: root.enableShadow
            
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.35)
                shadowBlur: 0.8
                shadowVerticalOffset: 8
                shadowHorizontalOffset: 0
            }
        }
        
        // Surface
        Rectangle {
            id: surface
            anchors.fill: parent
            color: root.surfaceColor
            radius: root.cornerRadius
            
            // Accent border
            border.width: 1
            border.color: Qt.rgba(
                root.primaryColor.r,
                root.primaryColor.g,
                root.primaryColor.b,
                0.15
            )
            
            // Content container
            Item {
                id: contentItem
                anchors.fill: parent
            }
        }
    }
}
