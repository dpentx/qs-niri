pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Controls the volume of a single running application's audio stream
// (i.e. what Windows calls the per-app volume mixer), instead of the
// MPRIS "Volume" property — which most media apps (browsers especially)
// never actually implement, so writing to player.volume silently does
// nothing. This talks to pipewire-pulse via `pactl`, which every desktop
// running PipeWire already ships (pactl is provided by pipewire's pulse
// compatibility layer, no extra package needed).

Singleton {
    id: root

    // Set this to the MPRIS player's `identity` (e.g. "Microsoft Edge",
    // "Firefox", "Spotify") to track that app's stream.
    property string targetIdentity: ""

    property bool ready: false
    property int sinkInputIndex: -1
    property real volume: 0
    property bool muted: false
    readonly property int percentage: Math.round(volume * 100)

    function normalize(s) {
        return (s || "").toLowerCase().replace(/[^a-z0-9]/g, "")
    }

    function refresh() {
        if (!targetIdentity) {
            ready = false
            sinkInputIndex = -1
            return
        }
        listProc.running = true
    }

    function setVolume(ratio) {
        const clamped = Math.min(1, Math.max(0, ratio))
        volume = clamped // optimistic UI update, corrected on next refresh
        if (sinkInputIndex < 0)
            return
        setVolProc.command = ["pactl", "set-sink-input-volume", String(sinkInputIndex), Math.round(clamped * 100) + "%"]
        setVolProc.running = true
    }

    function setMuted(m) {
        muted = m
        if (sinkInputIndex < 0)
            return
        setMuteProc.command = ["pactl", "set-sink-input-mute", String(sinkInputIndex), m ? "1" : "0"]
        setMuteProc.running = true
    }

    // Re-scan periodically while a target is set, since the sink-input
    // index changes whenever the app restarts its audio stream (new tab,
    // track change on some players, etc.)
    Timer {
        interval: 1500
        running: root.targetIdentity !== ""
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process {
        id: listProc
        command: ["pactl", "list", "sink-inputs"]
        stdout: StdioCollector {
            onStreamFinished: {
                const wanted = root.normalize(root.targetIdentity)
                const blocks = text.split(/(?=Sink Input #\d+)/)
                let found = -1
                let foundVolume = 0
                let foundMuted = false

                for (const block of blocks) {
                    const idMatch = block.match(/Sink Input #(\d+)/)
                    if (!idMatch) continue

                    const nameMatch = block.match(/application\.name\s*=\s*"([^"]*)"/)
                    if (!nameMatch) continue

                    const appName = root.normalize(nameMatch[1])
                    if (!appName) continue

                    if (appName.indexOf(wanted) === -1 && wanted.indexOf(appName) === -1)
                        continue

                    const volMatch = block.match(/Volume:.*?(\d+)%/)
                    const muteMatch = block.match(/Mute:\s*(yes|no)/)

                    found = parseInt(idMatch[1])
                    foundVolume = volMatch ? parseInt(volMatch[1]) / 100 : 0
                    foundMuted = muteMatch ? muteMatch[1] === "yes" : false

                    // Prefer a stream that isn't corked (i.e. actually
                    // playing) if there happen to be several from the
                    // same app; otherwise keep the first match found.
                    if (!/Corked:\s*yes/.test(block))
                        break
                }

                root.sinkInputIndex = found
                root.ready = found >= 0
                if (found >= 0) {
                    root.volume = foundVolume
                    root.muted = foundMuted
                }
            }
        }
    }

    Process { id: setVolProc }
    Process { id: setMuteProc }
}
