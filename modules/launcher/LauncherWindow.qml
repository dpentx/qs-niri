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

    property bool shouldShow: false
    property string query: ""
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
            glyph: "󰆍",
            type: "action",
            onTriggered: () => Quickshell.execDetached(terminalCommand)
        },
        {
            id: "action-files",
            name: "Open Files",
            comment: "Open your home directory",
            glyph: "󰉋",
            type: "action",
            onTriggered: () => Quickshell.execDetached(["xdg-open", Quickshell.env("HOME")])
        },
        {
            id: "action-screenshots",
            name: "Open Captures",
            comment: "Browse screenshots and recordings",
            glyph: "󰄄",
            type: "action",
            onTriggered: () => QsServices.Screenshot.openScreenshotsFolder()
        },
        {
            id: "action-network",
            name: "Network Settings",
            comment: "Open nm-connection-editor",
            glyph: "󰖩",
            type: "action",
            onTriggered: () => Quickshell.execDetached(["nm-connection-editor"])
        }
    ]

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
            .slice(0, config.launcher.maxResults)
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

        if (!q.length && favoriteApps.length > 0)
            return favoriteApps.slice(0, config.launcher.maxResults)

        return appEntries
    }

    function closeLauncher() {
        shouldShow = false
        query = ""
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
        if (selectedIndex >= visibleEntries.length)
            selectedIndex = Math.max(0, visibleEntries.length - 1)
    }

    screen: Quickshell.screens[0]
    anchors {
        top: true
        left: true
    }
    margins {
        top: (config.bar.height ?? 34) + 22
        left: Math.max(0, Math.round((screen.width - root.implicitWidth) / 2))
    }
    implicitWidth: config.launcher.width
    implicitHeight: shouldShow || panel.opacity > 0 ? panelColumn.implicitHeight + 40 : 0
    color: "transparent"
    visible: config.launcher.enabled && (shouldShow || panel.opacity > 0)

    WlrLayershell.keyboardFocus: shouldShow ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    FocusScope {
        id: panel
        anchors.fill: parent
        property real revealOffset: shouldShow ? 0 : -20
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
            anchors.fill: parent
            radius: 20
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

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 62
                    radius: 22
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

                        Text {
                            text: query.trim().startsWith(">") ? "󰘳" : "󰍉"
                            font.family: "Material Design Icons"
                            font.pixelSize: 22
                            color: root.cPrimary
                        }

                        QQC.TextField {
                            id: searchField
                            Layout.fillWidth: true
                            color: root.cText
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: 15
                            placeholderText: 'Search apps or type ">" for actions'
                            placeholderTextColor: root.cSubText
                            background: Item {}
                            selectByMouse: true

                            onTextChanged: {
                                root.query = text
                                root.selectedIndex = 0
                            }
                        }

                        Text {
                            visible: query.length > 0
                            text: "Esc"
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: 11
                            color: root.cSubText
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: query.trim().startsWith(">") ? "Quick actions" : (query.trim().length ? "Best matches" : "Favorites")
                        font.family: QsConfig.Config.appearance.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: root.cText
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: `${root.visibleEntries.length} item${root.visibleEntries.length === 1 ? "" : "s"}`
                        font.family: QsConfig.Config.appearance.fontFamily
                        font.pixelSize: 11
                        color: root.cSubText
                    }
                }

                GridView {
                    id: appGrid
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
                            radius: 20
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
                                        radius: delegateRoot.isAction ? width / 2 : 16
                                        color: Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, delegateRoot.isAction ? 0.16 : 0.10)
                                        visible: delegateRoot.isAction || appIcon.status !== Image.Ready

                                        Text {
                                            anchors.centerIn: parent
                                            text: delegateRoot.isAction
                                                ? (delegateRoot.modelData.glyph ?? "󰣆")
                                                : ((delegateRoot.modelData.name ?? "?").slice(0, 1).toUpperCase())
                                            font.family: delegateRoot.isAction ? "Material Design Icons" : QsConfig.Config.appearance.fontFamily
                                            font.pixelSize: delegateRoot.isAction ? 24 : 20
                                            font.weight: Font.DemiBold
                                            color: root.cPrimary
                                        }
                                    }

                                    IconImage {
                                        id: appIcon
                                        anchors.fill: parent
                                        visible: !delegateRoot.isAction && status === Image.Ready
                                        source: delegateRoot.isAction ? "" : Quickshell.iconPath(delegateRoot.modelData.icon ?? "")
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignHCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    text: delegateRoot.modelData.name ?? "Unknown"
                                    font.family: QsConfig.Config.appearance.fontFamily
                                    font.pixelSize: 12
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

                Text {
                    Layout.fillWidth: true
                    visible: root.visibleEntries.length === 0
                    text: query.trim().startsWith(">") ? "No actions matched." : "No applications matched your search."
                    horizontalAlignment: Text.AlignHCenter
                    font.family: QsConfig.Config.appearance.fontFamily
                    font.pixelSize: 12
                    color: root.cSubText
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
