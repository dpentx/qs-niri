import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../services" as QsServices
import "../../components"
import "../../components/effects"
import "../../config" as QsConfig

// Cast panel (`touch /tmp/qs-cast`): control the running screen shares, mirror the screen onto a
// wired TV / projector (wl-mirror) and open the wireless finder (gnome-network-displays).
PanelWindow {
    id: root

    property bool shouldShow: false
    readonly property var pywal: QsServices.Pywal
    readonly property var casts: QsServices.Casts

    property var outputs: []          // [{ name, label }]
    property string focusedOutput: ""
    property bool mirroring: false
    property bool hasMirror: false
    property bool hasWireless: false

    function trigger() { shouldShow = !shouldShow }
    onShouldShowChanged: if (shouldShow) { card.forceActiveFocus(); casts.refresh(); probe.running = false; probe.running = true }

    function mirrorTo(target) {
        if (!focusedOutput) return
        // same output as the source would mirror a screen onto itself
        Quickshell.execDetached(["wl-mirror", "--fullscreen", "--fullscreen-output", target, focusedOutput])
        mirroring = true
    }
    function stopMirror() { Quickshell.execDetached(["pkill", "-x", "wl-mirror"]); mirroring = false }

    // outputs, the focused one, and which helper tools exist; one shell call, JSON out
    Process {
        id: probe
        command: ["sh", "-c",
            'o=$(niri msg -j outputs 2>/dev/null); f=$(niri msg -j focused-output 2>/dev/null); [ -n "$o" ] || o=null; [ -n "$f" ] || f=null; ' +
            'm=0; command -v wl-mirror >/dev/null && m=1; w=0; command -v gnome-network-displays >/dev/null && w=1; ' +
            'r=0; pgrep -x wl-mirror >/dev/null && r=1; ' +
            'printf \'{"outputs":%s,"focused":%s,"mirror":%s,"wireless":%s,"running":%s}\' "$o" "$f" $m $w $r']
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text)
                    root.outputs = Object.keys(d.outputs ?? {}).map(k => {
                        const o = d.outputs[k]
                        return { name: k, label: [o.make, o.model].filter(x => x).join(" ") }
                    })
                    root.focusedOutput = d.focused?.name ?? ""
                    root.hasMirror = d.mirror === 1
                    root.hasWireless = d.wireless === 1
                    root.mirroring = d.running === 1
                } catch (e) { }
            }
        }
    }

    BackgroundEffect.blurRegion: QsConfig.Appearance.blur && shouldShow && card.opacity > 0.98 && Math.abs(card.scale - 1) < 0.002 ? _blur : null
    Region { id: _blur; item: card; radius: card.radius }

    visible: shouldShow || scrim.opacity > 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shouldShow ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell:cast"
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
        width: Math.min(root.width - 60, 520)
        height: Math.min(root.height - 60, col.implicitHeight + 40)
        radius: QsConfig.Appearance.radius.xl
        color: pywal.panelBackground
        clip: true
        scale: root.shouldShow ? 1 : 0.92
        opacity: root.shouldShow ? 1 : 0
        Behavior on scale { NumberAnimation { duration: OneUIMotion.medium2; easing.bezierCurve: OneUIMotion.emphasizedDecelerate } }
        Behavior on opacity { NumberAnimation { duration: 150 } }

        focus: true
        Keys.onEscapePressed: root.shouldShow = false

        ColumnLayout {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
            spacing: 12

            Text {
                text: "Cast"
                font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.xl; font.weight: Font.Bold
                color: pywal.foreground
            }

            // ── Screen sharing ──────────────────────────────────────
            Label { text: "Screen sharing" }
            Text {
                visible: root.casts.count === 0
                text: "Nothing is being shared. Start a share from a browser or call app and it shows up here."
                font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.xs
                color: pywal.onSurfaceMuted
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            Repeater {
                model: root.casts.list
                Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 52; radius: 16
                    color: pywal.surfaceContainerHighest
                    RowLayout {
                        anchors { fill: parent; leftMargin: 14; rightMargin: 10 }
                        spacing: 8
                        Rectangle { width: 10; height: 10; radius: 5; color: pywal.error }
                        Text {
                            text: "Sharing: " + modelData.target
                            font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.s
                            color: pywal.foreground
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                        Pill { text: "Stop"; danger: true; onClicked: root.casts.stop(modelData.session) }
                    }
                }
            }
            // what a "dynamic target" share (the portal's niri window/monitor choice) points at
            Flow {
                visible: root.casts.list.some(c => c.dynamic)
                Layout.fillWidth: true
                spacing: 6
                Pill { text: "Share focused window"; onClicked: root.casts.shareWindow() }
                Pill { text: "Share focused monitor"; onClicked: root.casts.shareMonitor() }
                Pill { text: "Show nothing"; onClicked: root.casts.shareNothing() }
            }

            // ── Wired mirror ────────────────────────────────────────
            Label { text: "Mirror to a TV or projector (cable)" }
            Text {
                visible: !root.hasMirror
                text: "wl-mirror is not installed."
                font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.xs
                color: pywal.onSurfaceMuted
            }
            Text {
                visible: root.hasMirror && root.outputs.length < 2
                text: "Connect a second display (HDMI / USB-C) and it will be listed here."
                font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.xs
                color: pywal.onSurfaceMuted
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            Repeater {
                model: root.hasMirror ? root.outputs.filter(o => o.name !== root.focusedOutput) : []
                Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 52; radius: 16
                    color: pywal.surfaceContainerHighest
                    RowLayout {
                        anchors { fill: parent; leftMargin: 14; rightMargin: 10 }
                        spacing: 8
                        Text {
                            text: modelData.name + (modelData.label ? "  ·  " + modelData.label : "")
                            font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.s
                            color: pywal.foreground
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                        Pill { text: "Mirror " + root.focusedOutput; onClicked: root.mirrorTo(modelData.name) }
                    }
                }
            }
            Pill { visible: root.mirroring; text: "Stop mirroring"; danger: true; onClicked: root.stopMirror() }

            // ── Wireless ────────────────────────────────────────────
            Label { text: "Wireless (Miracast / Chromecast)" }
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Text {
                    text: root.hasWireless ? "Search the network for TVs and projectors." : "gnome-network-displays is not installed."
                    font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.xs
                    color: pywal.onSurfaceMuted
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                Pill {
                    visible: root.hasWireless
                    text: "Find displays"
                    onClicked: { Quickshell.execDetached(["gnome-network-displays"]); root.shouldShow = false }
                }
            }
        }
    }

    component Label: Text {
        Layout.topMargin: 6
        font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.xs; font.weight: 600
        color: root.pywal.primary
    }

    component Pill: Rectangle {
        id: pill
        property string text: ""
        property bool danger: false
        signal clicked()
        implicitWidth: pillText.implicitWidth + 28; implicitHeight: 34; radius: 17
        color: danger ? root.pywal.error : (pillMouse.containsMouse ? root.pywal.primaryContainer : root.pywal.surfaceContainerHighest)
        border.width: danger ? 0 : 1
        border.color: root.pywal.outlineVariant
        Text {
            id: pillText
            anchors.centerIn: parent
            text: pill.text
            font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.xs; font.weight: 600
            color: pill.danger ? root.pywal.onError : root.pywal.foreground
        }
        MouseArea { id: pillMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pill.clicked() }
    }
}
