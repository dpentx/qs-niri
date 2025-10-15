// RippleEffect.qml - Material 3 Touch Ripple Effect
// Smooth ink-like expanding circle on touch/click

import QtQuick

Item {
    id: root
    
    property color rippleColor: Qt.rgba(1, 1, 1, 0.2)
    property int rippleDuration: 400
    property bool centered: false
    
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
                            easing.type: Easing.OutCubic
                        }
                        
                        SequentialAnimation {
                            NumberAnimation {
                                target: circle
                                property: "opacity"
                                from: 0
                                to: 0.5
                                duration: root.rippleDuration * 0.3
                                easing.type: Easing.OutCubic
                            }
                            NumberAnimation {
                                target: circle
                                property: "opacity"
                                to: 0
                                duration: root.rippleDuration * 0.7
                                easing.type: Easing.InCubic
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
