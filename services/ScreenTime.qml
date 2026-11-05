pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "." as QsServices

// Time per app: every 10 s the focused window's app gets 10 s. Kept per day (14 days) in
// ~/.local/state/quickshell-local/screentime.json, saved once a minute.
// shortcut: idle time still counts (no input-idle check), so a window left focused overnight adds up; fine for a rough view.
Singleton {
    id: root

    readonly property string file: Quickshell.env("HOME") + "/.local/state/quickshell-local/screentime.json"
    property var days: ({})              // { "2026-11-05": { "firefox": 3600, ... } }
    property bool loaded: false
    property int rev: 0                  // bumped on every tick so bindings re-read `today`

    function key() { return Qt.formatDate(new Date(), "yyyy-MM-dd") }
    readonly property var today: { rev; return days[key()] ?? ({}) }
    readonly property int totalToday: { rev; return Object.values(today).reduce((a, b) => a + b, 0) }
    // [[appId, seconds], ...] biggest first
    function top(n) { rev; return Object.entries(today).sort((a, b) => b[1] - a[1]).slice(0, n) }
    function fmt(s) { const h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60); return h > 0 ? `${h} h ${m} min` : `${m} min` }

    function tick() {
        if (!loaded) return
        const w = QsServices.Windows.list.find(x => x.focused)
        if (!w || !w.appId) return
        const k = key(), d = days[k] ?? (days[k] = {})
        d[w.appId] = (d[w.appId] ?? 0) + 10
        rev++
    }
    function save() {
        const keep = Object.keys(days).sort().slice(-14), out = {}
        for (const k of keep) out[k] = days[k]
        store.setText(JSON.stringify(out))
    }

    Timer { interval: 10000; running: root.loaded; repeat: true; onTriggered: root.tick() }
    Timer { interval: 60000; running: root.loaded; repeat: true; onTriggered: root.save() }

    FileView {
        id: store
        path: root.file
        onLoaded: { try { root.days = JSON.parse(text()) } catch (e) {} root.loaded = true }
        onLoadFailed: root.loaded = true     // first run: no file yet
    }
    Process { command: ["mkdir", "-p", Quickshell.env("HOME") + "/.local/state/quickshell-local"]; running: true }
}
