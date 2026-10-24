import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "../../../services" as QsServices
import "../../../components"
import "../../../components/effects"
import "../../../config" as QsConfig

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
    property int  localSubTab:  0   // 0 = Images  1 = Videos
    readonly property string videoThumbCacheDir: home + "/.cache/qs-video-thumbs"
    function videoThumbFor(path) {
        return videoThumbCacheDir + "/" + path.split("/").pop() + ".jpg"
    }

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
    // false = desktop wallpaper, true = the lock screen's own wallpaper (user.json lock.wallpaper, images only)
    property bool   lockTarget: false
    property string notice: ""

    implicitWidth:  360
    implicitHeight: 460

    // ── Init ──────────────────────────────────────────────────────────────
    property int _localScanGen: 0

    function rescanLocal() {
        root._localScanGen++
        root.localFiles   = []
        root.localLoading = true

        // We compute the command here, imperatively, from the CURRENT localSubTab
        // value and hand it to the Process as a plain string. Previously
        // "command" was a binding that depended on root.localSubTab; when the sub-tab
        // changed (Images -> Videos), re-evaluating that binding and actually
        // starting the Process happened in the same JS turn, and in practice the
        // command sometimes STILL targeted the old directory (Images) ->
        // ffmpeg treated image files as videos and failed to produce thumbnails
        // (the "could not extract thumbnail from image folder" error in the logs
        // came from here). We no longer rely on any binding; the command string
        // is built directly here.
        const dir  = root.localSubTab === 0 ? root.wallpapersDir : root.videosDir
        const exts = root.localSubTab === 0
            ? `\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' \\)`
            : `\\( -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' -o -iname '*.mov' \\)`

        let cmd
        if (root.localSubTab === 1) {
            cmd = `mkdir -p "${dir}" "${root.videoThumbCacheDir}"; ` +
                  `find "${dir}" -maxdepth 2 -type f ${exts} 2>/dev/null | sort | while IFS= read -r f; do ` +
                  `  b=$(basename "$f"); t="${root.videoThumbCacheDir}/$b.jpg"; ` +
                  `  [ -f "$t" ] || ffmpeg -y -ss 00:00:01 -i "$f" -frames:v 1 -vf "scale=320:-1" "$t" >>/tmp/qs-video-thumb.log 2>&1; ` +
                  `  echo "$f"; ` +
                  `done`
        } else {
            cmd = `mkdir -p "${dir}" && find "${dir}" -maxdepth 2 -type f ${exts} 2>/dev/null | sort`
        }

        localListProc._gen = root._localScanGen
        localListProc._cmd = cmd

        // If the process is already running, "running = true" is a no-op and the old
        // directory keeps being scanned; so it is stopped explicitly first.
        if (localListProc.running) localListProc.running = false
        localListProc.running = true
    }

    onShouldShowChanged: {
        if (shouldShow && currentTab === 0) rescanLocal()
    }

    onCurrentTabChanged: {
        if (currentTab === 0) rescanLocal()
    }

    onLocalSubTabChanged: rescanLocal()

    // ════════════════════════════════════════════════════════════════════════
    // PROCESSES
    // ════════════════════════════════════════════════════════════════════════

    // ── Local: list images or videos (depending on localSubTab) ─────────────
    Process {
        id: localListProc
        property string _cmd: ""
        property int    _gen: 0
        command: ["bash", "-c", _cmd]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                // If the tab/subtab changed since this process started, the result
                // is stale (it belongs to another folder); discard it.
                if (localListProc._gen !== root._localScanGen) return
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
    // Calls mw_fetch.py (with BeautifulSoup) via ~/.cache/mw-venv.
    // The previous regex-python version embedded in QML always returned an
    // empty result because the quote escaping got broken passing through the
    // JS template literal + bash heredoc + python raw-string layers.
    Process {
        id: mwSearchProc
        property string _url: ""
        property string _toolPath: root.home + "/.config/quickshell/scripts/mw-tool"
        command: [_toolPath, "fetch", _url]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const arr = JSON.parse(text.trim())
                    root.mwResults = arr.map(r => Object.assign({}, r, {isVideo: true}))
                } catch(e) { root.mwResults = [] }
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
        property string _url: ""
        readonly property string _ua: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
        // Referer only makes sense for Moewalls (its CDN wants it). Sending
        // a moewalls.com referer to Wallhaven's CDN unconditionally — as
        // this used to do for BOTH sources — trips hotlink/referer checks
        // on Wallhaven's side and silently fails the download.
        command: ["bash", "-c",
            `mkdir -p "${_isVideo ? root.videosDir : root.wallpapersDir}" && ` +
            `curl -Lf --max-time 60 --retry 3 --retry-delay 1 ` +
            `-A "${_ua}" ${_isVideo ? '-e "https://moewalls.com/" ' : ""}` +
            `-o "${_dest}" "${_url}"`]
        running: false
        property string _lastErr: ""
        stderr: StdioCollector {
            onStreamFinished: downloadProc._lastErr = text.trim().split("\n").pop()
        }
        onExited: (code, status) => {
            if (code === 0) {
                applyProc.applyPath(_dest, _isVideo)
            } else {
                downloadTimeoutTimer.stop()
                root.downloading = false
                root.downloadLabel = "Download failed (curl exit " + code + ")" +
                    (downloadProc._lastErr ? (": " + downloadProc._lastErr) : "")
            }
        }
    }

    // ── Moewalls: resolve detail page → actual video file URL ───────────────
    Process {
        id: mwResolveProc
        property string _detailUrl: ""
        property string _toolPath: root.home + "/.config/quickshell/scripts/mw-tool"
        property string _lastErr: ""
        command: [_toolPath, "resolve", _detailUrl]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                downloadTimeoutTimer.stop()
                const videoUrl = text.trim()
                if (videoUrl) {
                    root.downloadAndApply(videoUrl, true)
                } else {
                    root.downloadLabel = "Video URL resolve edilemedi" +
                        (mwResolveProc._lastErr ? (": " + mwResolveProc._lastErr) : "")
                    root.downloading = false
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: mwResolveProc._lastErr = text.trim().split("\n").pop()
        }
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
        downloadTimeoutTimer.restart()
        if (downloadProc.running) downloadProc.running = false
        downloadProc.running  = true
    }

    // ── Apply ──────────────────────────────────────────────────────────────
    Process {
        id: applyProc
        property string _path:    ""
        property bool   _isVideo: false
        property string _pidFile: root.home + "/.cache/qs-mpvpaper.pid"

        // "pkill -x mpvpaper" killed nothing because the mpvpaper script
        // internally does "exec mpv ..." -- the process name becomes mpv, and no
        // process called mpvpaper exists anymore. Instead we write our own PID to a file
        // and kill from that (pkill -x mpvpaper is no longer used at all).
        // The video is detached COMPLETELY from Quickshell's process tree with
        // setsid+nohup; when the popup closes and this Process object is destroyed,
        // the child process no longer dies.
        // lastwlpp is now written inside this command itself rather than by a separate
        // saveStateProc -- relying on the run/onExited order of a separate Process
        // proved unreliable in practice (it sometimes never fired).
        // On a video->video switch, if the old one is killed first and then the new one
        // started, an awww/empty layer was briefly visible in between (flash).
        // Instead the new instance is started first and we wait until "VO:" (first frame
        // rendered) appears in the log; only then is the old instance killed
        // -> no visible gap during the transition.
        command: _isVideo
            ? ["bash", "-c",
                `mkdir -p "${root.home}/.cache/wallpaper"; ` +
                `printf 'mpvpaper -o "no-audio loop no-border panscan=1.0" '"'"'*'"'"' %q\\n' "${_path}" ` +
                `> "${root.home}/.cache/wallpaper/lastwlpp"; ` +
                // We start the new mpvpaper FIRST, wait (max ~5s) until the "VO:" (video output
                // ready) line appears in the log, and only AFTER that kill the old
                // instance. That way the old one doesn't disappear before the new video
                // layer is on screen -> the brief flash of the awww/empty layer
                // is avoided.
                `: > /tmp/mpvpaper_new.log; ` +
                `setsid nohup mpvpaper -o "no-audio loop no-border panscan=1.0" '*' "${_path}" ` +
                `>/tmp/mpvpaper_new.log 2>&1 </dev/null & ` +
                `NEWPID=$!; ` +
                `for i in $(seq 1 50); do grep -q '^VO:' /tmp/mpvpaper_new.log 2>/dev/null && break; kill -0 "$NEWPID" 2>/dev/null || break; sleep 0.1; done; ` +
                `OLDPID=$(cat "${_pidFile}" 2>/dev/null); ` +
                `echo $NEWPID > "${_pidFile}"; ` +
                `mv -f /tmp/mpvpaper_new.log /tmp/mpvpaper.log; ` +
                `if [ -n "$OLDPID" ]; then kill -9 "$OLDPID" 2>/dev/null; fi; exit 0`]
            : ["bash", "-c",
                `mkdir -p "${root.home}/.cache/wallpaper"; ` +
                `printf 'awww img %q --transition-type fade --transition-duration 1\\n' "${_path}" ` +
                `> "${root.home}/.cache/wallpaper/lastwlpp"; ` +
                `[ -f "${_pidFile}" ] && kill -9 "$(cat "${_pidFile}")" 2>/dev/null; rm -f "${_pidFile}"; ` +
                `pkill -x mpvpaper 2>/dev/null; ` +
                `awww img "${_path}" --transition-type fade --transition-duration 1`]
        running: false
        property string _lastErr: ""
        stderr: StdioCollector {
            onStreamFinished: applyProc._lastErr = text.trim().split("\n").pop()
        }

        function applyPath(path, isVideo) {
            if (root.lockTarget) {
                downloadTimeoutTimer.stop()
                root.downloading = false
                if (isVideo) { root.notice = "The lock screen takes images only"; return }
                QsConfig.Config.set("lock.wallpaper", path)
                root.notice = "Lock screen wallpaper set"
                return
            }
            applyProc._path    = path
            applyProc._isVideo = isVideo
            root.downloading   = true
            root.downloadLabel = isVideo ? "Setting wallpaper (mpvpaper)…" : "Setting wallpaper…"
            downloadTimeoutTimer.restart()
            // If two clicks come back to back (e.g. a video immediately followed by an image),
            // the old command still running could make the new command a no-op;
            // so it is stopped explicitly first.
            if (applyProc.running) applyProc.running = false
            applyProc.running = true
        }

        onExited: (code, status) => {
            downloadTimeoutTimer.stop()
            root.downloading = false
            if (code === 0) {
                root.currentApplied = _path
                root.pywal.generate(_path)
                // lastwlpp was already written inside applyProc's command, BEFORE
                // apply succeeded/failed; no need to write it again here.
            } else {
                // Wallpaper could not be set; see /tmp/mpvpaper.log for details
                // or applyProc._lastErr. We don't close the popup in this case
                // so the user can see the error message.
                root.downloadLabel = "Wallpaper apply failed (exit " + code + ")" +
                    (applyProc._lastErr ? (": " + applyProc._lastErr) : "")
                return
            }
            // The video now runs independently in the background (setsid+nohup),
            // bash -c returns immediately -- we can close the popup without waiting.
            root.closeRequested()
        }
    }

    function applyLocal(path) {
        applyProc.applyPath(path, false)
    }

    // ── Safety timeout ──────────────────────────────────────────────────────
    // So that the UI doesn't get stuck forever on "Resolving video…" or
    // "Downloading…" if one of the resolve / download / apply processes
    // never finishes (network, mw-tool, mpvpaper spawn failure, etc.).
    Timer {
        id: downloadTimeoutTimer
        interval: 20000
        repeat: false
        onTriggered: {
            if (!root.downloading) return
            root.downloading = false
            root.downloadLabel = "Timed out: the operation did not finish within 20 s"
            if (mwResolveProc.running) mwResolveProc.running = false
            if (downloadProc.running)  downloadProc.running  = false
            if (applyProc.running)     applyProc.running     = false
        }
    }

    // ════════════════════════════════════════════════════════════════════════
    // UI  (One UI 8: pill segmented control, rounded 16:10 cards, check badge)
    // ════════════════════════════════════════════════════════════════════════

    readonly property bool tabLoading: currentTab === 0 ? localLoading : currentTab === 1 ? whLoading : mwLoading

    // One normalised list for the grid, whatever the tab: {thumb, label, key, video}
    readonly property var gridItems: currentTab === 0
        ? localFiles.map(f => ({
            thumb: "file://" + (localSubTab === 1 ? videoThumbFor(f) : f),
            label: f.split("/").pop(), key: f, video: localSubTab === 1 }))
        : currentTab === 1
            ? whResults.map(w => ({ thumb: w.thumb, label: w.fname, key: w.full, video: false }))
            : mwResults.map(r => ({ thumb: r.thumb, label: r.title ?? "", key: r.url, video: true }))

    function activate(it) {
        notice = ""
        if (lockTarget && it.video) { notice = "The lock screen takes images only"; return }
        if (currentTab === 0)      applyProc.applyPath(it.key, it.video)
        else if (currentTab === 1) downloadAndApply(it.key, false)
        else {
            downloading = true
            downloadLabel = "Resolving video…"
            mwResolveProc._detailUrl = it.key
            downloadTimeoutTimer.restart()
            if (mwResolveProc.running) mwResolveProc.running = false
            mwResolveProc.running = true
        }
    }

    function search() { currentTab === 1 ? whSearch(true) : mwSearch(true) }

    AuroraSurface {
        anchors.fill: parent
        radius: QsConfig.Appearance.radius.l
        color: pywal.surfaceContainerHigh
        borderWidth: 0
        accentColor: pywal.primary
        elevation: 1

        ColumnLayout {
            anchors { fill: parent; margins: 14 }
            spacing: 10

            // ── Header ──────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                OneUIIcon { name: "mdi_wallpaper"; size: 20; color: pywal.primary }
                Text {
                    text: "Wallpaper"
                    font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.l; font.weight: 600
                    color: pywal.foreground
                }
                Item { Layout.fillWidth: true }
                Text {
                    visible: root.downloading || root.notice !== ""
                    text: root.downloading ? root.downloadLabel : root.notice
                    font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.xs
                    color: pywal.primary
                    elide: Text.ElideRight
                    Layout.maximumWidth: 170
                }
            }

            // ── Target: desktop or lock screen ──────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: ["Desktop", "Lock screen"]
                    Rectangle {
                        required property string modelData
                        required property int index
                        implicitWidth: tgtText.implicitWidth + 28
                        implicitHeight: 30
                        radius: height / 2
                        readonly property bool on: root.lockTarget === (index === 1)
                        color: on ? pywal.primaryContainer : "transparent"
                        border.width: on ? 0 : 1
                        border.color: pywal.outlineVariant
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Text {
                            id: tgtText
                            anchors.centerIn: parent
                            text: modelData
                            font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.xs; font.weight: 500
                            color: parent.on ? pywal.primary : pywal.onSurfaceMuted
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { root.lockTarget = index === 1; root.notice = "" }
                        }
                    }
                }
                Item { Layout.fillWidth: true }
            }

            // ── Segmented control ───────────────────────────────────────
            Rectangle {
                id: seg
                Layout.fillWidth: true
                implicitHeight: 38
                radius: height / 2
                color: pywal.surfaceContainerHighest

                readonly property var names: ["Local", "Wallhaven", "Moewalls"]

                Rectangle {   // sliding highlight
                    width: (seg.width - 8) / 3; height: seg.height - 8
                    y: 4; x: 4 + root.currentTab * width
                    radius: height / 2
                    color: pywal.primary
                    Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                }
                Row {
                    anchors { fill: parent; margins: 4 }
                    Repeater {
                        model: seg.names
                        Item {
                            required property string modelData
                            required property int index
                            width: (seg.width - 8) / 3; height: seg.height - 8
                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.s; font.weight: 600
                                color: root.currentTab === index ? pywal.onPrimary : pywal.onSurfaceMuted
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.currentTab = index
                            }
                        }
                    }
                }
            }

            // ── Local: Images / Videos chips + rescan ───────────────────
            RowLayout {
                visible: root.currentTab === 0
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: ["Images", "Videos"]
                    Rectangle {
                        required property string modelData
                        required property int index
                        implicitWidth: chipText.implicitWidth + 28
                        implicitHeight: 30
                        radius: height / 2
                        color: root.localSubTab === index ? pywal.primaryContainer : "transparent"
                        border.width: root.localSubTab === index ? 0 : 1
                        border.color: pywal.outlineVariant
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Text {
                            id: chipText
                            anchors.centerIn: parent
                            text: modelData
                            font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.xs; font.weight: 500
                            color: root.localSubTab === index ? pywal.primary : pywal.onSurfaceMuted
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: root.localSubTab = index
                        }
                    }
                }
                Item { Layout.fillWidth: true }
                RoundBtn { icon: "mdi_refresh"; onClicked: root.rescanLocal() }
            }

            // ── Search pill (Wallhaven / Moewalls) ──────────────────────
            Rectangle {
                visible: root.currentTab > 0
                Layout.fillWidth: true
                implicitHeight: 40
                radius: height / 2
                color: pywal.surfaceContainerHighest
                border.width: searchInput.activeFocus ? 2 : 0
                border.color: pywal.primary

                RowLayout {
                    anchors { fill: parent; leftMargin: 14; rightMargin: 5 }
                    spacing: 8
                    OneUIIcon { name: "ic_search_24dp"; size: 18; color: pywal.onSurfaceMuted }
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: searchInput.implicitHeight
                        TextInput {
                            id: searchInput
                            anchors.fill: parent
                            font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.s
                            color: pywal.foreground
                            clip: true
                            onTextChanged: root.currentTab === 1 ? root.whQuery = text : root.mwQuery = text
                            Keys.onReturnPressed: root.search()
                        }
                        Text {
                            anchors.fill: parent
                            visible: searchInput.text.length === 0
                            text: root.currentTab === 1 ? "Search Wallhaven" : "Search Moewalls (↩ to browse)"
                            font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.s
                            color: pywal.onSurfaceMuted
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }
                    }
                    Repeater {   // Wallhaven categories
                        model: root.currentTab === 1
                            ? [ { label: "General", prop: "whGeneral" }, { label: "Anime", prop: "whAnime" } ] : []
                        Rectangle {
                            required property var modelData
                            implicitWidth: catText.implicitWidth + 18; implicitHeight: 28; radius: 14
                            color: root[modelData.prop] ? pywal.primaryContainer : "transparent"
                            border.width: root[modelData.prop] ? 0 : 1
                            border.color: pywal.outlineVariant
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Text {
                                id: catText
                                anchors.centerIn: parent
                                text: modelData.label
                                font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.xxs; font.weight: 500
                                color: root[modelData.prop] ? pywal.primary : pywal.onSurfaceMuted
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: root[modelData.prop] = !root[modelData.prop]
                            }
                        }
                    }
                    RoundBtn { icon: "ic_search_24dp"; filled: true; onClicked: root.search() }
                }
            }

            // ── Grid ────────────────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 120

                GridView {
                    id: grid
                    anchors.fill: parent
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: root.gridItems
                    readonly property int cols: Math.max(2, Math.floor(width / 170))
                    cellWidth: Math.floor(width / cols)
                    cellHeight: Math.round(cellWidth * 0.625) + 2

                    delegate: Item {
                        id: cell
                        required property var modelData
                        width: grid.cellWidth; height: grid.cellHeight
                        readonly property bool active: root.lockTarget
                            ? QsConfig.Config.lock.wallpaper === modelData.key
                            : root.currentApplied === modelData.key

                        Item {
                            id: card
                            anchors { fill: parent; margins: 3 }
                            scale: cellMouse.pressed ? 0.96 : 1
                            Behavior on scale { NumberAnimation { duration: 100 } }

                            Rectangle { anchors.fill: parent; radius: 16; color: pywal.surfaceContainerHighest }

                            Image {
                                id: img
                                anchors.fill: parent
                                source: cell.modelData.thumb
                                sourceSize.width: 400
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                visible: false
                            }
                            MultiEffect {
                                anchors.fill: parent
                                source: img
                                maskEnabled: true
                                maskSource: mask
                                opacity: img.status === Image.Ready ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 200 } }
                            }
                            Rectangle {
                                id: mask
                                anchors.fill: parent
                                radius: 16
                                layer.enabled: true
                                visible: false
                            }

                            // hover name
                            Rectangle {
                                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                                height: 30; radius: 16
                                visible: cellMouse.containsMouse
                                gradient: Gradient {
                                    GradientStop { position: 0; color: "transparent" }
                                    GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.65) }
                                }
                                Text {
                                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 8; bottomMargin: 5 }
                                    text: cell.modelData.label
                                    font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.xxs
                                    color: "white"; elide: Text.ElideMiddle
                                }
                            }

                            // video badge
                            Rectangle {
                                visible: cell.modelData.video
                                anchors { top: parent.top; right: parent.right; margins: 8 }
                                width: 22; height: 22; radius: 11
                                color: Qt.rgba(0, 0, 0, 0.55)
                                Text { anchors.centerIn: parent; anchors.horizontalCenterOffset: 1; text: "▶"; font.pixelSize: 9; color: "white" }
                            }

                            // selected ring + check
                            Rectangle {
                                anchors.fill: parent; radius: 16
                                color: "transparent"
                                border.width: cell.active ? 3 : 0
                                border.color: pywal.primary
                            }
                            Rectangle {
                                visible: cell.active
                                anchors { top: parent.top; left: parent.left; margins: 8 }
                                width: 22; height: 22; radius: 11
                                color: pywal.primary
                                OneUIIcon { anchors.centerIn: parent; name: "dnd_detail_option_ic_check"; size: 14; color: pywal.onPrimary }
                            }

                            MouseArea {
                                id: cellMouse
                                anchors.fill: parent; hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.activate(cell.modelData)
                            }
                        }
                    }
                }

                // loading / empty
                Text {
                    anchors.centerIn: parent
                    width: parent.width - 40
                    visible: root.tabLoading || root.gridItems.length === 0
                    text: root.tabLoading ? "Loading…"
                        : root.currentTab === 0 ? "Nothing in " + (root.localSubTab === 0 ? root.wallpapersDir : root.videosDir)
                        : root.currentTab === 1 ? "Search Wallhaven above"
                        : "Search Moewalls above or press ↩ to browse"
                    font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.s
                    color: pywal.onSurfaceMuted
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
            }

            // ── Footer: pagination ──────────────────────────────────────
            RowLayout {
                visible: root.currentTab > 0
                Layout.fillWidth: true
                spacing: 10
                RoundBtn {
                    icon: "ic_arrow_back"
                    enabled: root.currentTab === 1 ? root.whPage > 1 : root.mwPage > 1
                    onClicked: root.currentTab === 1 ? (root.whPage--, root.whSearch(false)) : (root.mwPage--, root.mwSearch(false))
                }
                Text {
                    text: root.currentTab === 1 ? `${root.whPage} / ${root.whLastPage}` : `${root.mwPage}`
                    font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.xs
                    color: pywal.onSurfaceMuted
                }
                RoundBtn {
                    icon: "ic_arrow_forward"
                    enabled: root.currentTab === 1 ? root.whPage < root.whLastPage : root.mwResults.length === 9
                    onClicked: root.currentTab === 1 ? (root.whPage++, root.whSearch(false)) : (root.mwPage++, root.mwSearch(false))
                }
                Item { Layout.fillWidth: true }
                Text {
                    visible: root.currentTab === 2
                    text: "via mpvpaper"
                    font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.xxs
                    color: pywal.onSurfaceMuted
                }
            }
        }
    }

    // Circular icon button (refresh, pagination, search)
    component RoundBtn: Rectangle {
        id: rb
        signal clicked()
        property string icon: ""
        property bool filled: false
        implicitWidth: 30; implicitHeight: 30; radius: 15
        opacity: enabled ? 1 : 0.35
        color: filled ? (rbMouse.containsMouse ? Qt.lighter(pywal.primary, 1.1) : pywal.primary)
                      : (rbMouse.containsMouse ? pywal.primaryContainer : pywal.surfaceContainerHighest)
        Behavior on color { ColorAnimation { duration: 120 } }
        OneUIIcon { anchors.centerIn: parent; name: rb.icon; size: 16; color: rb.filled ? pywal.onPrimary : pywal.foreground }
        MouseArea {
            id: rbMouse
            anchors.fill: parent; enabled: rb.enabled; hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: rb.clicked()
        }
    }
}
