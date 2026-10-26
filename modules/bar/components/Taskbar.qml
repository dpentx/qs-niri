import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10
import Quickshell
import "../../../services" as QsServices
import "../../../components"
import "../../../components/effects"
import "../../../config" as QsConfig

// DeX-style taskbar: pinned apps (taskbar.pinned, see Config.togglePin) stay, open windows
// join them (one icon per app). Click launches / focuses (again: next window of that app),
// hovering a running app shows a close badge, middle-click closes, right-click (or
// Shift+click) opens the menu: pin / unpin, the app's desktop actions, close.
Item {
    id: root

    readonly property var pywal: QsServices.Pywal
    readonly property var apps: DesktopEntries.applications.values ?? []

    // [{ key, entry, appId, wins }]
    readonly property var items: {
        const byKey = new Map()
        const out = []
        const slot = (entry, appId) => {
            const key = entry?.id ?? appId
            let it = byKey.get(key)
            if (!it) { it = { key, entry, appId, wins: [] }; byKey.set(key, it); out.push(it) }
            return it
        }
        for (const f of QsConfig.Config.taskbar.pinned ?? []) {
            const e = apps.find(a => a.id === f || a.name === f)
            if (e) slot(e, e.id)
        }
        for (const w of QsServices.Windows.list)
            slot(DesktopEntries.heuristicLookup(w.appId), w.appId).wins.push(w)
        return out.slice(0, QsConfig.Config.taskbar.maxItems)
    }
    readonly property bool hasItems: items.length > 0

    implicitWidth: row.implicitWidth
    implicitHeight: 40

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Repeater {
            model: root.items

            Rectangle {
                id: cell
                required property var modelData
                readonly property var entry: modelData.entry
                readonly property var wins: modelData.wins
                readonly property bool running: wins.length > 0
                readonly property bool focused: wins.some(w => w.focused)
                readonly property var actions: entry?.actions ?? []
                readonly property string label: entry?.name ?? modelData.appId
                // pin / unpin (only apps with a desktop entry can be launched again), desktop actions, close
                readonly property var menuItems: {
                    const out = []
                    if (entry) out.push({ pin: true, name: QsConfig.Config.isPinned(entry) ? "Unpin from taskbar" : "Pin to taskbar" })
                    for (let i = 0; i < actions.length; ++i) out.push(actions[i])
                    if (running) out.push({ close: true, name: "Close window", icon: "" })
                    return out
                }

                Layout.preferredWidth: 44
                Layout.preferredHeight: 40
                radius: QsConfig.Appearance.radius.m
                color: focused ? Qt.rgba(pywal.primary.r, pywal.primary.g, pywal.primary.b, 0.22)
                     : (hover.hovered ? Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.10) : "transparent")
                Behavior on color { ColorAnimation { duration: OneUIMotion.short3 } }
                scale: mouse.pressed ? 0.92 : 1
                Behavior on scale { NumberAnimation { duration: OneUIMotion.short2 } }

                HoverHandler { id: hover }
                ToolTip.visible: hover.hovered && label.length > 0
                ToolTip.text: running ? (wins.find(w => w.focused) ?? wins[0]).title || label : label
                ToolTip.delay: 500

                SquircleIcon {
                    id: icon
                    anchors.centerIn: parent
                    size: 28
                    tileColor: "transparent"
                    source: Quickshell.iconPath(cell.entry?.icon ?? cell.modelData.appId.toLowerCase(), true) || ""
                }
                Text {
                    anchors.centerIn: parent
                    visible: icon.status !== Image.Ready
                    text: (cell.label || "?").charAt(0).toUpperCase()
                    color: pywal.foreground
                    font.family: QsConfig.Config.appearance.fontFamily
                    font.pixelSize: QsConfig.Appearance.fontSize.l
                    font.weight: Font.DemiBold
                }

                // running marker: dot, long while focused
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 2
                    visible: cell.running
                    width: cell.focused ? 14 : 5
                    height: 3
                    radius: 1.5
                    color: cell.focused ? pywal.primary : Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.6)
                    Behavior on width { NumberAnimation { duration: OneUIMotion.short4 } }
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    onClicked: m => {
                        if (m.button === Qt.MiddleButton) {
                            if (cell.running) cell.closeOne()
                        } else if (m.button === Qt.RightButton || (m.modifiers & Qt.ShiftModifier)) {
                            menu.visible = !menu.visible
                        } else if (!cell.running) {
                            cell.entry?.execute()
                        } else {
                            const i = cell.wins.findIndex(w => w.focused)
                            QsServices.Windows.focus(cell.wins[(i + 1) % cell.wins.length].id)
                        }
                    }
                }

                function closeOne() { QsServices.Windows.close((wins.find(w => w.focused) ?? wins[0]).id) }

                // close badge (hover on a running app)
                Rectangle {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 2
                    width: 16; height: 16; radius: 8
                    visible: cell.running && hover.hovered
                    color: closeMouse.containsMouse ? pywal.error : pywal.surfaceContainerHighest
                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: closeMouse.containsMouse ? pywal.onError : pywal.foreground
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }
                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: cell.closeOne()
                    }
                }

                // right-click / Shift+click: app name, pin, desktop actions, close (above the bar)
                PopupWindow {
                    id: menu
                    anchor.item: cell
                    anchor.edges: Edges.Top
                    anchor.gravity: Edges.Top
                    anchor.margins.bottom: 6
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
                        transformOrigin: Item.Bottom
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
                                text: cell.label
                                elide: Text.ElideRight
                                color: pywal.onSurfaceMuted
                                font.family: QsConfig.Config.appearance.fontFamily
                                font.pixelSize: QsConfig.Appearance.fontSize.xs
                                font.weight: Font.Medium
                            }

                            Repeater {
                                model: cell.menuItems

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
                                            if (act.modelData.close) cell.closeOne()
                                            else if (act.modelData.pin) QsConfig.Config.togglePin(cell.entry)
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
