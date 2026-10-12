import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Effects
import Quickshell
import qs.services
import "../../../components"
import "../../../components/effects"
import "../../../config" as QsConfig
// Dynamic music pill: album art with a progress ring, title over artist.
// Hovering reveals transport controls (the pill widens with the bar's width spring).
// controls (the pill widens with the bar's width spring). Click opens the
// media popup, middle-click toggles playback.
Item {
    id: root

    property var barWindow
    property var bar  // Reference to Bar.qml root for inline popup toggle
    property var mediaPopup

    readonly property var player: Players.active
    readonly property bool hasPlayer: player !== null
    readonly property bool isPlaying: player?.isPlaying ?? false
    readonly property real progress: player?.position ?? 0
    readonly property real duration: player?.length ?? 1
    readonly property real progressPercent: duration > 0 ? Math.min(1, progress / duration) : 0
    readonly property bool hovered: hoverHandler.hovered

    readonly property real textWidth: 104

    // Fixed width for the empty state avoids a circular size dependency.
    implicitWidth: hasPlayer ? contentRow.implicitWidth : 70
    implicitHeight: 28

    HoverHandler { id: hoverHandler }

    // Background click handler: declared first so the control buttons above
    // it still get their own clicks.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) {
                if (root.player?.canTogglePlaying) root.player.togglePlaying()
            } else if (root.bar) {
                root.bar.togglePopup("media")
            }
        }
    }

    // Position is polled; MPRIS does not signal it while playing.
    Timer {
        interval: 1000
        running: root.hasPlayer && root.isPlaying
        repeat: true
        onTriggered: root.player?.positionChanged()
    }

    // ── Empty state ───────────────────────────────────────────────
    RowLayout {
        anchors.centerIn: parent
        spacing: 6
        visible: !root.hasPlayer

        OneUIIcon {
            name: "mdi_music_note"
            size: 14
            color: Qt.rgba(Pywal.foreground.r, Pywal.foreground.g, Pywal.foreground.b, 0.4)
            Layout.alignment: Qt.AlignVCenter
        }
        Text {
            text: "No media"
            font.family: "OneUI Sans"
            font.pixelSize: QsConfig.Appearance.fontSize.xs
            font.weight: Font.Medium
            color: Qt.rgba(Pywal.foreground.r, Pywal.foreground.g, Pywal.foreground.b, 0.4)
            Layout.alignment: Qt.AlignVCenter
        }
    }

    // ── Player ────────────────────────────────────────────────────
    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 0
        visible: root.hasPlayer
        opacity: root.hasPlayer ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        // Album art inside a progress ring
        Item {
            id: artWrap
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            Layout.rightMargin: 8
            Layout.alignment: Qt.AlignVCenter

            Canvas {
                id: ring
                anchors.fill: parent
                antialiasing: true
                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    const c = width / 2, r = c - 1.5
                    ctx.lineWidth = 2
                    ctx.lineCap = "round"
                    ctx.strokeStyle = Qt.rgba(Pywal.foreground.r, Pywal.foreground.g, Pywal.foreground.b, 0.14)
                    ctx.beginPath(); ctx.arc(c, c, r, 0, Math.PI * 2); ctx.stroke()
                    if (root.progressPercent > 0.002) {
                        ctx.strokeStyle = Pywal.primary
                        ctx.beginPath()
                        ctx.arc(c, c, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * root.progressPercent)
                        ctx.stroke()
                    }
                }
                Connections {
                    target: root
                    function onProgressPercentChanged() { ring.requestPaint() }
                }
                Connections {
                    target: Pywal
                    function onPrimaryChanged() { ring.requestPaint() }
                }
                Component.onCompleted: requestPaint()
            }

            Item {
                id: artBox
                anchors.centerIn: parent
                width: 20
                height: 20

                // Rounded mask for the art
                Item {
                    id: artMask
                    anchors.fill: parent
                    visible: false
                    layer.enabled: true
                    layer.smooth: true
                    Rectangle { anchors.fill: parent; radius: width / 2; color: "black" }
                }

                Image {
                    id: art
                    anchors.fill: parent
                    source: root.player?.trackArtUrl ?? ""
                    sourceSize: Qt.size(64, 64)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    visible: false
                }

                MultiEffect {
                    anchors.fill: parent
                    source: art
                    visible: art.status === Image.Ready
                    maskEnabled: true
                    maskSource: artMask
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1.0
                    rotation: spin.angle
                }

                // No art: a tinted note glyph
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    visible: art.status !== Image.Ready
                    color: Qt.rgba(Pywal.primary.r, Pywal.primary.g, Pywal.primary.b, 0.22)
                    OneUIIcon {
                        anchors.centerIn: parent
                        name: "mdi_music_note"
                        size: 12
                        color: Pywal.primary
                    }
                }

                // Slow vinyl-style spin while playing
                QtObject {
                    id: spin
                    property real angle: 0
                }
                NumberAnimation {
                    target: spin
                    property: "angle"
                    from: spin.angle
                    to: spin.angle + 360
                    duration: 14000
                    loops: Animation.Infinite
                    running: root.isPlaying && art.status === Image.Ready
                }
            }
        }

        // Title over artist
        Item {
            Layout.preferredWidth: root.textWidth
            Layout.preferredHeight: 28
            Layout.alignment: Qt.AlignVCenter
            clip: true

            Text {
                id: titleText
                y: 2
                text: root.player?.trackTitle ?? "Unknown"
                color: Pywal.foreground
                font.family: QsConfig.Config.appearance.fontFamily
                font.pixelSize: QsConfig.Appearance.fontSize.s
                font.weight: Font.DemiBold

                property bool needsScroll: implicitWidth > root.textWidth

                SequentialAnimation {
                    id: marquee
                    running: titleText.needsScroll && root.isPlaying
                    loops: Animation.Infinite
                    PauseAnimation { duration: 2200 }
                    NumberAnimation {
                        target: titleText; property: "x"
                        to: -(titleText.implicitWidth - root.textWidth + 8)
                        duration: Math.max(0, titleText.implicitWidth - root.textWidth) * 40
                        easing.type: Easing.InOutSine
                    }
                    PauseAnimation { duration: 1200 }
                    NumberAnimation { target: titleText; property: "x"; to: 0; duration: 500; easing.type: Easing.OutCubic }
                }
                onTextChanged: x = 0
            }

            Text {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 1
                width: parent.width
                text: root.player?.trackArtist ?? ""
                elide: Text.ElideRight
                color: Qt.rgba(Pywal.foreground.r, Pywal.foreground.g, Pywal.foreground.b, 0.62)
                font.family: QsConfig.Config.appearance.fontFamily
                font.pixelSize: QsConfig.Appearance.fontSize.xxs
                font.weight: Font.Medium
            }
        }

        // Transport controls, revealed on hover
        Item {
            id: tail
            Layout.preferredWidth: root.hovered ? controls.implicitWidth : 0
            Layout.leftMargin: root.hovered ? 8 : 0
            Behavior on Layout.leftMargin { NumberAnimation { duration: OneUIMotion.medium2; easing.bezierCurve: OneUIMotion.standard } }
            Layout.preferredHeight: 28
            Layout.alignment: Qt.AlignVCenter
            clip: true
            Behavior on Layout.preferredWidth {
                NumberAnimation { duration: OneUIMotion.medium2; easing.bezierCurve: OneUIMotion.standard }
            }

            RowLayout {
                id: controls
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                spacing: 2
                opacity: root.hovered ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 160 } }

                Repeater {
                    model: [
                        { icon: "pip_ic_skip_previous_white", act: "prev" },
                        { icon: "play", act: "play" },
                        { icon: "pip_ic_skip_next_white", act: "next" }
                    ]

                    Rectangle {
                        id: btn
                        required property var modelData
                        readonly property bool isPlay: modelData.act === "play"
                        Layout.preferredWidth: isPlay ? 24 : 20
                        Layout.preferredHeight: isPlay ? 24 : 20
                        radius: width / 2
                        color: isPlay ? (btnArea.containsMouse ? Qt.lighter(Pywal.primary, 1.08) : Pywal.primary)
                                      : (btnArea.containsMouse ? Qt.rgba(Pywal.foreground.r, Pywal.foreground.g, Pywal.foreground.b, 0.15) : "transparent")
                        scale: btnArea.pressed ? 0.88 : 1
                        Behavior on scale { NumberAnimation { duration: 80 } }
                        Behavior on color { ColorAnimation { duration: 100 } }

                        OneUIIcon {
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: btn.isPlay && !root.isPlaying ? 1 : 0
                            size: btn.isPlay ? 12 : 13
                            name: btn.isPlay ? (root.isPlaying ? "ic_pause" : "pip_ic_play_arrow_white") : btn.modelData.icon
                            color: btn.isPlay ? Pywal.onPrimary : (btnArea.containsMouse ? Pywal.primary : Pywal.foreground)
                        }

                        MouseArea {
                            id: btnArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const p = root.player
                                if (!p) return
                                if (btn.modelData.act === "prev" && p.canGoPrevious) p.previous()
                                else if (btn.modelData.act === "next" && p.canGoNext) p.next()
                                else if (btn.modelData.act === "play" && p.canTogglePlaying) p.togglePlaying()
                            }
                        }
                    }
                }
            }
        }
    }
}
