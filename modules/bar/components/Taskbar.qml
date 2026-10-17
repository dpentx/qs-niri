import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10
import Quickshell
import "../../../services" as QsServices
import "../../../components"
import "../../../components/effects"
import "../../../config" as QsConfig

// Open-window icons. Click focuses, middle-click closes, Shift+click lists the
// app's desktop actions (no right-click: Qt's context-menu synthesis can crash
// Quickshell, see SystemTray.qml).
Item {
    id: root

    readonly property var pywal: QsServices.Pywal
    readonly property var windows: QsServices.Windows.list.slice(0, QsConfig.Config.taskbar.maxItems)
    readonly property bool hasItems: windows.length > 0

    implicitWidth: row.implicitWidth
    implicitHeight: 24

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Repeater {
            model: root.windows

            Rectangle {
                id: item
                required property var modelData
                readonly property var entry: DesktopEntries.heuristicLookup(modelData.appId)
                readonly property var actions: entry?.actions ?? []

                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                radius: QsConfig.Appearance.radius.s
                color: modelData.focused ? Qt.rgba(pywal.primary.r, pywal.primary.g, pywal.primary.b, 0.22)
                     : (mouse.containsMouse ? Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.10) : "transparent")
                Behavior on color { ColorAnimation { duration: OneUIMotion.short3 } }
                scale: mouse.pressed ? 0.92 : 1
                Behavior on scale { NumberAnimation { duration: OneUIMotion.short2 } }

                Image {
                    id: icon
                    anchors.centerIn: parent
                    width: 18
                    height: 18
                    sourceSize: Qt.size(36, 36)
                    asynchronous: true
                    source: Quickshell.iconPath(item.entry?.icon ?? item.modelData.appId.toLowerCase(), true) || ""
                    visible: status === Image.Ready
                }
                Text {
                    anchors.centerIn: parent
                    visible: icon.status !== Image.Ready
                    text: (item.modelData.appId || item.modelData.title || "?").charAt(0).toUpperCase()
                    color: pywal.foreground
                    font.family: QsConfig.Config.appearance.fontFamily
                    font.pixelSize: QsConfig.Appearance.fontSize.m
                    font.weight: Font.DemiBold
                }

                // focus marker
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 1
                    width: item.modelData.focused ? 10 : 0
                    height: 2
                    radius: 1
                    color: pywal.primary
                    Behavior on width { NumberAnimation { duration: OneUIMotion.short4 } }
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    onClicked: m => {
                        if (m.button === Qt.MiddleButton) QsServices.Windows.close(item.modelData.id)
                        else if (m.modifiers & Qt.ShiftModifier) menu.visible = !menu.visible
                        else QsServices.Windows.focus(item.modelData.id)
                    }
                    ToolTip.visible: containsMouse && item.modelData.title.length > 0
                    ToolTip.text: item.modelData.title
                    ToolTip.delay: 500
                }

                // Shift+click: window title, desktop actions, close
                PopupWindow {
                    id: menu
                    anchor.item: item
                    anchor.edges: Edges.Bottom
                    anchor.gravity: Edges.Bottom
                    anchor.margins.top: 6
                    implicitWidth: 240
                    implicitHeight: menuCol.implicitHeight + 16
                    color: "transparent"

                    Timer { id: leave; interval: 350; onTriggered: menu.visible = false }

                    Rectangle {
                        anchors.fill: parent
                        radius: QsConfig.Appearance.radius.m
                        color: Qt.rgba(pywal.surface.r, pywal.surface.g, pywal.surface.b, 0.92)
                        border.width: 1
                        border.color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.10)
                        opacity: menu.visible ? 1 : 0
                        scale: menu.visible ? 1 : 0.94
                        transformOrigin: Item.Top
                        Behavior on opacity { NumberAnimation { duration: OneUIMotion.short4 } }
                        Behavior on scale { NumberAnimation { duration: OneUIMotion.medium1; easing.bezierCurve: OneUIMotion.springGentle } }

                        HoverHandler { onHoveredChanged: hovered ? leave.stop() : leave.start() }

                        ColumnLayout {
                            id: menuCol
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                Layout.leftMargin: 10
                                Layout.rightMargin: 10
                                Layout.topMargin: 2
                                text: item.entry?.name ?? item.modelData.appId
                                elide: Text.ElideRight
                                color: pywal.onSurfaceMuted
                                font.family: QsConfig.Config.appearance.fontFamily
                                font.pixelSize: QsConfig.Appearance.fontSize.xs
                                font.weight: Font.Medium
                            }

                            Repeater {
                                model: item.actions.concat([{ close: true, name: "Close window", icon: "" }])

                                Rectangle {
                                    id: act
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32
                                    radius: QsConfig.Appearance.radius.s
                                    color: actMouse.containsMouse ? Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.10) : "transparent"
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: 10
                                        width: parent.width - 20
                                        text: act.modelData.name
                                        elide: Text.ElideRight
                                        color: act.modelData.close ? pywal.error : pywal.foreground
                                        font.family: QsConfig.Config.appearance.fontFamily
                                        font.pixelSize: QsConfig.Appearance.fontSize.m
                                    }
                                    MouseArea {
                                        id: actMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            if (act.modelData.close) QsServices.Windows.close(item.modelData.id)
                                            else act.modelData.execute()
                                            menu.visible = false
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
