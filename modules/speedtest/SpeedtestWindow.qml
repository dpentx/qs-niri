import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import Quickshell.Wayland
import "../../config" as QsConfig
import "../../services" as QsServices
import "../../components"
import "../../components/effects"

// Speed test page. Opened with `touch /tmp/qs-speedtest`, from the bar's
// Ethernet button (when there is no Wi-Fi adapter) or the Control Center.
PanelWindow {
    id: root

    BackgroundEffect.blurRegion: QsConfig.Appearance.blur ? _blur : null
    Region { id: _blur; item: blurSurface; radius: blurSurface.radius }

    property bool shouldShow: false

    readonly property var config: QsConfig.Config
    readonly property var pywal: QsServices.Pywal
    readonly property var st: QsServices.Speedtest
    readonly property var net: QsServices.Network
    readonly property color cSurface: pywal.surfaceContainerHighest
    readonly property color cCard: pywal.surfaceContainerHigh
    readonly property color cPrimary: pywal.primary
    readonly property color cText: pywal.foreground
    readonly property color cSubText: pywal.onSurfaceMuted

    function close() { shouldShow = false }

    readonly property string phaseText: st.state === "latency" ? "Gecikme ölçülüyor…"
        : st.state === "download" ? "İndirme ölçülüyor…"
        : st.state === "upload" ? "Yükleme ölçülüyor…"
        : st.state === "done" ? "Test tamamlandı"
        : st.state === "error" ? (st.error || "Test başarısız")
        : "Teste hazır"

    readonly property string connectionText: net.hasWifiDevice && net.connected ? net.ssid
        : net.ethernetConnected ? "Ethernet" : "Bağlantı yok"

    function fmt(v) { return v < 0 ? "—" : (v >= 100 ? Math.round(v) : v.toFixed(1)) }

    screen: Quickshell.screens[0]
    anchors { top: true; left: true }
    margins {
        top: (config.bar.height ?? 34) + 22
        left: Math.max(0, Math.round((screen.width - root.implicitWidth) / 2))
    }
    implicitWidth: 420
    implicitHeight: shouldShow || panel.opacity > 0 ? 430 : 0
    color: "transparent"
    visible: shouldShow || panel.opacity > 0

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shouldShow ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    FocusScope {
        id: panel
        anchors.fill: parent
        property real revealOffset: shouldShow ? 0 : -20
        scale: shouldShow ? 1.0 : 0.97
        opacity: shouldShow ? 1.0 : 0.0
        focus: root.shouldShow
        transform: Translate { y: panel.revealOffset }

        Keys.onEscapePressed: root.close()
        Keys.onSpacePressed: root.st.running ? root.st.cancel() : root.st.start()

        Behavior on scale { NumberAnimation { duration: OneUIMotion.medium1; easing.bezierCurve: OneUIMotion.springGentle } }
        Behavior on opacity { NumberAnimation { duration: OneUIMotion.short4; easing.type: Easing.OutQuad } }
        Behavior on revealOffset { NumberAnimation { duration: OneUIMotion.medium1; easing.bezierCurve: OneUIMotion.emphasizedDecelerate } }

        AuroraSurface {
            id: blurSurface
            anchors.fill: parent
            radius: QsConfig.Appearance.radius.l
            color: root.cSurface
            borderWidth: 0
            accentColor: root.cPrimary
            elevation: 1
            highlighted: false

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    OneUIIcon { name: "mdi_speedometer"; size: 18; color: root.cPrimary }
                    Text {
                        Layout.fillWidth: true
                        text: "Hız Testi"
                        color: root.cText
                        font.family: QsConfig.Config.appearance.fontFamily
                        font.pixelSize: QsConfig.Appearance.fontSize.xl
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: root.connectionText
                        color: root.cSubText
                        font.family: QsConfig.Config.appearance.fontFamily
                        font.pixelSize: QsConfig.Appearance.fontSize.s
                    }
                    Rectangle {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        radius: 16
                        color: closeMouse.containsMouse ? Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.12) : "transparent"
                        scale: closeMouse.pressed ? 0.9 : 1
                        Behavior on scale { NumberAnimation { duration: OneUIMotion.short2 } }
                        OneUIIcon { anchors.centerIn: parent; name: "ic_close"; size: 15; color: root.cText }
                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.close()
                        }
                    }
                }

                // Headline number
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: root.st.state === "latency" ? "…"
                            : root.st.state === "upload" ? root.fmt(root.st.upMbps < 0 ? root.st.downMbps : root.st.upMbps)
                            : root.fmt(root.st.downMbps)
                        color: root.st.state === "error" ? pywal.error : root.cText
                        font.family: QsConfig.Config.appearance.fontFamily
                        font.pixelSize: 64
                        font.weight: Font.DemiBold
                    }
                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: "Mbps"
                        color: root.cSubText
                        font.family: QsConfig.Config.appearance.fontFamily
                        font.pixelSize: QsConfig.Appearance.fontSize.l
                    }
                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        Layout.topMargin: 8
                        text: root.phaseText
                        color: root.st.state === "error" ? pywal.error : root.cSubText
                        font.family: QsConfig.Config.appearance.fontFamily
                        font.pixelSize: QsConfig.Appearance.fontSize.m
                    }
                }

                // Indeterminate progress while running
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 6
                    radius: 3
                    color: Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.16)
                    clip: true
                    opacity: root.st.running ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: OneUIMotion.short4 } }

                    Rectangle {
                        id: sweep
                        width: parent.width * 0.35
                        height: parent.height
                        radius: 3
                        color: root.cPrimary
                        SequentialAnimation on x {
                            running: root.st.running
                            loops: Animation.Infinite
                            NumberAnimation { from: -sweep.width; to: sweep.parent.width; duration: 1100; easing.type: Easing.InOutQuad }
                        }
                    }
                }

                // Results
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    component Stat: Rectangle {
                        id: card
                        property string label: ""
                        property string value: "—"
                        property string unit: ""
                        property bool current: false
                        Layout.fillWidth: true
                        Layout.preferredHeight: 78
                        radius: QsConfig.Appearance.radius.m
                        color: current ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.18) : root.cCard
                        Behavior on color { ColorAnimation { duration: OneUIMotion.short4 } }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: card.label
                                color: root.cSubText
                                font.family: QsConfig.Config.appearance.fontFamily
                                font.pixelSize: QsConfig.Appearance.fontSize.s
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: card.value
                                color: root.cText
                                font.family: QsConfig.Config.appearance.fontFamily
                                font.pixelSize: QsConfig.Appearance.fontSize.xxl
                                font.weight: Font.DemiBold
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: card.unit
                                color: root.cSubText
                                font.family: QsConfig.Config.appearance.fontFamily
                                font.pixelSize: QsConfig.Appearance.fontSize.xs
                            }
                        }
                    }

                    Stat { label: "Gecikme"; value: root.st.pingMs < 0 ? "—" : Math.round(root.st.pingMs); unit: "ms"; current: root.st.state === "latency" }
                    Stat { label: "İndirme"; value: root.fmt(root.st.downMbps); unit: "Mbps"; current: root.st.state === "download" }
                    Stat { label: "Yükleme"; value: root.fmt(root.st.upMbps); unit: "Mbps"; current: root.st.state === "upload" }
                }

                Item { Layout.fillHeight: true }

                // Start / stop
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 46
                    radius: 23
                    color: root.st.running ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.2)
                                           : (btnMouse.containsMouse ? Qt.lighter(root.cPrimary, 1.08) : root.cPrimary)
                    Behavior on color { ColorAnimation { duration: OneUIMotion.short3 } }
                    scale: btnMouse.pressed ? 0.98 : 1
                    Behavior on scale { NumberAnimation { duration: OneUIMotion.short2 } }

                    Text {
                        anchors.centerIn: parent
                        text: root.st.running ? "Durdur" : (root.st.state === "idle" ? "Testi başlat" : "Tekrar test et")
                        color: root.st.running ? root.cPrimary : pywal.onPrimary
                        font.family: QsConfig.Config.appearance.fontFamily
                        font.pixelSize: QsConfig.Appearance.fontSize.l
                        font.weight: Font.DemiBold
                    }
                    MouseArea {
                        id: btnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.st.running ? root.st.cancel() : root.st.start()
                    }
                }
            }
        }
    }
}
