// RippleEffect.qml - Material 3 Touch Ripple Effect
// Smooth ink-like expanding circle on touch/click

import QtQuick

Item {
    id: root
    
    property color rippleColor: Qt.rgba(1, 1, 1, 0.2)
    property int rippleDuration: Material3Anim.medium4
    property bool centered: false
    
    // Clip to parent bounds
    clip: true
    
    signal triggered(real x, real y)
    
    // Trigger ripple at click point
    function trigger(mouseX, mouseY) {
        const ripple = rippleComponent.createObject(root, {
            "startX": centered ? width / 2 : mouseX,
            "startY": centered ? height / 2 : mouseY
        })
        ripple.start()
    }
    
    // Trigger ripple from center
    function triggerCentered() {
        trigger(width / 2, height / 2)
    }
    
    Component {
        id: rippleComponent
        
        Item {
            id: ripple
            anchors.fill: parent
            
            property real startX: 0
            property real startY: 0
            property real maxRadius: Math.sqrt(parent.width * parent.width + parent.height * parent.height)
            
            Rectangle {
                id: circle
                x: ripple.startX - radius
                y: ripple.startY - radius
                width: radius * 2
                height: radius * 2
                radius: 0
                color: root.rippleColor
                opacity: 0
                
                SequentialAnimation {
                    id: animation
                    
                    ParallelAnimation {
                        NumberAnimation {
                            target: circle
                            property: "radius"
                            from: 0
                            to: ripple.maxRadius
                            duration: root.rippleDuration
                            easing.bezierCurve: Material3Anim.standardDecelerate
                        }
                        
                        SequentialAnimation {
                            NumberAnimation {
                                target: circle
                                property: "opacity"
                                from: 0
                                to: Material3Anim.pressedOpacity + 0.04
                                duration: root.rippleDuration * 0.3
                                easing.bezierCurve: Material3Anim.standardDecelerate
                            }
                            NumberAnimation {
                                target: circle
                                property: "opacity"
                                to: 0
                                duration: root.rippleDuration * 0.7
                                easing.bezierCurve: Material3Anim.standardAccelerate
                            }
                        }
                    }
                    
                    ScriptAction {
                        script: ripple.destroy()
                    }
                }
            }
            
            function start() {
                animation.start()
            }
        }
    }
}
