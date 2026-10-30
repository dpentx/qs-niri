import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import Quickshell.Wayland
import "../../services" as QsServices
import "../../components"
import "../../components/effects"
import "../../config" as QsConfig

// Big-digit clock in the spirit of clock-rs: Clock / Timer / Stopwatch. Open with
// `touch /tmp/qs-clock`. Timer and stopwatch keep running while the window is closed.
// Keys: Space start/pause, R reset, Left/Right switch mode, Up/Down timer ±1 min, Esc close.
PanelWindow {
    id: root

    property bool shouldShow: false
    readonly property var pywal: QsServices.Pywal

    property int mode: 0                 // 0 clock, 1 timer, 2 stopwatch
    property real now: Date.now()
    property int timerSetMs: 5 * 60000
    property real timerEnd: 0            // epoch ms while running
    property int timerLeftMs: timerSetMs // while paused
    property real swStart: 0             // epoch ms of the running segment
    property int swBaseMs: 0             // accumulated before it
    property bool timerRunning: false
    property bool swRunning: false

    readonly property int timerShownMs: timerRunning ? Math.max(0, timerEnd - now) : timerLeftMs
    readonly property int swShownMs: swBaseMs + (swRunning ? now - swStart : 0)

    function two(n) { return (n < 10 ? "0" : "") + n }
    function hms(ms, withHours) {
        const t = Math.ceil(ms / 1000), h = Math.floor(t / 3600), m = Math.floor(t % 3600 / 60), s = t % 60
        return (withHours || h > 0) ? two(h) + ":" + two(m) + ":" + two(s) : two(m) + ":" + two(s)
    }
    readonly property string shown: mode === 0 ? Qt.formatTime(new Date(now), "HH:mm:ss")
        : mode === 1 ? hms(timerShownMs, false)
        : hms(swShownMs, false)

    function toggleRun() {
        if (mode === 1) {
            if (timerRunning) { timerLeftMs = Math.max(0, timerEnd - Date.now()); timerRunning = false }
            else if (timerLeftMs > 0) { timerEnd = Date.now() + timerLeftMs; timerRunning = true }
        } else if (mode === 2) {
            if (swRunning) { swBaseMs += Date.now() - swStart; swRunning = false }
            else { swStart = Date.now(); swRunning = true }
        }
    }
    function reset() {
        if (mode === 1) { timerRunning = false; timerLeftMs = timerSetMs }
        else if (mode === 2) { swRunning = false; swBaseMs = 0 }
    }
    function adjust(min) {
        if (mode !== 1 || timerRunning) return
        timerSetMs = Math.max(60000, timerSetMs + min * 60000)
        timerLeftMs = timerSetMs
    }
    function trigger() { shouldShow = !shouldShow }

    Timer {
        interval: 100
        repeat: true
        running: root.shouldShow || root.timerRunning || root.swRunning
        onTriggered: {
            root.now = Date.now()
            if (root.timerRunning && root.now >= root.timerEnd) {
                root.timerRunning = false
                root.timerLeftMs = 0
                Quickshell.execDetached(["notify-send", "-a", "Clock", "Timer finished", root.hms(root.timerSetMs, false) + " is up"])
            }
        }
    }

    onShouldShowChanged: if (shouldShow) card.forceActiveFocus()

    BackgroundEffect.blurRegion: QsConfig.Appearance.blur && shouldShow && card.opacity > 0.98 && Math.abs(card.scale - 1) < 0.002 ? _blur : null
    Region { id: _blur; item: card; radius: card.radius }

    visible: shouldShow || scrim.opacity > 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shouldShow ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell:clock"
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
        width: Math.min(root.width - 60, 760)
        height: col.implicitHeight + 48
        radius: QsConfig.Appearance.radius.xl
        color: pywal.panelBackground
        scale: root.shouldShow ? 1 : 0.92
        opacity: root.shouldShow ? 1 : 0
        Behavior on scale { NumberAnimation { duration: OneUIMotion.medium2; easing.bezierCurve: OneUIMotion.emphasizedDecelerate } }
        Behavior on opacity { NumberAnimation { duration: 150 } }

        focus: true
        Keys.onEscapePressed: root.shouldShow = false
        Keys.onSpacePressed: root.toggleRun()
        Keys.onPressed: (e) => {
            if (e.key === Qt.Key_R) root.reset()
            else if (e.key === Qt.Key_Left) root.mode = (root.mode + 3) % 4
            else if (e.key === Qt.Key_Right) root.mode = (root.mode + 1) % 4
            else if (e.key === Qt.Key_Up) root.adjust(1)
            else if (e.key === Qt.Key_Down) root.adjust(-1)
            else return
            e.accepted = true
        }

        ColumnLayout {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 24 }
            spacing: 18

            // mode pills
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8
                Repeater {
                    model: ["Clock", "Timer", "Stopwatch", "Agenda"]
                    Rectangle {
                        required property string modelData
                        required property int index
                        implicitWidth: modeText.implicitWidth + 32; implicitHeight: 34; radius: 17
                        readonly property bool on: root.mode === index
                        color: on ? pywal.primary : pywal.surfaceContainerHighest
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Text {
                            id: modeText
                            anchors.centerIn: parent
                            text: modelData
                            font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.s; font.weight: 600
                            color: parent.on ? pywal.onPrimary : pywal.onSurfaceMuted
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.mode = index }
                    }
                }
            }

            Loader { active: root.mode === 3; visible: active; Layout.fillWidth: true; source: "Agenda.qml" }

            // big fixed-width digits: no jitter as the numbers change
            Row {
                visible: root.mode !== 3
                Layout.alignment: Qt.AlignHCenter
                Repeater {
                    model: root.shown.split("")
                    Item {
                        required property string modelData
                        readonly property bool colon: modelData === ":"
                        width: colon ? 36 : 84; height: 150
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            font.family: "OneUI Sans"; font.pixelSize: 128; font.weight: 300
                            color: root.mode === 1 && root.timerShownMs === 0 && root.timerSetMs > 0 ? pywal.error : pywal.foreground
                            opacity: colon ? 0.55 : 1
                        }
                    }
                }
            }

            Text {
                visible: root.mode !== 3
                Layout.alignment: Qt.AlignHCenter
                text: root.mode === 0 ? Qt.formatDate(new Date(root.now), "dddd, d MMMM yyyy")
                    : root.mode === 1 ? "Space start / pause · R reset · ↑ ↓ set minutes (" + Math.round(root.timerSetMs / 60000) + " min)"
                    : "Space start / pause · R reset"
                font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.m
                color: pywal.onSurfaceMuted
            }

            RowLayout {
                visible: root.mode === 1 || root.mode === 2
                Layout.alignment: Qt.AlignHCenter
                spacing: 10
                Repeater {
                    model: root.mode === 1
                        ? [ { t: "−1 min", a: "dec" }, { t: "+1 min", a: "inc" } ] : []
                    Rectangle {
                        required property var modelData
                        implicitWidth: 84; implicitHeight: 38; radius: 19
                        color: pywal.surfaceContainerHighest
                        opacity: root.timerRunning ? 0.4 : 1
                        Text { anchors.centerIn: parent; text: modelData.t; font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.s; color: pywal.foreground }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.adjust(modelData.a === "inc" ? 1 : -1) }
                    }
                }
                Rectangle {
                    implicitWidth: 120; implicitHeight: 38; radius: 19
                    color: pywal.primary
                    Text {
                        anchors.centerIn: parent
                        text: (root.mode === 1 ? root.timerRunning : root.swRunning) ? "Pause" : "Start"
                        font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.s; font.weight: 600
                        color: pywal.onPrimary
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleRun() }
                }
                Rectangle {
                    implicitWidth: 84; implicitHeight: 38; radius: 19
                    color: pywal.surfaceContainerHighest
                    Text { anchors.centerIn: parent; text: "Reset"; font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.s; color: pywal.foreground }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.reset() }
                }
            }
        }
    }
}
