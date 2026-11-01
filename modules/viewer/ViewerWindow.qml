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

// Photo viewer, in the spirit of the Aves gallery app. `touch /tmp/qs-viewer` toggles it; the Files window
// opens images here (`/tmp/qs-viewer-open` holds the path). A folder shows as a grid, newest first.
// Viewer: wheel / double click zoom, drag to pan, arrows or the strip to move, R rotates (the view only,
// the file is untouched), I toggles the info panel, Space plays a slideshow, Del moves to the trash.
// Favorites (star) live in user.json under viewer.favorites and have their own filter.
// Not done: videos, map / EXIF, tags and ratings, albums across folders, editing.
FloatingWindow {
    id: root

    BackgroundEffect.blurRegion: QsConfig.Appearance.blur && shouldShow && panel.opacity > 0.98 && Math.abs(panel.scale - 1) < 0.002 && Math.abs(panel.revealOffset) < 0.5 ? _blur : null
    Region { id: _blur; item: panel; radius: blurSurface.radius }

    property bool shouldShow: false

    readonly property var pywal: QsServices.Pywal
    readonly property color cSurface: pywal.surfaceContainerHighest
    readonly property color cCard: pywal.surfaceContainerHigh
    readonly property color cPrimary: pywal.primary
    readonly property color cText: pywal.foreground
    readonly property color cSubText: pywal.onSurfaceMuted

    readonly property string home: Quickshell.env("HOME")
    property string dir: home + "/Pictures"
    property bool favOnly: false
    property int index: -1            // -1: grid, otherwise the photo shown (index into `items`)
    property bool showInfo: false
    property bool slideshow: false
    property int rot: 0               // quarter turns, view only
    property real zoom: 1
    property string pendingOpen: ""   // file to show once the folder has loaded
    property string trashArmed: ""

    readonly property var favs: QsConfig.Config.data.viewer?.favorites ?? []
    function isFav(p) { return favs.includes(p) }
    function toggleFav(p) { QsConfig.Config.set("viewer.favorites", isFav(p) ? favs.filter(x => x !== p) : [...favs, p]) }

    // The folder listing, copied into a ListModel so the favorites filter and index maths stay simple.
    ListModel { id: items }
    readonly property var cur: index >= 0 && index < items.count ? items.get(index) : null

    function rebuild() {
        items.clear()
        for (let i = 0; i < folderModel.count; i++) {
            const p = folderModel.get(i, "filePath")
            if (favOnly && !isFav(p)) continue
            items.append({ path: p, name: folderModel.get(i, "fileName"), size: folderModel.get(i, "fileSize"), mtime: folderModel.get(i, "fileModified").getTime() })
        }
        if (pendingOpen !== "") {
            for (let i = 0; i < items.count; i++) if (items.get(i).path === pendingOpen) { show(i); break }
            pendingOpen = ""
        } else if (index >= items.count) index = items.count - 1
    }
    onFavOnlyChanged: rebuild()
    onFavsChanged: if (favOnly) rebuild()

    function openPath(p) {
        if (!p.length) return
        const d = p.slice(0, p.lastIndexOf("/"))
        shouldShow = true
        favOnly = false
        if (d === dir) { pendingOpen = p; rebuild() }
        else { pendingOpen = p; dir = d }
    }
    function show(i) { rot = 0; zoom = 1; trashArmed = ""; index = i }
    function step(d) { if (items.count > 0) show((index + d + items.count) % items.count) }
    function close() { shouldShow = false; slideshow = false; index = -1 }

    FolderListModel {
        id: folderModel
        folder: "file://" + root.dir.split("/").map(encodeURIComponent).join("/")
        showDirs: false
        showDotAndDotDot: false
        caseSensitive: false
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.gif", "*.bmp", "*.svg", "*.avif", "*.heic", "*.tif", "*.tiff"]
        sortField: FolderListModel.Time
        sortReversed: true
        onStatusChanged: if (status === FolderListModel.Ready) root.rebuild()
        onCountChanged: if (status === FolderListModel.Ready) root.rebuild()
    }

    Timer {
        interval: 4000
        repeat: true
        running: root.slideshow && root.index >= 0
        onTriggered: root.step(1)
    }
    Timer { id: trashTimer; interval: 3000; onTriggered: root.trashArmed = "" }

    title: "Photos"
    implicitWidth: 1040
    implicitHeight: 680
    minimumSize: Qt.size(720, 480)
    onVisibleChanged: if (!visible) { shouldShow = false; slideshow = false }
    color: "transparent"
    visible: shouldShow || panel.opacity > 0

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

        Keys.onEscapePressed: root.index >= 0 ? (root.index = -1, root.slideshow = false) : root.close()
        Keys.onPressed: event => {
            event.accepted = true
            if (root.index < 0) { event.accepted = false; return }
            const k = event.key
            if (k === Qt.Key_Left) root.step(-1)
            else if (k === Qt.Key_Right) root.step(1)
            else if (k === Qt.Key_R) root.rot = (root.rot + 1) % 4
            else if (k === Qt.Key_I) root.showInfo = !root.showInfo
            else if (k === Qt.Key_Space) root.slideshow = !root.slideshow
            else if (k === Qt.Key_F && root.cur) root.toggleFav(root.cur.path)
            else if (k === Qt.Key_Delete) viewerTrash.ask()
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

        DexCaption { id: caption; title: root.cur ? root.cur.name : "Photos"; onHideRequested: root.close(); onCloseRequested: root.close() }

        // small round icon button used by both headers
        component Btn: Rectangle {
            id: btn
            property string icon
            property bool on: false
            property bool danger: false
            signal clicked()
            width: 34; height: 34; radius: 17
            color: btn.on ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.3)
                 : ma.containsMouse ? Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.12) : "transparent"
            OneUIIcon { anchors.centerIn: parent; name: btn.icon; size: 18; color: btn.danger ? root.pywal.error : root.cText }
            MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: btn.clicked() }
        }

        // ── Grid ────────────────────────────────────────────────
        ColumnLayout {
            visible: root.index < 0
            anchors.fill: parent
            anchors.margins: 14
            anchors.topMargin: 14 + caption.height
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Repeater {
                    model: [{ n: "Pictures", d: root.home + "/Pictures" }, { n: "Downloads", d: root.home + "/Downloads" }]
                    Rectangle {
                        required property var modelData
                        readonly property bool active: !root.favOnly && root.dir === modelData.d
                        Layout.preferredHeight: 32
                        Layout.preferredWidth: chipT.implicitWidth + 28
                        radius: 16
                        color: active ? root.cPrimary : root.pywal.tileOff
                        Text { id: chipT; anchors.centerIn: parent; text: modelData.n; font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.m; color: parent.active ? root.pywal.readableOn(root.cPrimary) : root.cText }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.favOnly = false; root.dir = parent.modelData.d } }
                    }
                }
                Rectangle {
                    Layout.preferredHeight: 32
                    Layout.preferredWidth: favT.implicitWidth + 28
                    radius: 16
                    color: root.favOnly ? root.cPrimary : root.pywal.tileOff
                    Text { id: favT; anchors.centerIn: parent; text: "★ Favorites"; font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.m; color: root.favOnly ? root.pywal.readableOn(root.cPrimary) : root.cText }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.favOnly = !root.favOnly }
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: items.count + (items.count === 1 ? " photo" : " photos") + "  ·  " + root.dir.slice(root.dir.lastIndexOf("/") + 1)
                    font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.s; color: root.cSubText
                }
            }

            GridView {
                id: grid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                cacheBuffer: 400
                readonly property int cols: Math.max(2, Math.floor(width / 170))
                cellWidth: Math.floor(width / cols)
                cellHeight: cellWidth
                model: items
                delegate: Item {
                    required property int index
                    required property string path
                    required property string name
                    width: grid.cellWidth; height: grid.cellHeight
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: QsConfig.Appearance.radius.m
                        color: root.cCard
                        clip: true
                        Image {
                            anchors.fill: parent
                            source: "file://" + path
                            sourceSize: Qt.size(320, 320)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: false
                        }
                        Text { visible: root.isFav(path); anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 6; text: "★"; font.pixelSize: 16; color: "#ffd54f" }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.show(index) }
                    }
                }
                Text {
                    visible: items.count === 0
                    anchors.centerIn: parent
                    text: root.favOnly ? "No favorites in this folder" : "No photos in " + root.dir
                    font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.l; color: root.cSubText
                }
            }
        }

        // ── Viewer ──────────────────────────────────────────────
        Item {
            id: viewer
            visible: root.index >= 0
            anchors.fill: parent
            anchors.topMargin: caption.height

            RowLayout {
                id: bar
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                anchors.margins: 10
                spacing: 4
                Btn { icon: "ic_arrow_back"; onClicked: { root.index = -1; root.slideshow = false } }
                Item { Layout.fillWidth: true }
                Btn { icon: "ic_play"; on: root.slideshow; onClicked: root.slideshow = !root.slideshow }
                Btn { icon: "ic_rotate_device_on"; onClicked: root.rot = (root.rot + 1) % 4 }
                Rectangle {
                    width: 34; height: 34; radius: 17
                    color: root.cur && root.isFav(root.cur.path) ? Qt.rgba(1, 0.84, 0.31, 0.25) : "transparent"
                    Text { anchors.centerIn: parent; text: root.cur && root.isFav(root.cur.path) ? "★" : "☆"; font.pixelSize: 20; color: root.cur && root.isFav(root.cur.path) ? "#ffd54f" : root.cText }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (root.cur) root.toggleFav(root.cur.path) }
                }
                Btn { icon: "ic_info"; on: root.showInfo; onClicked: root.showInfo = !root.showInfo }
                Btn { icon: "ic_menu"; onClicked: if (root.cur) Quickshell.execDetached(["xdg-open", root.cur.path]) }
                Rectangle {
                    id: viewerTrash
                    function ask() {
                        if (!root.cur) return
                        if (root.trashArmed === root.cur.path) { Quickshell.execDetached(["gio", "trash", root.cur.path]); root.trashArmed = "" }
                        else { root.trashArmed = root.cur.path; trashTimer.restart() }
                    }
                    width: trashT.implicitWidth + 24; height: 34; radius: 17
                    color: root.trashArmed !== "" ? root.pywal.error : "transparent"
                    Text { id: trashT; anchors.centerIn: parent; text: root.trashArmed !== "" ? "Tap again" : "🗑"; font.family: "OneUI Sans"; font.pixelSize: root.trashArmed !== "" ? QsConfig.Appearance.fontSize.m : 16; color: root.trashArmed !== "" ? root.pywal.readableOn(root.pywal.error) : root.cText }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: viewerTrash.ask() }
                }
            }

            Item {
                id: stage
                anchors.left: parent.left; anchors.top: bar.bottom; anchors.bottom: strip.top
                anchors.right: info.visible ? info.left : parent.right
                anchors.margins: 8
                clip: true

                Image {
                    id: photo
                    readonly property bool sideways: root.rot % 2 === 1
                    width: sideways ? stage.height : stage.width
                    height: sideways ? stage.width : stage.height
                    anchors.centerIn: parent
                    source: root.cur ? "file://" + root.cur.path : ""
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    smooth: true
                    rotation: root.rot * 90
                    scale: root.zoom
                    onSourceChanged: { x = 0; y = 0 }
                    DragHandler { id: pan; enabled: root.zoom > 1; target: photo; xAxis.enabled: true; yAxis.enabled: true }
                }
                BusyIndicatorLike { visible: photo.status === Image.Loading }
                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: event => {
                        root.zoom = Math.max(1, Math.min(8, root.zoom * Math.pow(1.15, event.angleDelta.y / 120)))
                        if (root.zoom === 1) { photo.x = 0; photo.y = 0 }
                    }
                }
                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    onDoubleTapped: { root.zoom = root.zoom > 1 ? 1 : 2.5; photo.x = 0; photo.y = 0 }
                }
                // click the left / right edge to step
                Rectangle { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; width: 40; height: 80; radius: 20; visible: items.count > 1; color: Qt.rgba(0, 0, 0, 0.3)
                    Text { anchors.centerIn: parent; text: "‹"; font.pixelSize: 26; color: "white" }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.step(-1) } }
                Rectangle { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; width: 40; height: 80; radius: 20; visible: items.count > 1; color: Qt.rgba(0, 0, 0, 0.3)
                    Text { anchors.centerIn: parent; text: "›"; font.pixelSize: 26; color: "white" }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.step(1) } }
            }

            // Info panel (Aves' info page): what the model already knows
            Rectangle {
                id: info
                visible: root.showInfo && root.cur !== null
                anchors.right: parent.right; anchors.top: bar.bottom; anchors.bottom: strip.top
                anchors.margins: 8
                width: 250
                radius: QsConfig.Appearance.radius.m
                color: root.cCard
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10
                    Repeater {
                        model: root.cur ? [
                            { k: "Name", v: root.cur.name },
                            { k: "Folder", v: root.cur.path.slice(0, root.cur.path.lastIndexOf("/")) },
                            { k: "Size", v: root.cur.size > 1048576 ? (root.cur.size / 1048576).toFixed(1) + " MB" : Math.max(1, Math.round(root.cur.size / 1024)) + " KB" },
                            { k: "Dimensions", v: photo.implicitWidth > 0 ? photo.implicitWidth + " × " + photo.implicitHeight : "…" },
                            { k: "Modified", v: Qt.formatDateTime(new Date(root.cur.mtime), "d MMM yyyy, HH:mm") },
                            { k: "Position", v: (root.index + 1) + " / " + items.count }
                        ] : []
                        ColumnLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 1
                            Text { text: modelData.k; font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.s; color: root.cSubText }
                            Text { Layout.fillWidth: true; text: modelData.v; wrapMode: Text.WrapAnywhere; font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.m; color: root.cText }
                        }
                    }
                    Item { Layout.fillHeight: true }
                }
            }

            // Thumbnail strip
            ListView {
                id: strip
                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                anchors.margins: 10
                height: 62
                orientation: ListView.Horizontal
                spacing: 6
                clip: true
                model: items
                currentIndex: root.index
                highlightFollowsCurrentItem: false
                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                delegate: Rectangle {
                    required property int index
                    required property string path
                    width: 62; height: 62; radius: 10
                    color: root.cCard
                    border.width: index === root.index ? 2 : 0
                    border.color: root.cPrimary
                    clip: true
                    Image { anchors.fill: parent; source: "file://" + path; sourceSize: Qt.size(128, 128); fillMode: Image.PreserveAspectCrop; asynchronous: true; cache: false; opacity: index === root.index ? 1 : 0.7 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.show(index) }
                }
            }
        }
    }

    // plain text spinner stand-in (no extra component needed)
    component BusyIndicatorLike: Text {
        anchors.centerIn: parent
        text: "…"
        font.pixelSize: 32
        color: root.cSubText
    }

    Component.onCompleted: QsServices.Logger.debug("Viewer", "Loaded")
}
