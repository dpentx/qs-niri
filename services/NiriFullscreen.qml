pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick 6.10
import "." as QsServices

// Approximates whether the focused window is fullscreen.
//
// niri's IPC does NOT currently expose a per-window "is fullscreen" flag
// (confirmed: https://github.com/niri-wm/niri/discussions/2554 is an open
// feature request for exactly this). So instead, this compares the
// focused window's logical size (`niri msg -j windows` -> `layout.window_size`)
// against each connected output's logical resolution
// (`niri msg -j outputs` -> `logical.width`/`logical.height`). A niri
// fullscreen window exactly fills its output with no gaps/borders, so an
// (near-)exact size match is a reliable stand-in for "is fullscreen".
//
// Field names above are verified against niri's own published IPC types
// (niri-ipc crate / JSR type defs), not guessed.
Singleton {
    id: root

    readonly property bool focusedFullscreen: _fullscreen

    property bool _fullscreen: false
    property var _outputSizes: []  // [[width, height], ...] of all connected outputs

    Process {
        id: outputsProc
        command: ["niri", "msg", "-j", "outputs"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const outputs = JSON.parse(text)
                    const sizes = []
                    for (const name in outputs) {
                        const o = outputs[name]
                        if (o.logical) sizes.push([o.logical.width, o.logical.height])
                    }
                    root._outputSizes = sizes
                } catch (e) {
                    // keep previous list on a bad read
                }
            }
        }
    }

    Process {
        id: windowsProc
        command: ["niri", "msg", "-j", "windows"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const wins = JSON.parse(text)
                    const focused = wins.find(w => w.is_focused)
                    if (!focused || !focused.layout || !focused.layout.window_size) {
                        root._fullscreen = false
                        return
                    }
                    const w = focused.layout.window_size[0]
                    const h = focused.layout.window_size[1]
                    // Small tolerance for fractional-scale rounding
                    let match = false
                    for (const size of root._outputSizes) {
                        if (Math.abs(w - size[0]) <= 2 && Math.abs(h - size[1]) <= 2) {
                            match = true
                            break
                        }
                    }
                    root._fullscreen = match
                    // Temporary — remove once fullscreen auto-hide is confirmed
                    // working. Lets us see in the log whether the size-match
                    // heuristic is actually firing during a real test.
                    QsServices.Logger.debug("NiriFullscreen", `window=${w}x${h} outputs=${JSON.stringify(root._outputSizes)} fullscreen=${match}`)
                } catch (e) {
                    // keep previous state on a bad read
                }
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            outputsProc.running = true
            windowsProc.running = true
        }
    }
}
