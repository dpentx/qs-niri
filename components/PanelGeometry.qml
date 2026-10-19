import QtQuick
import "../config" as QsConfig

// Where a floating panel sits and how big it is. The panel window covers the screen and only the
// panel item takes input (window `mask`), so moving/resizing is just changing x/y/w/h here.
// The geometry is remembered in user.json under panels.<name>; double-click the grabber to reset.
QtObject {
    id: g

    required property var screen
    required property string name
    property real defaultW: 600
    property real defaultH: 500
    property real defaultY: 40
    property real minW: 340
    property real minH: 220

    readonly property var saved: QsConfig.Config.panels?.[name] ?? null
    property var live: null          // set while dragging, written out on commit()
    readonly property var o: live ?? saved

    readonly property real sw: screen?.width ?? 1920
    readonly property real sh: screen?.height ?? 1080
    readonly property real w: Math.max(Math.min(o?.w ?? defaultW, sw), Math.min(minW, sw))
    readonly property real h: Math.max(Math.min(o?.h ?? defaultH, sh), Math.min(minH, sh))
    readonly property real x: Math.max(0, Math.min(o?.x ?? Math.round((sw - w) / 2), sw - w))
    readonly property real y: Math.max(0, Math.min(o?.y ?? defaultY, sh - h))

    function moveTo(nx, ny) { live = { x: nx, y: ny, w: w, h: h } }
    function resizeTo(nw, nh) { live = { x: x, y: y, w: Math.min(nw, sw - x), h: Math.min(nh, sh - y) } }
    function commit() {
        if (!live) return
        QsConfig.Config.set("panels." + name, { x: x, y: y, w: w, h: h })
        live = null
    }
    function reset() {
        live = null
        if (saved) QsConfig.Config.set("panels." + name, null)
    }
}
