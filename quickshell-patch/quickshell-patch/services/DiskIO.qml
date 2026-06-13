pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Disk I/O speed tracking (read/write bytes per second, all block devices combined)
Singleton {
    id: root

    property bool active: true

    property real readSpeed: 0   // bytes/sec
    property real writeSpeed: 0  // bytes/sec

    property real lastReadSectors: 0
    property real lastWriteSectors: 0
    property real lastTime: 0

    // Sector size is almost always 512 bytes on Linux block stats
    readonly property int sectorSize: 512

    Timer {
        id: updateTimer
        interval: 2000
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: diskIoProcess.running = true
    }

    // Sum read/write sectors across physical disks (sd*, nvme*, vd*),
    // skip partitions to avoid double counting.
    Process {
        id: diskIoProcess
        command: ["/bin/sh", "-c",
            "awk '$3 ~ /^(sd[a-z]+|nvme[0-9]+n[0-9]+|vd[a-z]+)$/ {r+=$6; w+=$10} END {print r\" \"w}' /proc/diskstats"
        ]
        running: false

        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(/\s+/)
                if (parts.length < 2) return

                const readSectors = parseFloat(parts[0])
                const writeSectors = parseFloat(parts[1])
                const now = Date.now() / 1000

                if (root.lastTime > 0) {
                    const dt = now - root.lastTime
                    if (dt > 0) {
                        root.readSpeed = Math.max(0, (readSectors - root.lastReadSectors) * root.sectorSize / dt)
                        root.writeSpeed = Math.max(0, (writeSectors - root.lastWriteSectors) * root.sectorSize / dt)
                    }
                }

                root.lastReadSectors = readSectors
                root.lastWriteSectors = writeSectors
                root.lastTime = now
            }
        }
    }

    function formatSpeed(bytesPerSec) {
        const mb = bytesPerSec / (1024 * 1024)
        if (mb >= 1) return mb.toFixed(1) + " MB/s"
        const kb = bytesPerSec / 1024
        return kb.toFixed(0) + " KB/s"
    }
}
