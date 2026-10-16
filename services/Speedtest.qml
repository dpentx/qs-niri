pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Internet speed test against Cloudflare's public endpoints, using only curl:
// latency (fastest of 4 requests), then a download and an upload transfer.
Singleton {
    id: root

    // idle | latency | download | upload | done | error
    property string state: "idle"
    readonly property bool running: state === "latency" || state === "download" || state === "upload"

    property real pingMs: -1
    property real downMbps: -1
    property real upMbps: -1
    property string error: ""
    property real finishedAt: 0

    readonly property string host: "https://speed.cloudflare.com"

    function start() {
        if (running) return
        pingMs = -1; downMbps = -1; upMbps = -1; error = ""
        state = "latency"
        latencyProc.running = true
    }

    function cancel() {
        latencyProc.running = false
        downProc.running = false
        upProc.running = false
        state = "idle"
    }

    function _fail(msg) {
        error = msg
        state = "error"
    }

    Process {
        id: latencyProc
        command: ["sh", "-c",
            'for i in 1 2 3 4; do curl -s -o /dev/null --max-time 5 -w "%{time_starttransfer}\\n" "$0/__down?bytes=0"; done | sort -n | head -n1', root.host]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = parseFloat(text.trim())
                if (!(t > 0)) { root._fail("Network unreachable"); return }
                root.pingMs = t * 1000
                root.state = "download"
                downProc.running = true
            }
        }
    }

    Process {
        id: downProc
        command: ["curl", "-s", "-o", "/dev/null", "--max-time", "12", "-w", "%{speed_download}", root.host + "/__down?bytes=100000000"]
        stdout: StdioCollector {
            onStreamFinished: {
                const bps = parseFloat(text.trim())
                if (!(bps > 0)) { root._fail("Download test failed"); return }
                root.downMbps = bps * 8 / 1e6
                root.state = "upload"
                upProc.running = true
            }
        }
    }

    Process {
        id: upProc
        command: ["sh", "-c",
            'head -c 25000000 /dev/zero | curl -s -o /dev/null --max-time 12 -X POST --data-binary @- -w "%{speed_upload}" "$0/__up"', root.host]
        stdout: StdioCollector {
            onStreamFinished: {
                const bps = parseFloat(text.trim())
                if (!(bps > 0)) { root._fail("Upload test failed"); return }
                root.upMbps = bps * 8 / 1e6
                root.finishedAt = Date.now()
                root.state = "done"
            }
        }
    }
}
