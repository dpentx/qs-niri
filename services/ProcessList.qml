pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Live process list for the task manager, sampled with `top` (its second
// frame is an instantaneous CPU reading, unlike ps's lifetime average).
Singleton {
    id: root

    // Poll only while the task manager is open.
    property bool active: false

    // [{ pid, user, state, cpu (percent of one core), rss (KiB), name }]
    property var processes: []
    property int stamp: 0   // bumps on every fresh sample

    property int cores: 1
    property string me: ""

    // Details for one process (shown when a row is expanded)
    property int detailPid: 0
    property string detailCmd: ""
    property string detailStarted: ""
    property int detailFds: 0
    function inspect(pid) {
        detailPid = pid; detailCmd = ""; detailStarted = ""; detailFds = 0
        inspector.command = ["sh", "-c",
            "p=$1; tr '\\0' ' ' </proc/$p/cmdline 2>/dev/null; echo; ps -o lstart= -p $p 2>/dev/null; ls /proc/$p/fd 2>/dev/null | wc -l",
            "sh", String(pid)]
        inspector.running = true
    }
    Process {
        id: inspector
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.split("\n")
                root.detailCmd = (l[0] ?? "").trim()
                root.detailStarted = (l[1] ?? "").trim()
                root.detailFds = parseInt(l[2]) || 0
            }
        }
    }
    Process {
        command: ["id", "-un"]
        running: true
        stdout: SplitParser { onRead: line => root.me = line.trim() }
    }
    property var _buf: []

    Process {
        command: ["nproc"]
        running: true
        stdout: SplitParser { onRead: line => root.cores = Math.max(1, parseInt(line) || 1) }
    }

    Timer {
        interval: 2500
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!sampler.running) sampler.running = true
    }

    Process {
        id: sampler
        command: ["top", "-b", "-n", "2", "-d", "0.8", "-e", "k", "-w", "256", "-o", "%CPU"]

        stdout: SplitParser {
            onRead: line => {
                if (/^\s*PID\s+USER/.test(line)) { root._buf = []; return }
                const m = line.trim().split(/\s+/)
                // PID USER PR NI VIRT RES SHR S %CPU %MEM TIME+ COMMAND...
                if (m.length < 12 || !/^\d+$/.test(m[0])) return
                root._buf.push({
                    pid: parseInt(m[0]),
                    user: m[1],
                    state: m[7],
                    cpu: parseFloat(m[8].replace(",", ".")) || 0,
                    rss: parseInt(m[5]) || 0,
                    name: m.slice(11).join(" ")
                })
            }
        }

        onExited: {
            if (root._buf.length > 0) {
                root.processes = root._buf
                root.stamp++
            }
        }
    }

    function terminate(pids) { Quickshell.execDetached(["kill", "-TERM"].concat(pids.map(String))) }
    function kill(pids)      { Quickshell.execDetached(["kill", "-KILL"].concat(pids.map(String))) }
}
