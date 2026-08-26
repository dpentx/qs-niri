pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool ready: false
    property bool muted: false
    property real volume: 0
    readonly property int percentage: Math.round(volume * 100)

    property bool sourceReady: false
    property bool sourceMuted: false
    property real sourceVolume: 0
    readonly property int sourcePercentage: Math.round(sourceVolume * 100)

    // Available audio output devices (sinks) — for the "Media output"
    // device switcher (mirrors OneUI's quick-panel output picker).
    // Each entry: { id, name, isDefault }
    property var sinks: []

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            if (!getSink.running)
                getSink.running = true
            if (!getSource.running)
                getSource.running = true
        }
    }

    // Sink list changes rarely (only when devices connect/disconnect) —
    // polled less often than volume to keep this cheap.
    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!listSinks.running)
                listSinks.running = true
        }
    }

    Process {
        id: listSinks
        command: ["wpctl", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                // `wpctl status` prints several sections; we only want the
                // lines between "Sinks:" and the next section header.
                // Each sink line looks like:
                //   " │  *   50. Built-in Audio Analog Stereo    [vol: 0.40]"
                //   " │      65. WH-1000XM4                      [vol: 0.80]"
                const lines = text.split("\n")
                let inSinks = false
                const found = []
                for (const line of lines) {
                    if (/Sinks:/.test(line)) { inSinks = true; continue }
                    if (inSinks && /^\s*(├─|└─)?\s*(Sources|Filters|Streams):/.test(line)) break
                    if (!inSinks) continue
                    const m = line.match(/(\*)?\s*(\d+)\.\s+(.+?)\s+\[vol:/)
                    if (m) {
                        found.push({
                            id: m[2],
                            name: m[3].trim(),
                            isDefault: m[1] === "*"
                        })
                    }
                }
                if (found.length > 0)
                    root.sinks = found
            }
        }
    }

    Process {
        id: getSink
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                const s = text.trim()
                // Examples:
                // "Volume: 0.39"
                // "Volume: 0.39 [MUTED]"
                const m = s.match(/Volume:\s*([0-9.]+)/)
                if (m) {
                    const v = parseFloat(m[1])
                    if (!isNaN(v)) {
                        root.ready = true
                        root.volume = Math.max(0, Math.min(1.5, v))
                    }
                }
                root.muted = /\[MUTED\]/.test(s)
            }
        }
    }

    Process {
        id: getSource
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
        stdout: StdioCollector {
            onStreamFinished: {
                const s = text.trim()
                const m = s.match(/Volume:\s*([0-9.]+)/)
                if (m) {
                    const v = parseFloat(m[1])
                    if (!isNaN(v)) {
                        root.sourceReady = true
                        root.sourceVolume = Math.max(0, Math.min(1.5, v))
                    }
                }
                root.sourceMuted = /\[MUTED\]/.test(s)
            }
        }
    }

    function setVolume(newVolume) {
        setMute(false)
        setVolProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", Math.max(0, Math.min(1.5, newVolume)).toFixed(3)]
        setVolProc.running = true
    }

    function increaseVolume() {
        setVolume(volume + 0.05)
    }

    function decreaseVolume() {
        setVolume(volume - 0.05)
    }

    function setMute(m) {
        setMuteProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", m ? "1" : "0"]
        setMuteProc.running = true
    }

    function toggleMute() {
        setMuteProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
        setMuteProc.running = true
    }

    function setSourceVolume(newVolume) {
        setSourceMute(false)
        setSourceVolProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", Math.max(0, Math.min(1.5, newVolume)).toFixed(3)]
        setSourceVolProc.running = true
    }

    function setSourceMute(m) {
        setSourceMuteProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", m ? "1" : "0"]
        setSourceMuteProc.running = true
    }

    function toggleSourceMute() {
        setSourceMuteProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]
        setSourceMuteProc.running = true
    }

    function setDefaultSink(id) {
        setDefaultSinkProc.command = ["wpctl", "set-default", String(id)]
        setDefaultSinkProc.running = true
        // Refresh sink list + volume shortly after switching so the UI
        // reflects the new default without waiting for the next poll tick.
        refreshAfterSwitch.restart()
    }

    Timer {
        id: refreshAfterSwitch
        interval: 300
        onTriggered: {
            listSinks.running = true
            getSink.running = true
        }
    }

    Process { id: setDefaultSinkProc }

    Process { id: setVolProc }
    Process { id: setMuteProc }
    Process { id: setSourceVolProc }
    Process { id: setSourceMuteProc }
}
