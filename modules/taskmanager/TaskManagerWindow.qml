import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10 as QQC
import Quickshell
import Quickshell.Wayland
import "../../config" as QsConfig
import "../../services" as QsServices
import "../../components"
import "../../components/effects"

// Task manager: CPU / memory summary on top, grouped process list below.
// Tap a row to reveal its actions. Opened with `touch /tmp/qs-taskmanager`
// or from the system tools panel.
PanelWindow {
    id: root

    BackgroundEffect.blurRegion: QsConfig.Appearance.blur ? _blur : null
    Region { id: _blur; item: blurSurface; radius: blurSurface.radius }

    property bool shouldShow: false

    readonly property var config: QsConfig.Config
    readonly property var pywal: QsServices.Pywal
    readonly property var usage: QsServices.SystemUsage
    readonly property color cSurface: pywal.surfaceContainerHighest
    readonly property color cCard: pywal.surfaceContainerHigh
    readonly property color cPrimary: pywal.primary
    readonly property color cText: pywal.foreground
    readonly property color cSubText: pywal.onSurfaceMuted
    readonly property color cError: pywal.error

    // view state
    property string sortKey: "cpu"        // cpu | mem | name
    property bool grouped: true
    property string filterText: ""
    property string selectedKey: ""
    readonly property int cores: QsServices.ProcessList.cores

    function close() { shouldShow = false }

    onShouldShowChanged: {
        QsServices.ProcessList.active = shouldShow
        if (!shouldShow) { filterText = ""; selectedKey = ""; search.text = "" }
    }

    // ── model ─────────────────────────────────────────────────────
    ListModel { id: rows }

    function formatMem(kib) {
        if (kib >= 1048576) return (kib / 1048576).toFixed(1) + " GB"
        if (kib >= 1024) return Math.round(kib / 1024) + " MB"
        return kib + " KB"
    }

    function rebuild() {
        const src = QsServices.ProcessList.processes
        const q = filterText.trim().toLowerCase()
        const map = new Map()
        for (const p of src) {
            if (q && !p.name.toLowerCase().includes(q) && String(p.pid) !== q) continue
            const key = grouped ? p.name : String(p.pid)
            let g = map.get(key)
            if (!g) {
                g = { key: key, name: p.name, cpu: 0, rss: 0, count: 0, pids: [], user: p.user }
                map.set(key, g)
            }
            g.cpu += p.cpu
            g.rss += p.rss
            g.count += 1
            g.pids.push(p.pid)
        }
        const list = Array.from(map.values())
        const cmp = sortKey === "mem" ? (a, b) => b.rss - a.rss
                  : sortKey === "name" ? (a, b) => a.name.localeCompare(b.name)
                  : (a, b) => b.cpu - a.cpu || b.rss - a.rss
        list.sort(cmp)

        // Update in place so scroll position and hover survive each sample.
        for (let i = 0; i < list.length; i++) {
            const g = list[i]
            const row = {
                key: g.key, name: g.name, cpu: g.cpu, rss: g.rss, count: g.count,
                pids: g.pids.join(","), user: g.user
            }
            if (i < rows.count) rows.set(i, row)
            else rows.append(row)
        }
        if (rows.count > list.length) rows.remove(list.length, rows.count - list.length)
    }

    Connections {
        target: QsServices.ProcessList
        function onStampChanged() { root.rebuild() }
    }
    onSortKeyChanged: rebuild()
    onGroupedChanged: rebuild()
    onFilterTextChanged: rebuild()

    // ── window ────────────────────────────────────────────────────
    screen: Quickshell.screens[0]
    anchors { top: true; left: true }
    margins {
        top: (config.bar.height ?? 34) + 22
        left: Math.max(0, Math.round((screen.width - root.implicitWidth) / 2))
    }
    implicitWidth: 560
    implicitHeight: shouldShow || panel.opacity > 0 ? Math.min(640, screen.height - margins.top - 24) : 0
    color: "transparent"
    visible: shouldShow || panel.opacity > 0

    // Overlay, so the click-outside dismiss layer (Top) stays beneath it
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shouldShow ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    FocusScope {
        id: panel
        anchors.fill: parent
        property real revealOffset: shouldShow ? 0 : -20
        scale: shouldShow ? 1.0 : 0.97
        opacity: shouldShow ? 1.0 : 0.0
        focus: root.shouldShow
        transform: Translate { y: panel.revealOffset }

        Keys.onEscapePressed: root.close()

        Behavior on scale { NumberAnimation { duration: OneUIMotion.medium1; easing.bezierCurve: OneUIMotion.springGentle } }
        Behavior on opacity { NumberAnimation { duration: OneUIMotion.short4; easing.type: Easing.OutQuad } }
        Behavior on revealOffset { NumberAnimation { duration: OneUIMotion.medium1; easing.bezierCurve: OneUIMotion.emphasizedDecelerate } }

        AuroraSurface {
            id: blurSurface
            anchors.fill: parent
            radius: QsConfig.Appearance.radius.l
            color: root.cSurface
            borderWidth: 0
            accentColor: root.cPrimary
            elevation: 1
            highlighted: false

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                // Title row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    OneUIIcon { name: "mdi_memory"; size: 18; color: root.cPrimary }
                    Text {
                        Layout.fillWidth: true
                        text: "Görev Yöneticisi"
                        color: root.cText
                        font.family: QsConfig.Config.appearance.fontFamily
                        font.pixelSize: QsConfig.Appearance.fontSize.xl
                        font.weight: Font.DemiBold
                    }
                    Rectangle {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        radius: 16
                        color: closeMouse.containsMouse ? Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.12) : "transparent"
                        scale: closeMouse.pressed ? 0.9 : 1
                        Behavior on scale { NumberAnimation { duration: OneUIMotion.short2 } }
                        OneUIIcon { anchors.centerIn: parent; name: "ic_close"; size: 15; color: root.cText }
                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.close()
                        }
                    }
                }

                // Summary cards: CPU + memory, pill bars like the quick panel
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    component StatCard: Rectangle {
                        id: card
                        property string label: ""
                        property string value: ""
                        property string detail: ""
                        property real fraction: 0
                        Layout.fillWidth: true
                        Layout.preferredHeight: 84
                        radius: QsConfig.Appearance.radius.m
                        color: root.cCard

                        readonly property color tint: fraction > 0.85 ? root.cError : root.cPrimary

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: card.label
                                    color: root.cSubText
                                    font.family: QsConfig.Config.appearance.fontFamily
                                    font.pixelSize: QsConfig.Appearance.fontSize.s
                                    font.weight: Font.Medium
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: card.detail
                                    color: root.cSubText
                                    font.family: QsConfig.Config.appearance.fontFamily
                                    font.pixelSize: QsConfig.Appearance.fontSize.xs
                                }
                            }
                            Text {
                                text: card.value
                                color: root.cText
                                font.family: QsConfig.Config.appearance.fontFamily
                                font.pixelSize: QsConfig.Appearance.fontSize.xxl
                                font.weight: Font.DemiBold
                            }
                            Item { Layout.fillHeight: true }
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 6
                                radius: 3
                                color: Qt.rgba(card.tint.r, card.tint.g, card.tint.b, 0.18)
                                Rectangle {
                                    width: Math.max(parent.height, parent.width * Math.min(1, card.fraction))
                                    height: parent.height
                                    radius: 3
                                    color: card.tint
                                    Behavior on width { NumberAnimation { duration: OneUIMotion.medium1; easing.bezierCurve: OneUIMotion.standard } }
                                }
                            }
                        }
                    }

                    StatCard {
                        label: "İşlemci"
                        value: Math.round(root.usage.cpuPerc * 100) + "%"
                        detail: root.cores + " çekirdek"
                        fraction: root.usage.cpuPerc
                    }
                    StatCard {
                        label: "Bellek"
                        value: Math.round(root.usage.memPerc * 100) + "%"
                        detail: (root.usage.memUsed / 1073741824).toFixed(1) + " / " + (root.usage.memTotal / 1073741824).toFixed(1) + " GB"
                        fraction: root.usage.memPerc
                    }
                }

                // Search + sort chips
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        radius: 18
                        color: root.cCard

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8
                            OneUIIcon { name: "mdi_magnify"; size: 14; color: root.cSubText }
                            QQC.TextField {
                                id: search
                                Layout.fillWidth: true
                                background: null
                                padding: 0
                                placeholderText: "İşlem ara"
                                placeholderTextColor: root.cSubText
                                color: root.cText
                                font.family: QsConfig.Config.appearance.fontFamily
                                font.pixelSize: QsConfig.Appearance.fontSize.m
                                selectByMouse: true
                                onTextChanged: root.filterText = text
                                Keys.onEscapePressed: root.close()
                            }
                        }
                    }

                    component Chip: Rectangle {
                        id: chip
                        property string label: ""
                        property bool on: false
                        signal clicked()
                        Layout.preferredHeight: 36
                        Layout.preferredWidth: chipText.implicitWidth + 26
                        radius: 18
                        color: on ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.22)
                                  : (chipMouse.containsMouse ? Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.10) : root.cCard)
                        Behavior on color { ColorAnimation { duration: OneUIMotion.short3 } }
                        scale: chipMouse.pressed ? 0.95 : 1
                        Behavior on scale { NumberAnimation { duration: OneUIMotion.short2 } }
                        Text {
                            id: chipText
                            anchors.centerIn: parent
                            text: chip.label
                            color: chip.on ? root.cPrimary : root.cText
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: QsConfig.Appearance.fontSize.s
                            font.weight: chip.on ? Font.DemiBold : Font.Medium
                        }
                        MouseArea {
                            id: chipMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: chip.clicked()
                        }
                    }

                    Chip { label: "CPU"; on: root.sortKey === "cpu"; onClicked: root.sortKey = "cpu" }
                    Chip { label: "Bellek"; on: root.sortKey === "mem"; onClicked: root.sortKey = "mem" }
                    Chip { label: "Ad"; on: root.sortKey === "name"; onClicked: root.sortKey = "name" }
                    Chip { label: "Grupla"; on: root.grouped; onClicked: root.grouped = !root.grouped }
                }

                // Column header
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 14
                    Layout.rightMargin: 14
                    spacing: 8
                    Text {
                        Layout.fillWidth: true
                        text: rows.count + " işlem"
                        color: root.cSubText
                        font.family: QsConfig.Config.appearance.fontFamily
                        font.pixelSize: QsConfig.Appearance.fontSize.xs
                        font.weight: Font.Medium
                    }
                    Text {
                        Layout.preferredWidth: 60
                        horizontalAlignment: Text.AlignRight
                        text: "CPU"
                        color: root.cSubText
                        font.family: QsConfig.Config.appearance.fontFamily
                        font.pixelSize: QsConfig.Appearance.fontSize.xs
                        font.weight: Font.Medium
                    }
                    Text {
                        Layout.preferredWidth: 76
                        horizontalAlignment: Text.AlignRight
                        text: "Bellek"
                        color: root.cSubText
                        font.family: QsConfig.Config.appearance.fontFamily
                        font.pixelSize: QsConfig.Appearance.fontSize.xs
                        font.weight: Font.Medium
                    }
                }

                // Process list
                ListView {
                    id: list
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 4
                    model: rows
                    boundsBehavior: Flickable.StopAtBounds
                    reuseItems: false

                    QQC.ScrollBar.vertical: QQC.ScrollBar { policy: QQC.ScrollBar.AsNeeded }

                    delegate: Item {
                        id: row
                        required property int index
                        required property string key
                        required property string name
                        required property real cpu
                        required property real rss
                        required property int count
                        required property string pids
                        required property string user

                        readonly property bool selected: root.selectedKey === key
                        readonly property bool hot: cpu / root.cores >= 50
                        readonly property var pidList: pids.split(",").map(Number)

                        width: list.width - 6
                        height: selected ? 52 + 48 : 52
                        Behavior on height { NumberAnimation { duration: OneUIMotion.medium1; easing.bezierCurve: OneUIMotion.emphasizedDecelerate } }
                        clip: true

                        Rectangle {
                            anchors.fill: parent
                            radius: QsConfig.Appearance.radius.m
                            color: row.selected ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.16)
                                 : (rowMouse.containsMouse ? Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.07) : root.cCard)
                            Behavior on color { ColorAnimation { duration: OneUIMotion.short3 } }
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            height: 52
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedKey = row.selected ? "" : row.key
                        }

                        RowLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            height: 52
                            spacing: 10

                            // App icon, falling back to the first letter
                            Item {
                                Layout.preferredWidth: 28
                                Layout.preferredHeight: 28
                                Image {
                                    id: icon
                                    anchors.fill: parent
                                    sourceSize: Qt.size(56, 56)
                                    source: {
                                        const e = DesktopEntries.heuristicLookup(row.name)
                                        return Quickshell.iconPath(e?.icon ?? row.name.toLowerCase(), true) || ""
                                    }
                                    visible: status === Image.Ready
                                }
                                Rectangle {
                                    anchors.fill: parent
                                    visible: icon.status !== Image.Ready
                                    radius: 9
                                    color: Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.18)
                                    Text {
                                        anchors.centerIn: parent
                                        text: row.name.charAt(0).toUpperCase()
                                        color: root.cPrimary
                                        font.family: QsConfig.Config.appearance.fontFamily
                                        font.pixelSize: QsConfig.Appearance.fontSize.m
                                        font.weight: Font.DemiBold
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Text {
                                    Layout.fillWidth: true
                                    text: row.name
                                    elide: Text.ElideRight
                                    color: root.cText
                                    font.family: QsConfig.Config.appearance.fontFamily
                                    font.pixelSize: QsConfig.Appearance.fontSize.m
                                    font.weight: Font.Medium
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: row.count > 1 ? (row.count + " işlem") : ("PID " + row.pidList[0] + "  ·  " + row.user)
                                    elide: Text.ElideRight
                                    color: root.cSubText
                                    font.family: QsConfig.Config.appearance.fontFamily
                                    font.pixelSize: QsConfig.Appearance.fontSize.xs
                                }
                            }

                            Text {
                                Layout.preferredWidth: 60
                                horizontalAlignment: Text.AlignRight
                                text: row.cpu.toFixed(1) + "%"
                                color: row.hot ? root.cError : root.cText
                                font.family: QsConfig.Config.appearance.fontFamily
                                font.pixelSize: QsConfig.Appearance.fontSize.s
                                font.weight: row.hot ? Font.DemiBold : Font.Medium
                            }
                            Text {
                                Layout.preferredWidth: 76
                                horizontalAlignment: Text.AlignRight
                                text: root.formatMem(row.rss)
                                color: root.cText
                                font.family: QsConfig.Config.appearance.fontFamily
                                font.pixelSize: QsConfig.Appearance.fontSize.s
                                font.weight: Font.Medium
                            }
                        }

                        // Actions, revealed when the row is selected
                        RowLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            anchors.bottomMargin: 8
                            height: 36
                            spacing: 8
                            opacity: row.selected ? 1 : 0
                            visible: opacity > 0
                            Behavior on opacity { NumberAnimation { duration: OneUIMotion.short4 } }

                            component ActionButton: Rectangle {
                                id: act
                                property string label: ""
                                property color tint: root.cText
                                property bool filled: false
                                signal clicked()
                                Layout.fillWidth: true
                                Layout.preferredHeight: 36
                                radius: 18
                                color: filled ? (actMouse.containsMouse ? Qt.lighter(tint, 1.1) : tint)
                                              : Qt.rgba(tint.r, tint.g, tint.b, actMouse.containsMouse ? 0.22 : 0.14)
                                Behavior on color { ColorAnimation { duration: OneUIMotion.short3 } }
                                scale: actMouse.pressed ? 0.96 : 1
                                Behavior on scale { NumberAnimation { duration: OneUIMotion.short2 } }
                                Text {
                                    anchors.centerIn: parent
                                    text: act.label
                                    color: act.filled ? root.pywal.onError : act.tint
                                    font.family: QsConfig.Config.appearance.fontFamily
                                    font.pixelSize: QsConfig.Appearance.fontSize.s
                                    font.weight: Font.DemiBold
                                }
                                MouseArea {
                                    id: actMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: act.clicked()
                                }
                            }

                            ActionButton {
                                label: row.count > 1 ? "Hepsini sonlandır" : "Sonlandır"
                                tint: root.cPrimary
                                onClicked: { QsServices.ProcessList.terminate(row.pidList); root.selectedKey = "" }
                            }
                            ActionButton {
                                label: "Zorla durdur"
                                tint: root.cError
                                filled: true
                                onClicked: { QsServices.ProcessList.kill(row.pidList); root.selectedKey = "" }
                            }
                        }
                    }
                }
            }
        }
    }
}
