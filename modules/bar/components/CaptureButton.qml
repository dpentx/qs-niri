import QtQuick 6.10
import QtQuick.Controls 6.10
import Quickshell
import "../../../components"
import "../../../components/effects"
import "../../../config" as QsConfig
import "../../../services" as QsServices

Item {
    id: root

    readonly property var pywal: QsServices.Pywal
    readonly property var screenshot: QsServices.Screenshot
    readonly property bool hovered: mouse.containsMouse

    implicitWidth: 28
    implicitHeight: 28
    activeFocusOnTab: true

    Keys.onReturnPressed: screenshot.takeScreenshot("screen")
    Keys.onEnterPressed: screenshot.takeScreenshot("screen")
    Keys.onSpacePressed: screenshot.takeScreenshot("screen")

    Rectangle {
        anchors.fill: parent
        radius: QsConfig.Appearance.radius.s
        color: pywal.foreground
        opacity: root.hovered ? OneUIMotion.hoverOpacity + 0.04 : 0
        border.width: root.activeFocus ? QsConfig.Appearance.border.focus : 0
        border.color: pywal.primary
        Behavior on opacity { NumberAnimation { duration: OneUIMotion.short3 } }
    }

    OneUIIcon {
        anchors.centerIn: parent
        name: "ic_screen_capture"
        size: 18
        color: root.hovered ? pywal.primary : pywal.foreground
        scale: mouse.pressed ? OneUIMotion.pressedScale : (root.hovered ? 1.05 : 1.0)
        Behavior on color { ColorAnimation { duration: OneUIMotion.short2 } }
        Behavior on scale { NumberAnimation { duration: OneUIMotion.short2 } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: mouseEvent => {
            root.forceActiveFocus()
            if (mouseEvent.button === Qt.RightButton) {
                screenshot.takeScreenshot("region")
            } else {
                screenshot.takeScreenshot("screen")
            }
        }
    }

    ToolTip.visible: root.hovered
    ToolTip.delay: 450
    ToolTip.text: "Screen capture (Right-click: Region)"
}
