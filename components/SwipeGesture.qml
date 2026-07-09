// SwipeGesture.qml - Swipe gesture handler for dismissible items
// Material 3 swipe-to-dismiss with velocity-based animation

import QtQuick 6.10
import "effects"

Item {
    id: root
    
    // The target item to make swipeable
    property Item target: parent
    
    // Swipe direction (horizontal or vertical)
    property bool horizontal: true
    
    // Dismiss threshold (percentage of width/height)
    property real dismissThreshold: 0.4
    
    // Velocity threshold for quick swipe dismiss (pixels per second)
    property real velocityThreshold: 500
    
    // Enable/disable swipe
    property bool enabled: true
    
    // Visual feedback
    property bool showDismissIndicator: true
    property color dismissColor: Qt.rgba(1, 0.3, 0.3, 0.3)
    
    // Signals
    signal dismissed(string direction)  // "left", "right", "up", "down"
    signal swiping(real progress)       // -1 to 1
    signal cancelled()
    
    // Internal state
    property real _startX: 0
    property real _startY: 0
    property real _lastX: 0
    property real _lastY: 0
    property real _lastTime: 0
    property real _velocity: 0
    
    anchors.fill: target
    
    MouseArea {
        id: dragArea
        anchors.fill: parent
        enabled: root.enabled
        
        property bool dragging: false
        
        onPressed: event => {
            root._startX = event.x
            root._startY = event.y
            root._lastX = event.x
            root._lastY = event.y
            root._lastTime = Date.now()
            root._velocity = 0
            dragging = false
        }
        
        onPositionChanged: event => {
            const dx = event.x - root._startX
            const dy = event.y - root._startY
            const currentTime = Date.now()
            const dt = Math.max(1, currentTime - root._lastTime) / 1000
            
            if (root.horizontal) {
                // Calculate velocity
                root._velocity = (event.x - root._lastX) / dt
                
                // Start dragging after threshold
                if (Math.abs(dx) > 10) {
                    dragging = true
                    root.target.x = dx
                    
                    const progress = dx / root.target.width
                    root.swiping(Math.max(-1, Math.min(1, progress)))
                }
            } else {
                root._velocity = (event.y - root._lastY) / dt
                
                if (Math.abs(dy) > 10) {
                    dragging = true
                    root.target.y = dy
                    
                    const progress = dy / root.target.height
                    root.swiping(Math.max(-1, Math.min(1, progress)))
                }
            }
            
            root._lastX = event.x
            root._lastY = event.y
            root._lastTime = currentTime
        }
        
        onReleased: {
            if (!dragging) return
            
            const size = root.horizontal ? root.target.width : root.target.height
            const offset = root.horizontal ? root.target.x : root.target.y
            const progress = Math.abs(offset / size)
            const velocity = Math.abs(root._velocity)
            
            // Determine if should dismiss
            const shouldDismiss = progress > root.dismissThreshold || velocity > root.velocityThreshold
            
            if (shouldDismiss) {
                // Animate out and emit dismiss
                const direction = root.horizontal 
                    ? (offset > 0 ? "right" : "left")
                    : (offset > 0 ? "down" : "up")
                
                dismissAnim.targetValue = offset > 0 ? size * 1.2 : -size * 1.2
                dismissAnim.start()
                
                // Emit after animation
                dismissTimer.direction = direction
                dismissTimer.start()
            } else {
                // Animate back to original position
                resetAnim.start()
                root.cancelled()
            }
            
            dragging = false
        }
        
        onCanceled: {
            if (dragging) {
                resetAnim.start()
                root.cancelled()
            }
            dragging = false
        }
    }
    
    // Dismiss animation
    NumberAnimation {
        id: dismissAnim
        target: root.target
        property: root.horizontal ? "x" : "y"
        property real targetValue: 0
        to: targetValue
        duration: Material3Anim.short4
        easing.bezierCurve: Material3Anim.emphasizedAccelerate
    }
    
    // Reset animation
    NumberAnimation {
        id: resetAnim
        target: root.target
        property: root.horizontal ? "x" : "y"
        to: 0
        duration: Material3Anim.medium1
        easing.bezierCurve: Material3Anim.emphasizedDecelerate
    }
    
    // Emit dismissed after animation completes
    Timer {
        id: dismissTimer
        interval: Material3Anim.short4
        property string direction: ""
        onTriggered: {
            root.target.opacity = 0
            root.dismissed(direction)
        }
    }
    
    // Opacity fade during swipe
    Binding {
        target: root.target
        property: "opacity"
        value: {
            if (!dragArea.dragging) return 1
            const size = root.horizontal ? root.target.width : root.target.height
            const offset = root.horizontal ? root.target.x : root.target.y
            return 1 - Math.abs(offset / size) * 0.5
        }
        when: dragArea.dragging
    }
}
