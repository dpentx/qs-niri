import QtQuick 6.10
import "../services" as QsServices

// Filled line graph over a rolling history, used by the task manager.
// `series` is an array of arrays (oldest → newest); each is drawn with the
// matching entry of `colors`. Values are scaled to `maxValue` (0 = auto).
Canvas {
    id: canvas

    property var series: []
    property var colors: []
    property real maxValue: 0
    property int points: 60
    property bool grid: true
    property real lineWidth: 2

    readonly property var pywal: QsServices.Pywal

    antialiasing: true
    onSeriesChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    Connections { target: canvas.pywal; function onPrimaryChanged() { canvas.requestPaint() } }

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const w = width, h = height
        if (w <= 0 || h <= 0) return

        if (grid) {
            ctx.strokeStyle = Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.08)
            ctx.lineWidth = 1
            for (let i = 1; i < 4; i++) {
                const y = Math.round(h * i / 4) + 0.5
                ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(w, y); ctx.stroke()
            }
        }

        let max = maxValue
        if (max <= 0) {
            for (const s of series) for (const v of s) if (v > max) max = v
            max = Math.max(max * 1.15, 1)
        }

        for (let k = 0; k < series.length; k++) {
            const s = series[k]
            if (!s || s.length < 2) continue
            const c = colors[k] ?? pywal.primary
            const step = w / (points - 1)
            const x0 = w - (s.length - 1) * step
            const pad = lineWidth
            const yOf = v => h - pad - Math.min(1, v / max) * (h - pad * 2)

            ctx.beginPath()
            ctx.moveTo(x0, yOf(s[0]))
            for (let i = 1; i < s.length; i++) ctx.lineTo(x0 + i * step, yOf(s[i]))
            ctx.lineWidth = lineWidth
            ctx.lineJoin = "round"
            ctx.strokeStyle = c
            ctx.stroke()

            ctx.lineTo(w, h); ctx.lineTo(x0, h); ctx.closePath()
            const g = ctx.createLinearGradient(0, 0, 0, h)
            g.addColorStop(0, Qt.rgba(c.r, c.g, c.b, 0.28))
            g.addColorStop(1, Qt.rgba(c.r, c.g, c.b, 0.02))
            ctx.fillStyle = g
            ctx.fill()
        }
    }
}
