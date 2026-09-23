import QtQuick 6.10
import QtQuick.Effects
import "effects"

// State layer (hover/press/focus) with ripple, restrained per One UI
MouseArea {
    id: root

    property bool disabled: false
    property color stateColor: Qt.rgba(1, 1, 1, 1)
    property real radius: parent?.radius ?? 0
    
    // Focus support
    property bool showFocus: activeFocus
    property color focusColor: stateColor
    
    signal clicked()

    anchors.fill: parent
    enabled: !disabled
    cursorShape: disabled ? undefined : Qt.PointingHandCursor
    hoverEnabled: true
    
    // Enable keyboard focus
    focus: true
    Keys.onSpacePressed: if (!disabled) root.clicked()
    Keys.onReturnPressed: if (!disabled) root.clicked()

    onPressed: event => {
        if (disabled) return
        
        rippleAnim.x = event.x
        rippleAnim.y = event.y

        const dist = (ox, oy) => ox * ox + oy * oy
        rippleAnim.radius = Math.sqrt(Math.max(
            dist(event.x, event.y),
            dist(event.x, height - event.y),
            dist(width - event.x, event.y),
            dist(width - event.x, height - event.y)
        ))

        rippleAnim.restart()
    }

    onClicked: () => {
        if (!disabled) root.clicked()
    }

    SequentialAnimation {
        id: rippleAnim

        property real x
        property real y
        property real radius

        PropertyAction {
            target: ripple
            property: "x"
            value: rippleAnim.x
        }
        PropertyAction {
            target: ripple
            property: "y"
            value: rippleAnim.y
        }
        PropertyAction {
            target: ripple
            property: "opacity"
            value: OneUIMotion.pressedOpacity
        }
        NumberAnimation {
            target: ripple
            properties: "width,height"
            from: 0
            to: rippleAnim.radius * 2
            duration: OneUIMotion.medium2
            easing.bezierCurve: OneUIMotion.standardDecelerate
        }
        NumberAnimation {
            target: ripple
            property: "opacity"
            to: 0
            duration: OneUIMotion.short4
            easing.bezierCurve: OneUIMotion.standardAccelerate
        }
    }

    // Hover/press/focus layer
    Rectangle {
        id: hoverLayer
        anchors.fill: parent
        radius: root.radius
        color: Qt.rgba(
            root.stateColor.r,
            root.stateColor.g,
            root.stateColor.b,
            root.disabled ? 0 : 
                root.pressed ? OneUIMotion.pressedOpacity : 
                root.showFocus ? OneUIMotion.focusOpacity :
                root.containsMouse ? OneUIMotion.hoverOpacity : 0
        )
        
        Behavior on color {
            ColorAnimation { 
                duration: OneUIMotion.short4
                easing.bezierCurve: OneUIMotion.standard
            }
        }

        // Ripple effect
        Rectangle {
            id: ripple
            width: 0
            height: 0
            radius: width / 2
            color: root.stateColor
            opacity: 0
            x: 0
            y: 0
            
            transform: Translate {
                x: -ripple.width / 2
                y: -ripple.height / 2
            }
        }
    }
    
    // Focus ring indicator
    Rectangle {
        anchors.fill: parent
        anchors.margins: -2
        radius: root.radius + 2
        color: "transparent"
        border.width: 2
        border.color: root.focusColor
        opacity: root.showFocus && !root.disabled ? 1 : 0
        visible: opacity > 0
        
        Behavior on opacity {
            NumberAnimation {
                duration: OneUIMotion.short3
                easing.bezierCurve: OneUIMotion.standard
            }
        }
    }
}
