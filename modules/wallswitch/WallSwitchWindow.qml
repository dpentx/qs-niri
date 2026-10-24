import QtQuick 6.10
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../services" as QsServices
import "../../components"
import "../../components/effects"
import "../../config" as QsConfig

// Quick wallpaper switcher (bloated profile). Bind a key to `touch /tmp/qs-wallswitch`:
// the first press opens a strip of ~/Pictures/Wallpapers, every further press steps to the
// next one, Enter / click applies it, Esc closes. Images only (videos stay in the full panel).
PanelWindow {
    id: root

    property bool shouldShow: false
    readonly property var pywal: QsServices.Pywal
    readonly property string dir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    property var files: []

    function step(d) {
        if (files.length === 0) return
        strip.currentIndex = (strip.currentIndex + d + files.length) % files.length
    }
    function applyCurrent() {
        if (files.length === 0) return
        applyProc.path = files[strip.currentIndex]
        applyProc.running = true
        shouldShow = false
    }
    // a second touch of the trigger file while open = Alt+Tab-style "next"
    function trigger() { shouldShow ? step(1) : shouldShow = true }

    onShouldShowChanged: if (shouldShow) { scan.running = true; card.forceActiveFocus() }

    Process {
        id: scan
        command: ["bash", "-c", `find "${root.dir}" -maxdepth 2 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) 2>/dev/null | sort`]
        stdout: StdioCollector {
            onStreamFinished: {
                root.files = text.trim().split("\n").filter(f => f.length > 0)
                strip.currentIndex = Math.min(1, root.files.length - 1)  // first press already moves on
            }
        }
    }

    // Same as the image branch of WallpaperPanel: stop any video wallpaper, set the image, re-theme.
    Process {
        id: applyProc
        property string path: ""
        command: ["bash", "-c",
            `H="$HOME"; mkdir -p "$H/.cache/wallpaper"; ` +
            `printf 'awww img %q --transition-type fade --transition-duration 1\\n' "$1" > "$H/.cache/wallpaper/lastwlpp"; ` +
            `[ -f "$H/.cache/qs-mpvpaper.pid" ] && kill -9 "$(cat "$H/.cache/qs-mpvpaper.pid")" 2>/dev/null; rm -f "$H/.cache/qs-mpvpaper.pid"; ` +
            `pkill -x mpvpaper 2>/dev/null; awww img "$1" --transition-type fade --transition-duration 1`,
            "_", path]
        onExited: (code) => { if (code === 0) root.pywal.generate(path) }
    }

    BackgroundEffect.blurRegion: QsConfig.Appearance.blur && shouldShow && card.opacity > 0.98 && Math.abs(card.scale - 1) < 0.002 ? _blur : null
    Region { id: _blur; item: card; radius: card.radius }

    visible: shouldShow || scrim.opacity > 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shouldShow ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell:wallswitch"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    Rectangle {
        id: scrim
        anchors.fill: parent
        color: "#000000"
        opacity: root.shouldShow ? 0.4 : 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        MouseArea { anchors.fill: parent; onClicked: root.shouldShow = false }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(root.width - 80, 960)
        height: 212
        radius: QsConfig.Appearance.radius.xl
        color: pywal.panelBackground
        scale: root.shouldShow ? 1 : 0.92
        opacity: root.shouldShow ? 1 : 0
        Behavior on scale { NumberAnimation { duration: OneUIMotion.medium2; easing.bezierCurve: OneUIMotion.emphasizedDecelerate } }
        Behavior on opacity { NumberAnimation { duration: 150 } }

        focus: true
        Keys.onEscapePressed: root.shouldShow = false
        Keys.onReturnPressed: root.applyCurrent()
        Keys.onEnterPressed: root.applyCurrent()
        Keys.onTabPressed: root.step(1)
        Keys.onBacktabPressed: root.step(-1)
        Keys.onRightPressed: root.step(1)
        Keys.onDownPressed: root.step(1)
        Keys.onLeftPressed: root.step(-1)
        Keys.onUpPressed: root.step(-1)

        Text {
            anchors.centerIn: parent
            visible: root.files.length === 0
            text: "No images in " + root.dir
            font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.s
            color: pywal.onSurfaceMuted
        }

        ListView {
            id: strip
            anchors { fill: parent; topMargin: 16; bottomMargin: 44 }
            orientation: ListView.Horizontal
            spacing: 12
            model: root.files
            clip: true
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: width / 2 - 88
            preferredHighlightEnd: width / 2 + 88
            highlightMoveDuration: 220
            leftMargin: 0; rightMargin: 0

            delegate: Item {
                id: cell
                required property string modelData
                required property int index
                readonly property bool current: ListView.isCurrentItem
                width: 176; height: strip.height
                scale: current ? 1 : 0.88
                opacity: current ? 1 : 0.7
                Behavior on scale { NumberAnimation { duration: 180 } }
                Behavior on opacity { NumberAnimation { duration: 180 } }

                Image {
                    id: img
                    anchors.centerIn: parent
                    width: 176; height: 110
                    source: "file://" + cell.modelData
                    sourceSize.width: 360
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: false
                }
                MultiEffect {
                    anchors.fill: img
                    source: img
                    maskEnabled: true
                    maskSource: mask
                    opacity: img.status === Image.Ready ? 1 : 0
                }
                Rectangle { id: mask; anchors.fill: img; radius: 16; layer.enabled: true; visible: false }
                Rectangle {
                    anchors.fill: img; radius: 16; color: "transparent"
                    border.width: cell.current ? 3 : 0
                    border.color: pywal.primary
                }
                MouseArea {
                    anchors.fill: img
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { strip.currentIndex = cell.index; root.applyCurrent() }
                }
            }
        }

        Text {
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 14 }
            visible: root.files.length > 0
            text: (root.files[strip.currentIndex] ?? "").split("/").pop() + "   ·   Tab next · Enter apply · Esc close"
            font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.xs
            color: pywal.onSurfaceMuted
            elide: Text.ElideMiddle
            width: parent.width - 40
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
