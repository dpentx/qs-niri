pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    
    property bool enabled: false
    property bool dndEnabled: false
    
    // Performance settings
    readonly property string performanceGovernor: "performance"
    readonly property string balancedGovernor: "schedutil"
    
    onEnabledChanged: {
        console.log("🎮 [GamingMode] Gaming mode", enabled ? "ENABLED" : "DISABLED")
        
        if (enabled) {
            // Save current DND state
            dndEnabled = notifs?.dnd ?? false
            
            // Enable performance mode
            setCpuGovernor(performanceGovernor)
            
            // Enable DND
            if (notifs) {
                notifs.dnd = true
            }
            
            // Boost brightness (optional - can be customized)
            if (brightness && brightness.screen < 0.8) {
                brightness.screen = 1.0
            }
        } else {
            // Restore balanced mode
            setCpuGovernor(balancedGovernor)
            
            // Restore DND state
            if (notifs) {
                notifs.dnd = dndEnabled
            }
        }
    }
    
    function toggle() {
        enabled = !enabled
    }
    
    function setCpuGovernor(governor) {
        console.log("🎮 [GamingMode] Setting CPU governor to:", governor)
        cpuGovernorProc.exec([
            "sh", "-c",
            `echo ${governor} | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor`
        ])
    }
    
    // Process to set CPU governor (requires passwordless sudo for cpufreq)
    Process {
        id: cpuGovernorProc
        
        stdout: StdioCollector {
            onStreamFinished: {
                console.log("🎮 [GamingMode] CPU governor output:", text.trim())
            }
        }
        
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0) {
                    console.log("🎮 [GamingMode] CPU governor error:", text.trim())
                    console.log("💡 Tip: For passwordless CPU governor, add to /etc/sudoers.d/cpufreq:")
                    console.log("    %wheel ALL=(ALL) NOPASSWD: /usr/bin/tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor")
                }
            }
        }
    }
    
    // Check current CPU governor on startup
    Component.onCompleted: {
        checkGovernorProc.running = true
    }
    
    Process {
        id: checkGovernorProc
        command: ["cat", "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"]
        running: false
        
        stdout: StdioCollector {
            onStreamFinished: {
                const currentGovernor = text.trim()
                console.log("🎮 [GamingMode] Current CPU governor:", currentGovernor)
                // Auto-detect if gaming mode was already enabled
                if (currentGovernor === performanceGovernor) {
                    enabled = true
                }
            }
        }
    }
    
    // Reference to services (will be set by Control Center)
    property var notifs: null
    property var brightness: null
}
