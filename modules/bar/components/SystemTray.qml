import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10
import Quickshell
import Quickshell.Services.SystemTray
import "../../../services" as QsServices
import "../../../components/effects"

Item {
    id: root

    readonly property var pywal: QsServices.Pywal
    readonly property bool hasItems: SystemTray.items.length > 0

    implicitWidth: trayRow.implicitWidth
    implicitHeight: 24
    visible: hasItems

    RowLayout {
        id: trayRow
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: SystemTray.items

            Rectangle {
                id: trayItem
                required property var modelData

                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                radius: 8
                color: itemMouse.containsMouse
                    ? Qt.rgba(root.pywal.foreground.r, root.pywal.foreground.g, root.pywal.foreground.b, 0.10)
                    : "transparent"

                Behavior on color {
                    ColorAnimation {
                        duration: Material3Anim.short3
                        easing.bezierCurve: Material3Anim.standard
                    }
                }

                scale: itemMouse.pressed ? 0.9 : (itemMouse.containsMouse ? 1.08 : 1.0)
                Behavior on scale {
                    NumberAnimation {
                        duration: Material3Anim.short2
                        easing.bezierCurve: Material3Anim.springGentle
                    }
                }

                Image {
                    id: trayIcon
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    smooth: true
                    asynchronous: true
                    // modelData.icon is a Quickshell image handle — use directly,
                    // no manual ?path= parsing needed.
                    source: trayItem.modelData.icon ?? ""
                    visible: status === Image.Ready
                }

                // Fallback glyph if the icon fails to load
                Text {
                    anchors.centerIn: parent
                    visible: trayIcon.status !== Image.Ready
                    text: "󰀻"
                    font.family: "Material Design Icons"
                    font.pixelSize: 14
                    color: Qt.rgba(root.pywal.foreground.r, root.pywal.foreground.g, root.pywal.foreground.b, 0.7)
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                    onClicked: mouse => {
                        const geo = trayItem.mapToGlobal(trayItem.width / 2, trayItem.height)
                        if (mouse.button === Qt.LeftButton) {
                            trayItem.modelData.activate(geo.x, geo.y)
                        } else if (mouse.button === Qt.RightButton) {
                            trayItem.modelData.menu?.show(geo.x, geo.y)
                        } else if (mouse.button === Qt.MiddleButton) {
                            trayItem.modelData.secondaryActivate?.(geo.x, geo.y)
                        }
                    }

                    ToolTip.visible: containsMouse && (trayItem.modelData.tooltipTitle?.length ?? 0) > 0
                    ToolTip.text: trayItem.modelData.tooltipTitle ?? ""
                    ToolTip.delay: 400
                }
            }
        }
    }
}
