import QtQuick 6.10
import QtQuick.Layouts 6.10
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Wayland
import "../../config" as QsConfig
import "../../services" as QsServices
import "../../components"
import "../../components/effects"

// File manager. Opened with `touch /tmp/qs-files`.
// Browse, open (xdg-open), copy / cut / paste, rename, new folder, move to trash.
// Not done: drag and drop, tabs, restoring from the trash, multi-select.
PanelWindow {
    id: root

    BackgroundEffect.blurRegion: QsConfig.Appearance.blur ? _blur : null
    Region { id: _blur; item: blurSurface; radius: blurSurface.radius }

    property bool shouldShow: false

    readonly property var config: QsConfig.Config
    readonly property var pywal: QsServices.Pywal
    readonly property color cSurface: pywal.surfaceContainerHighest
    readonly property color cCard: pywal.surfaceContainerHigh
    readonly property color cPrimary: pywal.primary
    readonly property color cText: pywal.foreground
    readonly property color cSubText: pywal.onSurfaceMuted

    readonly property string home: Quickshell.env("HOME")
    property string path: home
    property var backStack: []
    property var forwardStack: []

    property bool gridView: true
    property bool showHidden: false
    property string filter: ""

    // selection (one item) and clipboard
    property string selPath: ""
    property string selName: ""
    property bool selIsDir: false
    property string clipPath: ""
    property bool clipCut: false

    // "" | "rename" | "newfolder"
    property string prompt: ""

    readonly property var places: [
        { name: "Home",      dir: home,                         icon: "mdi_harddisk" },
        { name: "Desktop",   dir: home + "/Desktop",            icon: "mdi_monitor" },
        { name: "Documents", dir: home + "/Documents",          icon: "ic_doc_document" },
        { name: "Downloads", dir: home + "/Downloads",          icon: "ic_arrow_down_24dp" },
        { name: "Pictures",  dir: home + "/Pictures",           icon: "mdi_wallpaper" },
        { name: "Music",     dir: home + "/Music",              icon: "mdi_music_note" },
        { name: "Videos",    dir: home + "/Videos",             icon: "ic_video" },
        { name: "Trash",     dir: home + "/.local/share/Trash/files", icon: "mdi_trash_can_outline" }
    ]

    function close() { shouldShow = false; prompt = "" }

    function clearSelection() { selPath = ""; selName = ""; selIsDir = false }

    function go(p) {
        if (!p || p === path) return
        backStack = backStack.concat([path])
        forwardStack = []
        path = p
        clearSelection()
    }
    function back() {
        if (!backStack.length) return
        forwardStack = forwardStack.concat([path])
        path = backStack[backStack.length - 1]
        backStack = backStack.slice(0, -1)
        clearSelection()
    }
    function forward() {
        if (!forwardStack.length) return
        backStack = backStack.concat([path])
        path = forwardStack[forwardStack.length - 1]
        forwardStack = forwardStack.slice(0, -1)
        clearSelection()
    }
    function up() {
        if (path === "/") return
        const i = path.lastIndexOf("/")
        go(i <= 0 ? "/" : path.slice(0, i))
    }
    function openItem(p, isDir) {
        if (isDir) go(p)
        else Quickshell.execDetached(["xdg-open", p])
    }
    function baseName(p) { return p.slice(p.lastIndexOf("/") + 1) }

    function trashSelected() {
        if (!selPath) return
        Quickshell.execDetached(["gio", "trash", selPath])
        clearSelection()
    }
    // cp/mv refuse to overwrite silently: -n keeps an existing file of that name.
    function paste() {
        if (!clipPath) return
        Quickshell.execDetached(clipCut
            ? ["mv", "-n", "--", clipPath, path + "/"]
            : ["cp", "-rn", "--", clipPath, path + "/"])
        if (clipCut) clipPath = ""
    }
    function copySelected(cut) {
        if (!selPath) return
        clipPath = selPath
        clipCut = cut
    }
    function commitPrompt(text) {
        const t = text.trim()
        // a name must not contain a slash and "." / ".." are not names
        if (!t.length || t.indexOf("/") !== -1 || t === "." || t === "..") return
        if (prompt === "newfolder") {
            Quickshell.execDetached(["mkdir", "--", path + "/" + t])
        } else if (prompt === "rename" && selPath) {
            const dir = selPath.slice(0, selPath.lastIndexOf("/"))
            Quickshell.execDetached(["mv", "-n", "--", selPath, dir + "/" + t])
            clearSelection()
        }
        prompt = ""
        panel.forceActiveFocus()
    }
    function startPrompt(kind) {
        if (kind === "rename" && !selPath) return
        prompt = kind
        promptField.text = kind === "rename" ? selName : ""
        promptField.forceActiveFocus()
        promptField.selectAll()
    }

    function fileKind(name, isDir) {
        if (isDir) return "dir"
        const e = name.slice(name.lastIndexOf(".") + 1).toLowerCase()
        if (["png", "jpg", "jpeg", "webp", "gif", "bmp", "svg"].includes(e)) return "image"
        if (["mp4", "mkv", "webm", "mov", "avi"].includes(e)) return "video"
        if (["mp3", "flac", "ogg", "opus", "wav", "m4a"].includes(e)) return "audio"
        return "file"
    }
    function sizeText(b) {
        if (b < 1024) return b + " B"
        if (b < 1048576) return (b / 1024).toFixed(0) + " KB"
        if (b < 1073741824) return (b / 1048576).toFixed(1) + " MB"
        return (b / 1073741824).toFixed(1) + " GB"
    }

    screen: Quickshell.screens[0]
    anchors { top: true; left: true }
    margins {
        top: (config.bar.height ?? 34) + 22
        left: Math.max(0, Math.round((screen.width - root.implicitWidth) / 2))
    }
    implicitWidth: Math.min(980, screen.width - 80)
    implicitHeight: shouldShow || panel.opacity > 0 ? Math.min(640, screen.height - (config.bar.height ?? 34) - 60) : 0
    color: "transparent"
    visible: shouldShow || panel.opacity > 0

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shouldShow ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    FolderListModel {
        id: folderModel
        folder: "file://" + root.path.split("/").map(encodeURIComponent).join("/")
        showDirs: true
        showFiles: true
        showHidden: root.showHidden
        showDotAndDotDot: false
        showDirsFirst: true
        caseSensitive: false
        sortField: FolderListModel.Name
        nameFilters: root.filter.length ? ["*" + root.filter + "*"] : ["*"]
    }

    FocusScope {
        id: panel
        anchors.fill: parent
        property real revealOffset: shouldShow ? 0 : -20
        scale: shouldShow ? 1.0 : 0.97
        opacity: shouldShow ? 1.0 : 0.0
        focus: root.shouldShow
        transform: Translate { y: panel.revealOffset }

        Behavior on scale { NumberAnimation { duration: OneUIMotion.medium1; easing.bezierCurve: OneUIMotion.springGentle } }
        Behavior on opacity { NumberAnimation { duration: OneUIMotion.short4; easing.type: Easing.OutQuad } }
        Behavior on revealOffset { NumberAnimation { duration: OneUIMotion.medium1; easing.bezierCurve: OneUIMotion.emphasizedDecelerate } }

        Keys.onEscapePressed: root.prompt.length ? (root.prompt = "") : root.close()
        Keys.onPressed: event => {
            if (root.prompt.length) return
            const ctrl = event.modifiers & Qt.ControlModifier
            if (event.key === Qt.Key_Backspace) { root.up(); event.accepted = true }
            else if (event.key === Qt.Key_Delete) { root.trashSelected(); event.accepted = true }
            else if (event.key === Qt.Key_F2) { root.startPrompt("rename"); event.accepted = true }
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { if (root.selPath) root.openItem(root.selPath, root.selIsDir); event.accepted = true }
            else if (ctrl && event.key === Qt.Key_C) { root.copySelected(false); event.accepted = true }
            else if (ctrl && event.key === Qt.Key_X) { root.copySelected(true); event.accepted = true }
            else if (ctrl && event.key === Qt.Key_V) { root.paste(); event.accepted = true }
            else if (ctrl && event.key === Qt.Key_H) { root.showHidden = !root.showHidden; event.accepted = true }
            else if (ctrl && event.key === Qt.Key_N) { root.startPrompt("newfolder"); event.accepted = true }
        }

        AuroraSurface {
            id: blurSurface
            anchors.fill: parent
            radius: QsConfig.Appearance.radius.l
            color: root.cSurface
            borderWidth: 0
            accentColor: root.cPrimary
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 14

            // ── Places ──────────────────────────────────────────
            ColumnLayout {
                Layout.preferredWidth: 168
                Layout.fillHeight: true
                spacing: 4

                Text {
                    text: "Files"
                    Layout.leftMargin: 10
                    Layout.bottomMargin: 8
                    font.family: QsConfig.Config.appearance.fontFamily
                    font.pixelSize: QsConfig.Appearance.fontSize.xxl
                    font.weight: Font.DemiBold
                    color: root.cText
                }

                Repeater {
                    model: root.places

                    Rectangle {
                        id: placeRow
                        required property var modelData
                        readonly property bool active: root.path === modelData.dir
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        radius: 20
                        color: active ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.22)
                            : placeArea.containsMouse ? Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.07) : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 10
                            spacing: 10

                            OneUIIcon {
                                name: placeRow.modelData.icon
                                size: 17
                                color: placeRow.active ? root.cPrimary : root.cText
                            }
                            Text {
                                Layout.fillWidth: true
                                text: placeRow.modelData.name
                                elide: Text.ElideRight
                                font.family: QsConfig.Config.appearance.fontFamily
                                font.pixelSize: QsConfig.Appearance.fontSize.m
                                font.weight: placeRow.active ? Font.DemiBold : Font.Normal
                                color: placeRow.active ? root.cPrimary : root.cText
                            }
                        }

                        MouseArea {
                            id: placeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.go(placeRow.modelData.dir)
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }

            // ── Main area ───────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 10

                // toolbar
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: [
                            { icon: "ic_arrow_back",      on: root.backStack.length > 0,    act: () => root.back() },
                            { icon: "ic_arrow_forward",   on: root.forwardStack.length > 0, act: () => root.forward() },
                            { icon: "ic_arrow_up_24dp",   on: root.path !== "/",            act: () => root.up() }
                        ]
                        Rectangle {
                            id: navBtn
                            required property var modelData
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36
                            radius: 18
                            color: navArea.containsMouse && modelData.on ? Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.1) : "transparent"
                            opacity: modelData.on ? 1 : 0.35
                            OneUIIcon { anchors.centerIn: parent; name: navBtn.modelData.icon; size: 18; color: root.cText }
                            MouseArea {
                                id: navArea
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: navBtn.modelData.on
                                cursorShape: Qt.PointingHandCursor
                                onClicked: navBtn.modelData.act()
                            }
                        }
                    }

                    // breadcrumbs
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        radius: 18
                        color: root.cCard
                        clip: true

                        Row {
                            id: crumbRow
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: 14
                            spacing: 2

                            Repeater {
                                model: {
                                    const parts = root.path.split("/").filter(s => s.length)
                                    const out = [{ label: "/", dir: "/" }]
                                    let acc = ""
                                    for (const s of parts) { acc += "/" + s; out.push({ label: s, dir: acc }) }
                                    return out
                                }
                                Text {
                                    id: crumb
                                    required property var modelData
                                    required property int index
                                    text: (index > 1 ? "›  " : "") + modelData.label
                                    font.family: QsConfig.Config.appearance.fontFamily
                                    font.pixelSize: QsConfig.Appearance.fontSize.m
                                    font.weight: modelData.dir === root.path ? Font.DemiBold : Font.Normal
                                    color: modelData.dir === root.path ? root.cText : root.cSubText
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.go(crumb.modelData.dir)
                                    }
                                }
                            }
                        }
                    }

                    // filter
                    Rectangle {
                        Layout.preferredWidth: 170
                        Layout.preferredHeight: 36
                        radius: 18
                        color: root.cCard

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8
                            OneUIIcon { name: "ic_search_24dp"; size: 15; color: root.cSubText }
                            TextInput {
                                id: filterInput
                                Layout.fillWidth: true
                                clip: true
                                color: root.cText
                                selectionColor: root.cPrimary
                                font.family: QsConfig.Config.appearance.fontFamily
                                font.pixelSize: QsConfig.Appearance.fontSize.m
                                onTextChanged: root.filter = text
                                Keys.onEscapePressed: { text = ""; panel.forceActiveFocus() }
                                Text {
                                    visible: !parent.text.length
                                    text: "Filter"
                                    color: root.cSubText
                                    font: parent.font
                                }
                            }
                        }
                    }

                    // view + hidden toggles
                    Repeater {
                        model: [
                            { label: root.gridView ? "List" : "Grid", on: false, act: () => { root.gridView = !root.gridView } },
                            { label: "Hidden", on: root.showHidden,   act: () => { root.showHidden = !root.showHidden } }
                        ]
                        Rectangle {
                            id: tgl
                            required property var modelData
                            Layout.preferredWidth: tglText.implicitWidth + 24
                            Layout.preferredHeight: 36
                            radius: 18
                            color: modelData.on ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.25) : root.cCard
                            Text {
                                id: tglText
                                anchors.centerIn: parent
                                text: tgl.modelData.label
                                font.family: QsConfig.Config.appearance.fontFamily
                                font.pixelSize: QsConfig.Appearance.fontSize.m
                                color: tgl.modelData.on ? root.cPrimary : root.cText
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: tgl.modelData.act() }
                        }
                    }
                }

                // file view
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: QsConfig.Appearance.radius.m
                    color: Qt.rgba(root.cCard.r, root.cCard.g, root.cCard.b, 0.55)
                    clip: true

                    GridView {
                        id: fileView
                        anchors.fill: parent
                        anchors.margins: 8
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        cellWidth: root.gridView ? 118 : width
                        cellHeight: root.gridView ? 116 : 46
                        model: folderModel

                        MouseArea {
                            // empty space deselects
                            anchors.fill: parent
                            z: -1
                            onClicked: root.clearSelection()
                        }

                        delegate: Item {
                            id: cell
                            required property string fileName
                            required property string filePath
                            required property bool fileIsDir
                            required property var fileModified
                            required property int fileSize
                            readonly property bool selected: root.selPath === filePath
                            readonly property string kind: root.fileKind(fileName, fileIsDir)
                            width: fileView.cellWidth
                            height: fileView.cellHeight

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 2
                                radius: 14
                                color: cell.selected ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.22)
                                    : cellArea.containsMouse ? Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.07) : "transparent"
                            }

                            // icon or thumbnail, shared by both layouts
                            Item {
                                id: thumb
                                width: root.gridView ? 56 : 28
                                height: width
                                x: root.gridView ? Math.round((cell.width - width) / 2) : 14
                                y: root.gridView ? 10 : Math.round((cell.height - height) / 2)

                                Image {
                                    anchors.fill: parent
                                    visible: cell.kind === "image"
                                    source: cell.kind === "image" ? "file://" + cell.filePath.split("/").map(encodeURIComponent).join("/") : ""
                                    sourceSize.width: 128
                                    sourceSize.height: 128
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                }
                                OneUIIcon {
                                    anchors.centerIn: parent
                                    visible: cell.kind !== "image"
                                    size: Math.round(thumb.width * 0.72)
                                    name: cell.kind === "dir" ? "mdi_folder_outline"
                                        : cell.kind === "video" ? "ic_video"
                                        : cell.kind === "audio" ? "mdi_music_note" : "ic_doc_document"
                                    color: cell.kind === "dir" ? root.cPrimary : root.cText
                                }
                            }

                            Text {
                                visible: root.gridView
                                x: 6
                                y: 72
                                width: cell.width - 12
                                height: 36
                                text: cell.fileName
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter
                                font.family: QsConfig.Config.appearance.fontFamily
                                font.pixelSize: QsConfig.Appearance.fontSize.s
                                color: root.cText
                            }

                            RowLayout {
                                visible: !root.gridView
                                x: 56
                                width: cell.width - 70
                                height: cell.height
                                spacing: 12
                                Text {
                                    Layout.fillWidth: true
                                    text: cell.fileName
                                    elide: Text.ElideRight
                                    font.family: QsConfig.Config.appearance.fontFamily
                                    font.pixelSize: QsConfig.Appearance.fontSize.m
                                    color: root.cText
                                }
                                Text {
                                    Layout.preferredWidth: 150
                                    text: Qt.formatDateTime(cell.fileModified, "dd MMM yyyy  HH:mm")
                                    font.family: QsConfig.Config.appearance.fontFamily
                                    font.pixelSize: QsConfig.Appearance.fontSize.s
                                    color: root.cSubText
                                }
                                Text {
                                    Layout.preferredWidth: 70
                                    horizontalAlignment: Text.AlignRight
                                    text: cell.fileIsDir ? "" : root.sizeText(cell.fileSize)
                                    font.family: QsConfig.Config.appearance.fontFamily
                                    font.pixelSize: QsConfig.Appearance.fontSize.s
                                    color: root.cSubText
                                }
                            }

                            MouseArea {
                                id: cellArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.selPath = cell.filePath
                                    root.selName = cell.fileName
                                    root.selIsDir = cell.fileIsDir
                                    panel.forceActiveFocus()
                                }
                                onDoubleClicked: root.openItem(cell.filePath, cell.fileIsDir)
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: folderModel.count === 0
                        text: root.filter.length ? "Nothing matches." : "This folder is empty."
                        font.family: QsConfig.Config.appearance.fontFamily
                        font.pixelSize: QsConfig.Appearance.fontSize.m
                        color: root.cSubText
                    }
                }

                // action bar
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        Layout.fillWidth: true
                        text: root.selPath ? root.selName : `${folderModel.count} item${folderModel.count === 1 ? "" : "s"}`
                        elide: Text.ElideMiddle
                        font.family: QsConfig.Config.appearance.fontFamily
                        font.pixelSize: QsConfig.Appearance.fontSize.s
                        color: root.cSubText
                    }

                    Repeater {
                        model: [
                            { label: "New folder", icon: "ic_add",                 on: true,                act: () => root.startPrompt("newfolder") },
                            { label: "Open",       icon: "mdi_arrow_right",        on: root.selPath !== "", act: () => root.openItem(root.selPath, root.selIsDir) },
                            { label: "Copy",       icon: "abc_ic_menu_copy_mtrl_am_alpha", on: root.selPath !== "", act: () => root.copySelected(false) },
                            { label: "Cut",        icon: "abc_ic_menu_cut_mtrl_alpha",     on: root.selPath !== "", act: () => root.copySelected(true) },
                            { label: "Paste",      icon: "ic_content_paste",       on: root.clipPath !== "", act: () => root.paste() },
                            { label: "Rename",     icon: "ic_edit_square",         on: root.selPath !== "", act: () => root.startPrompt("rename") },
                            { label: "Trash",      icon: "mdi_trash_can_outline",  on: root.selPath !== "", act: () => root.trashSelected() }
                        ]
                        Rectangle {
                            id: actBtn
                            required property var modelData
                            Layout.preferredWidth: actRow.implicitWidth + 24
                            Layout.preferredHeight: 34
                            radius: 17
                            color: actArea.containsMouse && modelData.on ? Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.14) : root.cCard
                            opacity: modelData.on ? 1 : 0.4
                            Row {
                                id: actRow
                                anchors.centerIn: parent
                                spacing: 6
                                OneUIIcon { name: actBtn.modelData.icon; size: 15; color: root.cText; anchors.verticalCenter: parent.verticalCenter }
                                Text {
                                    text: actBtn.modelData.label
                                    anchors.verticalCenter: parent.verticalCenter
                                    font.family: QsConfig.Config.appearance.fontFamily
                                    font.pixelSize: QsConfig.Appearance.fontSize.s
                                    color: root.cText
                                }
                            }
                            MouseArea {
                                id: actArea
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: actBtn.modelData.on
                                cursorShape: Qt.PointingHandCursor
                                onClicked: actBtn.modelData.act()
                            }
                        }
                    }
                }
            }
        }

        // rename / new folder prompt
        Rectangle {
            anchors.fill: parent
            visible: root.prompt.length > 0
            radius: QsConfig.Appearance.radius.l
            color: Qt.rgba(0, 0, 0, 0.4)

            MouseArea { anchors.fill: parent; onClicked: root.prompt = "" }

            Rectangle {
                anchors.centerIn: parent
                width: 380
                height: 150
                radius: QsConfig.Appearance.radius.l
                color: root.cSurface

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12

                    Text {
                        text: root.prompt === "rename" ? "Rename" : "New folder"
                        font.family: QsConfig.Config.appearance.fontFamily
                        font.pixelSize: QsConfig.Appearance.fontSize.l
                        font.weight: Font.DemiBold
                        color: root.cText
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        radius: 20
                        color: root.cCard
                        TextInput {
                            id: promptField
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            verticalAlignment: TextInput.AlignVCenter
                            clip: true
                            color: root.cText
                            selectionColor: root.cPrimary
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: QsConfig.Appearance.fontSize.m
                            onAccepted: root.commitPrompt(text)
                            Keys.onEscapePressed: { root.prompt = ""; panel.forceActiveFocus() }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Item { Layout.fillWidth: true }
                        Repeater {
                            model: [
                                { label: "Cancel", primary: false },
                                { label: "OK",     primary: true }
                            ]
                            Rectangle {
                                id: dlgBtn
                                required property var modelData
                                Layout.preferredWidth: 84
                                Layout.preferredHeight: 36
                                radius: 18
                                color: modelData.primary ? root.cPrimary : root.cCard
                                Text {
                                    anchors.centerIn: parent
                                    text: dlgBtn.modelData.label
                                    font.family: QsConfig.Config.appearance.fontFamily
                                    font.pixelSize: QsConfig.Appearance.fontSize.m
                                    color: dlgBtn.modelData.primary ? root.pywal.onPrimary : root.cText
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: dlgBtn.modelData.primary ? root.commitPrompt(promptField.text) : (root.prompt = "")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
