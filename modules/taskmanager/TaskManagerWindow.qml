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

    // Blur only while the panel is fully shown: the region is a fixed rect and would otherwise be
    // drawn before the panel has faded in (and stay after it has gone).
    BackgroundEffect.blurRegion: QsConfig.Appearance.blur && shouldShow && panel.opacity > 0.98 && Math.abs(panel.scale - 1) < 0.002 && Math.abs(panel.revealOffset) < 0.5 ? _blur : null
    Region { id: _blur; item: panel; radius: blurSurface.radius }  // panel carries the movable geometry; a child item would keep the old rect when the panel is moved

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
    property Item tab0
    property Item tab1

    // view state
    property string sortKey: "cpu"        // cpu | mem | name
    property bool grouped: true
    property bool onlyMine: true
    property string filterText: ""
    property string selectedKey: ""
    property int tab: 0                    // 0 = processes, 1 = performance
    property string perfKey: "cpu"         // cpu | mem | disk | net

    // Rolling history (1 sample/s, 60 s) for the performance tab
    property var hCpu: []
    property var hMem: []
    property var hGpu: []
    property var hDiskR: []
    property var hDiskW: []
    property var hNetD: []
    property var hNetU: []
    property var hEthD: []
    property var hEthU: []
    property var hWifiD: []
    property var hWifiU: []
    function _push(arr, v) { const a = arr.concat([v]); return a.length > 60 ? a.slice(a.length - 60) : a }
    Timer {
        interval: 1000
        running: root.shouldShow
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const u = root.usage
            root.hCpu = root._push(root.hCpu, u.cpuPerc * 100)
            root.hMem = root._push(root.hMem, u.memPerc * 100)
            if (u.hasGpu) root.hGpu = root._push(root.hGpu, u.gpuUsage)
            root.hDiskR = root._push(root.hDiskR, QsServices.DiskIO.readSpeed)
            root.hDiskW = root._push(root.hDiskW, QsServices.DiskIO.writeSpeed)
            root.hNetD = root._push(root.hNetD, u.downloadSpeed)
            root.hNetU = root._push(root.hNetU, u.uploadSpeed)
            const hw = QsServices.HardwareInfo, eth = hw.rate("eth"), wifi = hw.rate("wifi")
            root.hEthD = root._push(root.hEthD, eth.rx)
            root.hEthU = root._push(root.hEthU, eth.tx)
            root.hWifiD = root._push(root.hWifiD, wifi.rx)
            root.hWifiU = root._push(root.hWifiU, wifi.tx)
        }
    }
    function formatRate(b) {
        if (b >= 1048576) return (b / 1048576).toFixed(1) + " MB/s"
        if (b >= 1024) return Math.round(b / 1024) + " KB/s"
        return Math.round(b) + " B/s"
    }
    readonly property int cores: QsServices.ProcessList.cores

    function close() { shouldShow = false }

    onShouldShowChanged: {
        if (shouldShow && !usage.hasGpu) perfKey = perfKey === "gpu" ? "cpu" : perfKey
        QsServices.ProcessList.active = shouldShow
        QsServices.HardwareInfo.active = shouldShow
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
            if (onlyMine && QsServices.ProcessList.me && p.user !== QsServices.ProcessList.me) continue
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
    onOnlyMineChanged: rebuild()
    Connections { target: QsServices.ProcessList; function onMeChanged() { root.rebuild() } }
    onFilterTextChanged: rebuild()

    // ── window ────────────────────────────────────────────────────
    screen: Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    // The window covers the screen; only the panel takes input and it can be moved/resized (PanelGeometry).
    mask: Region { item: panel }
    PanelGeometry {
        id: geo
        screen: root.screen
        name: "taskManager"
        minW: 560
        minH: 420
        defaultW: 600
        defaultH: Math.min(560, screen.height - defaultY - 24)
        defaultY: (config.bar.height ?? 34) + 22
    }
    color: "transparent"
    visible: shouldShow || panel.opacity > 0

    // Overlay, so the click-outside dismiss layer (Top) stays beneath it
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shouldShow ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    FocusScope {
        id: panel
        x: geo.x; y: geo.y; width: geo.w; height: geo.h

        PanelGrips { geo: geo; color: root.cText }
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

                // Title row: tabs + close
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    OneUIIcon { name: "mdi_memory"; size: 18; color: root.cPrimary }

                    Rectangle {
                        Layout.preferredHeight: 36
                        Layout.preferredWidth: tabRow.implicitWidth + 8
                        radius: 18
                        color: root.cCard

                        // sliding selection pill
                        Rectangle {
                            height: 28
                            y: 4
                            radius: 14
                            color: Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.24)
                            x: 4 + (root.tab === 0 || !root.tab0 ? 0 : root.tab0.width)
                            width: (root.tab === 0 ? root.tab0?.width : root.tab1?.width) ?? 0
                            Behavior on x { NumberAnimation { duration: OneUIMotion.medium1; easing.bezierCurve: OneUIMotion.springGentle } }
                            Behavior on width { NumberAnimation { duration: OneUIMotion.medium1; easing.bezierCurve: OneUIMotion.springGentle } }
                        }

                        Row {
                            id: tabRow
                            x: 4
                            y: 4
                            Repeater {
                                model: ["Processes", "Performance"]
                                Item {
                                    id: tabItem
                                    required property int index
                                    required property string modelData
                                    width: tabText.implicitWidth + 28
                                    height: 28
                                    Component.onCompleted: { if (index === 0) tab0 = tabItem; else tab1 = tabItem }
                                    Text {
                                        id: tabText
                                        anchors.centerIn: parent
                                        text: tabItem.modelData
                                        color: root.tab === tabItem.index ? root.cPrimary : root.cText
                                        font.family: QsConfig.Config.appearance.fontFamily
                                        font.pixelSize: QsConfig.Appearance.fontSize.m
                                        font.weight: root.tab === tabItem.index ? Font.DemiBold : Font.Medium
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.tab = tabItem.index
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

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

                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: root.tab

                    // ── Processes ─────────────────────────────────
                    ColumnLayout {
                        spacing: 10

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
                                    OneUIIcon { name: "ic_search_24dp"; size: 14; color: root.cSubText }
                                    QQC.TextField {
                                        id: search
                                        Layout.fillWidth: true
                                        background: null
                                        padding: 0
                                        placeholderText: "Search processes"
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
                            Chip { label: "Memory"; on: root.sortKey === "mem"; onClicked: root.sortKey = "mem" }
                            Chip { label: "Name"; on: root.sortKey === "name"; onClicked: root.sortKey = "name" }
                            Chip { label: "Group"; on: root.grouped; onClicked: root.grouped = !root.grouped }
                            Chip { label: "Mine"; on: root.onlyMine; onClicked: root.onlyMine = !root.onlyMine }
                        }

                        // Column header
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 14
                            Layout.rightMargin: 14
                            spacing: 8
                            Text {
                                Layout.fillWidth: true
                                text: rows.count + " processes"
                                color: root.cSubText
                                font.family: QsConfig.Config.appearance.fontFamily
                                font.pixelSize: QsConfig.Appearance.fontSize.xs
                                font.weight: Font.Medium
                            }
                            Text {
                                Layout.preferredWidth: 72
                                horizontalAlignment: Text.AlignRight
                                text: "CPU " + Math.round(root.usage.cpuPerc * 100) + "%"
                                color: root.cSubText
                                font.family: QsConfig.Config.appearance.fontFamily
                                font.pixelSize: QsConfig.Appearance.fontSize.xs
                                font.weight: Font.Medium
                            }
                            Text {
                                Layout.preferredWidth: 88
                                horizontalAlignment: Text.AlignRight
                                text: "Memory " + Math.round(root.usage.memPerc * 100) + "%"
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
                                height: selected ? 52 + 46 + 48 : 52
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
                                    onClicked: {
                                    root.selectedKey = row.selected ? "" : row.key
                                    if (!row.selected) QsServices.ProcessList.inspect(row.pidList[0])
                                }
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
                                            text: row.count > 1 ? (row.count + " processes") : ("PID " + row.pidList[0] + "  ·  " + row.user)
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

                                // Details of the (first) process
                                Column {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.topMargin: 52
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 14
                                    spacing: 2
                                    opacity: row.selected ? 1 : 0
                                    visible: opacity > 0
                                    Behavior on opacity { NumberAnimation { duration: OneUIMotion.short4 } }
                                    readonly property bool ready: QsServices.ProcessList.detailPid === row.pidList[0]
                                    Text {
                                        width: parent.width
                                        text: parent.ready && QsServices.ProcessList.detailCmd ? QsServices.ProcessList.detailCmd : row.name
                                        elide: Text.ElideMiddle
                                        color: root.cText
                                        font.family: QsConfig.Config.appearance.fontFamily
                                        font.pixelSize: QsConfig.Appearance.fontSize.xs
                                    }
                                    Text {
                                        width: parent.width
                                        text: parent.ready ? ("Started: " + QsServices.ProcessList.detailStarted + "  ·  Open files: " + QsServices.ProcessList.detailFds) : ""
                                        elide: Text.ElideRight
                                        color: root.cSubText
                                        font.family: QsConfig.Config.appearance.fontFamily
                                        font.pixelSize: QsConfig.Appearance.fontSize.xs
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
                                        label: row.count > 1 ? "End all" : "End"
                                        tint: root.cPrimary
                                        onClicked: { QsServices.ProcessList.terminate(row.pidList); root.selectedKey = "" }
                                    }
                                    ActionButton {
                                        label: "Force stop"
                                        tint: root.cError
                                        filled: true
                                        onClicked: { QsServices.ProcessList.kill(row.pidList); root.selectedKey = "" }
                                    }
                                }
                            }
                        }
                    }

                    // ── Performance ───────────────────────────────
                    RowLayout {
                        id: perf
                        spacing: 12

                        // Ethernet and Wi-Fi get a tile each (like Windows); "Network" (all adapters) only when neither is found
                        readonly property var kinds: {
                            const hw = QsServices.HardwareInfo
                            const out = [{ k: "cpu", label: "CPU" }, { k: "mem", label: "Memory" }, { k: "disk", label: "Disk" }]
                            if (hw.hasKind("eth")) out.push({ k: "eth", label: "Ethernet" })
                            if (hw.hasKind("wifi")) out.push({ k: "wifi", label: "Wi-Fi" })
                            if (!hw.hasKind("eth") && !hw.hasKind("wifi")) out.push({ k: "net", label: "Network" })
                            if (root.usage.hasGpu) out.push({ k: "gpu", label: "GPU" })
                            return out
                        }
                        // the selected tile, or CPU when that adapter is gone
                        readonly property string key: kinds.some(x => x.k === root.perfKey) ? root.perfKey : "cpu"

                        function seriesOf(k) {
                            return k === "cpu" ? [root.hCpu] : k === "mem" ? [root.hMem] : k === "gpu" ? [root.hGpu]
                                 : k === "disk" ? [root.hDiskR, root.hDiskW]
                                 : k === "eth" ? [root.hEthD, root.hEthU] : k === "wifi" ? [root.hWifiD, root.hWifiU]
                                 : [root.hNetD, root.hNetU]
                        }
                        function colorsOf(k) {
                            return k === "cpu" ? [root.pywal.primary] : k === "mem" ? [root.pywal.secondary] : k === "gpu" ? [root.pywal.warning]
                                 : k === "disk" ? [root.pywal.primary, root.pywal.secondary] : [root.pywal.success, root.pywal.info]
                        }
                        function valueOf(k) {
                            const u = root.usage
                            return k === "cpu" ? Math.round(u.cpuPerc * 100) + "%"
                                 : k === "mem" ? Math.round(u.memPerc * 100) + "%"
                                 : k === "gpu" ? Math.round(u.gpuUsage) + "%"
                                 : k === "disk" ? root.formatRate(QsServices.DiskIO.readSpeed + QsServices.DiskIO.writeSpeed)
                                 : k === "eth" || k === "wifi" ? root.formatRate(QsServices.HardwareInfo.rate(k).rx + QsServices.HardwareInfo.rate(k).tx)
                                 : root.formatRate(u.downloadSpeed + u.uploadSpeed)
                        }
                        function statsOf(k) {
                            const u = root.usage, gb = 1073741824
                            if (k === "cpu") return [
                                ["Usage", Math.round(u.cpuPerc * 100) + "%"],
                                ["Cores", String(QsServices.ProcessList.cores)],
                                ["Processes", String(QsServices.ProcessList.processes.length)]]
                            if (k === "mem") return [
                                ["In use", (u.memUsed / gb).toFixed(1) + " GB"],
                                ["Total", (u.memTotal / gb).toFixed(1) + " GB"],
                                ["Free", ((u.memTotal - u.memUsed) / gb).toFixed(1) + " GB"]]
                            if (k === "gpu") return [
                                ["Usage", Math.round(u.gpuUsage) + "%"],
                                ["Temperature", u.gpuTemp > 0 ? Math.round(u.gpuTemp) + " °C" : "—"],
                                ["VRAM", u.gpuMemTotal > 0 ? (u.gpuMemUsed / 1024).toFixed(1) + " / " + (u.gpuMemTotal / 1024).toFixed(1) + " GB" : "—"]]
                            if (k === "disk") return [
                                ["Read", root.formatRate(QsServices.DiskIO.readSpeed)],
                                ["Write", root.formatRate(QsServices.DiskIO.writeSpeed)],
                                ["Used", Math.round(u.diskPerc * 100) + "%"]]
                            if (k === "eth" || k === "wifi") {
                                const r = QsServices.HardwareInfo.rate(k), a = QsServices.HardwareInfo.first(k)
                                return [
                                    ["Download", root.formatRate(r.rx)],
                                    ["Upload", root.formatRate(r.tx)],
                                    k === "eth" ? ["Link speed", a && a.speed > 0 ? (a.speed >= 1000 ? a.speed / 1000 + " Gbps" : a.speed + " Mbps") : "—"]
                                                : ["Signal", QsServices.Network.connected ? QsServices.Network.signalStrength + "%" : "—"]]
                            }
                            return [
                                ["Download", root.formatRate(u.downloadSpeed)],
                                ["Upload", root.formatRate(u.uploadSpeed)]]
                        }

                        // PCIe: GT/s per lane -> generation and usable MB/s per lane (after encoding overhead)
                        readonly property var pcieGen: ({ "2.5": [1, 250], "5": [2, 500], "8": [3, 985], "16": [4, 1969], "32": [5, 3938], "64": [6, 7563] })
                        function sizeText(bytes) {
                            return bytes >= 1e12 ? (bytes / 1e12).toFixed(bytes >= 1e13 ? 0 : 1) + " TB" : Math.round(bytes / 1e9) + " GB"
                        }
                        function mbText(mb) { return mb >= 1000 ? "~" + (mb / 1000).toFixed(1) + " GB/s" : "~" + mb + " MB/s" }
                        function linkText(link) {
                            const p = link.split(":")
                            if (p[0] === "pcie") {
                                const g = pcieGen[String(parseFloat(p[1]))], w = Number(p[2])
                                return g ? "PCIe " + g[0] + ".0 x" + w + " (" + mbText(g[1] * w) + " max)" : "PCIe x" + w
                            }
                            if (p[0] === "sata") { const gb = parseFloat(p[1]); return "SATA " + gb + " Gbps (" + mbText(Math.round(gb * 100)) + " max)" }
                            return p[0] === "usb" ? "USB" : ""
                        }
                        function diskKind(d) { return d.name.startsWith("nvme") ? "NVMe SSD" : d.rotational ? "HDD" : "SSD" }
                        function diskLine(d) {
                            const bits = [d.model || "—", sizeText(d.size)]
                            if (d.rotational) bits.push(d.rpm > 1 ? d.rpm + " RPM" : "RPM unknown")
                            const l = linkText(d.link)
                            if (l) bits.push(l)
                            return bits.join(" · ")
                        }
                        // [label, value] rows under the stats: what the hardware is
                        function detailsOf(k) {
                            const hw = QsServices.HardwareInfo, c = hw.cpu, rows = []
                            if (k === "cpu") {
                                if (c["Model name"]) rows.push(["Processor", c["Model name"]])
                                const sockets = c["Socket(s)"], cores = c["Core(s) per socket"], threads = c["Thread(s) per core"]
                                if (cores) rows.push(["Cores / threads", sockets * cores + " / " + sockets * cores * threads])
                                if (hw.cpuMhz > 0) rows.push(["Current speed", (hw.cpuMhz / 1000).toFixed(2) + " GHz"])
                                if (c["CPU max MHz"]) rows.push(["Max speed", (parseFloat(c["CPU max MHz"]) / 1000).toFixed(2) + " GHz"])
                                for (const f of ["L2", "L3"]) if (c[f]) rows.push([f + " cache", c[f]])
                                if (c["Virtualization"]) rows.push(["Virtualization", c["Virtualization"]])
                            } else if (k === "gpu") {
                                for (const g of hw.gpus)
                                    rows.push([g.driver || "GPU", (g.name || "Unknown GPU") + (g.vram > 0 ? " · " + Math.round(g.vram / 1073741824) + " GB" : "")])
                            } else if (k === "disk") {
                                for (const d of hw.disks) rows.push([d.name + " · " + diskKind(d), diskLine(d)])
                            } else if (k === "eth" || k === "wifi") {
                                for (const a of hw.ifaces) {
                                    if (a.kind !== k) continue
                                    rows.push(["Adapter", a.name + " (" + (a.state === "up" ? "connected" : "disconnected") + ")"])
                                    if (k === "wifi" && QsServices.Network.connected) {
                                        const f = QsServices.Network.active?.frequency ?? 0
                                        rows.push(["Network", QsServices.Network.ssid + (f ? " · " + (f > 5900 ? "6" : f > 4000 ? "5" : "2.4") + " GHz" : "")])
                                    }
                                    if (a.ip) rows.push(["IPv4", a.ip])
                                }
                            }
                            return rows
                        }
                        readonly property string kindLabel: kinds.find(x => x.k === perf.key)?.label ?? ""

                        // Resource list
                        ColumnLayout {
                            Layout.preferredWidth: 190
                            Layout.maximumWidth: 190
                            Layout.fillHeight: true
                            spacing: 8

                            Repeater {
                                model: perf.kinds

                                Rectangle {
                                    id: tile
                                    required property var modelData
                                    readonly property bool sel: perf.key === modelData.k
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: perf.kinds.length > 4 ? 64 : 74
                                    radius: QsConfig.Appearance.radius.m
                                    color: sel ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.18)
                                               : (tileMouse.containsMouse ? Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.07) : root.cCard)
                                    Behavior on color { ColorAnimation { duration: OneUIMotion.short3 } }
                                    scale: tileMouse.pressed ? 0.98 : 1
                                    Behavior on scale { NumberAnimation { duration: OneUIMotion.short2 } }

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 4
                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text {
                                                Layout.fillWidth: true
                                                text: tile.modelData.label
                                                color: root.cText
                                                font.family: QsConfig.Config.appearance.fontFamily
                                                font.pixelSize: QsConfig.Appearance.fontSize.m
                                                font.weight: Font.DemiBold
                                            }
                                            Text {
                                                text: perf.valueOf(tile.modelData.k)
                                                color: root.cSubText
                                                font.family: QsConfig.Config.appearance.fontFamily
                                                font.pixelSize: QsConfig.Appearance.fontSize.s
                                            }
                                        }
                                        HistoryGraph {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            grid: false
                                            lineWidth: 1.5
                                            maxValue: (["cpu", "mem", "gpu"].includes(tile.modelData.k)) ? 100 : 0
                                            series: perf.seriesOf(tile.modelData.k)
                                            colors: perf.colorsOf(tile.modelData.k)
                                        }
                                    }
                                    MouseArea {
                                        id: tileMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.perfKey = tile.modelData.k
                                    }
                                }
                            }
                            Item { Layout.fillHeight: true }
                        }

                        // Detail
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: QsConfig.Appearance.radius.m
                            color: root.cCard

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: perf.kindLabel
                                        color: root.cText
                                        font.family: QsConfig.Config.appearance.fontFamily
                                        font.pixelSize: QsConfig.Appearance.fontSize.xxl
                                        font.weight: Font.DemiBold
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: perf.valueOf(perf.key)
                                        color: root.cPrimary
                                        font.family: QsConfig.Config.appearance.fontFamily
                                        font.pixelSize: QsConfig.Appearance.fontSize.xxl
                                        font.weight: Font.DemiBold
                                    }
                                }

                                Text {
                                    text: "Last 60 seconds"
                                    color: root.cSubText
                                    font.family: QsConfig.Config.appearance.fontFamily
                                    font.pixelSize: QsConfig.Appearance.fontSize.xs
                                }

                                HistoryGraph {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    maxValue: (["cpu", "mem", "gpu"].includes(perf.key)) ? 100 : 0
                                    series: perf.seriesOf(perf.key)
                                    colors: perf.colorsOf(perf.key)
                                }

                                // key / value stats
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 16
                                    Repeater {
                                        model: perf.statsOf(perf.key)
                                        ColumnLayout {
                                            required property var modelData
                                            spacing: 0
                                            Text {
                                                text: parent.modelData[0]
                                                color: root.cSubText
                                                font.family: QsConfig.Config.appearance.fontFamily
                                                font.pixelSize: QsConfig.Appearance.fontSize.xs
                                            }
                                            Text {
                                                text: parent.modelData[1]
                                                color: root.cText
                                                font.family: QsConfig.Config.appearance.fontFamily
                                                font.pixelSize: QsConfig.Appearance.fontSize.l
                                                font.weight: Font.DemiBold
                                            }
                                        }
                                    }
                                    Item { Layout.fillWidth: true }
                                }

                                // what the hardware is
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 3
                                    Repeater {
                                        model: perf.detailsOf(perf.key)
                                        RowLayout {
                                            required property var modelData
                                            Layout.fillWidth: true
                                            spacing: 10
                                            Text {
                                                Layout.preferredWidth: 120
                                                text: parent.modelData[0]
                                                elide: Text.ElideRight
                                                color: root.cSubText
                                                font.family: QsConfig.Config.appearance.fontFamily
                                                font.pixelSize: QsConfig.Appearance.fontSize.xs
                                            }
                                            Text {
                                                Layout.fillWidth: true
                                                text: parent.modelData[1]
                                                elide: Text.ElideRight
                                                color: root.cText
                                                font.family: QsConfig.Config.appearance.fontFamily
                                                font.pixelSize: QsConfig.Appearance.fontSize.s
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
}
