import QtQuick 6.10
import QtQuick.Effects

// OneUI SVG icon with dynamic color tinting via MultiEffect colorization.
//
// Icons are produced by scripts/vector-to-svg.py as solid white shapes.
// Colorization uses `layer.effect:` embedded directly on the Image —
// NOT a separate sibling MultiEffect referencing the image via `source:`
// with `visible: false` (an earlier, incorrect version of this file used
// that pattern and it never worked reliably). `layer.effect` is the same,
// already-proven pattern used for panel shadows elsewhere in this shell
// (see NetworkPanel.qml's backgroundRect), and is Qt's own documented way
// to transform an item's rendering in place — no visibility tricks needed.
// `colorization`/`colorizationColor` are real, documented MultiEffect
// properties (https://doc.qt.io/qt-6/qml-qtquick-effects-multieffect.html).
//
// Usage:
//   OneUIIcon {
//       source: "qrc:/icons/oneui/ic_wifi_3.svg"
//       size: 20
//       color: pywal.foreground
//   }
Item {
    id: root

    property alias source: img.source
    property int size: 20
    property color color: "white"

    width: size
    height: size

    Behavior on opacity { NumberAnimation { duration: 150 } }

    Image {
        id: img
        anchors.fill: parent
        sourceSize.width: root.size * 2  // 2x for crisp scaling on hidpi
        sourceSize.height: root.size * 2
        fillMode: Image.PreserveAspectFit
        smooth: true

        layer.enabled: true
        layer.effect: MultiEffect {
            brightness: 1.0
            colorization: 1.0
            colorizationColor: root.color
        }
    }
}
