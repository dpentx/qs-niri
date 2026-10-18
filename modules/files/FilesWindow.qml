import QtQuick 6.10
import QtQuick.Layouts 6.10
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../config" as QsConfig
import "../../services" as QsServices
import "../../components"
import "../../components/effects"

// File manager. Opened with `touch /tmp/qs-files`.
// Browse, open (xdg-open), multi-select (Ctrl / Shift click, Ctrl+A, arrows), copy / cut / paste,
// rename, new file / folder, trash with restore and empty, sort, editable path (Ctrl+L), copy path.
// Network (smb, sftp, ftp, nfs, dav ...) goes through gvfs: `gio mount <uri>` and the gvfs FUSE directory.
// Needs the user's packages: glib (gio) and gvfs (+ its smb / nfs / ... backends); missing ones are reported.
// Not done: drag and drop, tabs, rubber-band selection, undo.
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

    // selection: path -> true; selPath/selName/selIsDir describe the last clicked item
    property var sel: ({})
    property int lastIdx: -1
    property string selPath: ""
    property string selName: ""
    property bool selIsDir: false
    readonly property int selCount: Object.keys(sel).length
    readonly property bool single: selCount === 1 && selPath !== "" && sel[selPath] === true

    // clipboard
    property var clipPaths: []
    property bool clipCut: false

    property int sortIdx: 0          // 0 name, 1 modified, 2 size
    property bool sortRev: false
    readonly property var sortNames: ["Name", "Modified", "Size"]

    readonly property string trashDir: home + "/.local/share/Trash/files"
    readonly property string gvfsDir: Quickshell.env("XDG_RUNTIME_DIR") + "/gvfs"
    readonly property bool inNetwork: path === gvfsDir || path.indexOf(gvfsDir + "/") === 0
    property bool gioOk: true      // set by checkProc
    property bool gvfsOk: true

    readonly property bool inTrash: path === trashDir || path.indexOf(trashDir + "/") === 0

    // "" | "rename" | "newfolder" | "newfile" | "goto" | "connect"
    property string prompt: ""

    readonly property var places: [
        { name: "Home",      dir: home,                         icon: "mdi_harddisk" },
        { name: "Desktop",   dir: home + "/Desktop",            icon: "mdi_monitor" },
        { name: "Documents", dir: home + "/Documents",          icon: "ic_doc_document" },
        { name: "Downloads", dir: home + "/Downloads",          icon: "ic_arrow_down_24dp" },
        { name: "Pictures",  dir: home + "/Pictures",           icon: "mdi_wallpaper" },
        { name: "Music",     dir: home + "/Music",              icon: "mdi_music_note" },
        { name: "Videos",    dir: home + "/Videos",             icon: "ic_video" },
        { name: "Network",   dir: gvfsDir,                      icon: "mdi_ethernet" },
        { name: "Trash",     dir: trashDir,                    icon: "mdi_trash_can_outline" }
    ]

    function close() { shouldShow = false; prompt = "" }

    onShouldShowChanged: if (shouldShow) checkProc.exec(["sh", "-c",
        'command -v gio >/dev/null && echo gio; [ -d "$XDG_RUNTIME_DIR/gvfs" ] && echo fuse; exit 0'])

    Process {
        id: checkProc
        stdout: StdioCollector {
            onStreamFinished: {
                root.gioOk = text.indexOf("gio") !== -1
                root.gvfsOk = text.indexOf("fuse") !== -1
            }
        }
    }

    // gio mount <uri>; on success the gvfs directory shows the new mount
    Process {
        id: mountProc
        stderr: StdioCollector { id: mountErr }
        onExited: code => {
            if (code === 0) {
                Quickshell.execDetached(["notify-send", "File manager", "Connected"])
                root.go(root.gvfsDir)
                return
            }
            const e = mountErr.text
            const missing = /not supported|Operation not supported|doesn't implement|No such file or directory|not found/i.test(e)
            Quickshell.execDetached(["notify-send", "-u", "critical", "File manager",
                missing ? "Connection failed: gvfs or the backend for this protocol is not installed (gvfs, gvfs-smb, ...)"
                        : "Connection failed: " + e.trim().split("\n").slice(-1)[0]])
        }
    }
    function connectTo(uri) {
        if (!gioOk) {
            Quickshell.execDetached(["notify-send", "-u", "critical", "File manager", "gio is not installed (package: glib)"])
            return
        }
        // --anonymous would skip credentials; without it gio asks on stdin, so only keyring / URI credentials work
        mountProc.exec(["gio", "mount", uri])
    }
    function disconnectSelected() {
        if (!single || !inNetwork) return
        run('u=$(gio info -a standard::target-uri "$1" | sed -n "s/.*target-uri: //p"); gio mount -u "${u:-$1}"', [selPath], "Disconnect")
        clearSelection()
    }

    function clearSelection() { sel = ({}); lastIdx = -1; selPath = ""; selName = ""; selIsDir = false }

    // idx: model index of the clicked item; mods: Qt keyboard modifiers
    function select(idx, mods) {
        const p = folderModel.get(idx, "filePath")
        const ns = {}
        if ((mods & Qt.ShiftModifier) && lastIdx >= 0) {
            for (let i = Math.min(idx, lastIdx); i <= Math.max(idx, lastIdx); i++)
                ns[folderModel.get(i, "filePath")] = true
        } else if (mods & Qt.ControlModifier) {
            Object.assign(ns, sel)
            if (ns[p]) delete ns[p]; else ns[p] = true
        } else {
            ns[p] = true
        }
        sel = ns
        lastIdx = idx
        selPath = p
        selName = folderModel.get(idx, "fileName")
        selIsDir = folderModel.get(idx, "fileIsDir")
        fileView.positionViewAtIndex(idx, GridView.Contain)
    }
    function selectAll() {
        const ns = {}
        for (let i = 0; i < folderModel.count; i++) ns[folderModel.get(i, "filePath")] = true
        sel = ns
    }
    function moveSel(delta, mods) {
        if (!folderModel.count) return
        const i = lastIdx < 0 ? 0 : Math.max(0, Math.min(folderModel.count - 1, lastIdx + delta))
        select(i, mods & Qt.ShiftModifier)
    }
    readonly property int columns: gridView ? Math.max(1, Math.floor(fileView.width / fileView.cellWidth)) : 1

    // runs a shell snippet with the paths as "$@"; a failure raises a notification
    function run(script, args, what) {
        Quickshell.execDetached(["sh", "-c", script + ' || notify-send -u critical "File manager" "' + what + ' failed"', "sh"].concat(args))
    }

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
        if (!selCount) return
        run('gio trash -- "$@"', Object.keys(sel), "Move to trash")
        clearSelection()
    }
    // -n: never overwrite an existing file of the same name
    function paste() {
        if (!clipPaths.length) return
        run(clipCut ? 'd="$1"; shift; mv -n -- "$@" "$d/"' : 'd="$1"; shift; cp -rn -- "$@" "$d/"',
            [path].concat(clipPaths), clipCut ? "Move" : "Copy")
        if (clipCut) clipPaths = []
    }
    function copySelected(cut) {
        if (!selCount) return
        clipPaths = Object.keys(sel)
        clipCut = cut
    }
    function copyPath() {
        if (selCount) Quickshell.execDetached(["wl-copy", "--", Object.keys(sel).join("\n")])
    }
    // files in the trash: put them back where the .trashinfo says they came from
    function restoreSelected() {
        if (!selCount || !inTrash) return
        run('for f; do n=${f##*/}; i="$HOME/.local/share/Trash/info/$n.trashinfo"; p=$(sed -n "s/^Path=//p" "$i" | head -1); p=$(printf "%b" "$(printf %s "$p" | sed "s/%/\\\\x/g")"); mkdir -p "${p%/*}" && mv -n -- "$f" "$p" && rm -f "$i"; done',
            Object.keys(sel), "Restore")
        clearSelection()
    }
    function emptyTrash() { run("gio trash --empty", [], "Empty trash") }

    function commitPrompt(text) {
        const t = text.trim()
        if (!t.length) return
        if (prompt === "connect") {
            connectTo(t)
        } else if (prompt === "goto") {
            go(t === "~" ? home : t.indexOf("~/") === 0 ? home + t.slice(1) : t)
        } else {
            // a name must not contain a slash and "." / ".." are not names
            if (t.indexOf("/") !== -1 || t === "." || t === "..") return
            if (prompt === "newfolder") {
                run('mkdir -- "$1"', [path + "/" + t], "New folder")
            } else if (prompt === "newfile") {
                run('touch -- "$1"', [path + "/" + t], "New file")
            } else if (prompt === "rename" && single) {
                const dir = selPath.slice(0, selPath.lastIndexOf("/"))
                run('mv -n -- "$1" "$2"', [selPath, dir + "/" + t], "Rename")
                clearSelection()
            }
        }
        prompt = ""
        panel.forceActiveFocus()
    }
    function startPrompt(kind) {
        if (kind === "rename" && !single) return
        prompt = kind
        promptField.text = kind === "rename" ? selName : kind === "goto" ? path : ""
        if (kind === "connect") promptField.text = "smb://"
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
        sortField: [FolderListModel.Name, FolderListModel.Time, FolderListModel.Size][root.sortIdx]
        sortReversed: root.sortRev
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
            const k = event.key
            event.accepted = true
            if (k === Qt.Key_Backspace) root.up()
            else if (k === Qt.Key_Delete) root.trashSelected()
            else if (k === Qt.Key_F2) root.startPrompt("rename")
            else if (k === Qt.Key_Return || k === Qt.Key_Enter) { if (root.single) root.openItem(root.selPath, root.selIsDir) }
            else if (k === Qt.Key_Left) root.moveSel(-1, event.modifiers)
            else if (k === Qt.Key_Right) root.moveSel(1, event.modifiers)
            else if (k === Qt.Key_Up) root.moveSel(-root.columns, event.modifiers)
            else if (k === Qt.Key_Down) root.moveSel(root.columns, event.modifiers)
            else if (ctrl && k === Qt.Key_A) root.selectAll()
            else if (ctrl && k === Qt.Key_C) root.copySelected(false)
            else if (ctrl && k === Qt.Key_X) root.copySelected(true)
            else if (ctrl && k === Qt.Key_V) root.paste()
            else if (ctrl && k === Qt.Key_H) root.showHidden = !root.showHidden
            else if (ctrl && k === Qt.Key_L) root.startPrompt("goto")
            else if (ctrl && (event.modifiers & Qt.ShiftModifier) && k === Qt.Key_N) root.startPrompt("newfolder")
            else if (ctrl && k === Qt.Key_N) root.startPrompt("newfile")
            else event.accepted = false
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

                        MouseArea { anchors.fill: parent; z: -1; onClicked: root.startPrompt("goto") }

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

                }

                // chips: create, view, hidden, sort
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: [
                            { label: "New folder", on: false, act: () => root.startPrompt("newfolder") },
                            { label: "New file",   on: false, act: () => root.startPrompt("newfile") },
                            { label: "Connect to server", on: false, act: () => root.startPrompt("connect") }
                        ]
                        Rectangle {
                            id: mk
                            required property var modelData
                            Layout.preferredWidth: mkText.implicitWidth + 24
                            Layout.preferredHeight: 30
                            radius: 15
                            color: root.cCard
                            Text { id: mkText; anchors.centerIn: parent; text: mk.modelData.label
                                font.family: QsConfig.Config.appearance.fontFamily; font.pixelSize: QsConfig.Appearance.fontSize.s; color: root.cText }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: mk.modelData.act() }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Repeater {
                        model: [
                            { label: root.gridView ? "List view" : "Grid view", on: false, act: () => { root.gridView = !root.gridView } },
                            { label: "Hidden files", on: root.showHidden, act: () => { root.showHidden = !root.showHidden } },
                            { label: "Sort: " + root.sortNames[root.sortIdx], on: false, act: () => { root.sortIdx = (root.sortIdx + 1) % 3 } },
                            { label: root.sortRev ? "Descending" : "Ascending", on: false, act: () => { root.sortRev = !root.sortRev } }
                        ]
                        Rectangle {
                            id: tgl
                            required property var modelData
                            Layout.preferredWidth: tglText.implicitWidth + 24
                            Layout.preferredHeight: 30
                            radius: 15
                            color: modelData.on ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.25) : root.cCard
                            Text {
                                id: tglText
                                anchors.centerIn: parent
                                text: tgl.modelData.label
                                font.family: QsConfig.Config.appearance.fontFamily
                                font.pixelSize: QsConfig.Appearance.fontSize.s
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
                            required property int index
                            readonly property bool selected: root.sel[filePath] === true
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
                                onClicked: mouse => {
                                    root.select(cell.index, mouse.modifiers)
                                    panel.forceActiveFocus()
                                }
                                onDoubleClicked: root.openItem(cell.filePath, cell.fileIsDir)
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: folderModel.count === 0
                        text: root.filter.length ? "Nothing matches."
                            : (root.path === root.gvfsDir && !root.gioOk) ? "gio is not installed (package: glib)."
                            : (root.path === root.gvfsDir && !root.gvfsOk) ? "gvfs is not installed or not running (package: gvfs, plus gvfs-smb / gvfs-nfs ...)."
                            : root.path === root.gvfsDir ? "No network locations connected. Use \"Connect to server\" (smb://, sftp://, ftp://, nfs://, dav://)."
                            : "This folder is empty."
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
                        text: root.single ? `${root.selName}${root.selIsDir ? "" : "  ·  " + root.sizeText(folderModel.get(root.lastIdx, "fileSize"))}  ·  ${Qt.formatDateTime(folderModel.get(root.lastIdx, "fileModified"), "dd MMM yyyy HH:mm")}`
                            : root.selCount > 1 ? `${root.selCount} selected`
                            : `${folderModel.count} item${folderModel.count === 1 ? "" : "s"}`
                        elide: Text.ElideMiddle
                        font.family: QsConfig.Config.appearance.fontFamily
                        font.pixelSize: QsConfig.Appearance.fontSize.s
                        color: root.cSubText
                    }

                    Repeater {
                        model: [
                            { label: "Restore",    icon: "mdi_refresh",            show: root.inTrash,  on: root.selCount > 0,          act: () => root.restoreSelected() },
                            { label: "Empty trash", icon: "mdi_trash_can_outline", show: root.inTrash,  on: true,                       act: () => root.emptyTrash() },
                            { label: "Disconnect", icon: "ic_close",               show: root.inNetwork, on: root.single && root.path === root.gvfsDir, act: () => root.disconnectSelected() },
                            { label: "Copy",       icon: "abc_ic_menu_copy_mtrl_am_alpha", show: true,  on: root.selCount > 0,          act: () => root.copySelected(false) },
                            { label: "Cut",        icon: "abc_ic_menu_cut_mtrl_alpha",     show: true,  on: root.selCount > 0,          act: () => root.copySelected(true) },
                            { label: "Paste",      icon: "ic_content_paste",       show: true,          on: root.clipPaths.length > 0,  act: () => root.paste() },
                            { label: "Rename",     icon: "ic_edit_square",         show: true,          on: root.single,                act: () => root.startPrompt("rename") },
                            { label: "Copy path",  icon: "mdi_link_variant",       show: true,          on: root.selCount > 0,          act: () => root.copyPath() },
                            { label: "Trash",      icon: "mdi_trash_can_outline",  show: !root.inTrash, on: root.selCount > 0,          act: () => root.trashSelected() }
                        ]
                        Rectangle {
                            id: actBtn
                            required property var modelData
                            visible: modelData.show
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
                        text: root.prompt === "rename" ? "Rename" : root.prompt === "newfile" ? "New file" : root.prompt === "goto" ? "Go to folder" : root.prompt === "connect" ? "Connect to server" : "New folder"
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
