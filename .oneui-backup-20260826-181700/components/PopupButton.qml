// Reusable bar button component with popup support
import QtQuick 6.10
import QtQuick.Layouts 6.10
import "../services" as QsServices
import "effects"

Item {
    id: root
    
    // Required properties
    required property string iconText
    required property string labelText
    required property color iconColor
    
    // Optional popup reference
    property var popup: null
    property var barWindow: null
    
    // Disabled state
    property bool disabled: false
    
    // Optional click handler
    signal clicked()
    
    // Appearance
    readonly property var pywal: QsServices.Pywal
    readonly property var logger: QsServices.Logger
    readonly property bool isHovered: mouseArea.containsMouse
    readonly property bool isPressed: mouseArea.pressed
    
    implicitWidth: contentRow.implicitWidth
    implicitHeight: contentRow.implicitHeight
    
    // Show popup timer
    Timer {
        id: showTimer
        interval: Material3Anim.medium2
        onTriggered: {
            if (popup && barWindow) {
                logger.debug("PopupButton", "Showing popup for: " + labelText)
                const pos = root.mapToItem(barWindow.contentItem, 0, 0)
                const rightEdge = pos.x + root.width
                const screenWidth = barWindow.screen.width
                popup.margins.right = Math.round(screenWidth - rightEdge)
                popup.margins.top = Math.round(barWindow.height + 6)
                popup.shouldShow = true
            }
        }
    }
    
    // Hover detection with proper interaction states
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        enabled: !root.disabled
        cursorShape: root.disabled ? undefined : Qt.PointingHandCursor
        
        onEntered: {
            if (popup) {
                showTimer.start()
            }
        }
        
        onExited: {
            showTimer.stop()
        }
        
        onClicked: {
            if (!root.disabled) root.clicked()
        }
    }
    
    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 6
        
        // Scale micro-interaction
        scale: root.isPressed ? Material3Anim.pressedScale : 1.0
        
        Behavior on scale {
            NumberAnimation {
                duration: Material3Anim.short3
                easing.bezierCurve: Material3Anim.springGentle
            }
        }
        
        // Icon
        Text {
            id: icon
            Layout.alignment: Qt.AlignVCenter
            
            text: root.iconText
            font.family: "Material Design Icons"
            font.pixelSize: 16
            color: root.disabled ? Qt.rgba(root.iconColor.r, root.iconColor.g, root.iconColor.b, Material3Anim.disabledOpacity) : root.iconColor
            
            Behavior on color {
                ColorAnimation { 
                    duration: Material3Anim.short4
                    easing.bezierCurve: Material3Anim.standard
                }
            }
        }
        
        // Label (optional, only shown if text is provided)
        Text {
            id: label
            Layout.alignment: Qt.AlignVCenter
            
            visible: root.labelText !== ""
            text: root.labelText
            font.family: "Inter"
            font.pixelSize: 12
            font.weight: Font.Medium
            color: root.disabled ? Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, Material3Anim.disabledOpacity) : pywal.foreground
            
            Behavior on opacity {
                NumberAnimation { 
                    duration: Material3Anim.short4
                    easing.bezierCurve: Material3Anim.standard
                }
            }
        }
    }
    
    // Hover/pressed highlight effect with proper layering
    Rectangle {
        anchors.fill: parent
        anchors.margins: -4
        radius: 6
        color: Qt.rgba(
            pywal.color4.r, 
            pywal.color4.g, 
            pywal.color4.b, 
            root.disabled ? 0 :
                root.isPressed ? Material3Anim.pressedOpacity :
                root.isHovered ? Material3Anim.hoverOpacity : 0
        )
        z: -1
        
        Behavior on color {
            ColorAnimation { 
                duration: Material3Anim.short3
                easing.bezierCurve: Material3Anim.standard
            }
        }
    }
}
