import QtQuick 6.10
import QtQuick.Shapes
import QtQuick.Effects

// App icon in the Samsung One UI icon silhouette. The outline is the
// squircle taken from Samsung's own app-icon artwork (32x32 viewBox): a square
// with soft, slightly uneven corners — not a plain superellipse. The icon is
// masked to it over a faint tile, so glyph-style icons from a theme such as
// Papirus get the same silhouette as full-bleed ones.
Item {
    id: root

    property url source: ""
    property real size: 52
    property color tileColor: Qt.rgba(1, 1, 1, 0.08)
    readonly property int status: img.status

    readonly property string outline: "M31.969 14.271c-0.177-5.104-1.516-9.214-4.542-11.458s-7.573-3.021-13.286-2.75c-2.599 0.125-4.938 0.464-6.839 1.224-1.958 0.786-3.474 1.896-4.583 3.438-2.229 3.099-2.917 7.781-2.672 13.172 0.234 5.12 1.557 9.172 4.62 11.38 3.047 2.198 7.995 2.896 13.214 2.672 5.063-0.214 9.177-1.552 11.38-4.62 2.198-3.063 2.896-7.578 2.708-13.057z"

    implicitWidth: size
    implicitHeight: size
    width: size
    height: size

    // Mask shape (rendered into a texture, never shown directly)
    Item {
        id: maskItem
        anchors.fill: parent
        visible: false
        layer.enabled: true
        layer.smooth: true
        Shape {
            width: 32; height: 32
            scale: root.size / 32
            transformOrigin: Item.TopLeft
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: "white"
                strokeWidth: -1
                PathSvg { path: root.outline }
            }
        }
    }

    // Faint tile behind the icon
    Shape {
        width: 32; height: 32
        scale: root.size / 32
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: root.tileColor
            strokeWidth: -1
            PathSvg { path: root.outline }
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
