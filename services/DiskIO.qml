pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property real readSpeed: 0   // bytes per second
    property real writeSpeed: 0  // bytes per second

    property real lastReadBytes: 0
    property real lastWriteBytes: 0
    property real lastTime: 0

    property bool active: true

    Component.onCompleted: poll()

    function poll() {
        diskProc.running = true
    }

    Process {
        id: diskProc
        command: ["/bin/sh", "-c",
            "awk '/^[a-z]/ && !/^loop/ {r+=$3*512; w+=$7*512} END {print r\" \"w}' /proc/diskstats"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(/\s+/)
                if (parts.length < 2) return
                const r = parseFloat(parts[0])
                const w = parseFloat(parts[1])
                const now = Date.now() / 1000

                if (root.lastTime > 0) {
                    const dt = now - root.lastTime
                    if (dt > 0) {
                        root.readSpeed  = (r - root.lastReadBytes)  / dt
                        root.writeSpeed = (w - root.lastWriteBytes) / dt
                    }
                }
                root.lastReadBytes  = r
                root.lastWriteBytes = w
                root.lastTime = now
            }
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: root.poll()
    }
}
