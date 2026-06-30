import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import Quickshell.Io
import "../../../services" as QsServices
import "../../../components"
import "../../../components/effects"

// ── Wallpaper Picker Panel ─────────────────────────────────────────────────
// Tabs: Local | Wallhaven | Moewalls (video via mpvpaper)
//
// Wallpaper dir : ~/Pictures/Wallpapers/   (static, applied with awww)
// Video dir     : ~/Pictures/Wallpapers/Videos/  (applied with mpvpaper)
// Wallhaven API : https://wallhaven.cc/api/v1/  (SFW, no key needed)
// Moewalls API  : WordPress REST API at moewalls.com/wp-json/wp/v2/
// ──────────────────────────────────────────────────────────────────────────

Item {
    id: root

    signal closeRequested()

    property bool shouldShow: false

    readonly property var pywal: QsServices.Pywal
    readonly property string home: Quickshell.env("HOME")

    property string wallpapersDir: home + "/Pictures/Wallpapers"
    property string videosDir:     home + "/Pictures/Wallpapers/Videos"

    // ── Tab state ─────────────────────────────────────────────────────────
    // 0 = Local  1 = Wallhaven  2 = Moewalls
    property int currentTab: 0

    // ── Local ─────────────────────────────────────────────────────────────
    property var  localFiles:   []
    property bool localLoading: false

    // ── Wallhaven ──────────────────────────────────────────────────────────
    property string whQuery:    ""
    property bool   whAnime:    true
    property bool   whGeneral:  true
    property var    whResults:  []   // [{thumb, full, fname}]
    property bool   whLoading:  false
    property int    whPage:     1
    property int    whLastPage: 1

    // ── Moewalls ───────────────────────────────────────────────────────────
    property string mwQuery:   ""
    property var    mwResults: []   // [{thumb, url, title, isVideo}]
    property bool   mwLoading: false
    property int    mwPage:     1

    // ── Download / apply state ─────────────────────────────────────────────
    property bool   downloading:   false
    property string downloadLabel: ""
    property string currentApplied: ""

    implicitWidth:  360
    implicitHeight: 420

    // ── Init ──────────────────────────────────────────────────────────────
    onShouldShowChanged: {
        if (shouldShow && currentTab === 0 && localFiles.length === 0)
            localListProc.running = true
    }

    onCurrentTabChanged: {
        if (currentTab === 0 && localFiles.length === 0)
            localListProc.running = true
    }

    // ════════════════════════════════════════════════════════════════════════
    // PROCESSES
    // ════════════════════════════════════════════════════════════════════════

    // ── Local: list images ─────────────────────────────────────────────────
    Process {
        id: localListProc
        command: ["bash", "-c",
            `mkdir -p "${root.wallpapersDir}" && ` +
            `find "${root.wallpapersDir}" -maxdepth 2 -type f ` +
            `\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' ` +
            `-o -iname '*.webp' -o -iname '*.gif' \\) 2>/dev/null | sort`]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.localFiles = text.trim().split("\n").filter(f => f.length > 0)
                root.localLoading = false
            }
        }
    }

    // ── Wallhaven: search ──────────────────────────────────────────────────
    Process {
        id: whSearchProc
        property string _url: ""
        command: ["bash", "-c",
            `curl -sf --max-time 12 "${_url}"`]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text)
                    root.whResults = (d.data ?? []).map(w => ({
                        thumb: w.thumbs?.small ?? "",
                        full:  w.path ?? "",
                        fname: w.path?.split("/").pop() ?? `wallhaven-${w.id}.jpg`
                    }))
                    root.whLastPage = d.meta?.last_page ?? 1
                } catch(e) { root.whResults = [] }
                root.whLoading = false
            }
        }
    }

    function whSearch(resetPage) {
        if (resetPage) { root.whPage = 1; root.whLastPage = 1 }
        const cats = (root.whGeneral ? "1" : "0") + (root.whAnime ? "1" : "0") + "0"
        const q    = encodeURIComponent(root.whQuery)
        whSearchProc._url =
            `https://wallhaven.cc/api/v1/search?q=${q}&categories=${cats}` +
            `&purity=100&sorting=date_added&page=${root.whPage}`
        root.whLoading = true
        whSearchProc.running = true
    }

    // ── Moewalls: browse / search ──────────────────────────────────────────
    // Uses WordPress REST API — posts contain embedded videos.
    // Adjust endpoint if moewalls.com changes their WP setup.
    Process {
        id: mwSearchProc
        property string _url: ""
        property string _scriptPath: root.home + "/.config/quickshell/scripts/mw_fetch.py"
        // mw_fetch.py: Playwright ile sayfayı render edip <article> kartlarını
        // (.entry-featured-media a[href], img, .entry-title) parse eder.
        command: ["bash", "-c",
            `LC_ALL=C nix-shell '${root.home}/.config/quickshell/scripts/shell.nix' --run ` +
            `"python3 '${_scriptPath}' '${_url}'"`
        ]
        running: false
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0)
                    console.warn("mwSearchProc stderr:", text.trim())
            }
        }
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const arr = JSON.parse(text.trim())
                    root.mwResults = arr.map(r => Object.assign({}, r, {isVideo: true}))
                } catch(e) {
                    console.warn("mwSearchProc parse error:", e, "raw:", text)
                    root.mwResults = []
                }
                root.mwLoading = false
            }
        }
    }

    function mwSearch(resetPage) {
        if (resetPage) root.mwPage = 1
        const q = root.mwQuery.trim()
        mwSearchProc._url = q
            ? `https://moewalls.com/page/${root.mwPage}/?s=${encodeURIComponent(q)}`
            : `https://moewalls.com/page/${root.mwPage}/`
        root.mwLoading = true
        mwSearchProc.running = true
    }

    // ── Download ───────────────────────────────────────────────────────────
    Process {
        id: downloadProc
        property string _dest:    ""
        property bool   _isVideo: false
        command: ["bash", "-c",
            `mkdir -p "${_isVideo ? root.videosDir : root.wallpapersDir}" && ` +
            `curl -Lf --max-time 60 -o "${_dest}" "${_url}"`]
        property string _url: ""
        running: false
        onExited: (code, status) => {
            root.downloading = false
            if (code === 0) applyProc.applyPath(_dest, _isVideo)
            else root.downloadLabel = "Download failed"
        }
    }

    // ── Moewalls: tekil sayfadan gerçek video URL'sini çöz ──────────────────
    // Playwright gerekmiyor; video path'i statik HTML'de gömülü geliyor.
    Process {
        id: mwResolveProc
        property string _pageUrl: ""
        property string _scriptPath: root.home + "/.config/quickshell/scripts/mw_resolve.py"
        command: ["bash", "-c", `python3 '${_scriptPath}' '${_pageUrl}'`]
        running: false
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0)
                    console.warn("mwResolveProc stderr:", text.trim())
            }
        }
        stdout: StdioCollector {
            onStreamFinished: {
                const videoUrl = text.trim()
                if (videoUrl.length > 0) {
                    root.downloadAndApply(videoUrl, true)
                } else {
                    root.downloading   = false
                    root.downloadLabel = "Video linki bulunamadı"
                    console.warn("mwResolveProc: video URL boş döndü, sayfa:", _pageUrl)
                }
            }
        }
    }

    function mwResolveAndApply(pageUrl) {
        if (root.downloading) return
        root.downloading   = true
        root.downloadLabel = "Video linki çözülüyor…"
        mwResolveProc._pageUrl = pageUrl
        mwResolveProc.running  = true
    }

    function downloadAndApply(url, isVideo) {
        const fname   = url.split("/").pop().split("?")[0]
        const destDir = isVideo ? root.videosDir : root.wallpapersDir
        const dest    = destDir + "/" + fname
        root.downloading   = true
        root.downloadLabel = "Downloading " + fname + "…"
        downloadProc._url     = url
        downloadProc._dest    = dest
        downloadProc._isVideo = isVideo
        downloadProc.running  = true
    }

    // ── Apply ──────────────────────────────────────────────────────────────
    Process {
        id: applyProc
        property string _path:    ""
        property bool   _isVideo: false

        // static: awww img <path> --transition-type fade
        // video : kill existing mpvpaper, then mpvpaper -o "no-audio loop" '*' <path>
        command: _isVideo
            ? ["bash", "-c",
                `pkill -x mpvpaper 2>/dev/null; sleep 0.3; ` +
                `setsid -f mpvpaper -o "no-audio loop" '*' "${_path}" ` +
                `</dev/null >/tmp/mpvpaper.log 2>&1`]
            : ["bash", "-c",
                `pkill -x mpvpaper 2>/dev/null; ` +
                `awww img "${_path}" --transition-type fade --transition-duration 1`]
        running: false

        function applyPath(path, isVideo) {
            applyProc._path    = path
            applyProc._isVideo = isVideo
            applyProc.running  = true
        }

        onExited: (code, status) => {
            if (code === 0) {
                root.currentApplied = _path
                saveStateProc._service = _isVideo ? "mpvpaper" : "awww"
                saveStateProc._wpath   = _path
                saveStateProc.running  = true
                root.closeRequested()
            }
        }
    }

    // ── Persist last-used wallpaper ────────────────────────────────────────
    // Writes ~/.cache/qs-wallpaper-last.json → {"service": "...", "path": "..."}
    // restore-wallpaper.sh reads this on login to replay the correct tool.
    Process {
        id: saveStateProc
        property string _service: ""
        property string _wpath:   ""
        // Use bash -c so we can safely interpolate via env vars
        command: ["bash", "-c",
            `python3 -c "import json,os; json.dump({'service':os.environ['SVC'],'path':os.environ['WP']},open(os.environ['HOME']+'/.cache/qs-wallpaper-last.json','w'))"`
        ]
        environment: ({"SVC": _service, "WP": _wpath})
        running: false
    }

    function applyLocal(path) {
        applyProc.applyPath(path, false)
    }

    // ════════════════════════════════════════════════════════════════════════
    // UI
    // ════════════════════════════════════════════════════════════════════════

    AuroraSurface {
        anchors.fill: parent
        radius: 16
        color: pywal.surfaceContainerHigh
        strokeColor: pywal.outlineVariant
        borderWidth: 1
        accentColor: pywal.primary
        elevation: 4

        Column {
            anchors {
                fill: parent
                margins: 12
            }
            spacing: 8

            // ── Header ──────────────────────────────────────────────────
            RowLayout {
                width: parent.width
                Text {
                    text: "󰸉  Wallpaper"
                    font.family: "Inter"; font.pixelSize: 12; font.weight: 600
                    color: pywal.foreground
                }
                Item { Layout.fillWidth: true }
                Text {
                    visible: root.downloading
                    text: root.downloadLabel
                    font.family: "Inter"; font.pixelSize: 9
                    color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.5)
                    elide: Text.ElideRight
                    Layout.maximumWidth: 160
                }
            }

            // ── Tab bar ──────────────────────────────────────────────────
            Row {
                spacing: 4
                Repeater {
                    model: ["Local", "Wallhaven", "Moewalls"]
                    Rectangle {
                        required property string modelData
                        required property int    index
                        width: tabLabel.implicitWidth + 16
                        height: 22
                        radius: 10
                        color: root.currentTab === index
                            ? Qt.rgba(pywal.primary.r, pywal.primary.g, pywal.primary.b, 0.25)
                            : tabMouse.containsMouse
                                ? Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.08)
                                : "transparent"
                        border.width: root.currentTab === index ? 1 : 0
                        border.color: Qt.rgba(pywal.primary.r, pywal.primary.g, pywal.primary.b, 0.5)
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text {
                            id: tabLabel
                            anchors.centerIn: parent
                            text: modelData
                            font.family: "Inter"; font.pixelSize: 10; font.weight: Font.Medium
                            color: root.currentTab === index
                                ? pywal.primary
                                : Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.65)
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                        MouseArea {
                            id: tabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.currentTab = index
                        }
                    }
                }
            }

            // ── Search bar (Wallhaven / Moewalls) ────────────────────────
            Rectangle {
                visible: root.currentTab > 0
                width: parent.width
                height: 28
                radius: 8
                color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.07)
                border.width: searchInput.activeFocus ? 1 : 0
                border.color: Qt.rgba(pywal.primary.r, pywal.primary.g, pywal.primary.b, 0.6)
                Behavior on border.color { ColorAnimation { duration: 120 } }

                RowLayout {
                    anchors { fill: parent; leftMargin: 8; rightMargin: 4 }
                    Text {
                        text: "󰍉"
                        font.family: "Material Design Icons"; font.pixelSize: 12
                        color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.45)
                    }
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: searchInput.implicitHeight

                        TextInput {
                            id: searchInput
                            anchors.fill: parent
                            font.family: "Inter"; font.pixelSize: 10
                            color: pywal.foreground
                            clip: true
                            onTextChanged: {
                                if (root.currentTab === 1) root.whQuery = text
                                else root.mwQuery = text
                            }
                            Keys.onReturnPressed: {
                                if (root.currentTab === 1) root.whSearch(true)
                                else root.mwSearch(true)
                            }
                        }

                        // Placeholder overlay
                        Text {
                            anchors.fill: parent
                            visible: searchInput.text.length === 0 && !searchInput.activeFocus
                            text: root.currentTab === 1 ? "Search Wallhaven…" : "Search Moewalls…"
                            font.family: "Inter"; font.pixelSize: 10
                            color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.35)
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                    // Category toggles for Wallhaven
                    Row {
                        visible: root.currentTab === 1
                        spacing: 4
                        Repeater {
                            model: [
                                { label: "G", prop: "whGeneral" },
                                { label: "A", prop: "whAnime"   }
                            ]
                            Rectangle {
                                required property var modelData
                                width: 18; height: 18; radius: 4
                                color: root[modelData.prop]
                                    ? Qt.rgba(pywal.primary.r, pywal.primary.g, pywal.primary.b, 0.3)
                                    : Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.1)
                                Behavior on color { ColorAnimation { duration: 100 } }
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    font.family: "Inter"; font.pixelSize: 9; font.weight: Font.Bold
                                    color: root[modelData.prop] ? pywal.primary : Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.5)
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root[modelData.prop] = !root[modelData.prop]
                                }
                            }
                        }
                        // Search button
                        Rectangle {
                            width: 18; height: 18; radius: 4
                            color: whGoMouse.containsMouse
                                ? Qt.rgba(pywal.primary.r, pywal.primary.g, pywal.primary.b, 0.35)
                                : Qt.rgba(pywal.primary.r, pywal.primary.g, pywal.primary.b, 0.15)
                            Behavior on color { ColorAnimation { duration: 100 } }
                            Text {
                                anchors.centerIn: parent
                                text: "󰑓"; font.family: "Material Design Icons"; font.pixelSize: 10
                                color: pywal.primary
                            }
                            MouseArea {
                                id: whGoMouse
                                anchors.fill: parent
                                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: root.whSearch(true)
                            }
                        }
                    }
                    // Search button for Moewalls
                    Rectangle {
                        visible: root.currentTab === 2
                        width: 18; height: 18; radius: 4
                        color: mwGoMouse.containsMouse
                            ? Qt.rgba(pywal.primary.r, pywal.primary.g, pywal.primary.b, 0.35)
                            : Qt.rgba(pywal.primary.r, pywal.primary.g, pywal.primary.b, 0.15)
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Text {
                            anchors.centerIn: parent
                            text: "󰑓"; font.family: "Material Design Icons"; font.pixelSize: 10
                            color: pywal.primary
                        }
                        MouseArea {
                            id: mwGoMouse
                            anchors.fill: parent
                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: root.mwSearch(true)
                        }
                    }
                }
            }

            // ── Content area (fixed height, scrollable) ──────────────────
            Item {
                width: parent.width
                height: 280

                // Loading spinner text
                Text {
                    anchors.centerIn: parent
                    visible: (root.currentTab === 0 && root.localLoading)
                          || (root.currentTab === 1 && root.whLoading)
                          || (root.currentTab === 2 && root.mwLoading)
                    text: "Loading…"
                    font.family: "Inter"; font.pixelSize: 11
                    color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.45)
                }

                // Empty state
                Column {
                    anchors.centerIn: parent
                    spacing: 4
                    visible: !( (root.currentTab === 0 && root.localLoading)
                             || (root.currentTab === 1 && root.whLoading)
                             || (root.currentTab === 2 && root.mwLoading) )
                          && ( (root.currentTab === 0 && root.localFiles.length  === 0)
                             || (root.currentTab === 1 && root.whResults.length  === 0)
                             || (root.currentTab === 2 && root.mwResults.length  === 0) )

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.currentTab === 0 ? "No images in\n" + root.wallpapersDir
                            : root.currentTab === 1 ? "Search Wallhaven above"
                            : "Search Moewalls above\nor press ↩ to browse"
                        font.family: "Inter"; font.pixelSize: 10
                        color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.45)
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }
                }

                // ── LOCAL grid ────────────────────────────────────────────
                Flickable {
                    anchors.fill: parent
                    visible: root.currentTab === 0
                    contentHeight: localGrid.implicitHeight
                    clip: true

                    Grid {
                        id: localGrid
                        width: parent.width
                        columns: 3
                        spacing: 6

                        Repeater {
                            model: root.localFiles
                            delegate: WallpaperThumb {
                                required property string modelData
                                thumbPath: modelData
                                gridWidth: localGrid.width
                                isActive: root.currentApplied === modelData
                                isVideo: false
                                pywal: root.pywal
                                onActivated: root.applyLocal(modelData)
                            }
                        }
                    }
                }

                // ── WALLHAVEN grid ────────────────────────────────────────
                Flickable {
                    anchors.fill: parent
                    visible: root.currentTab === 1
                    contentHeight: whGrid.implicitHeight
                    clip: true

                    Grid {
                        id: whGrid
                        width: parent.width
                        columns: 3
                        spacing: 6

                        Repeater {
                            model: root.whResults
                            delegate: WallpaperThumb {
                                required property var modelData
                                thumbUrl: modelData.thumb
                                gridWidth: whGrid.width
                                isActive: root.currentApplied === modelData.full
                                isVideo: false
                                pywal: root.pywal
                                onActivated: root.downloadAndApply(modelData.full, false)
                            }
                        }
                    }
                }

                // ── MOEWALLS grid ─────────────────────────────────────────
                Flickable {
                    anchors.fill: parent
                    visible: root.currentTab === 2
                    contentHeight: mwGrid.implicitHeight
                    clip: true

                    Grid {
                        id: mwGrid
                        width: parent.width
                        columns: 3
                        spacing: 6

                        Repeater {
                            model: root.mwResults
                            delegate: WallpaperThumb {
                                required property var modelData
                                thumbUrl: modelData.thumb
                                label: modelData.title
                                gridWidth: mwGrid.width
                                isActive: root.currentApplied === modelData.url
                                isVideo: true
                                pywal: root.pywal
                                onActivated: root.mwResolveAndApply(modelData.url)
                            }
                        }
                    }
                }
            }

            // ── Footer: pagination + rescan ───────────────────────────────
            RowLayout {
                width: parent.width

                // Rescan (Local tab)
                Rectangle {
                    visible: root.currentTab === 0
                    width: 70; height: 22; radius: 6
                    color: rescanMouse.containsMouse
                        ? Qt.rgba(pywal.primary.r, pywal.primary.g, pywal.primary.b, 0.18)
                        : Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.07)
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text {
                        anchors.centerIn: parent
                        text: "󰑐 Rescan"
                        font.family: "Inter"; font.pixelSize: 9
                        color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.7)
                    }
                    MouseArea {
                        id: rescanMouse
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.localFiles = []; root.localLoading = true
                            localListProc.running = true
                        }
                    }
                }

                // Pagination (Wallhaven / Moewalls)
                RowLayout {
                    visible: root.currentTab > 0
                    spacing: 6

                    PaginationBtn {
                        text: "←"
                        enabled: root.currentTab === 1 ? root.whPage > 1 : root.mwPage > 1
                        pywal: root.pywal
                        onClicked: {
                            if (root.currentTab === 1) { root.whPage--; root.whSearch(false) }
                            else                       { root.mwPage--; root.mwSearch(false) }
                        }
                    }

                    Text {
                        text: root.currentTab === 1
                            ? `${root.whPage} / ${root.whLastPage}`
                            : `${root.mwPage}`
                        font.family: "Inter"; font.pixelSize: 9
                        color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.55)
                    }

                    PaginationBtn {
                        text: "→"
                        enabled: root.currentTab === 1
                            ? root.whPage < root.whLastPage
                            : root.mwResults.length === 9
                        pywal: root.pywal
                        onClicked: {
                            if (root.currentTab === 1) { root.whPage++; root.whSearch(false) }
                            else                       { root.mwPage++; root.mwSearch(false) }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // mpvpaper note for Moewalls
                Text {
                    visible: root.currentTab === 2
                    text: "via mpvpaper"
                    font.family: "Inter"; font.pixelSize: 8
                    color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.35)
                }
            }
        }
    }

    // ════════════════════════════════════════════════════════════════════════
    // INLINE COMPONENTS
    // ════════════════════════════════════════════════════════════════════════

    // Thumbnail cell (reused for all three tabs)
    component WallpaperThumb: Rectangle {
        id: thumbCell

        signal activated()

        property string thumbPath: ""  // local file path  → "file://" + thumbPath
        property string thumbUrl:  ""  // remote URL       → thumbUrl directly
        property string label:     ""
        property real   gridWidth: 300
        property bool   isActive:  false
        property bool   isVideo:   false
        property var    pywal

        width:  (gridWidth - 12) / 3
        height: 40
        radius: 6
        clip:   true

        color: cellMouse.containsMouse
            ? Qt.rgba(pywal.primary.r, pywal.primary.g, pywal.primary.b, 0.2)
            : Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.06)
        border.width: isActive ? 2 : 0
        border.color: pywal.primary
        Behavior on color { ColorAnimation { duration: 100 } }

        Image {
            anchors.fill: parent
            anchors.margins: 2
            source: thumbCell.thumbPath !== "" ? ("file://" + thumbCell.thumbPath) : thumbCell.thumbUrl
            fillMode: Image.PreserveAspectCrop
            asynchronous: true; smooth: true
            visible: status === Image.Ready
        }

        // Video badge
        Text {
            visible: thumbCell.isVideo
            anchors { top: parent.top; right: parent.right; margins: 3 }
            text: "▶"
            font.pixelSize: 8
            color: "white"
            style: Text.Outline; styleColor: "#00000080"
        }

        // Hover label
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width; height: 13
            color: Qt.rgba(0, 0, 0, 0.55)
            visible: cellMouse.containsMouse && thumbCell.label !== ""
            Text {
                anchors.centerIn: parent
                width: parent.width - 4
                text: thumbCell.label !== ""
                    ? thumbCell.label
                    : (thumbCell.thumbPath !== ""
                        ? thumbCell.thumbPath.split("/").pop()
                        : thumbCell.thumbUrl.split("/").pop().split("?")[0])
                font.family: "Inter"; font.pixelSize: 7
                color: "white"; elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
            }
        }

        scale: cellMouse.pressed ? 0.93 : cellMouse.containsMouse ? 1.04 : 1.0
        Behavior on scale { NumberAnimation { duration: 90 } }

        MouseArea {
            id: cellMouse
            anchors.fill: parent; hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: thumbCell.activated()
        }
    }

    // Tiny pagination button
    component PaginationBtn: Rectangle {
        id: pgBtn
        signal clicked()
        property string text: ""
        property bool   enabled: true
        property var    pywal

        width: 26; height: 22; radius: 6
        opacity: pgBtn.enabled ? 1.0 : 0.35
        color: pgMouse.containsMouse && pgBtn.enabled
            ? Qt.rgba(pywal.primary.r, pywal.primary.g, pywal.primary.b, 0.22)
            : Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.07)
        Behavior on color { ColorAnimation { duration: 100 } }
        Text {
            anchors.centerIn: parent
            text: pgBtn.text
            font.family: "Inter"; font.pixelSize: 11
            color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.75)
        }
        MouseArea {
            id: pgMouse; anchors.fill: parent
            enabled: pgBtn.enabled; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: pgBtn.clicked()
        }
    }
}
