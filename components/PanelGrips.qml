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

    // Resize: the bottom-right corner always, and with Ctrl held (left or right button) the panel is split
    // like a compass into 3x3 zones: the pointer's zone picks the edge(s) to pull (N, NE, E, SE, S, SW, W, NW;
    // the centre does nothing). Drag handlers rather than MouseAreas so plain clicks still reach the content.
    property int edges: 0       // edges the current drag resizes (bit mask, see PanelGeometry.resizeEdges)
    property var rect0

    function edgesAt(p) {
        let e = 0
        if (p.x < width / 3) e |= 1
        else if (p.x > width * 2 / 3) e |= 2
        if (p.y < height / 3) e |= 4
        else if (p.y > height * 2 / 3) e |= 8
        return e
    }
    function cursorFor(e) {
        if (e === 5 || e === 10) return Qt.SizeFDiagCursor
        if (e === 6 || e === 9) return Qt.SizeBDiagCursor
        if (e === 1 || e === 2) return Qt.SizeHorCursor
        if (e === 4 || e === 8) return Qt.SizeVerCursor
        return Qt.ArrowCursor
    }

    HoverHandler {
        id: ctrlHover
        acceptedModifiers: Qt.ControlModifier
        cursorShape: root.cursorFor(root.edgesAt(point.position))
    }
    DragHandler {
        acceptedModifiers: Qt.ControlModifier
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        target: null
        onActiveChanged: {
            if (active) {
                root.edges = root.edgesAt(centroid.pressPosition)
                root.rect0 = { x: root.geo.x, y: root.geo.y, w: root.geo.w, h: root.geo.h }
            } else if (root.edges) { root.edges = 0; root.geo.commit() }
        }
        onTranslationChanged: if (root.edges) root.geo.resizeEdges(root.rect0, root.edges, translation.x, translation.y)
    }

    Item {
        id: corner
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
                opacity: cornerHover.hovered || cornerDrag.active ? 0.7 : 0.25
            }
        }
        HoverHandler { id: cornerHover; cursorShape: Qt.SizeFDiagCursor }
        DragHandler {
            id: cornerDrag
            target: null
            onActiveChanged: {
                if (active) root.rect0 = { x: root.geo.x, y: root.geo.y, w: root.geo.w, h: root.geo.h }
                else root.geo.commit()
            }
            onTranslationChanged: if (active) root.geo.resizeEdges(root.rect0, 10, translation.x, translation.y)
        }
    }
}
