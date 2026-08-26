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

    implicitWidth:  360
    implicitHeight: 420

    // ── Init ──────────────────────────────────────────────────────────────
    property int _localScanGen: 0

    function rescanLocal() {
        root._localScanGen++
        root.localFiles   = []
        root.localLoading = true

        // Komutu burada, imperatif olarak, ŞU ANKİ localSubTab değerine göre
        // hesaplıyoruz ve Process'e düz bir string olarak veriyoruz. Eskiden
        // "command" bir binding'di ve root.localSubTab'a bağımlıydı; sub-tab
        // değiştirildiğinde (Images -> Videos) bu binding'in yeniden
        // hesaplanması ile Process'in gerçekten başlatılması aynı JS turu
        // içinde oluyordu ve pratikte bazen komut HALA eski dizini (Images)
        // hedefliyordu -> ffmpeg resim dosyalarını video sanıp thumbnail
        // çıkaramıyordu (loglardaki "resim klasöründen thumbnail
        // çıkarılamadı" hatası buradan geliyordu). Artık hiçbir binding'e
        // güvenmiyoruz, komut string'i doğrudan burada üretiliyor.
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

        // Süreç zaten çalışıyorsa "running = true" no-op olur ve eski
        // dizin taranmaya devam eder; bu yüzden önce kesin durdurulur.
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
                // Bu süreç başladığından beri tab/subtab değiştiyse sonuç
                // bayattır (başka klasöre ait), at.
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
    // mw_fetch.py'yi (BeautifulSoup ile) ~/.cache/mw-venv üzerinden çağırır.
    // Önceki QML içine gömülü regex-python versiyonu tırnak kaçışlarının
    // JS template literal + bash heredoc + python raw-string katmanlarından
    // geçerken bozulmasından dolayı her zaman boş sonuç döndürüyordu.
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

        // "pkill -x mpvpaper" hiçbir şeyi öldürmüyordu çünkü mpvpaper script'i
        // içeride "exec mpv ..." yapıyor — süreç adı mpv'ye dönüşüyor, mpvpaper
        // diye bir süreç artık yok. Bunun yerine kendi PID'imizi dosyaya
        // yazıp ondan öldürüyoruz (pkill -x mpvpaper artık hiç kullanılmıyor).
        // Video, setsid+nohup ile Quickshell'in process ağacından TAMAMEN
        // koparılıyor; popup kapanıp bu Process nesnesi yok edildiğinde alt
        // süreç artık ölmüyor.
        // lastwlpp yazımı artık ayrı bir saveStateProc'a değil, doğrudan bu
        // komutun içine gömülü — ayrı bir Process'in run/onExited sırasına
        // güvenmek pratikte güvenilmez çıktı (bazen hiç tetiklenmiyordu).
        // Video->video geçişinde eskisi önce öldürülüp sonra yenisi
        // başlatılırsa arada bir an awww/boş katman görünüyordu (flash).
        // Bunun yerine yeni instance önce başlatılıp log'da "VO:" (ilk kare
        // render edildi) görülene kadar bekleniyor, eski instance ancak o
        // zaman öldürülüyor -> geçiş sırasında görünür kesinti kalmıyor.
        command: _isVideo
            ? ["bash", "-c",
                `mkdir -p "${root.home}/.cache/wallpaper"; ` +
                `printf 'mpvpaper -o "no-audio loop no-border panscan=1.0" '"'"'*'"'"' %q\\n' "${_path}" ` +
                `> "${root.home}/.cache/wallpaper/lastwlpp"; ` +
                // Yeni mpvpaper'ı ÖNCE başlatıyoruz, log'da "VO:" (video output
                // hazır) satırı görünene kadar (max ~5sn) bekliyoruz, ve ancak
                // ONDAN SONRA eski instance'ı öldürüyoruz. Böylece yeni video
                // katmanı ekrana gelmeden eskisi kaybolmuyor -> awww/boş katmanın
                // arada bir an görünmesi (flash) engellenmiş oluyor.
                `: > /tmp/mpvpaper_new.log; ` +
                `setsid nohup mpvpaper -o "no-audio loop no-border panscan=1.0" '*' "${_path}" ` +
                `>/tmp/mpvpaper_new.log 2>&1 </dev/null & ` +
                `NEWPID=$!; ` +
                `for i in $(seq 1 50); do grep -q '^VO:' /tmp/mpvpaper_new.log 2>/dev/null && break; kill -0 "$NEWPID" 2>/dev/null || break; sleep 0.1; done; ` +
                `OLDPID=$(cat "${_pidFile}" 2>/dev/null); ` +
                `echo $NEWPID > "${_pidFile}"; ` +
                `mv -f /tmp/mpvpaper_new.log /tmp/mpvpaper.log; ` +
                `[ -n "$OLDPID" ] && kill -9 "$OLDPID" 2>/dev/null`]
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
            applyProc._path    = path
            applyProc._isVideo = isVideo
            root.downloading   = true
            root.downloadLabel = isVideo ? "Duvar kağıdı ayarlanıyor (mpvpaper)…" : "Duvar kağıdı ayarlanıyor…"
            downloadTimeoutTimer.restart()
            // İki tıklama üst üste gelirse (örn. video hemen ardından resim)
            // eski komutun hâlâ çalışıyor olması yeni komutu no-op yapabilir;
            // bu yüzden önce kesin durdurulur.
            if (applyProc.running) applyProc.running = false
            applyProc.running = true
        }

        onExited: (code, status) => {
            downloadTimeoutTimer.stop()
            root.downloading = false
            if (code === 0) {
                root.currentApplied = _path
                // lastwlpp zaten applyProc'un komutu içinde, apply
                // başarılı/başarısız olmadan ÖNCE yazıldı; ayrıca
                // yazmaya gerek yok.
            } else {
                // Duvar kağıdı ayarlanamadı; ayrıntı için /tmp/mpvpaper.log
                // veya applyProc._lastErr'a bakılabilir. Popup'ı bu durumda
                // kapatmıyoruz ki kullanıcı hata mesajını görebilsin.
                root.downloadLabel = "Wallpaper apply failed (exit " + code + ")" +
                    (applyProc._lastErr ? (": " + applyProc._lastErr) : "")
                return
            }
            // Video artık arka planda (setsid+nohup) bağımsız çalışıyor,
            // bash -c anında dönüyor — popup'ı beklemeden kapatabiliriz.
            root.closeRequested()
        }
    }

    function applyLocal(path) {
        applyProc.applyPath(path, false)
    }

    // ── Güvenlik zaman aşımı ────────────────────────────────────────────────
    // resolve / download / apply süreçlerinden biri (ağ, mw-tool, mpvpaper
    // spawn hatası vb. yüzünden) hiç sonuçlanmazsa arayüz "Resolving video…"
    // ya da "Downloading…" yazısında sonsuza kadar takılı kalmasın diye.
    Timer {
        id: downloadTimeoutTimer
        interval: 20000
        repeat: false
        onTriggered: {
            if (!root.downloading) return
            root.downloading = false
            root.downloadLabel = "Zaman aşımı: işlem 20sn içinde tamamlanamadı"
            if (mwResolveProc.running) mwResolveProc.running = false
            if (downloadProc.running)  downloadProc.running  = false
            if (applyProc.running)     applyProc.running     = false
        }
    }

    // ════════════════════════════════════════════════════════════════════════
    // UI
    // ════════════════════════════════════════════════════════════════════════

    AuroraSurface {
        anchors.fill: parent
        radius: 20
        color: pywal.surfaceContainerHigh
        borderWidth: 0
        accentColor: pywal.primary
        elevation: 1

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
                    font.family: "OneUI Sans"; font.pixelSize: 12; font.weight: 600
                    color: pywal.foreground
                }
                Item { Layout.fillWidth: true }
                Text {
                    visible: root.downloading
                    text: root.downloadLabel
                    font.family: "OneUI Sans"; font.pixelSize: 9
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
                            font.family: "OneUI Sans"; font.pixelSize: 10; font.weight: Font.Medium
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

            // ── Local subtab (Images / Videos) ─────────────────────────────
            Row {
                visible: root.currentTab === 0
                spacing: 4
                Repeater {
                    model: ["Images", "Videos"]
                    Rectangle {
                        required property string modelData
                        required property int    index
                        width: subLabel.implicitWidth + 14
                        height: 18
                        radius: 8
                        color: root.localSubTab === index
                            ? Qt.rgba(pywal.primary.r, pywal.primary.g, pywal.primary.b, 0.22)
                            : subMouse.containsMouse
                                ? Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.07)
                                : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text {
                            id: subLabel
                            anchors.centerIn: parent
                            text: modelData
                            font.family: "OneUI Sans"; font.pixelSize: 9
                            color: root.localSubTab === index
                                ? pywal.primary
                                : Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.55)
                        }
                        MouseArea {
                            id: subMouse
                            anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.localSubTab = index
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
                            font.family: "OneUI Sans"; font.pixelSize: 10
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
                            font.family: "OneUI Sans"; font.pixelSize: 10
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
                                    font.family: "OneUI Sans"; font.pixelSize: 9; font.weight: Font.Bold
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
                    font.family: "OneUI Sans"; font.pixelSize: 11
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
                        font.family: "OneUI Sans"; font.pixelSize: 10
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
                                cachedThumbPath: root.localSubTab === 1 ? root.videoThumbFor(modelData) : ""
                                gridWidth: localGrid.width
                                isActive: root.currentApplied === modelData
                                isVideo: root.localSubTab === 1
                                pywal: root.pywal
                                onActivated: {
                                    applyProc.applyPath(modelData, root.localSubTab === 1)
                                }
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
                                onActivated: {
                                    root.downloading = true
                                    root.downloadLabel = "Resolving video…"
                                    mwResolveProc._detailUrl = modelData.url
                                    downloadTimeoutTimer.restart()
                                    if (mwResolveProc.running) mwResolveProc.running = false
                                    mwResolveProc.running = true
                                }
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
                        font.family: "OneUI Sans"; font.pixelSize: 9
                        color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.7)
                    }
                    MouseArea {
                        id: rescanMouse
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: root.rescanLocal()
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
                        font.family: "OneUI Sans"; font.pixelSize: 9
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
                    font.family: "OneUI Sans"; font.pixelSize: 8
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
        property string cachedThumbPath: ""  // yerel video için ffmpeg cache jpg'i
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
            // Yerel video dosyaları (.webm/.mp4) resim olarak decode edilemez;
            // bunun yerine ffmpeg'in ürettiği cache jpg'i gösterilir.
            // Uzak (Moewalls) isVideo öğelerinde thumbUrl zaten gerçek bir jpg.
            source: (thumbCell.isVideo && thumbCell.thumbPath !== "")
                ? (thumbCell.cachedThumbPath !== "" ? ("file://" + thumbCell.cachedThumbPath) : "")
                : (thumbCell.thumbPath !== "" ? ("file://" + thumbCell.thumbPath) : thumbCell.thumbUrl)
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
                font.family: "OneUI Sans"; font.pixelSize: 7
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
            onClicked: {
                thumbCell.activated()
            }
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
            font.family: "OneUI Sans"; font.pixelSize: 11
            color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.75)
        }
        MouseArea {
            id: pgMouse; anchors.fill: parent
            enabled: pgBtn.enabled; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: pgBtn.clicked()
        }
    }
}
