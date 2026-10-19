import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../config" as QsConfig
import "../../services" as QsServices
import "../../components"
import "../../components/effects"

// Hotspot credentials as a Wi-Fi QR code (needs `qrencode`). Opens by itself
// when the hotspot is switched on, via `touch /tmp/qs-hotspotqr`, or from the
// bar's hotspot icon.
PanelWindow {
    id: root

    BackgroundEffect.blurRegion: QsConfig.Appearance.blur ? _blur : null
    Region { id: _blur; item: panel; radius: blurSurface.radius }

    property bool shouldShow: false

    readonly property var config: QsConfig.Config
    readonly property var pywal: QsServices.Pywal
    readonly property var net: QsServices.Network
    readonly property color cText: pywal.foreground
    readonly property color cSubText: pywal.onSurfaceMuted

    readonly property string qrFile: "/tmp/qs-hotspot-qr.png"
    property int qrRev: 0
    property bool qrFailed: false
    readonly property bool ready: net.hotspotActive && net.hotspotPsk !== ""

    function close() { shouldShow = false }
    function esc(v) { return v.replace(/([\;,:"])/g, "\\$1") }

    function makeQr() {
        if (!ready) return
        qrFailed = false
        qrProc.command = ["qrencode", "-s", "8", "-m", "2", "-o", qrFile,
            `WIFI:T:WPA;S:${esc(net.hotspotSsid)};P:${esc(net.hotspotPsk)};;`]
        qrProc.running = true
    }

    onShouldShowChanged: if (shouldShow) makeQr()
    onReadyChanged: if (ready && shouldShow) makeQr()
    // Switching the hotspot off closes the panel.
    Connections { target: root.net; function onHotspotActiveChanged() { if (!root.net.hotspotActive) root.close() } }
    Connections { target: root.net; function onHotspotReady() { root.shouldShow = true } }

    Process {
        id: qrProc
        onExited: code => { root.qrFailed = code !== 0; root.qrRev++ }
    }

    screen: Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    mask: Region { item: panel }
    PanelGeometry {
        id: geo
        screen: root.screen
        name: "hotspot"
        minW: 300
        minH: 440
        defaultW: 320
        defaultH: 470
        defaultY: (config.bar.height ?? 34) + 22
    }
    color: "transparent"
    visible: shouldShow || panel.opacity > 0

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shouldShow ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    FocusScope {
        id: panel
        x: geo.x; y: geo.y; width: geo.w; height: geo.h
        property real revealOffset: shouldShow ? 0 : -20
        scale: shouldShow ? 1.0 : 0.97
        opacity: shouldShow ? 1.0 : 0.0
        focus: root.shouldShow
        transform: Translate { y: panel.revealOffset }

        Keys.onEscapePressed: root.close()

        Behavior on scale { NumberAnimation { duration: OneUIMotion.medium1; easing.bezierCurve: OneUIMotion.springGentle } }
        Behavior on opacity { NumberAnimation { duration: OneUIMotion.short4; easing.type: Easing.OutQuad } }
        Behavior on revealOffset { NumberAnimation { duration: OneUIMotion.medium1; easing.bezierCurve: OneUIMotion.emphasizedDecelerate } }

        PanelGrips { geo: geo; color: root.cText }

        AuroraSurface {
            id: blurSurface
            anchors.fill: parent
            radius: QsConfig.Appearance.radius.l
            color: pywal.surfaceContainerHighest
            borderWidth: 0
            accentColor: pywal.primary
            elevation: 1
            highlighted: false

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    OneUIIcon { name: "ic_hotspot"; size: 18; color: pywal.primary }
                    Text {
                        Layout.fillWidth: true
                        text: "Hotspot"
                        color: root.cText
                        font.family: QsConfig.Config.appearance.fontFamily
                        font.pixelSize: QsConfig.Appearance.fontSize.xl
                        font.weight: Font.DemiBold
                    }
                }

                // The code needs a light background to scan reliably.
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 230
                    Layout.preferredHeight: 230
                    radius: QsConfig.Appearance.radius.m
                    color: "white"

                    Image {
                        anchors.fill: parent
                        anchors.margins: 8
                        source: root.qrRev > 0 && !root.qrFailed ? `file://${root.qrFile}?${root.qrRev}` : ""
                        cache: false
                        smooth: false
                        fillMode: Image.PreserveAspectFit
                    }
                    Text {
                        anchors.centerIn: parent
                        width: parent.width - 24
                        visible: root.qrFailed || !root.ready
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        color: "#444"
                        text: !root.ready ? "Preparing…" : "Could not create the QR code.\nIs `qrencode` installed?"
                        font.pixelSize: QsConfig.Appearance.fontSize.s
                    }
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: root.net.hotspotSsid
                    color: root.cText
                    font.family: QsConfig.Config.appearance.fontFamily
                    font.pixelSize: QsConfig.Appearance.fontSize.l
                    font.weight: Font.DemiBold
                }
                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: root.net.hotspotPsk
                    color: root.cSubText
                    font.family: "monospace"
                    font.pixelSize: QsConfig.Appearance.fontSize.m
                    textFormat: Text.PlainText
                }

                Item { Layout.fillHeight: true }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Repeater {
                        model: [
                            { label: "Close", off: false },
                            { label: "Turn hotspot off", off: true }
                        ]
                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            radius: height / 2
                            color: modelData.off ? pywal.error : pywal.surfaceContainerHigh
                            Text {
                                anchors.centerIn: parent
                                text: parent.modelData.label
                                color: parent.modelData.off ? pywal.onError : root.cText
                                font.family: QsConfig.Config.appearance.fontFamily
                                font.pixelSize: QsConfig.Appearance.fontSize.m
                                font.weight: Font.Medium
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: modelData.off ? root.net.toggleHotspot() : root.close()
                            }
                        }
                    }
                }
            }
        }
    }
}
