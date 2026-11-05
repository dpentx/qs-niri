pragma Singleton

import Quickshell
import QtQuick
import "../config" as QsConfig

// Control Center tile customizing (One UI's "Edit" mode): which compact tiles show and in what order.
// Stored in user.json as controlCenter.hidden / controlCenter.order; tiles register their own availability.
Singleton {
    id: root

    readonly property var defaults: ["dnd", "mic", "camera", "caffeine", "screenshot", "record", "hotspot",
                                     "speedtest", "nightlight", "airplane", "vpn", "gaming", "captures", "ocr", "colorpick"]
    readonly property var cfg: QsConfig.Config.data.controlCenter ?? ({})
    readonly property var hidden: cfg.hidden ?? []
    readonly property var order: {
        const o = (cfg.order ?? []).filter(i => defaults.includes(i))
        return [...o, ...defaults.filter(i => !o.includes(i))]
    }

    property bool editMode: false
    property var avail: ({})   // id -> bool, reassigned on change so bindings re-evaluate

    function setAvail(id, v) {
        if (avail[id] === v) return
        const a = Object.assign({}, avail); a[id] = v; avail = a
    }
    function shows(id) { return editMode || !hidden.includes(id) }
    function slot(id) {
        let n = 0
        for (const i of order) {
            if (i === id) return n
            if ((avail[i] ?? true) && shows(i)) n++
        }
        return n
    }
    function toggle(id) {
        QsConfig.Config.set("controlCenter.hidden", hidden.includes(id) ? hidden.filter(x => x !== id) : [...hidden, id])
    }
    // Swap with the next tile that is actually on screen in that direction.
    function move(id, d) {
        const o = [...order]
        let i = o.indexOf(id), j = i + d
        while (j >= 0 && j < o.length && !((avail[o[j]] ?? true) && shows(o[j]))) j += d
        if (j < 0 || j >= o.length) return
        const t = o[i]; o[i] = o[j]; o[j] = t
        QsConfig.Config.set("controlCenter.order", o)
    }
}
