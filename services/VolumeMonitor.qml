pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Monitor volume from /tmp/volume_osd file (workaround for broken PipeWire)
Singleton {
    id: root
    
    property int percentage: 50
    property bool muted: false
    
    // Fast polling for responsive OSD (200ms)
    Timer {
        interval: 200
        repeat: true
        running: true
        triggeredOnStart: true
        
        onTriggered: {
            volumeProc.running = true
        }
    }
    
    Process {
        id: volumeProc
        command: ["cat", "/tmp/volume_osd"]
        
        stdout: StdioCollector {
            onStreamFinished: {
                const vol = parseInt(text.trim()) || 50
                if (vol !== root.percentage) {
                    root.percentage = vol
                }
            }
        }
    }
    
    // Monitor mute state
    Timer {
        interval: 300
        repeat: true
        running: true
        triggeredOnStart: true
        
        onTriggered: {
            muteProc.running = true
        }
    }
    
    Process {
        id: muteProc
        command: ["pamixer", "--get-mute"]
        
        stdout: StdioCollector {
            onStreamFinished: {
                root.muted = text.trim() === "true"
            }
        }
    }
    
    Component.onCompleted: {
        console.log("📊 [VolumeMonitor] Service loaded - monitoring /tmp/volume_osd")
    }
}
