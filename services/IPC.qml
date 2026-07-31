pragma Singleton

import QtQuick 6.10
import Quickshell
import Quickshell.Io
import "." as QsServices

Singleton {
    id: root

    // path to IPC command file
    property string ipcDir: Quickshell.env("HOME") + "/.config/quickshell/ipc"
    property string ipcFile: ipcDir + "/cmd"
    property int pollIntervalMs: 200

    Component.onCompleted: {
        // Ensure directory and file exist with secure perms
        var cmd = "mkdir -p '" + root.ipcDir + "' && touch '" + root.ipcFile + "' && chmod 600 '" + root.ipcFile + "'"
        ensureProc.exec(["/bin/sh", "-c", cmd])
        QsServices.Logger && QsServices.Logger.info && QsServices.Logger.info("IPC", "IPC service started; monitoring: " + root.ipcFile)
        pollTimer.running = true
    }

    Timer {
        id: pollTimer
        interval: root.pollIntervalMs
        running: false
        repeat: true
        onTriggered: readProc.exec(["/bin/sh", "-c", "if [ -f '" + root.ipcFile + "' ]; then cat '" + root.ipcFile + "'; fi"])
    }

    Process { id: ensureProc }

    Process {
        id: readProc
        stdout: StdioCollector {
            onStreamFinished: {
                var cmd = text.trim()
                if (!cmd) return
                QsServices.Logger && QsServices.Logger.info && QsServices.Logger.info("IPC", "Command received: " + cmd)
                handleCommand(cmd)
                truncateProc.exec(["/bin/sh", "-c", "printf '' > '" + root.ipcFile + "'"])
            }
        }
    }

    Process { id: truncateProc }

    function handleCommand(cmd) {
        switch (cmd) {
            case "open-launcher":
                QsServices.UIState.launcherOpen = true
                break
            case "close-launcher":
                QsServices.UIState.launcherOpen = false
                break
            case "toggle-launcher":
                QsServices.UIState.launcherOpen = !QsServices.UIState.launcherOpen
                break
            default:
                QsServices.Logger && QsServices.Logger.warn && QsServices.Logger.warn("IPC", "Unknown command: " + cmd)
        }
    }
}
