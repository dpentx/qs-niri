// StyledListView.qml - Material 3 Optimized ListView
// With tuned scroll physics, smooth scroll bar, and stagger animations

import QtQuick 6.10
import "effects"

ListView {
    id: root
    
    // Expose scroll bar visibility control
    property bool showScrollBar: true
    property color scrollBarColor: Qt.rgba(1, 1, 1, 0.3)
    property color scrollBarActiveColor: Qt.rgba(1, 1, 1, 0.5)
    
    // Stagger animation control
    property bool enableStaggerAnimation: true
    property int staggerDelay: 30
    
    // Tuned physics for smooth, responsive scrolling
    maximumFlickVelocity: 3000
    flickDeceleration: 1500
    boundsBehavior: Flickable.DragAndOvershootBounds
    boundsMovement: Flickable.FollowBoundsBehavior
    
    // Smooth rebound animation
    rebound: Transition {
        NumberAnimation {
            properties: "x,y"
            duration: Material3Anim.medium2
            easing.bezierCurve: Material3Anim.emphasizedDecelerate
        }
    }
    
    // Staggered entrance animations for list items
    add: Transition {
        id: addTransition
        enabled: root.enableStaggerAnimation
        
        SequentialAnimation {
            // Stagger delay based on item index
            PauseAnimation {
                duration: addTransition.ViewTransition.index * root.staggerDelay
            }
            
            ParallelAnimation {
                NumberAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Material3Anim.short4
                    easing.bezierCurve: Material3Anim.emphasizedDecelerate
                }
                NumberAnimation {
                    property: "y"
                    from: addTransition.ViewTransition.item.y + 20
                    duration: Material3Anim.medium1
                    easing.bezierCurve: Material3Anim.emphasizedDecelerate
                }
            }
        }
    }
    
    // Smooth displacement when items are added/removed
    addDisplaced: Transition {
        enabled: root.enableStaggerAnimation
        
        NumberAnimation {
            properties: "x,y"
            duration: Material3Anim.medium1
            easing.bezierCurve: Material3Anim.standard
        }
    }
    
    // Remove animation
    remove: Transition {
        enabled: root.enableStaggerAnimation
        
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                to: 0
                duration: Material3Anim.short3
                easing.bezierCurve: Material3Anim.emphasizedAccelerate
            }
            NumberAnimation {
                property: "x"
                to: -20
                duration: Material3Anim.short4
                easing.bezierCurve: Material3Anim.emphasizedAccelerate
            }
        }
    }
    
    removeDisplaced: Transition {
        enabled: root.enableStaggerAnimation
        
        NumberAnimation {
            properties: "x,y"
            duration: Material3Anim.medium1
            easing.bezierCurve: Material3Anim.standard
        }
    }
    
    // Move animation
    move: Transition {
        enabled: root.enableStaggerAnimation
        
        NumberAnimation {
            properties: "x,y"
            duration: Material3Anim.medium2
            easing.bezierCurve: Material3Anim.standard
        }
    }
    
    moveDisplaced: Transition {
        enabled: root.enableStaggerAnimation
        
        NumberAnimation {
            properties: "x,y"
            duration: Material3Anim.medium2
            easing.bezierCurve: Material3Anim.standard
        }
    }
    
    // Vertical scroll bar
    Rectangle {
        id: scrollBar
        
        anchors.right: parent.right
        anchors.rightMargin: 2
        
        y: root.visibleArea.yPosition * root.height
        width: 4
        height: Math.max(20, root.visibleArea.heightRatio * root.height)
        radius: 2
        
        visible: root.showScrollBar && root.contentHeight > root.height
        
        color: scrollBarMouseArea.containsMouse || scrollBarMouseArea.pressed 
            ? root.scrollBarActiveColor 
            : root.scrollBarColor
        
        opacity: root.moving || scrollBarMouseArea.containsMouse || fadeTimer.running ? 1 : 0
        
        Behavior on opacity {
            NumberAnimation {
                duration: Material3Anim.short4
                easing.bezierCurve: Material3Anim.standard
            }
        }
        
        Behavior on color {
            ColorAnimation {
                duration: Material3Anim.short3
            }
        }
        
        MouseArea {
            id: scrollBarMouseArea
            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            
            drag.target: scrollBar
            drag.axis: Drag.YAxis
            drag.minimumY: 0
            drag.maximumY: root.height - scrollBar.height
            
            onPositionChanged: {
                if (pressed) {
                    root.contentY = scrollBar.y / root.height * root.contentHeight
                }
            }
        }
    }
    
    // Timer to keep scrollbar visible after scrolling
    Timer {
        id: fadeTimer
        interval: 600
        running: root.moving
        onTriggered: {} // Just keeps scrollbar visible
    }
    
    // Reset fade timer when scrolling starts
    onMovingChanged: {
        if (moving) {
            fadeTimer.restart()
        }
    }
}
