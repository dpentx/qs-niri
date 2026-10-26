import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10 as QQC
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../../config" as QsConfig
import "../../services" as QsServices
import "../../components"

PanelWindow {
    id: root

    // Blur only while the panel is fully shown: the region is a fixed rect and would otherwise be
    // drawn before the panel has faded in (and stay after it has gone).
    BackgroundEffect.blurRegion: QsConfig.Appearance.blur && shouldShow && panel.opacity > 0.98 && Math.abs(panel.scale - 1) < 0.002 && Math.abs(panel.revealOffset) < 0.5 ? _blur : null
    Region { id: _blur; item: blurSurface; radius: blurSurface.radius }

    property bool shouldShow: false
    property string query: ""
    property bool showAll: false   // empty search: list every app instead of just the favorites
    property int selectedIndex: 0
    readonly property int gridColumns: 5

    readonly property var config: QsConfig.Config
    readonly property var pywal: QsServices.Pywal
    readonly property color cSurface: pywal.surfaceContainerHighest
    readonly property color cSurfaceContainer: pywal.surfaceContainerHigh
    readonly property color cSurfaceContainerHigh: pywal.surfaceContainerHigh
    readonly property color cPrimary: pywal.primary
    readonly property color cText: pywal.foreground
    readonly property color cSubText: pywal.onSurfaceMuted
    readonly property color cBorder: pywal.outlineVariant
    readonly property var terminalCommand: Array.isArray(config.launcher.terminalCommand) && config.launcher.terminalCommand.length > 0
        ? config.launcher.terminalCommand
        : ["foot"]

    readonly property var actionEntries: [
        {
            id: "action-terminal",
            name: "Open Terminal",
            comment: "Launch your configured terminal",
            glyph: "mdi_console",
            type: "action",
            onTriggered: () => Quickshell.execDetached(terminalCommand)
        },
        {
            id: "action-files",
            name: "Open Files",
            comment: "Open your home directory",
            glyph: "mdi_folder_outline",
            type: "action",
            onTriggered: () => root.openFiles()
        },
        {
            id: "action-screenshots",
            name: "Open Captures",
            comment: "Browse screenshots and recordings",
            glyph: "ic_camera",
            type: "action",
            onTriggered: () => QsServices.Screenshot.openScreenshotsFolder()
        },
        {
            id: "action-network",
            name: "Network Settings",
            comment: "Open nm-connection-editor",
            glyph: "sec_ic_wifi_signal_4",
            type: "action",
            onTriggered: () => Quickshell.execDetached(["nm-connection-editor"])
        }
    ]

    // Built-in file manager: toggled through its touch-file like the other panels.
    function openFiles() {
        if (config.features.files)
            Quickshell.execDetached(["touch", "/tmp/qs-files"])
        else
            Quickshell.execDetached(["xdg-open", Quickshell.env("HOME")])
    }
    readonly property var filesEntry: ({
        id: "app-files", name: "Files", comment: "File manager",
        glyph: "mdi_folder_outline", type: "action",
        iconFile: Qt.resolvedUrl("../../assets/icons/files/folder.svg"),
        onTriggered: () => root.openFiles()
    })

    readonly property var favoriteApps: {
        const favorites = config.launcher.favorites ?? []
        const apps = DesktopEntries.applications.values ?? []
        return favorites
            .map(favoriteId => apps.find(entry => entry.id === favoriteId || entry.name === favoriteId))
            .filter(entry => !!entry)
    }

    readonly property var appEntries: {
        const apps = DesktopEntries.applications.values ?? []
        const q = query.trim().toLowerCase()
        const favoriteIds = (favoriteApps ?? []).map(entry => entry.id)

        function score(entry) {
            const name = (entry.name ?? "").toLowerCase()
            const genericName = (entry.genericName ?? "").toLowerCase()
            const comment = (entry.comment ?? "").toLowerCase()
            const execString = (entry.execString ?? "").toLowerCase()
            const id = (entry.id ?? "").toLowerCase()
            let rank = 0

            if (!q.length)
                rank = favoriteIds.includes(entry.id) ? 200 : 100
            else if (name === q)
                rank = 1000
            else if (name.startsWith(q))
                rank = 900
            else if (genericName.startsWith(q) || id.startsWith(q))
                rank = 760
            else if (name.includes(q))
                rank = 680
            else if (genericName.includes(q) || comment.includes(q))
                rank = 520
            else if (execString.includes(q))
                rank = 420

            if (favoriteIds.includes(entry.id))
                rank += 90

            return rank
        }

        const filtered = apps
            .map(entry => ({ entry, rank: score(entry) }))
            .filter(item => item.rank > 0)
            .sort((left, right) => {
                if (right.rank !== left.rank)
                    return right.rank - left.rank
                return (left.entry.name ?? "").localeCompare(right.entry.name ?? "")
            })
            .slice(0, (showAll && !q.length) ? apps.length : config.launcher.maxResults)
            .map(item => item.entry)

        if (!q.length && filtered.length === 0)
            return (apps ?? []).slice(0, config.launcher.maxResults)

        return filtered
    }

    readonly property var visibleEntries: {
        const q = query.trim()
        if (q.startsWith(">")) {
            const actionQuery = q.slice(1).trim().toLowerCase()
            return actionEntries.filter(entry => {
                if (!actionQuery.length)
                    return true
                return entry.name.toLowerCase().includes(actionQuery) || entry.comment.toLowerCase().includes(actionQuery)
            })
        }

        const withFiles = list => {
            const hit = !q.length || ["files", "file manager", "dosya"].some(w => w.startsWith(q.toLowerCase()))
            return config.features.files && hit ? [filesEntry, ...list] : list
        }

        if (!q.length && !showAll && favoriteApps.length > 0)
            return withFiles(favoriteApps.slice(0, config.launcher.maxResults - 1))

        return withFiles(appEntries)
    }

    // ── Desktop actions ("quick actions" of an app, like a right-click menu) ──
    // Hold Shift or Ctrl on a selected app to list its .desktop actions (new
    // window, new private window, ...). Arrow keys / mouse pick one, Space or
    // Enter runs it. Releasing the key with nothing picked returns to the
    // normal search view; once something is picked the list stays.
    property bool actionMode: false
    property var actionEntry: null
    property int actionIndex: -1
    readonly property var currentActions: {
        if (!actionEntry) return []
        const out = []
        const acts = actionEntry.actions ?? []
        for (let i = 0; i < acts.length; ++i) out.push(acts[i])
        out.push({
            name: QsConfig.Config.isPinned(actionEntry) ? "Unpin from taskbar" : "Pin to taskbar",
            execute: () => QsConfig.Config.togglePin(actionEntry)
        })
        return out
    }

    function canShowActions() {
        const e = visibleEntries[selectedIndex]
        return !!e && e.type !== "action"
    }
    function enterActions() {
        if (!canShowActions()) return
        actionEntry = visibleEntries[selectedIndex]
        actionIndex = -1
        actionMode = true
    }
    function leaveActions() {
        holdTimer.stop()
        actionMode = false
        actionEntry = null
        actionIndex = -1
    }
    function runAction(i) {
        const a = currentActions[i]
        if (!a) return
        a.execute()
        closeLauncher()
    }

    // A modifier must be held briefly before actions show, so ordinary
    // capital-letter typing (Shift+letter) never flashes the actions view.
    Timer {
        id: holdTimer
        interval: 220
        onTriggered: root.enterActions()
    }

    function closeLauncher() {
        leaveActions()
        shouldShow = false
        query = ""
        showAll = false
        selectedIndex = 0
    }

    function openLauncher() {
        shouldShow = true
        selectedIndex = 0
        searchField.forceActiveFocus()
    }

    function launchEntry(entry) {
        if (!entry)
            return

        if (entry.type === "action") {
            entry.onTriggered()
            closeLauncher()
            return
        }

        if (entry.runInTerminal) {
            Quickshell.execDetached({
                command: [...terminalCommand, ...entry.command],
                workingDirectory: entry.workingDirectory
            })
        } else {
            Quickshell.execDetached({
                command: entry.command,
                workingDirectory: entry.workingDirectory
            })
        }

        closeLauncher()
    }

    onShouldShowChanged: {
       if (shouldShow) {
           selectedIndex = 0
            Qt.callLater(() => {
              searchField.clear()
              searchField.forceActiveFocus()
           })
        }
    }

    onVisibleEntriesChanged: {
        if (actionMode) leaveActions()
        if (selectedIndex >= visibleEntries.length)
            selectedIndex = Math.max(0, visibleEntries.length - 1)
    }

    screen: Quickshell.screens[0]
    // DeX app drawer: sits on the taskbar, bottom-left, grows upwards
    exclusionMode: ExclusionMode.Ignore
    anchors {
        bottom: true
        left: true
    }
    margins {
        bottom: (config.bar.height ?? 48) + 8
        left: 8
    }
    implicitWidth: config.launcher.width
    implicitHeight: shouldShow || panel.opacity > 0 ? panelColumn.implicitHeight + 40 : 0
    color: "transparent"
    visible: config.launcher.enabled && (shouldShow || panel.opacity > 0)

    // Overlay, so the click-outside dismiss layer (Top) stays beneath the panel
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shouldShow ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    FocusScope {
        id: panel
        anchors.fill: parent
        property real revealOffset: shouldShow ? 0 : 20
        scale: shouldShow ? 1.0 : 0.97
        opacity: shouldShow ? 1.0 : 0.0
        focus: root.shouldShow
        transform: Translate { y: panel.revealOffset }

        Keys.onEscapePressed: root.closeLauncher()
        Keys.onDownPressed: root.selectedIndex = Math.min(root.selectedIndex + root.gridColumns, root.visibleEntries.length - 1)
        Keys.onUpPressed: root.selectedIndex = Math.max(root.selectedIndex - root.gridColumns, 0)
        Keys.onRightPressed: root.selectedIndex = Math.min(root.selectedIndex + 1, root.visibleEntries.length - 1)
        Keys.onLeftPressed: root.selectedIndex = Math.max(root.selectedIndex - 1, 0)
        Keys.onReturnPressed: root.launchEntry(root.visibleEntries[root.selectedIndex])
        Keys.onEnterPressed: root.launchEntry(root.visibleEntries[root.selectedIndex])

        Behavior on scale {
            NumberAnimation { duration: 240; easing.bezierCurve: [0.22, 1.0, 0.36, 1.0] }
        }

        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
        }

        Behavior on revealOffset {
            NumberAnimation { duration: 260; easing.bezierCurve: [0.05, 0.7, 0.1, 1.0] }
        }

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
                id: panelColumn
                anchors.fill: parent
                anchors.margins: 18
                spacing: 16

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: root.actionMode ? `${root.actionEntry?.name ?? ""} · Actions`
                            : query.trim().startsWith(">") ? "Quick actions" : (query.trim().length ? "Best matches" : (root.showAll ? "All apps" : "Favorites"))
                        font.family: QsConfig.Config.appearance.fontFamily
                        font.pixelSize: QsConfig.Appearance.fontSize.l
                        font.weight: Font.DemiBold
                        color: root.cText
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        visible: !root.actionMode && !query.trim().length && root.favoriteApps.length > 0
                        text: root.showAll ? "‹ Favorites" : "All apps ›"
                        font.family: QsConfig.Config.appearance.fontFamily
                        font.pixelSize: QsConfig.Appearance.fontSize.s
                        font.weight: Font.DemiBold
                        color: root.cText

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { root.showAll = !root.showAll; root.selectedIndex = 0 }
                        }
                    }

                    Text {
                        text: root.actionMode ? "Space / Enter to run  ·  Esc to go back"
                            : `${root.visibleEntries.length} item${root.visibleEntries.length === 1 ? "" : "s"}`
                        font.family: QsConfig.Config.appearance.fontFamily
                        font.pixelSize: QsConfig.Appearance.fontSize.s
                        color: root.cSubText
                    }
                }

                GridView {
                    id: appGrid
                    visible: !root.actionMode
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(4 * cellHeight + 12, Math.ceil(root.visibleEntries.length / root.gridColumns) * cellHeight + 12)
                    clip: true
                    cellWidth: Math.floor(width / root.gridColumns)
                    cellHeight: 108
                    boundsBehavior: Flickable.StopAtBounds
                    model: root.visibleEntries

                    QQC.ScrollBar.vertical: QQC.ScrollBar {
                        policy: QQC.ScrollBar.AsNeeded
                    }

                    delegate: Item {
                        id: delegateRoot
                        required property var modelData
                        required property int index

                        width: appGrid.cellWidth
                        height: appGrid.cellHeight

                        readonly property bool isAction: modelData.type === "action"
                        readonly property bool isSelected: root.selectedIndex === index

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 4
                            radius: QsConfig.Appearance.radius.l
                            color: delegateRoot.isSelected
                                ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.16)
                                : (hovered.hovered ? root.cSurfaceContainerHigh : "transparent")

                            Behavior on color { ColorAnimation { duration: 160 } }

                            scale: hovered.hovered ? 1.03 : 1.0
                            Behavior on scale { NumberAnimation { duration: 180; easing.bezierCurve: [0.22, 1.0, 0.36, 1.0] } }

                            HoverHandler { id: hovered }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.topMargin: 14
                                anchors.bottomMargin: 10
                                anchors.leftMargin: 6
                                anchors.rightMargin: 6
                                spacing: 8

                                // Icon — real app icon via the desktop entry's
                                // icon theme lookup, with a lettered-badge
                                // fallback (matches the pattern already used
                                // for media-player tabs elsewhere in the shell)
                                Item {
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.preferredWidth: 52
                                    Layout.preferredHeight: 52

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: delegateRoot.isAction ? width / 2 : width * 0.32
                                        color: Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, delegateRoot.isAction ? 0.16 : 0.10)
                                        visible: !delegateRoot.modelData.iconFile && (delegateRoot.isAction || appIcon.status !== Image.Ready)

                                        OneUIIcon {
                                            anchors.centerIn: parent
                                            visible: delegateRoot.isAction
                                            name: delegateRoot.modelData.glyph ?? "ic_apps_expressive"
                                            size: 26
                                            color: root.cPrimary
                                        }
                                        Text {
                                            anchors.centerIn: parent
                                            visible: !delegateRoot.isAction
                                            text: (delegateRoot.modelData.name ?? "?").slice(0, 1).toUpperCase()
                                            font.family: QsConfig.Config.appearance.fontFamily
                                            font.pixelSize: 20
                                            font.weight: Font.DemiBold
                                            color: root.cPrimary
                                        }
                                    }

                                    Image {
                                        anchors.fill: parent
                                        visible: !!delegateRoot.modelData.iconFile
                                        source: delegateRoot.modelData.iconFile ?? ""
                                        sourceSize: Qt.size(104, 104)
                                        fillMode: Image.PreserveAspectFit
                                    }

                                    SquircleIcon {
                                        id: appIcon
                                        size: parent.width
                                        visible: !delegateRoot.isAction && status === Image.Ready
                                        tileColor: Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.08)
                                        source: delegateRoot.isAction ? "" : Quickshell.iconPath(delegateRoot.modelData.icon ?? "")
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignHCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    text: delegateRoot.modelData.name ?? "Unknown"
                                    font.family: QsConfig.Config.appearance.fontFamily
                                    font.pixelSize: QsConfig.Appearance.fontSize.m
                                    font.weight: Font.Medium
                                    color: root.cText
                                    elide: Text.ElideRight
                                    maximumLineCount: 2
                                    wrapMode: Text.WordWrap
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: root.selectedIndex = delegateRoot.index
                                onClicked: root.launchEntry(delegateRoot.modelData)
                            }
                        }
                    }
                }

                // Desktop actions of the selected app
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.actionMode
                    spacing: 6

                    Repeater {
                        model: root.currentActions

                        Rectangle {
                            id: actionRow
                            required property var modelData
                            required property int index
                            readonly property bool picked: root.actionIndex === index

                            Layout.fillWidth: true
                            Layout.preferredHeight: 46
                            radius: QsConfig.Appearance.radius.m
                            color: picked ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.20)
                                          : (rowMouse.containsMouse ? root.cSurfaceContainerHigh : root.cSurfaceContainer)

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14
                                spacing: 12

                                Image {
                                    Layout.preferredWidth: 22
                                    Layout.preferredHeight: 22
                                    sourceSize: Qt.size(44, 44)
                                    source: actionRow.modelData.icon ? Quickshell.iconPath(actionRow.modelData.icon, true) : ""
                                    visible: status === Image.Ready
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: actionRow.modelData.name
                                    elide: Text.ElideRight
                                    font.family: QsConfig.Config.appearance.fontFamily
                                    font.pixelSize: QsConfig.Appearance.fontSize.l
                                    font.weight: actionRow.picked ? Font.DemiBold : Font.Medium
                                    color: root.cText
                                }
                                Text {
                                    visible: actionRow.picked
                                    text: "Space"
                                    font.family: QsConfig.Config.appearance.fontFamily
                                    font.pixelSize: QsConfig.Appearance.fontSize.s
                                    color: root.cSubText
                                }
                            }

                            MouseArea {
                                id: rowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: root.actionIndex = actionRow.index
                                onClicked: root.runAction(actionRow.index)
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: root.visibleEntries.length === 0
                    text: query.trim().startsWith(">") ? "No actions matched." : "No applications matched your search."
                    horizontalAlignment: Text.AlignHCenter
                    font.family: QsConfig.Config.appearance.fontFamily
                    font.pixelSize: QsConfig.Appearance.fontSize.m
                    color: root.cSubText
                }

                // Search sits at the bottom, next to the taskbar button (DeX)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    radius: QsConfig.Appearance.radius.l
                    color: root.cSurfaceContainer
                    border.width: 1
                    border.color: Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.18)

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.04)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        OneUIIcon {
                            name: query.trim().startsWith(">") ? "ic_chevron_right" : "ic_search_24dp"
                            size: 22
                            color: root.cPrimary
                        }

                        QQC.TextField {
                            id: searchField
                            Layout.fillWidth: true
                            color: root.cText
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: QsConfig.Appearance.fontSize.xl
                            placeholderText: 'Search apps or type ">" for actions'
                            placeholderTextColor: root.cSubText
                            background: Item {}
                            selectByMouse: true

                            onTextChanged: {
                                root.query = text
                                root.selectedIndex = 0
                            }

                            Keys.onPressed: event => {
                                const isMod = event.key === Qt.Key_Shift || event.key === Qt.Key_Control
                                const arrow = event.key === Qt.Key_Left || event.key === Qt.Key_Right
                                    || event.key === Qt.Key_Up || event.key === Qt.Key_Down
                                const modHeld = (event.modifiers & (Qt.ShiftModifier | Qt.ControlModifier)) !== 0
                                const n = root.currentActions.length

                                if (!root.actionMode) {
                                    if (isMod) {
                                        if (!holdTimer.running && !event.isAutoRepeat) holdTimer.start()
                                    } else if (arrow && modHeld) {
                                        holdTimer.restart()   // new selection, modifier still down
                                    } else {
                                        holdTimer.stop()      // typing: not an actions request
                                    }
                                    return
                                }

                                if (isMod) return
                                switch (event.key) {
                                case Qt.Key_Down:
                                case Qt.Key_Right:
                                    root.actionIndex = Math.min(root.actionIndex + 1, n - 1)
                                    event.accepted = true
                                    break
                                case Qt.Key_Up:
                                case Qt.Key_Left:
                                    root.actionIndex = Math.max(root.actionIndex - 1, 0)
                                    event.accepted = true
                                    break
                                case Qt.Key_Space:
                                    if (root.actionIndex >= 0) root.runAction(root.actionIndex)
                                    event.accepted = true
                                    break
                                case Qt.Key_Return:
                                case Qt.Key_Enter:
                                    if (root.actionIndex >= 0) {
                                        root.runAction(root.actionIndex)
                                        event.accepted = true
                                    }   // nothing picked: Enter launches the app as usual
                                    break
                                case Qt.Key_Escape:
                                    root.leaveActions()
                                    event.accepted = true
                                    break
                                default:
                                    root.leaveActions()   // typing resumes normal search
                                }
                            }

                            Keys.onReleased: event => {
                                if (event.key !== Qt.Key_Shift && event.key !== Qt.Key_Control) return
                                if (event.modifiers & (Qt.ShiftModifier | Qt.ControlModifier)) return  // other one still held
                                holdTimer.stop()
                                if (root.actionMode && root.actionIndex < 0)
                                    root.leaveActions()
                            }
                        }

                        Text {
                            visible: query.length > 0
                            text: "Esc"
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: QsConfig.Appearance.fontSize.s
                            color: root.cSubText
                        }
                    }
                }

            }
        }

        // NOTE: previously had a full-window MouseArea accepting
        // Qt.RightButton here to close the launcher. Any real RightButton
        // mouse event reaching a quickshell PanelWindow can crash the
        // process (Qt's context-menu synthesis segfaults on this Qt/
        // Quickshell build — see qs-niri issue tracker). Escape already
        // closes the launcher (line 219), so this isn't needed.
    }
}
