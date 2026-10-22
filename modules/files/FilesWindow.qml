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
// rename, new file / folder, trash with restore and empty, sort, editable path bar (click the bar or Ctrl+L), copy path.
// Same-name files ask: Replace / Skip / Keep both.
// Network (smb, sftp, ftp, nfs, dav ...) goes through gvfs: `gio mount <uri>` and the gvfs FUSE directory.
// Needs the user's packages: glib (gio) and gvfs (+ its smb / nfs / ... backends); missing ones are reported.
// Not done: drag and drop, tabs, rubber-band selection, undo.
PanelWindow {
    id: root

    // Blur only while the panel is fully shown: the region is a fixed rect and would otherwise be
    // drawn before the panel has faded in (and stay after it has gone).
    BackgroundEffect.blurRegion: QsConfig.Appearance.blur && shouldShow && panel.opacity > 0.98 ? _blur : null
    Region { id: _blur; item: panel; radius: blurSurface.radius }  // panel carries the movable geometry; a child item would keep the old rect when the panel is moved

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

    // "" | "rename" | "newfolder" | "newfile" | "connect"
    property string prompt: ""
    property bool pathEdit: false   // the breadcrumb bar is a text field
    property bool compactPlaces: false   // left panel shows only the icons (☰ button); kept until the shell restarts

    // Localized folders (e.g. Belgeler, İndirilenler) come from ~/.config/user-dirs.dirs; English names are the fallback.
    property var xdg: ({})
    function xdgDir(key, fallback) { return xdg[key] && xdg[key].length ? xdg[key] : home + "/" + fallback }
    readonly property var places: [
        { name: "Home",      dir: home,                              icon: "mdi_harddisk" },
        { name: "Desktop",   dir: xdgDir("DESKTOP", "Desktop"),      icon: "mdi_monitor" },
        { name: "Documents", dir: xdgDir("DOCUMENTS", "Documents"),  icon: "ic_doc_document" },
        { name: "Downloads", dir: xdgDir("DOWNLOAD", "Downloads"),   icon: "ic_arrow_down_24dp" },
        { name: "Pictures",  dir: xdgDir("PICTURES", "Pictures"),    icon: "mdi_wallpaper" },
        { name: "Music",     dir: xdgDir("MUSIC", "Music"),          icon: "mdi_music_note" },
        { name: "Videos",    dir: xdgDir("VIDEOS", "Videos"),        icon: "ic_video" },
        { name: "Network",   dir: gvfsDir,                      icon: "mdi_ethernet" },
        { name: "Trash",     dir: trashDir,                    icon: "mdi_trash_can_outline" }
    ]

    function close() { shouldShow = false; prompt = ""; pathEdit = false; job = ({}) }

    onShouldShowChanged: if (shouldShow) {
        checkProc.exec(["sh", "-c",
            'command -v gio >/dev/null && echo gio; [ -d "$XDG_RUNTIME_DIR/gvfs" ] && echo fuse; exit 0'])
        xdgProc.exec(["sh", "-c",
            'f="${XDG_CONFIG_HOME:-$HOME/.config}/user-dirs.dirs"; [ -r "$f" ] && . "$f"; ' +
            'for k in DESKTOP DOCUMENTS DOWNLOAD PICTURES MUSIC VIDEOS; do eval "v=\\$XDG_${k}_DIR"; echo "$k=$v"; done'])
    }

    Process {
        id: xdgProc
        stdout: StdioCollector {
            onStreamFinished: {
                const o = {}
                for (const l of text.split("\n")) {
                    const i = l.indexOf("=")
                    if (i > 0) o[l.slice(0, i)] = l.slice(i + 1)
                }
                root.xdg = o
            }
        }
    }

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

    // ── Tabs ───────────────────────────────────────────────────
    // The active tab lives in path/backStack/forwardStack; the others are parked in `tabs`.
    property var tabs: [{ path: "", back: [], fwd: [] }]
    property int tabIdx: 0
    function tabPath(i) { return i === tabIdx ? path : tabs[i]?.path ?? "" }
    function tabTitle(i) {
        const p = tabPath(i)
        return p === home ? "Home" : p === "/" ? "/" : baseName(p)
    }
    function saveTab() {
        const t = tabs.slice()
        t[tabIdx] = { path: path, back: backStack, fwd: forwardStack }
        tabs = t
    }
    function loadTab(i) {
        const t = tabs[i]
        tabIdx = i
        path = t.path
        backStack = t.back
        forwardStack = t.fwd
        clearSelection()
    }
    function switchTab(i) {
        if (i === tabIdx || i < 0 || i >= tabs.length) return
        saveTab()
        loadTab(i)
    }
    function newTab(p) {
        saveTab()
        tabs = tabs.concat([{ path: p || path, back: [], fwd: [] }])
        loadTab(tabs.length - 1)
    }
    function closeTab(i) {
        if (tabs.length < 2) return
        saveTab()
        const next = tabs.filter((_, k) => k !== i)
        const ni = i < tabIdx ? tabIdx - 1 : Math.min(tabIdx, next.length - 1)
        tabs = next
        loadTab(ni)
    }

    // ── Drag and drop (move; hold Ctrl to copy) ────────────────
    // Targets (folders in the list, sidebar places, tab heads) register themselves with a `dropPath`;
    // the pointer position is matched against them by hand, so nothing competes with the click handlers.
    property bool dragging: false
    property point dragPoint: Qt.point(0, 0)
    property string dragHover: ""
    property string dragLabel: ""
    property string dragKind: "file"
    property var dropTargets: []
    function dirName(p) { const i = p.lastIndexOf("/"); return i <= 0 ? "/" : p.slice(0, i) }
    function targetAt(pt) {
        for (let i = dropTargets.length - 1; i >= 0; i--) {
            const it = dropTargets[i]
            if (!it || !it.visible || !it.dropPath) continue
            const m = it.mapToItem(panel, 0, 0)
            if (pt.x >= m.x && pt.x <= m.x + it.width && pt.y >= m.y && pt.y <= m.y + it.height) return it
        }
        return null
    }
    function canDrop(dest) {
        if (!dest || dest === path || dest === gvfsDir || dest.indexOf(gvfsDir + "/") === 0) return false
        // not onto itself or into its own subfolder; at least one item must actually change folder
        const paths = Object.keys(sel)
        return paths.some(p => dirName(p) !== dest) && !paths.some(p => dest === p || dest.indexOf(p + "/") === 0)
    }
    function dragStart(c) {
        if (!sel[c.filePath]) select(c.index, 0)
        dragLabel = selCount > 1 ? selCount + " items" : c.fileName
        dragKind = selCount > 1 ? "file" : c.kind
        dragging = true
    }
    function dragMove(scenePos) {
        dragPoint = panel.mapFromItem(null, scenePos.x, scenePos.y)
        const t = targetAt(dragPoint)
        dragHover = t && canDrop(t.dropPath) ? t.dropPath : ""
    }
    function dragEnd() {
        const dest = dragHover
        dragging = false
        dragHover = ""
        if (!dest) return
        const paths = Object.keys(sel).filter(p => dirName(p) !== dest)
        if (dest === trashDir) {
            run('gio trash -- "$@"', paths, "Move to trash")
            pushUndo("delete", restoreByPath, paths)
        } else {
            transfer(paths, dest, !(Qt.application.keyboardModifiers & Qt.ControlModifier), false)
        }
        clearSelection()
    }

    // Ctrl+Z: each undoable action pushes the shell snippet that reverses it
    // (fire-and-forget like the actions themselves, so a failed action still leaves an entry).
    // shortcut: copy-paste is not undoable (cannot tell new copies from files that already existed).
    property var undoStack: []
    function pushUndo(what, script, args) { undoStack = undoStack.concat([{ what, script, args }]).slice(-20) }
    function undo() {
        if (!undoStack.length) return
        const u = undoStack[undoStack.length - 1]
        undoStack = undoStack.slice(0, -1)
        run(u.script, u.args, "Undo " + u.what)
    }
    readonly property string restoreByPath: 'for o; do for i in "$HOME/.local/share/Trash/info/"*.trashinfo; do [ -e "$i" ] || continue; ' +
        'p=$(sed -n "s/^Path=//p" "$i" | head -1); p=$(printf "%b" "$(printf %s "$p" | sed "s/%/\\\\x/g")"); ' +
        '[ "$p" = "$o" ] && n=$(basename "$i" .trashinfo) && mv -n -- "$HOME/.local/share/Trash/files/$n" "$o" && rm -f "$i"; done; done'

    function trashSelected() {
        if (!selCount) return
        const paths = Object.keys(sel)
        run('gio trash -- "$@"', paths, "Move to trash")
        if (!inTrash) pushUndo("delete", restoreByPath, paths)
        clearSelection()
    }
    // ── Copy / move with conflict dialogs ──────────────────────
    // transfer() first asks the shell which names already exist in the target; each of those gets a
    // Replace / Skip / Keep both dialog (job.todo), then scripts/fm-transfer.sh does the work (cp -a / mv,
    // with a progress notification for long copies).
    property var job: ({})          // { dest, cut, clip, items: [{ m, s }], todo: [conflicting sources] }
    property bool applyAll: false
    readonly property bool conflict: !!job.todo && job.todo.length > 0
    function transfer(paths, dest, cut, clip) {
        // a folder cannot go into itself; a move into the folder it is already in does nothing
        const ps = paths.filter(p => dest !== p && dest.indexOf(p + "/") !== 0 && !(cut && dirName(p) === dest))
        if (!ps.length || job.dest) return
        job = { dest, cut, clip, srcs: ps, items: [], todo: [] }
        scanProc.exec(["sh", "-c", 'd="$1"; shift; for f; do [ -e "$d/${f##*/}" ] && printf "%s\\n" "$f"; done; exit 0', "sh", dest].concat(ps))
    }
    Process {
        id: scanProc
        stdout: StdioCollector {
            onStreamFinished: {
                const j = root.job
                const clash = text.split("\n").filter(l => l.length)
                root.job = Object.assign({}, j, { todo: clash,
                    items: j.srcs.filter(s => clash.indexOf(s) === -1).map(s => ({ m: "-", s })) })
                if (!clash.length) root.runJob()
            }
        }
    }
    function decide(mode) {
        const j = job
        const take = applyAll ? j.todo : [j.todo[0]]
        // "replace" onto the very file being copied would trash the original
        const items = j.items.concat(mode === "skip" ? [] : take.filter(s => !(mode === "replace" && dirName(s) === j.dest)).map(s => ({ m: mode, s })))
        job = Object.assign({}, j, { items, todo: j.todo.slice(take.length) })
        if (!job.todo.length) runJob()
    }
    function runJob() {
        const j = job
        job = ({})
        applyAll = false
        if (!j.items.length) return
        Quickshell.execDetached(["bash", Quickshell.shellPath("scripts/fm-transfer.sh"), j.dest, j.cut ? "1" : "0"]
            .concat(j.items.flatMap(i => [i.m, i.s])))
        if (j.cut) {
            // pairs of (new location, old location) for the undo; renamed copies ("both") are not tracked
            pushUndo("move", 'while [ $# -gt 1 ]; do mv -n -- "$1" "$2"; shift 2; done',
                j.items.filter(i => i.m !== "both").flatMap(i => [j.dest + "/" + baseName(i.s), i.s]))
            if (j.clip) clipPaths = []
        }
    }
    function paste() {
        if (clipPaths.length) transfer(clipPaths, path, clipCut, true)
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
        } else {
            // a name must not contain a slash and "." / ".." are not names
            if (t.indexOf("/") !== -1 || t === "." || t === "..") return
            if (prompt === "newfolder") {
                run('mkdir -- "$1"', [path + "/" + t], "New folder")
                pushUndo("new folder", 'rmdir -- "$1"', [path + "/" + t])
            } else if (prompt === "newfile") {
                run('touch -- "$1"', [path + "/" + t], "New file")
                pushUndo("new file", 'gio trash -- "$1"', [path + "/" + t])
            } else if (prompt === "rename" && single) {
                const dir = selPath.slice(0, selPath.lastIndexOf("/"))
                run('mv -n -- "$1" "$2"', [selPath, dir + "/" + t], "Rename")
                pushUndo("rename", 'mv -n -- "$1" "$2"', [dir + "/" + t, selPath])
                clearSelection()
            }
        }
        prompt = ""
        panel.forceActiveFocus()
    }
    function startPathEdit() {
        pathEdit = true
        pathField.text = path
        pathField.forceActiveFocus()
        pathField.selectAll()
    }
    function commitPath(text) {
        const t = text.trim()
        pathEdit = false
        panel.forceActiveFocus()
        if (t.length) go(t === "~" ? home : t.indexOf("~/") === 0 ? home + t.slice(1) : t)
    }
    function startPrompt(kind) {
        if (kind === "rename" && !single) return
        prompt = kind
        promptField.text = kind === "rename" ? selName : ""
        if (kind === "connect") promptField.text = "smb://"
        promptField.forceActiveFocus()
        promptField.selectAll()
    }

    // Returns the name of an icon in assets/icons/files (Samsung My Files set).
    readonly property var extKinds: ({
        pdf: "pdf", xls: "excel", xlsx: "excel", csv: "excel", doc: "word", docx: "word", odt: "word",
        ppt: "powerpoint", pptx: "powerpoint", txt: "txt", md: "txt", log: "txt", apk: "apk",
        mp4: "video", mkv: "video", webm: "video", mov: "video", avi: "video",
        mp3: "audio", flac: "audio", ogg: "audio", opus: "audio", wav: "audio", m4a: "audio",
        png: "image", jpg: "image", jpeg: "image", webp: "image", gif: "image", bmp: "image", svg: "image"
    })
    function fileKind(name, isDir) {
        if (isDir) {
            if (path === gvfsDir) {
                if (name.indexOf("smb") === 0) return "smb"
                if (name.indexOf("sftp") === 0) return "sftp"
                if (name.indexOf("ftp") === 0) return "ftp"
            }
            const full = path + "/" + name
            return full === xdgDir("MUSIC", "Music") ? "folder-music" : full === xdgDir("DOWNLOAD", "Downloads") ? "folder-download" : "folder"
        }
        return extKinds[name.slice(name.lastIndexOf(".") + 1).toLowerCase()] ?? "file"
    }
    function sizeText(b) {
        if (b < 1024) return b + " B"
        if (b < 1048576) return (b / 1024).toFixed(0) + " KB"
        if (b < 1073741824) return (b / 1048576).toFixed(1) + " MB"
        return (b / 1073741824).toFixed(1) + " GB"
    }

    screen: Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    // The window covers the screen; only the panel takes input and it can be moved/resized (PanelGeometry).
    mask: Region { item: panel }
    PanelGeometry {
        id: geo
        screen: root.screen
        name: "files"
        minW: 840
        minH: 360
        defaultW: Math.min(980, screen.width - 80)
        defaultH: Math.min(640, screen.height - (config.bar.height ?? 34) - 60)
        defaultY: (config.bar.height ?? 34) + 22
    }
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
        x: geo.x; y: geo.y; width: geo.w; height: geo.h

        PanelGrips { geo: geo; color: root.cText }
        property real revealOffset: shouldShow ? 0 : -20
        scale: shouldShow ? 1.0 : 0.97
        opacity: shouldShow ? 1.0 : 0.0
        focus: root.shouldShow
        transform: Translate { y: panel.revealOffset }

        Behavior on scale { NumberAnimation { duration: OneUIMotion.medium1; easing.bezierCurve: OneUIMotion.springGentle } }
        Behavior on opacity { NumberAnimation { duration: OneUIMotion.short4; easing.type: Easing.OutQuad } }
        Behavior on revealOffset { NumberAnimation { duration: OneUIMotion.medium1; easing.bezierCurve: OneUIMotion.emphasizedDecelerate } }

        Keys.onEscapePressed: root.conflict ? (root.job = ({})) : root.prompt.length ? (root.prompt = "") : root.close()
        Keys.onPressed: event => {
            if (root.prompt.length || root.conflict || root.pathEdit) return
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
            else if (ctrl && k === Qt.Key_Z) root.undo()
            else if (ctrl && k === Qt.Key_T) root.newTab()
            else if (ctrl && k === Qt.Key_W) root.closeTab(root.tabIdx)
            else if (ctrl && (k === Qt.Key_PageDown || (k === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier)))) root.switchTab((root.tabIdx + 1) % root.tabs.length)
            else if (ctrl && (k === Qt.Key_PageUp || k === Qt.Key_Backtab)) root.switchTab((root.tabIdx + root.tabs.length - 1) % root.tabs.length)
            else if (ctrl && k === Qt.Key_H) root.showHidden = !root.showHidden
            else if (ctrl && k === Qt.Key_L) root.startPathEdit()
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
                Layout.preferredWidth: root.compactPlaces ? 48 : 168
                Layout.fillHeight: true
                spacing: 4
                Behavior on Layout.preferredWidth { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 8
                    spacing: 6

                    // ☰ like a website's menu button: folds the places down to their icons
                    Rectangle {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        radius: 20
                        color: menuArea.containsMouse ? Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.1) : "transparent"
                        OneUIIcon { anchors.centerIn: parent; name: "ic_menu"; size: 20; color: root.cText }
                        MouseArea {
                            id: menuArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.compactPlaces = !root.compactPlaces
                        }
                    }
                    Text {
                        visible: !root.compactPlaces
                        Layout.fillWidth: true
                        text: "Files"
                        elide: Text.ElideRight
                        font.family: QsConfig.Config.appearance.fontFamily
                        font.pixelSize: QsConfig.Appearance.fontSize.xxl
                        font.weight: Font.DemiBold
                        color: root.cText
                    }
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
                        readonly property string dropPath: modelData.dir
                        Component.onCompleted: root.dropTargets.push(placeRow)
                        Component.onDestruction: root.dropTargets = root.dropTargets.filter(x => x !== placeRow)
                        color: root.dragHover === modelData.dir ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.4)
                            : active ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.22)
                            : placeArea.containsMouse ? Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.07) : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: root.compactPlaces ? 0 : 14
                            anchors.rightMargin: root.compactPlaces ? 0 : 10
                            spacing: 10

                            Item { Layout.fillWidth: true; visible: root.compactPlaces }
                            OneUIIcon {
                                name: placeRow.modelData.icon
                                size: 17
                                color: placeRow.active ? root.cPrimary : root.cText
                            }
                            Item { Layout.fillWidth: true; visible: root.compactPlaces }
                            Text {
                                visible: !root.compactPlaces
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

                // tabs (shown once there is more than one)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    visible: root.tabs.length > 1

                    Repeater {
                        model: root.tabs.length
                        Rectangle {
                            id: tabHead
                            required property int index
                            readonly property bool active: index === root.tabIdx
                            readonly property string dropPath: root.tabPath(index)
                            Layout.preferredWidth: Math.min(180, Math.max(96, tabText.implicitWidth + 52))
                            Layout.preferredHeight: 32
                            radius: 16
                            color: root.dragHover === dropPath && !active ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.4)
                                : active ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.22)
                                : tabArea.containsMouse ? Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.07) : root.cCard
                            Component.onCompleted: root.dropTargets.push(tabHead)
                            Component.onDestruction: root.dropTargets = root.dropTargets.filter(x => x !== tabHead)

                            MouseArea {
                                id: tabArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                onClicked: mouse => mouse.button === Qt.MiddleButton ? root.closeTab(tabHead.index) : root.switchTab(tabHead.index)
                            }
                            Text {
                                id: tabText
                                anchors.left: parent.left
                                anchors.leftMargin: 14
                                anchors.right: tabClose.left
                                anchors.rightMargin: 4
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.tabTitle(tabHead.index)
                                elide: Text.ElideRight
                                font.family: QsConfig.Config.appearance.fontFamily
                                font.pixelSize: QsConfig.Appearance.fontSize.s
                                font.weight: tabHead.active ? Font.DemiBold : Font.Normal
                                color: tabHead.active ? root.cPrimary : root.cText
                            }
                            Text {
                                id: tabClose
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                text: "✕"
                                font.pixelSize: QsConfig.Appearance.fontSize.s
                                color: root.cSubText
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -6
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.closeTab(tabHead.index)
                                }
                            }
                        }
                    }
                    Item { Layout.fillWidth: true }
                }

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

                        // Every folder of the path is a button. A long path scrolls (wheel or drag),
                        // starting at the current folder, so the leading segments stay reachable.
                        Flickable {
                            id: crumbFlick
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            contentWidth: crumbRow.width
                            contentHeight: height
                            flickableDirection: Flickable.HorizontalFlick
                            boundsBehavior: Flickable.StopAtBounds
                            clip: true
                            visible: !root.pathEdit
                            function toEnd() { contentX = Math.max(0, contentWidth - width) }
                            onContentWidthChanged: Qt.callLater(toEnd)
                            onWidthChanged: Qt.callLater(toEnd)
                            Component.onCompleted: Qt.callLater(toEnd)
                            WheelHandler {
                                onWheel: e => crumbFlick.contentX = Math.max(0, Math.min(crumbFlick.contentWidth - crumbFlick.width,
                                    crumbFlick.contentX - (e.angleDelta.x || e.angleDelta.y)))
                            }

                            // empty space after the last folder: edit the path in place (Ctrl+L does the same)
                            MouseArea {
                                z: -1
                                width: Math.max(crumbFlick.width, crumbRow.width)
                                height: crumbFlick.height
                                onClicked: root.startPathEdit()
                            }

                            Row {
                                id: crumbRow
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 0

                                Repeater {
                                    model: {
                                        const parts = root.path.split("/").filter(s => s.length)
                                        const out = [{ label: "/", dir: "/" }]
                                        let acc = ""
                                        for (const s of parts) { acc += "/" + s; out.push({ label: s, dir: acc }) }
                                        return out
                                    }
                                    Row {
                                        id: crumb
                                        required property var modelData
                                        required property int index
                                        readonly property bool current: modelData.dir === root.path
                                        spacing: 0
                                        anchors.verticalCenter: parent.verticalCenter

                                        Text {
                                            visible: crumb.index > 1
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "›"
                                            font.pixelSize: QsConfig.Appearance.fontSize.m
                                            color: root.cSubText
                                        }
                                        Rectangle {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: crumbText.implicitWidth + 16
                                            height: 26
                                            radius: 13
                                            color: crumbArea.containsMouse ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.22)
                                                : crumb.current ? Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.08) : "transparent"
                                            Text {
                                                id: crumbText
                                                anchors.centerIn: parent
                                                text: crumb.modelData.label
                                                font.family: QsConfig.Config.appearance.fontFamily
                                                font.pixelSize: QsConfig.Appearance.fontSize.m
                                                font.weight: crumb.current ? Font.DemiBold : Font.Normal
                                                color: crumb.current || crumbArea.containsMouse ? root.cText : root.cSubText
                                            }
                                            MouseArea {
                                                id: crumbArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.go(crumb.modelData.dir)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        TextInput {
                            id: pathField
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            visible: root.pathEdit
                            verticalAlignment: TextInput.AlignVCenter
                            clip: true
                            color: root.cText
                            selectionColor: root.cPrimary
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: QsConfig.Appearance.fontSize.m
                            onAccepted: root.commitPath(text)
                            onActiveFocusChanged: if (!activeFocus) root.pathEdit = false
                            Keys.onEscapePressed: { root.pathEdit = false; panel.forceActiveFocus() }
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
                            { label: "New tab",    on: false, act: () => root.newTab() },
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
                            ...(root.undoStack.length ? [{ label: "Undo " + root.undoStack[root.undoStack.length - 1].what, on: false, act: () => root.undo() }] : []),
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
                        // Native wheel/touchpad scrolling. Pressing on an item or empty space must not start a
                        // drag-scroll (item drags are DnD), hence preventStealing on the MouseAreas below.
                        cellWidth: root.gridView ? 118 : width
                        cellHeight: root.gridView ? 116 : 46
                        model: folderModel

                        MouseArea {
                            // empty space deselects
                            anchors.fill: parent
                            preventStealing: true
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
                            readonly property string dropPath: fileIsDir ? filePath : ""
                            property bool thumbFailed: false
                            Component.onCompleted: root.dropTargets.push(cell)
                            Component.onDestruction: root.dropTargets = root.dropTargets.filter(x => x !== cell)
                            width: fileView.cellWidth
                            height: fileView.cellHeight

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 2
                                radius: 14
                                color: root.dragHover !== "" && root.dragHover === cell.dropPath ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.4)
                                    : cell.selected ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.22)
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
                                    onStatusChanged: cell.thumbFailed = (status === Image.Error)
                                }
                                Image {
                                    anchors.fill: parent
                                    visible: cell.kind !== "image" || cell.thumbFailed
                                    source: Qt.resolvedUrl("../../assets/icons/files/" + (cell.kind === "image" ? "image" : cell.kind) + ".svg")
                                    sourceSize.width: 128
                                    sourceSize.height: 128
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
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
                                preventStealing: true
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                onClicked: mouse => {
                                    if (mouse.button === Qt.MiddleButton) {
                                        if (cell.fileIsDir) root.newTab(cell.filePath)   // middle click: folder in a new tab
                                        return
                                    }
                                    root.select(cell.index, mouse.modifiers)
                                    panel.forceActiveFocus()
                                }
                                onDoubleClicked: root.openItem(cell.filePath, cell.fileIsDir)
                            }

                            DragHandler {
                                target: null
                                acceptedButtons: Qt.LeftButton
                                dragThreshold: 12
                                onActiveChanged: active ? root.dragStart(cell) : root.dragEnd()
                                onCentroidChanged: if (active) root.dragMove(centroid.scenePosition)
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
                        text: root.prompt === "rename" ? "Rename" : root.prompt === "newfile" ? "New file" : root.prompt === "connect" ? "Connect to server" : "New folder"
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

        // same name already in the target folder
        Rectangle {
            anchors.fill: parent
            visible: root.conflict
            z: 90
            radius: QsConfig.Appearance.radius.l
            color: Qt.rgba(0, 0, 0, 0.4)

            MouseArea { anchors.fill: parent }  // modal

            Rectangle {
                anchors.centerIn: parent
                width: 420
                height: dlgCol.implicitHeight + 36
                radius: QsConfig.Appearance.radius.l
                color: root.cSurface

                ColumnLayout {
                    id: dlgCol
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12

                    Text {
                        Layout.fillWidth: true
                        text: "“" + (root.conflict ? root.baseName(root.job.todo[0]) : "") + "” already exists"
                        elide: Text.ElideMiddle
                        font.family: QsConfig.Config.appearance.fontFamily
                        font.pixelSize: QsConfig.Appearance.fontSize.l
                        font.weight: Font.DemiBold
                        color: root.cText
                    }
                    Text {
                        Layout.fillWidth: true
                        text: "A file or folder with this name is already in " + (root.job.dest ? root.baseName(root.job.dest) || "/" : "") + "."
                        wrapMode: Text.Wrap
                        font.family: QsConfig.Config.appearance.fontFamily
                        font.pixelSize: QsConfig.Appearance.fontSize.m
                        color: root.cSubText
                    }
                    Row {
                        spacing: 8
                        visible: root.conflict && root.job.todo.length > 1
                        Rectangle {
                            width: 20; height: 20; radius: 6
                            anchors.verticalCenter: parent.verticalCenter
                            color: root.applyAll ? root.cPrimary : root.cCard
                            Text { anchors.centerIn: parent; visible: root.applyAll; text: "✓"; color: root.pywal.onPrimary; font.pixelSize: 14 }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.applyAll = !root.applyAll }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Apply to all (" + (root.conflict ? root.job.todo.length : 0) + " conflicts)"
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: QsConfig.Appearance.fontSize.m
                            color: root.cText
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Repeater {
                            model: [
                                { label: "Skip",      mode: "skip",    primary: false },
                                { label: "Keep both", mode: "both",    primary: false },
                                { label: "Replace",   mode: "replace", primary: true }
                            ]
                            Rectangle {
                                id: cfBtn
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: 36
                                radius: 18
                                color: modelData.primary ? root.cPrimary : root.cCard
                                Text {
                                    anchors.centerIn: parent
                                    text: cfBtn.modelData.label
                                    font.family: QsConfig.Config.appearance.fontFamily
                                    font.pixelSize: QsConfig.Appearance.fontSize.m
                                    color: cfBtn.modelData.primary ? root.pywal.onPrimary : root.cText
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.decide(cfBtn.modelData.mode)
                                }
                            }
                        }
                    }
                }
            }
        }

        // what is being dragged, following the pointer
        Rectangle {
            visible: root.dragging
            z: 100
            x: root.dragPoint.x + 14
            y: root.dragPoint.y + 14
            width: ghostRow.implicitWidth + 24
            height: 40
            radius: 20
            color: Qt.rgba(root.cSurface.r, root.cSurface.g, root.cSurface.b, 0.95)
            border.width: 1
            border.color: root.dragHover !== "" ? root.cPrimary : Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.2)
            Row {
                id: ghostRow
                anchors.centerIn: parent
                spacing: 8
                Image {
                    width: 24; height: 24
                    anchors.verticalCenter: parent.verticalCenter
                    source: Qt.resolvedUrl("../../assets/icons/files/" + root.dragKind + ".svg")
                    sourceSize: Qt.size(48, 48)
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.dragLabel + (root.dragHover !== "" && (Qt.application.keyboardModifiers & Qt.ControlModifier) ? "  (copy)" : "")
                    font.family: QsConfig.Config.appearance.fontFamily
                    font.pixelSize: QsConfig.Appearance.fontSize.s
                    color: root.cText
                }
            }
        }
    }
}
