import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Io
import "../../services" as QsServices
import "../../config" as QsConfig
import "../../components/effects"

PanelWindow {
    id: root
    
    required property var pywal
    property bool showing: false
    
    // Direct brightness reading with faster polling
    property int currentBrightness: 50
    property int prevBrightness: -1
    
    readonly property string backlightPath: "/sys/class/backlight/amdgpu_bl1/brightness"
    readonly property string maxBrightnessPath: "/sys/class/backlight/amdgpu_bl1/max_brightness"
    property int maxValue: 255
    
    readonly property var appearance: QsConfig.AppearanceConfig
    
    visible: showing
    
    // Top-right overlay position, below volume OSD
    anchors {
        top: true
        right: true
    }
    
    margins {
        top: 75
        right: 12
    }
    
    implicitWidth: 250
    implicitHeight: 45
    color: "transparent"
    
    mask: Region { item: container }
    
    Timer {
        id: hideTimer
        interval: 2000
        onTriggered: root.showing = false
    }
    
    // Fast polling for responsive OSD (100ms when showing, 300ms otherwise)
    Timer {
        id: pollTimer
        interval: root.showing ? 50 : 200
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: brightnessProc.running = true
    }
    
    // Read max brightness once at start
    Component.onCompleted: {
        maxBrightnessProc.running = true
    }
    
    Process {
        id: maxBrightnessProc
        command: ["/bin/cat", maxBrightnessPath]
        
        stdout: SplitParser {
            onRead: data => {
                const value = parseInt(data.trim())
                if (!isNaN(value) && value > 0) {
                    root.maxValue = value
                }
            }
        }
    }
    
    Process {
        id: brightnessProc
        command: ["/bin/cat", backlightPath]
        
        stdout: SplitParser {
            onRead: data => {
                const value = parseInt(data.trim())
                if (!isNaN(value) && root.maxValue > 0) {
                    const pct = Math.round((value / root.maxValue) * 100)
                    if (pct !== root.currentBrightness) {
                        root.currentBrightness = pct
                    }
                }
            }
        }
    }
    
    // Detect changes and show OSD
    onCurrentBrightnessChanged: {
        if (prevBrightness !== -1 && currentBrightness !== prevBrightness) {
            show()
        }
        prevBrightness = currentBrightness
    }
    
    function show() {
        showing = true
        hideTimer.restart()
    }
    
    Rectangle {
        id: container
        anchors.fill: parent
        radius: 16
        
        color: Qt.rgba(
            pywal?.background?.r ?? 0.1, 
            pywal?.background?.g ?? 0.1, 
            pywal?.background?.b ?? 0.1, 
            0.95
        )
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.1)
        
        opacity: root.showing ? 1.0 : 0.0
        scale: root.showing ? 1.0 : 0.9
        transformOrigin: Item.Center
        
        Behavior on opacity {
            NumberAnimation { 
                duration: Material3Anim.short4
                easing.bezierCurve: root.showing ? Material3Anim.emphasizedDecelerate : Material3Anim.emphasizedAccelerate
            }
        }
        
        Behavior on scale {
            NumberAnimation { 
                duration: Material3Anim.short4
                easing.bezierCurve: root.showing ? Material3Anim.emphasizedDecelerate : Material3Anim.emphasizedAccelerate
            }
        }
        
        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12
            
            // Icon - Material Design Icons
            Text {
                text: root.currentBrightness > 66 ? "󰃠" : (root.currentBrightness > 33 ? "󰃟" : "󰃞")
                font.family: "Material Design Icons"
                color: pywal.primary
                font.pixelSize: 20
            }
            
            // Bar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 6
                radius: 3
                color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.15)
                
                Rectangle {
                    width: parent.width * (root.currentBrightness / 100)
                    height: parent.height
                    radius: 3
                    color: pywal.primary
                    
                    Behavior on width {
                        NumberAnimation { 
                            duration: 100
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
            
            // Text
            Text {
                text: root.currentBrightness + "%"
                color: pywal.foreground
                font.family: "Inter"
                font.pixelSize: 13
                font.weight: Font.DemiBold
                Layout.preferredWidth: 36
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}