pragma Singleton

import Quickshell
import QtQuick
import "../config" as QsConfig
import "reminders.js" as R

// Reminders for the clock window's Agenda (reminders in user.json: [{ id, text, at, fired }]).
// A due one raises a notification, also when the clock window is closed.
Singleton {
    id: root

    readonly property var list: QsConfig.Config.data.reminders ?? []

    function add(text, whenText) {
        const at = R.parseWhen(whenText, Date.now())
        if (!text.trim() || !at) return false
        QsConfig.Config.set("reminders", [...list, { id: String(Date.now()), text: text.trim(), at, fired: false }].sort((a, b) => a.at - b.at))
        return true
    }
    function remove(id) { QsConfig.Config.set("reminders", list.filter(r => r.id !== id)) }

    Timer {
        interval: 15000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const now = Date.now()
            const due = root.list.filter(r => !r.fired && r.at <= now)
            if (!due.length) return
            for (const r of due) Quickshell.execDetached(["notify-send", "-a", "Reminder", "Reminder", r.text])
            // fired ones stay for a day so the agenda still shows what just happened, then go
            QsConfig.Config.set("reminders", root.list.map(r => due.includes(r) ? Object.assign({}, r, { fired: true }) : r)
                .filter(r => !r.fired || r.at > now - 86400000))
        }
    }
}
