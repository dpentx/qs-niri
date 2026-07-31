pragma Singleton

import QtQuick 6.10
import Quickshell
import Quickshell.Io
import "." as QsServices

// Power Profiles Service (power-profiles-daemon)
// Disabled by default per user request; this file is preserved for easy re-enabling.
Singleton {
    id: root

    // Disabled mode: this avoids running systemctl/powerprofilesctl automatically.
    // Set enabled = true if you want to re-enable this service.
    property bool enabled: false

    property string activeProfile: "balanced"  // performance, balanced, power-saver
    property var availableProfiles: ["performance", "balanced", "power-saver"]
    property bool isAvailable: false

    Component.onCompleted: {
        QsServices.Logger.info("PowerProfiles", "Service loaded (disabled). Set enabled=true to re-enable.")
    }

    function checkAvailability() {
        if (!enabled) return
        checkProc.running = true
    }

    Process {
        id: checkProc
        command: ["which", "powerprofilesctl"]
        onExited: code => {
            root.isAvailable = code === 0
            if (root.isAvailable) {
                QsServices.Logger.debug("PowerProfiles", "Service available")
                root.updateActiveProfile()
            }
        }
    }

    function updateActiveProfile() {
        if (!enabled || !isAvailable) return
        getProc.running = true
    }

    Process {
        id: getProc
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.activeProfile = text.trim()
                QsServices.Logger.info("PowerProfiles", `Active profile: ${root.activeProfile}`)
            }
        }
    }

    function setProfile(profile: string) {
        if (!enabled) return
        if (!availableProfiles.includes(profile)) return
        setProc.exec(["powerprofilesctl", "set", profile])
    }

    Process {
        id: setProc
        onExited: code => {
            if (code === 0) {
                root.updateActiveProfile()
            }
        }
    }

    function getProfileIcon(profile: string): string {
        switch(profile) {
            case "performance": return "󰓅"
            case "balanced": return "󰾅"
            case "power-saver": return "󰂎"
            default: return "󰚥"
        }
    }

    function getProfileLabel(profile: string): string {
        switch(profile) {
            case "performance": return "Performance"
            case "balanced": return "Balanced"
            case "power-saver": return "Power Saver"
            default: return profile
        }
    }

    // Auto-update timer disabled unless enabled is true
    Timer {
        interval: 5000
        running: enabled && root.isAvailable
        repeat: true
        onTriggered: root.updateActiveProfile()
    }
}
