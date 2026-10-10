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
                        if (!root._busy) root.volume = Math.max(0, Math.min(1.5, v))
                    }
                }
                if (!root._busy) root.muted = /\[MUTED\]/.test(s)
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

    // Volume writes are optimistic and coalesced: the UI value moves
    // immediately, only the latest target is sent, and wpctl is never started
    // while a previous call is still running (a Process ignores `running = true`
    // when it is already running, which used to drop fast slider/wheel input).
    // Polled values are ignored while a write is in flight or just settled, so
    // the slider does not snap back to a stale reading.
    property real _pendingVolume: -1
    readonly property bool _busy: _pendingVolume >= 0 || setVolProc.running || settleTimer.running

    function setVolume(newVolume) {
        const v = Math.max(0, Math.min(1.5, newVolume))
        if (muted) setMute(false)
        volume = v
        _pendingVolume = v
        settleTimer.restart()
        if (!setVolProc.running) _flushVolume()
    }

    function _flushVolume() {
        if (_pendingVolume < 0) return
        const v = _pendingVolume
        _pendingVolume = -1
        setVolProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", v.toFixed(3)]
        setVolProc.running = true
    }

    Timer {
        id: settleTimer
        interval: 700
    }

    function increaseVolume() {
        setVolume(volume + 0.05)
    }

    function decreaseVolume() {
        setVolume(volume - 0.05)
    }

    function setMute(m) {
        muted = m
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

    Process {
        id: setVolProc
        onExited: root._flushVolume()
    }
    Process { id: setMuteProc }
    Process { id: setSourceVolProc }
    Process { id: setSourceMuteProc }
}
