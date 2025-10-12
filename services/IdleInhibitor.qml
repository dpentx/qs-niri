pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    
    property bool inhibited: false
    
    onInhibitedChanged: {
        if (inhibited) {
            enableProcess.running = true
        } else {
            disableProcess.running = true
        }
    }
    
    // Enable idle inhibitor
    Process {
        id: enableProcess
        command: ["/bin/sh", "-c", "systemd-inhibit --what=idle --who=QuickShell --why='User requested' sleep infinity &"]
        running: false
    }
    
    // Disable idle inhibitor
    Process {
        id: disableProcess
        command: ["/bin/sh", "-c", "pkill -f 'systemd-inhibit.*QuickShell'"]
        running: false
    }
}
