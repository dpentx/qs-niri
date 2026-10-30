import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import Quickshell.Io
import "../../services" as QsServices
import "../../components"
import "../../config" as QsConfig

// Screenshot editor: a real window that opens on Screenshot.editPath. Pen, arrow, box, hide (solid
// block) and crop; Save writes <name>-edited.png next to the original, Copy puts it on the clipboard.
FloatingWindow {
    id: root

    readonly property var pywal: QsServices.Pywal
    readonly property string path: QsServices.Screenshot.editPath
    property string tool: "arrow"
    property color ink: "#ff3b30"
    property var shapes: []              // [{ t, c, pts: [{x,y}...] }] in image pixels
    property var crop: null              // { x, y, w, h } in image pixels
    property var drag: null

    title: "Screenshot editor"
    implicitWidth: 1000
    implicitHeight: 720
    minimumSize: Qt.size(640, 420)
    color: pywal.surfaceContainerHighest
    visible: path !== ""
    onVisibleChanged: if (!visible) QsServices.Screenshot.editPath = ""
    onPathChanged: { shapes = []; crop = null; drag = null }

    function close() { QsServices.Screenshot.editPath = "" }
    function undo() { if (shapes.length) shapes = shapes.slice(0, -1); else crop = null }
    function outPath() { return path.replace(/\.png$/, "") + "-edited.png" }
    function render(done) {
        cropper.grabToImage(r => { r.saveToFile(outPath()); done() }, Qt.size(view.cw, view.ch))
    }

    Process { id: copyProc }

    component Tool: Rectangle {
        property string label
        property bool active: false
        signal clicked()
        implicitWidth: lt.implicitWidth + 24; implicitHeight: 34; radius: 17
        color: active ? root.pywal.primary : root.pywal.surfaceContainerHigh
        Text { id: lt; anchors.centerIn: parent; text: parent.label; font.family: "OneUI Sans"; font.pixelSize: 12
               color: parent.active ? root.pywal.onPrimary : root.pywal.foreground }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: parent.clicked() }
    }

    Keys.onEscapePressed: close()
    Keys.onPressed: e => { if (e.key === Qt.Key_Z && (e.modifiers & Qt.ControlModifier)) { undo(); e.accepted = true } }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: [["pen", "Pen"], ["arrow", "Arrow"], ["box", "Box"], ["hide", "Hide"], ["crop", "Crop"]]
                Tool { required property var modelData; label: modelData[1]; active: root.tool === modelData[0]; onClicked: root.tool = modelData[0] }
            }
            Repeater {
                model: ["#ff3b30", "#ffcc00", "#34c759", "#0a84ff", "#ffffff"]
                Rectangle {
                    required property string modelData
                    implicitWidth: 26; implicitHeight: 26; radius: 13; color: modelData
                    border.width: root.ink === modelData ? 3 : 1; border.color: root.ink === modelData ? root.pywal.primary : root.pywal.divider
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.ink = parent.modelData }
                }
            }
            Item { Layout.fillWidth: true }
            Tool { label: "Undo"; onClicked: root.undo() }
            Tool { label: "Save"; onClicked: root.render(() => Quickshell.execDetached(["notify-send", "-i", root.outPath(), "Screenshot saved", root.outPath()])) }
            Tool { label: "Copy"; active: true; onClicked: root.render(() => copyProc.exec(["sh", "-c", "wl-copy < \"" + root.outPath() + "\""])) }
            Tool { label: "Close"; onClicked: root.close() }
        }

        // The image is shown at its own size inside `stage` and scaled as a whole to fit the window.
        Item {
            id: view
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            Image { id: probe; visible: false; source: root.path ? "file://" + root.path : ""; cache: false; asynchronous: true }
            readonly property real cw: root.crop ? root.crop.w : probe.implicitWidth
            readonly property real ch: root.crop ? root.crop.h : probe.implicitHeight
            readonly property real fit: cw > 0 ? Math.min(width / cw, height / ch, 1) : 1

            Item {
                id: holder
                width: view.cw * view.fit; height: view.ch * view.fit
                anchors.centerIn: parent

                Item {
                    id: cropper
                    width: view.cw; height: view.ch
                    clip: true
                    scale: view.fit
                    transformOrigin: Item.TopLeft

                    Item {
                        id: stage
                        x: root.crop ? -root.crop.x : 0
                        y: root.crop ? -root.crop.y : 0
                        width: probe.implicitWidth; height: probe.implicitHeight

                        Image { anchors.fill: parent; source: probe.source; cache: false }
                        Canvas {
                            id: canvas
                            anchors.fill: parent
                            property var live: root.drag
                            onLiveChanged: requestPaint()
                            Connections { target: root; function onShapesChanged() { canvas.requestPaint() } }
                            function draw(ctx, s) {
                                const a = s.pts[0], b = s.pts[s.pts.length - 1]
                                ctx.strokeStyle = s.c; ctx.fillStyle = s.t === "hide" ? "#000000" : s.c
                                ctx.lineWidth = 5; ctx.lineCap = "round"; ctx.lineJoin = "round"
                                ctx.beginPath()
                                if (s.t === "pen") { ctx.moveTo(a.x, a.y); for (const p of s.pts) ctx.lineTo(p.x, p.y); ctx.stroke() }
                                else if (s.t === "box") ctx.strokeRect(a.x, a.y, b.x - a.x, b.y - a.y)
                                else if (s.t === "hide") ctx.fillRect(a.x, a.y, b.x - a.x, b.y - a.y)
                                else if (s.t === "arrow") {
                                    const ang = Math.atan2(b.y - a.y, b.x - a.x), h = 26
                                    ctx.moveTo(a.x, a.y); ctx.lineTo(b.x, b.y); ctx.stroke()
                                    ctx.beginPath(); ctx.moveTo(b.x, b.y)
                                    ctx.lineTo(b.x - h * Math.cos(ang - 0.45), b.y - h * Math.sin(ang - 0.45))
                                    ctx.lineTo(b.x - h * Math.cos(ang + 0.45), b.y - h * Math.sin(ang + 0.45))
                                    ctx.closePath(); ctx.fill()
                                }
                            }
                            onPaint: {
                                const ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)
                                for (const s of root.shapes) draw(ctx, s)
                                if (root.drag && root.drag.t !== "crop") draw(ctx, root.drag)
                            }
                        }
                        // crop preview while dragging
                        Rectangle {
                            visible: root.drag?.t === "crop"
                            x: root.drag ? Math.min(root.drag.pts[0].x, root.drag.pts[root.drag.pts.length - 1].x) : 0
                            y: root.drag ? Math.min(root.drag.pts[0].y, root.drag.pts[root.drag.pts.length - 1].y) : 0
                            width: root.drag ? Math.abs(root.drag.pts[root.drag.pts.length - 1].x - root.drag.pts[0].x) : 0
                            height: root.drag ? Math.abs(root.drag.pts[root.drag.pts.length - 1].y - root.drag.pts[0].y) : 0
                            color: "#22ffffff"; border.width: 2; border.color: "white"
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.CrossCursor
                    function pt(m) { return { x: m.x / view.fit + (root.crop ? root.crop.x : 0), y: m.y / view.fit + (root.crop ? root.crop.y : 0) } }
                    onPressed: m => root.drag = { t: root.tool, c: root.ink, pts: [pt(m)] }
                    onPositionChanged: m => {
                        if (!root.drag) return
                        const d = root.drag, p = pt(m)
                        root.drag = { t: d.t, c: d.c, pts: d.t === "pen" ? [...d.pts, p] : [d.pts[0], p] }
                    }
                    onReleased: {
                        const d = root.drag
                        root.drag = null
                        if (!d) return
                        const a = d.pts[0], b = d.pts[d.pts.length - 1]
                        if (Math.abs(b.x - a.x) + Math.abs(b.y - a.y) < 4) return
                        if (d.t === "crop") root.crop = { x: Math.max(0, Math.min(a.x, b.x)), y: Math.max(0, Math.min(a.y, b.y)),
                                                           w: Math.min(Math.abs(b.x - a.x), probe.implicitWidth), h: Math.min(Math.abs(b.y - a.y), probe.implicitHeight) }
                        else root.shapes = [...root.shapes, d]
                    }
                }
            }
        }
    }
}
