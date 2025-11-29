// IconButton.qml - Material 3 Icon Button with micro-interactions
// Scale squish on press, hover state, focus ring, icon fill animation

import QtQuick 6.10
import "effects"
import "../services" as QsServices

Item {
    id: root
    
    // Icon properties
    property string icon: ""
    property real iconSize: 24
    property string fontFamily: "Material Design Icons"
    
    // Icon fill animation (0 = outlined, 1 = filled)
    // Use with Material Symbols for fill effect
    property real iconFill: 0
    property bool animateIconFill: true
    
    // Colors
    property color iconColor: pywal.foreground
    property color backgroundColor: "transparent"
    property color hoverColor: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, Material3Anim.hoverOpacity)
    property color pressedColor: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, Material3Anim.pressedOpacity)
    property color focusColor: pywal.primary
    
    // State
    property bool disabled: false
    property bool toggled: false
    property bool checkable: false
    
    // Touch target (minimum 44dp for accessibility)
    property real touchTargetSize: Math.max(44, iconSize + 16)
    
    // Signals
    signal clicked()
    signal pressAndHold()
    
    // Pywal colors
    readonly property var pywal: QsServices.Pywal
    
    // Internal state
    readonly property bool isHovered: mouseArea.containsMouse
    readonly property bool isPressed: mouseArea.pressed
    readonly property bool isFocused: activeFocus
    
    implicitWidth: touchTargetSize
    implicitHeight: touchTargetSize
    
    // Enable focus
    focus: true
    Keys.onSpacePressed: if (!disabled) { clicked(); if (checkable) toggled = !toggled }
    Keys.onReturnPressed: if (!disabled) { clicked(); if (checkable) toggled = !toggled }
    
    // Background with hover/pressed states
    Rectangle {
        id: background
        anchors.centerIn: parent
        width: root.touchTargetSize
        height: root.touchTargetSize
        radius: width / 2
        
        color: root.disabled ? "transparent" :
               root.isPressed ? root.pressedColor :
               root.isHovered ? root.hoverColor :
               root.backgroundColor
        
        // Scale micro-interaction
        scale: root.isPressed ? Material3Anim.pressedScale : 1.0
        
        Behavior on color {
            ColorAnimation {
                duration: Material3Anim.short3
                easing.bezierCurve: Material3Anim.standard
            }
        }
        
        Behavior on scale {
            NumberAnimation {
                duration: Material3Anim.short2
                easing.bezierCurve: Material3Anim.springGentle
            }
        }
    }
    
    // Focus ring
    Rectangle {
        anchors.centerIn: parent
        width: root.touchTargetSize + 4
        height: root.touchTargetSize + 4
        radius: width / 2
        color: "transparent"
        border.width: 2
        border.color: root.focusColor
        opacity: root.isFocused && !root.disabled ? 1 : 0
        visible: opacity > 0
        
        Behavior on opacity {
            NumberAnimation {
                duration: Material3Anim.short3
                easing.bezierCurve: Material3Anim.standard
            }
        }
    }
    
    // Icon
    Text {
        id: iconText
        anchors.centerIn: parent
        
        text: root.icon
        font.family: root.fontFamily
        font.pixelSize: root.iconSize
        
        // Font variation for fill (Material Symbols)
        // font.variationSettings: { "FILL": root.iconFill }
        
        color: root.disabled 
            ? Qt.rgba(root.iconColor.r, root.iconColor.g, root.iconColor.b, Material3Anim.disabledOpacity)
            : root.iconColor
        
        // Scale with background
        scale: background.scale
        
        Behavior on color {
            ColorAnimation {
                duration: Material3Anim.short4
                easing.bezierCurve: Material3Anim.standard
            }
        }
    }
    
    // Animated icon fill indicator (for non-variable fonts)
    Rectangle {
        id: fillIndicator
        anchors.centerIn: parent
        width: root.iconSize * root.iconFill
        height: root.iconSize * root.iconFill
        radius: width / 2
        color: root.iconColor
        opacity: root.animateIconFill ? root.iconFill * 0.15 : 0
        scale: background.scale
        
        Behavior on width {
            enabled: root.animateIconFill
            NumberAnimation {
                duration: Material3Anim.medium1
                easing.bezierCurve: Material3Anim.springBounce
            }
        }
        
        Behavior on opacity {
            enabled: root.animateIconFill
            NumberAnimation {
                duration: Material3Anim.short4
            }
        }
    }
    
    // Mouse area
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: !root.disabled
        hoverEnabled: true
        cursorShape: root.disabled ? undefined : Qt.PointingHandCursor
        
        onClicked: {
            if (root.checkable) {
                root.toggled = !root.toggled
            }
            root.clicked()
        }
        
        onPressAndHold: {
            root.pressAndHold()
        }
    }
    
    // Update icon fill when toggled
    onToggledChanged: {
        if (checkable && animateIconFill) {
            iconFill = toggled ? 1 : 0
        }
    }
}
