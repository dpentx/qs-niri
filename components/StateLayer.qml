import QtQuick 6.10
import QtQuick.Effects

// Material 3 State Layer with ripple effect
MouseArea {
    id: root

    property bool disabled: false
    property color stateColor: Qt.rgba(1, 1, 1, 1)
    property real radius: parent?.radius ?? 0
    
    signal clicked()

    anchors.fill: parent
    enabled: !disabled
    cursorShape: disabled ? undefined : Qt.PointingHandCursor
    hoverEnabled: true

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
            value: 0.12
        }
        NumberAnimation {
            target: ripple
            properties: "width,height"
            from: 0
            to: rippleAnim.radius * 2
            duration: 300
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: ripple
            property: "opacity"
            to: 0
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    // Hover/press layer
    Rectangle {
        id: hoverLayer
        anchors.fill: parent
        radius: root.radius
        color: Qt.rgba(
            root.stateColor.r,
            root.stateColor.g,
            root.stateColor.b,
            root.disabled ? 0 : root.pressed ? 0.12 : root.containsMouse ? 0.08 : 0
        )
        
        Behavior on color {
            ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
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
}
