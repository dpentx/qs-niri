import QtQuick 6.10
import QtQuick.Shapes
import QtQuick.Effects

// App icon in a One UI squircle: the icon is masked to a superellipse
// (|x|^n + |y|^n = 1, n ≈ 5 — the soft "squarish" shape of Samsung launcher
// icons) over a faint tile, so glyph-style icons from a theme such as Papirus
// get the same silhouette as full-bleed ones.
Item {
    id: root

    property url source: ""
    property real size: 52
    property color tileColor: Qt.rgba(1, 1, 1, 0.08)
    property real exponent: 5
    readonly property int status: img.status

    implicitWidth: size
    implicitHeight: size
    width: size
    height: size

    // Superellipse outline as a polyline in unit coordinates
    readonly property var _points: {
        const pts = []
        const n = root.exponent
        const steps = 96
        for (let i = 0; i < steps; i++) {
            const t = (i / steps) * 2 * Math.PI
            const c = Math.cos(t), s = Math.sin(t)
            const x = Math.sign(c) * Math.pow(Math.abs(c), 2 / n)
            const y = Math.sign(s) * Math.pow(Math.abs(s), 2 / n)
            pts.push(Qt.point((x + 1) / 2 * root.size, (y + 1) / 2 * root.size))
        }
        return pts
    }

    // Mask shape (rendered into a texture, never shown directly)
    Item {
        id: maskItem
        anchors.fill: parent
        visible: false
        layer.enabled: true
        layer.smooth: true
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: "white"
                strokeWidth: -1
                PathPolyline { path: root._points }
            }
        }
    }

    // Faint tile behind the icon
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: root.tileColor
            strokeWidth: -1
            PathPolyline { path: root._points }
        }
    }

    Image {
        id: img
        anchors.fill: parent
        source: root.source
        sourceSize: Qt.size(root.size * 2, root.size * 2)
        fillMode: Image.PreserveAspectFit
        smooth: true
        asynchronous: true
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: img
        visible: img.status === Image.Ready
        maskEnabled: true
        maskSource: maskItem
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }
}
