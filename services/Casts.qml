pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Screen sharing as niri sees it (`niri msg -j casts`, niri 25.11+), polled every few seconds:
// the bar badge shows while a PipeWire cast is running, the Cast panel lists and controls them.
// niri's JSON is read defensively: unknown shapes just show up as "Screen".
Singleton {
    id: root

    // [{ session, target, dynamic, active }]
    property var list: []
    readonly property int count: list.length

    function stop(session)    { Quickshell.execDetached(["niri", "msg", "action", "stop-cast", "--session-id", String(session)]) ; refresh() }
    function shareWindow(id)  { Quickshell.execDetached(id === undefined ? ["niri", "msg", "action", "set-dynamic-cast-window"] : ["niri", "msg", "action", "set-dynamic-cast-window", "--id", String(id)]); refresh() }
    function shareMonitor(n)  { Quickshell.execDetached(n ? ["niri", "msg", "action", "set-dynamic-cast-monitor", n] : ["niri", "msg", "action", "set-dynamic-cast-monitor"]); refresh() }
    function shareNothing()   { Quickshell.execDetached(["niri", "msg", "action", "clear-dynamic-cast-target"]); refresh() }
    function refresh()        { if (!proc.running) proc.running = true }

    function _targetText(t) {
        if (!t || t === "Nothing") return "Nothing"
        if (t.Output) return "Monitor " + (t.Output.name ?? "")
        if (t.Window) return "Window " + (t.Window.id ?? "")
        return "Screen"
    }

    Process {
        id: proc
        command: ["niri", "msg", "-j", "casts"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.list = JSON.parse(text).map(c => ({
                        session: c.session_id,
                        target: root._targetText(c.target),
                        dynamic: !!c.is_dynamic_target,
                        active: c.is_active !== false
                    }))
                } catch (e) { /* keep the last list */ }
            }
        }
    }

    Timer { interval: 3000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
}
