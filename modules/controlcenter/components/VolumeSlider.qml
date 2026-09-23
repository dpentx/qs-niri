import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10
import Quickshell
import "../../../components/effects"
import "../../../services" as QsServices

Rectangle {
    id: root
    
    required property var audio
    property var pywal
    
    // Current volume value - use PipeWire audio service
    readonly property int currentVolume: audio.percentage
    readonly property bool isMuted: audio.muted
    
    // Solid color tokens
    readonly property color surfaceColor: pywal ? pywal.surfaceContainerHighest : "#1a1a1a"
    readonly property color textColor: pywal ? pywal.foreground : "#dddddd"
    readonly property color accentColor: pywal ? pywal.primary : "#88cc88"
    
    Layout.fillWidth: true
    Layout.preferredHeight: 54
    
    radius: 20
    color: surfaceColor
    // OneUI panels are flat — no outline stroke (consistent with every
    // other panel in the shell)
    
    Behavior on color {
        ColorAnimation {
            duration: OneUIMotion.medium2
            easing.bezierCurve: OneUIMotion.standard
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0
        
        // Mute Button
        Rectangle {
            id: muteBtn
            Layout.preferredWidth: 52
            Layout.fillHeight: true
            radius: 20
            color: muteMouse.containsMouse 
                ? Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.1) 
                : "transparent"
            
            Behavior on color {
                ColorAnimation {
                    duration: OneUIMotion.short3
                    easing.bezierCurve: OneUIMotion.standard
                }
            }
            
            Text {
                anchors.centerIn: parent
                text: root.isMuted ? "󰆟" : (root.currentVolume > 66 ? "󰅞" : (root.currentVolume > 33 ? "󰅠" : "󰅟"))
                font.family: "Material Design Icons"
                font.pixelSize: 20
                color: root.isMuted ? Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.5) : root.accentColor
                
                Behavior on color {
                    ColorAnimation {
                        duration: OneUIMotion.short3
                        easing.bezierCurve: OneUIMotion.standard
                    }
                }
            }
            
            MouseArea {
                id: muteMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: root.audio.toggleMute()
            }
        }
        
        // Slider
        Slider {
            id: slider
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.rightMargin: 12
            
            from: 0
            to: 100
            value: root.currentVolume
            live: true
            
            onMoved: root.audio.setVolume(value / 100)
            
            background: Rectangle {
                x: slider.leftPadding
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                implicitWidth: 200
                implicitHeight: 30
                width: slider.availableWidth
                height: implicitHeight
                radius: 15
                color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.08)
                
                // Progress fill
                Rectangle {
                    width: slider.visualPosition * parent.width
                    height: parent.height
                    radius: 15
                    color: root.accentColor
                    opacity: 0.34
                    
                    Behavior on width {
                        NumberAnimation {
                            duration: OneUIMotion.short2
                            easing.bezierCurve: OneUIMotion.standard
                        }
                    }
                }

                Rectangle {
                    width: 10
                    height: 10
                    radius: 5
                    x: Math.max(0, Math.min(parent.width - width, slider.visualPosition * parent.width - width / 2))
                    y: (parent.height - height) / 2
                    color: root.accentColor
                    border.width: 2
                    border.color: root.surfaceColor
                }
            }
            
            handle: Rectangle {
                visible: false
            }
        }
        
        // Percentage Text
        Text {
            Layout.rightMargin: 16
            Layout.preferredWidth: 44
            text: root.currentVolume + "%"
            font.family: "OneUI Sans"
            font.pixelSize: 13
            font.weight: Font.DemiBold
            color: root.textColor
            horizontalAlignment: Text.AlignRight
        }
    }
}
