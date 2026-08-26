pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick 6.10

// Polls niri for whether the currently-focused window is fullscreen.
// Used to drive the bar's DeX-style auto-hide behavior (see Bar.qml).
//
// Follows the same Process + StdioCollector + Timer polling pattern
// already used by KeyboardLayout.qml elsewhere in this shell, rather
// than a persistent `niri msg event-stream` parser — each poll is
// independent, so a single malformed/partial JSON response just gets
// silently skipped (keeping the previous known state) instead of
// desyncing a long-lived stream parser.
Singleton {
    id: root

    // True when the focused window is fullscreen. False if there's no
    // focused window, niri isn't running, or the query fails.
    readonly property bool focusedFullscreen: _fullscreen

    property bool _fullscreen: false

    Process {
        id: proc
        command: ["niri", "msg", "-j", "windows"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const wins = JSON.parse(text)
                    const focused = wins.find(w => w.is_focused)
                    root._fullscreen = !!(focused && focused.is_fullscreen)
                } catch (e) {
                    // Malformed/partial response — keep the last known
                    // state rather than flicker the bar off a bad read.
                }
            }
        }
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }
}
