import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../../../services" as QsServices
import "../../../components/effects"
import "../../../config" as QsConfig
import "../../../components"

Item {
    id: root

    readonly property var pywal: QsServices.Pywal
    readonly property bool hasItems: SystemTray.items.values.length > 0

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
                radius: QsConfig.Appearance.radius.s
                color: itemMouse.containsMouse
                    ? Qt.rgba(root.pywal.foreground.r, root.pywal.foreground.g, root.pywal.foreground.b, 0.10)
                    : "transparent"

                Behavior on color {
                    ColorAnimation {
                        duration: OneUIMotion.short3
                        easing.bezierCurve: OneUIMotion.standard
                    }
                }

                scale: itemMouse.pressed ? 0.9 : (itemMouse.containsMouse ? 1.08 : 1.0)
                Behavior on scale {
                    NumberAnimation {
                        duration: OneUIMotion.short2
                        easing.bezierCurve: OneUIMotion.springGentle
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
                OneUIIcon {
                    anchors.centerIn: parent
                    visible: trayIcon.status !== Image.Ready
                    name: "ic_apps_expressive"
                    size: 14
                    color: Qt.rgba(root.pywal.foreground.r, root.pywal.foreground.g, root.pywal.foreground.b, 0.7)
                }

                // Own menu renderer (QsMenuOpener) instead of a native Qt menu:
                // nothing here goes through Qt's context-menu machinery.
                PopupWindow {
                    id: trayMenu
                    anchor.item: trayItem
                    anchor.edges: Edges.Bottom
                    anchor.gravity: Edges.Bottom
                    anchor.margins.top: 6
                    implicitWidth: 240
                    implicitHeight: menuCol.implicitHeight + 16
                    color: "transparent"

                    // Closed on mouse-leave, like the other bar popups.
                    Timer { id: leaveTimer; interval: 350; onTriggered: trayMenu.visible = false }
                    property int level: 0
                    property var menuStack: []
                    readonly property var currentHandle: level === 0 ? trayItem.modelData.menu : menuStack[level - 1]

                    onVisibleChanged: { if (!visible) { level = 0; menuStack = [] } }

                    QsMenuOpener { id: opener; menu: trayMenu.currentHandle }

                    Rectangle {
                        anchors.fill: parent
                        // Pop-in on open (the window hides instantly on close).
                        opacity: trayMenu.visible ? 1 : 0
                        scale: trayMenu.visible ? 1 : 0.94
                        transformOrigin: Item.Top
                        Behavior on opacity { NumberAnimation { duration: OneUIMotion.short4; easing.type: Easing.OutQuad } }
                        Behavior on scale { NumberAnimation { duration: OneUIMotion.medium1; easing.bezierCurve: OneUIMotion.springGentle } }
                        radius: QsConfig.Appearance.radius.m
                        color: Qt.rgba(root.pywal.surface.r, root.pywal.surface.g, root.pywal.surface.b, 0.92)
                        border.width: 1
                        border.color: Qt.rgba(root.pywal.foreground.r, root.pywal.foreground.g, root.pywal.foreground.b, 0.10)

                        HoverHandler {
                            onHoveredChanged: hovered ? leaveTimer.stop() : leaveTimer.start()
                        }

                        ColumnLayout {
                            id: menuCol
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 2

                            // back row for sub-menus
                            Rectangle {
                                visible: trayMenu.level > 0
                                Layout.fillWidth: true
                                Layout.preferredHeight: 32
                                radius: QsConfig.Appearance.radius.s
                                color: backMouse.containsMouse ? Qt.rgba(root.pywal.foreground.r, root.pywal.foreground.g, root.pywal.foreground.b, 0.10) : "transparent"
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: 10
                                    text: "‹  Back"
                                    color: root.pywal.foreground
                                    font.pixelSize: QsConfig.Appearance.fontSize.m
                                }
                                MouseArea {
                                    id: backMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        trayMenu.menuStack = trayMenu.menuStack.slice(0, -1)
                                        trayMenu.level -= 1
                                    }
                                }
                            }

                            Repeater {
                                model: opener.children

                                Item {
                                    id: entryRow
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: modelData.isSeparator ? 9 : 32

                                    Rectangle {
                                        visible: entryRow.modelData.isSeparator
                                        anchors.centerIn: parent
                                        width: parent.width - 12
                                        height: 1
                                        color: Qt.rgba(root.pywal.foreground.r, root.pywal.foreground.g, root.pywal.foreground.b, 0.14)
                                    }

                                    Rectangle {
                                        visible: !entryRow.modelData.isSeparator
                                        anchors.fill: parent
                                        radius: QsConfig.Appearance.radius.s
                                        color: entryMouse.containsMouse && entryRow.modelData.enabled
                                            ? Qt.rgba(root.pywal.foreground.r, root.pywal.foreground.g, root.pywal.foreground.b, 0.10) : "transparent"

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 10
                                            anchors.rightMargin: 10
                                            spacing: 8
                                            Image {
                                                Layout.preferredWidth: 16
                                                Layout.preferredHeight: 16
                                                visible: status === Image.Ready
                                                source: entryRow.modelData.icon ?? ""
                                                sourceSize: Qt.size(32, 32)
                                            }
                                            Text {
                                                Layout.fillWidth: true
                                                text: entryRow.modelData.text
                                                elide: Text.ElideRight
                                                color: root.pywal.foreground
                                                opacity: entryRow.modelData.enabled ? 1 : 0.4
                                                font.pixelSize: QsConfig.Appearance.fontSize.m
                                            }
                                            Text {
                                                visible: entryRow.modelData.hasChildren
                                                text: "›"
                                                color: root.pywal.foreground
                                            }
                                        }

                                        MouseArea {
                                            id: entryMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            enabled: entryRow.modelData.enabled
                                            onClicked: {
                                                if (entryRow.modelData.hasChildren) {
                                                    trayMenu.menuStack = trayMenu.menuStack.concat([entryRow.modelData])
                                                    trayMenu.level += 1
                                                } else {
                                                    entryRow.modelData.triggered()
                                                    trayMenu.visible = false
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

                    onClicked: mouse => {
                        const geo = trayItem.mapToGlobal(trayItem.width / 2, trayItem.height)
                        if (mouse.button === Qt.LeftButton) {
                            if (mouse.modifiers & Qt.ShiftModifier) {
                                // Shift+Left-click opens the tray menu instead
                                // of right-click: a real Qt.RightButton mouse
                                // event reaching this window can crash
                                // quickshell (Qt's context-menu synthesis
                                // segfaults on this build), so the menu is
                                // reachable without ever generating one.
                                if (trayItem.modelData.hasMenu) trayMenu.visible = !trayMenu.visible
                            } else {
                                trayItem.modelData.activate(geo.x, geo.y)
                            }
                        } else if (mouse.button === Qt.RightButton) {
                            // Right-click opens the menu like everywhere else. It used to crash Quickshell through a
                            // Qt context-menu bug (fixed in newer Qt); Shift+click above stays as the way around it.
                            if (trayItem.modelData.hasMenu) trayMenu.visible = !trayMenu.visible
                        } else if (mouse.button === Qt.MiddleButton) {
                            trayItem.modelData.secondaryActivate?.(geo.x, geo.y)
                        }
                    }

                }
            }
        }
    }
}
