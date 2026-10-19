import QtQuick

// Handles for a PanelGeometry: a grabber pill on the top edge moves the panel, the bottom-right
// corner resizes it. Put it as the last child of the panel item.
Item {
    id: root

    required property var geo
    property color color: "white"

    anchors.fill: parent
    z: 1000

    Item {
        width: 120
        height: 12
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        Rectangle {
            width: 36; height: 4; radius: 2
            anchors.horizontalCenter: parent.horizontalCenter
            y: 4
            color: root.color
            opacity: moveArea.containsMouse || moveArea.pressed ? 0.7 : 0.25
        }
        MouseArea {
            id: moveArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
            property point p0
            property real x0
            property real y0
            onPressed: m => { p0 = mapToItem(null, m.x, m.y); x0 = root.geo.x; y0 = root.geo.y }
            onPositionChanged: m => {
                if (!pressed) return
                const p = mapToItem(null, m.x, m.y)   // scene coordinates: the panel moves under the pointer
                root.geo.moveTo(x0 + p.x - p0.x, y0 + p.y - p0.y)
            }
            onReleased: root.geo.commit()
            onDoubleClicked: root.geo.reset()
        }
    }

    Item {
        width: 26
        height: 26
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        Repeater {
            model: [{ w: 14, dx: 19, dy: 13 }, { w: 7, dx: 13, dy: 7 }]
            Rectangle {
                required property var modelData
                width: modelData.w; height: 2; radius: 1
                x: parent.width - modelData.dx
                y: parent.height - modelData.dy
                rotation: -45
                color: root.color
                opacity: sizeArea.containsMouse || sizeArea.pressed ? 0.7 : 0.25
            }
        }
        MouseArea {
            id: sizeArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.SizeFDiagCursor
            property point p0
            property real w0
            property real h0
            onPressed: m => { p0 = mapToItem(null, m.x, m.y); w0 = root.geo.w; h0 = root.geo.h }
            onPositionChanged: m => {
                if (!pressed) return
                const p = mapToItem(null, m.x, m.y)
                root.geo.resizeTo(w0 + p.x - p0.x, h0 + p.y - p0.y)
            }
            onReleased: root.geo.commit()
        }
    }
}
