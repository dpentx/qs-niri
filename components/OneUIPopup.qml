// OneUIPopup.qml - Reusable animated popup surface.
// Restrained entrance/exit motion in line with One UI's calmer feel:
// no overshoot, a short fade+scale rather than a bounce.

import QtQuick 6.10
import QtQuick.Effects
import "effects"
import "../services" as QsServices

Item {
    id: root
    
    // Pywal colors for theming
    readonly property var pywal: QsServices.Pywal
    
    // Public properties
    property bool show: false
    property int animDuration: OneUIMotion.medium4
    property color surfaceColor: pywal.surfaceContainer
    property color primaryColor: pywal.primary
    property real cornerRadius: 16
    property bool enableShadow: true
    property int elevationLevel: 3  // Uses Elevation component
    
    // Animation progress for external use
    readonly property real animProgress: show ? 1.0 : 0.0
    
    // Content container
    default property alias content: contentItem.children
    
    // Entrance: fade + settle, no overshoot
    SequentialAnimation {
        id: entranceAnim
        running: root.show
        
        ParallelAnimation {
            NumberAnimation {
                target: container
                property: "scale"
                from: 0.94
                to: 1.0
                duration: root.animDuration
                easing.bezierCurve: OneUIMotion.emphasizedDecelerate
            }

            NumberAnimation {
                target: container
                property: "opacity"
                from: 0
                to: 1
                duration: root.animDuration * 0.7
                easing.bezierCurve: OneUIMotion.standardDecelerate
            }
        }
    }
    
    // Exit animation - snappier
    ParallelAnimation {
        id: exitAnim
        running: !root.show && container.opacity > 0
        
        NumberAnimation {
            target: container
            property: "scale"
            to: 0.9
            duration: root.animDuration * 0.5
            easing.bezierCurve: OneUIMotion.emphasizedAccelerate
        }
        
        NumberAnimation {
            target: container
            property: "opacity"
            to: 0
            duration: root.animDuration * 0.5
            easing.bezierCurve: OneUIMotion.emphasizedAccelerate
        }
    }
    
    // Main container
    Item {
        id: container
        anchors.fill: parent
        scale: 0.94
        opacity: 0
        transformOrigin: Item.Center
        
        // Elevation shadow (using new Elevation component)
        Elevation {
            level: root.enableShadow ? root.elevationLevel : 0
            target: surface
            radius: surface.radius
            shadowColor: pywal.shadow
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
