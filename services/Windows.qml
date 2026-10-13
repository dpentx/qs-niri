pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Open windows from niri (`niri msg -j windows`), refreshed whenever the
// event stream reports a window change.
Singleton {
    id: root

    // [{ id, title, appId, focused, workspaceId }]
    property var list: []

    function focus(id)  { Quickshell.execDetached(["niri", "msg", "action", "focus-window", "--id", String(id)]) }
    function close(id)  { Quickshell.execDetached(["niri", "msg", "action", "close-window", "--id", String(id)]) }

    Process {
        id: windowsProc
        command: ["niri", "msg", "-j", "windows"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const wins = JSON.parse(text)
                    root.list = wins
                        .map(w => ({
                            id: w.id,
                            title: w.title ?? "",
                            appId: w.app_id ?? "",
                            focused: !!w.is_focused,
                            workspaceId: w.workspace_id ?? 0
                        }))
                        .sort((a, b) => a.workspaceId - b.workspaceId || a.id - b.id)
                } catch (e) {
                    // keep the previous list on a bad read
                }
            }
        }
    }

    Timer {
        id: refresh
        interval: 150
        onTriggered: if (!windowsProc.running) windowsProc.running = true
    }

    Process {
        id: events
        command: ["niri", "msg", "-j", "event-stream"]
        running: true
        stdout: SplitParser {
            onRead: line => { if (line.includes("Window")) refresh.restart() }
        }
        onExited: restartTimer.start()
    }

    Timer { id: restartTimer; interval: 2000; onTriggered: events.running = true }

    Component.onCompleted: windowsProc.running = true
}
