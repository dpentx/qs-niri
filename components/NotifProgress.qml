import QtQuick 6.10

// Thin progress bar for a notification that carries a `value` hint (0..100); hidden when value < 0.
Item {
    id: root
    property int value: -1
    property color color: "#ffffff"
    visible: value >= 0
    implicitHeight: 4

    Rectangle { anchors.fill: parent; radius: height / 2; color: root.color; opacity: 0.18 }
    Rectangle {
        height: parent.height
        width: parent.width * Math.max(0, Math.min(100, root.value)) / 100
        radius: height / 2
        color: root.color
        Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    }
}
