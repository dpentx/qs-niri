import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import "../services" as QsServices
import "../config" as QsConfig

// Now-playing card (Samsung quick panel style): cover as background, wavy seek bar,
// icon controls. Colours follow the cover. Used by the bar popup, the control centre
// and the dashboard.
// Now-playing card: the cover fills the card, text sits on a dark scrim,
// and the played part of the seek bar is a wave while the track plays.
Rectangle {
    id: root

    property var player: null
    property bool active: true            // drives the wave animation
    property bool showOutputButton: false
    property bool outputsOpen: false
    signal outputClicked()

    readonly property var pywal: QsServices.Pywal

    function formatTime(seconds) {
        if (!seconds || seconds <= 0) return "0:00"
        const mins = Math.floor(seconds / 60)
        const secs = Math.floor(seconds % 60)
        return mins + ":" + (secs < 10 ? "0" : "") + secs
    }

    // Accent from the cover: saturation-weighted average colour, lifted to a light tone.
    property color accent: pywal.primary
    Behavior on accent { ColorAnimation { duration: 400 } }
    readonly property string artUrl: player?.trackArtUrl ?? ""
    onArtUrlChanged: { if (artUrl === "") accent = pywal.primary; else sampler.loadImage(artUrl) }
    Canvas {
        id: sampler
        width: 24; height: 24
        opacity: 0.01
        renderTarget: Canvas.Image
        onImageLoaded: requestPaint()
        onPaint: {
            if (root.artUrl === "" || !isImageLoaded(root.artUrl)) return
            const ctx = getContext("2d")
            ctx.drawImage(root.artUrl, 0, 0, 24, 24)
            const d = ctx.getImageData(0, 0, 24, 24).data
            let r = 0, g = 0, b = 0, w = 0
            for (let i = 0; i < d.length; i += 4) {
                const mx = Math.max(d[i], d[i + 1], d[i + 2]), mn = Math.min(d[i], d[i + 1], d[i + 2])
                const wt = (mx - mn) / 255 * mx / 255 + 0.02
                r += d[i] * wt; g += d[i + 1] * wt; b += d[i + 2] * wt; w += wt
            }
            if (w <= 0) return
            const c = Qt.rgba(r / w / 255, g / w / 255, b / w / 255, 1)
            root.accent = c.hslHue < 0 ? Qt.hsla(0, 0, 0.85, 1)
                : Qt.hsla(c.hslHue, Math.min(0.9, Math.max(0.4, c.hslSaturation)), 0.72, 1)
        }
    }
    Layout.fillWidth: true
    Layout.preferredHeight: cardCol.implicitHeight + 32
    radius: QsConfig.Appearance.radius.l
    color: Qt.hsla(root.accent.hslHue < 0 ? 0 : root.accent.hslHue, 0.4, 0.2, 1)
    layer.enabled: true
    layer.effect: MultiEffect {
        maskEnabled: true
        maskSource: cardMask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }
    Rectangle {
        id: cardMask
        visible: false
        layer.enabled: true
        width: root.width
        height: root.height
        radius: root.radius
    }

    Item {
        id: artStack
        anchors.fill: parent
        visible: player?.trackArtUrl ?? false

        property string currentUrl: ""
        property string watchedUrl: player?.trackArtUrl ?? ""
        onWatchedUrlChanged: setArt(watchedUrl)
        Component.onCompleted: setArt(watchedUrl)

        function setArt(url) {
            if (url === currentUrl) return
            currentUrl = url
            if (!imgFront.source || imgFront.source.toString() === "") {
                imgFront.source = url
            } else {
                imgBack.source = url
            }
        }

        Image {
            id: imgFront
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            smooth: true
            asynchronous: true
            opacity: 1
        }

        Image {
            id: imgBack
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            smooth: true
            asynchronous: true
            opacity: 0
            onStatusChanged: if (status === Image.Ready) crossfadeAnim.start()
        }

        SequentialAnimation {
            id: crossfadeAnim
            ParallelAnimation {
                NumberAnimation { target: imgBack; property: "opacity"; to: 1; duration: 260; easing.type: Easing.OutCubic }
                NumberAnimation { target: imgFront; property: "opacity"; to: 0; duration: 260; easing.type: Easing.OutCubic }
            }
            ScriptAction {
                script: {
                    imgFront.source = imgBack.source
                    imgFront.opacity = 1
                    imgBack.opacity = 0
                }
            }
        }
    }


    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.72) }
            GradientStop { position: 0.55; color: Qt.rgba(0, 0, 0, 0.45) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.12) }
        }
    }

    ColumnLayout {
        id: cardCol
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
        spacing: 2

        // Source app
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            IconImage {
                id: srcIcon
                implicitWidth: 16
                implicitHeight: 16
                source: player?.desktopEntry ? Quickshell.iconPath(player.desktopEntry) : ""
                visible: status === Image.Ready
            }
            OneUIIcon {
                visible: !srcIcon.visible
                name: "mdi_music_note"
                size: 14
                color: "white"
            }
            Text {
                text: player?.identity ?? ""
                color: "white"
                opacity: 0.85
                font.family: "OneUI Sans"
                font.pixelSize: QsConfig.Appearance.fontSize.s
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                visible: root.showOutputButton
                implicitWidth: outLabel.implicitWidth + 20
                implicitHeight: 24
                radius: 12
                color: root.outputsOpen ? Qt.rgba(1, 1, 1, 0.35) : Qt.rgba(1, 1, 1, 0.2)
                Text {
                    id: outLabel
                    anchors.centerIn: parent
                    text: "Media output"
                    color: "white"
                    font.family: "OneUI Sans"
                    font.pixelSize: QsConfig.Appearance.fontSize.s
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.outputClicked()
                }
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.topMargin: 6
            text: player?.trackTitle || "No media playing"
            color: "white"
            font.family: "OneUI Sans"
            font.pixelSize: QsConfig.Appearance.fontSize.xl
            font.bold: true
            elide: Text.ElideRight
        }

        Text {
            Layout.fillWidth: true
            text: player?.trackArtist ?? ""
            color: "white"
            opacity: 0.75
            font.family: "OneUI Sans"
            font.pixelSize: QsConfig.Appearance.fontSize.m
            elide: Text.ElideRight
        }

        // Seek bar: a flat capsule; while playing, soft translucent hills rise
        // over the played part (Samsung's media card), flat when paused.
        Item {
            id: seekItem
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            Layout.topMargin: 4

            readonly property bool canSeek: (player?.canSeek ?? false) && (player?.positionSupported ?? false)
            readonly property real ratio: (player && player.length > 0) ? Math.min(1, Math.max(0, player.position / player.length)) : 0
            readonly property bool playing: player?.isPlaying ?? false
            property real phase: 0
            property real amp: playing ? 13 : 0
            Behavior on amp { NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }
            NumberAnimation on phase {
                from: 0; to: Math.PI * 2; duration: 3200
                loops: Animation.Infinite
                running: root.active && seekItem.playing
            }
            onPhaseChanged: wave.requestPaint()
            onAmpChanged: wave.requestPaint()
            onRatioChanged: wave.requestPaint()

            Canvas {
                id: wave
                anchors.fill: parent
                onWidthChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    const barH = 8, r = 9
                    const mid = height - 12
                    const top = mid - barH / 2
                    const x1 = Math.min(width - r, Math.max(r, width * seekItem.ratio))
                    const prim = root.accent
                    ctx.lineCap = "round"
                    ctx.lineWidth = barH
                    ctx.strokeStyle = "rgba(255,255,255,0.28)"
                    ctx.beginPath()
                    ctx.moveTo(barH / 2, mid)
                    ctx.lineTo(width - barH / 2, mid)
                    ctx.stroke()
                    ctx.strokeStyle = prim.toString()
                    ctx.beginPath()
                    ctx.moveTo(barH / 2, mid)
                    ctx.lineTo(Math.max(barH / 2, x1), mid)
                    ctx.stroke()

                    // Hills: two sines of different length and speed, windowed to 0 at both ends
                    if (seekItem.amp > 0.2 && x1 > 40) {
                        const x0 = 10, span = x1 - 6 - x0
                        ctx.fillStyle = Qt.lighter(prim, 1.45).toString()
                        ctx.globalAlpha = 0.8
                        ctx.beginPath()
                        ctx.moveTo(x0, top + 1)
                        for (let x = x0; x <= x0 + span; x += 2) {
                            const t = (x - x0) / span
                            const env = Math.pow(Math.sin(Math.PI * t), 0.8)
                            const s1 = 0.5 + 0.5 * Math.sin(2 * Math.PI * x / 78 - seekItem.phase)
                            const s2 = 0.5 + 0.5 * Math.sin(2 * Math.PI * x / 46 + 2 * seekItem.phase + 1.3)
                            ctx.lineTo(x, top + 1 - seekItem.amp * env * (0.6 * s1 + 0.4 * s2 * s1 + 0.15))
                        }
                        ctx.lineTo(x0 + span, top + 1)
                        ctx.closePath()
                        ctx.fill()
                        ctx.globalAlpha = 1
                    }

                    ctx.fillStyle = "white"
                    ctx.beginPath()
                    ctx.arc(x1, mid, seekArea.pressed ? 10 : 9, 0, Math.PI * 2)
                    ctx.fill()
                }
            }

            MouseArea {
                id: seekArea
                anchors.fill: parent
                enabled: seekItem.canSeek
                cursorShape: seekItem.canSeek ? Qt.PointingHandCursor : Qt.ArrowCursor
                function seekToX(x) {
                    if (!player || player.length <= 0) return
                    player.position = Math.min(1, Math.max(0, x / width)) * player.length
                }
                onPressed: mouse => { seekToX(mouse.x); wave.requestPaint() }
                onPositionChanged: mouse => { if (pressed) seekToX(mouse.x) }
                onReleased: wave.requestPaint()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: root.formatTime(player?.position ?? 0)
                color: "white"; opacity: 0.7
                font.pixelSize: QsConfig.Appearance.fontSize.xs
            }
            Item { Layout.fillWidth: true }
            Text {
                text: root.formatTime(player?.length ?? 0)
                color: "white"; opacity: 0.7
                font.pixelSize: QsConfig.Appearance.fontSize.xs
            }
        }

        // shuffle | prev | play/pause | next | repeat
        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            component CtrlBtn: Item {
                id: btn
                property string icon
                property int iconSize: 22
                property bool on: false
                property bool usable: true
                signal clicked()
                implicitWidth: 40
                implicitHeight: 40
                opacity: usable ? 1 : 0.3
                OneUIIcon {
                    anchors.centerIn: parent
                    name: btn.icon
                    size: btn.iconSize
                    color: btn.on ? root.accent : "white"
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: btn.usable
                    cursorShape: Qt.PointingHandCursor
                    onClicked: btn.clicked()
                }
            }

            CtrlBtn {
                icon: "mdi_shuffle_variant"; iconSize: 18
                on: player?.shuffle ?? false
                usable: player?.shuffleSupported ?? false
                opacity: usable ? 1 : 0
                onClicked: player.shuffle = !player.shuffle
            }
            Item { Layout.fillWidth: true }
            CtrlBtn {
                icon: "ic_prev"
                usable: player?.canGoPrevious ?? false
                onClicked: player.previous()
            }
            Item { Layout.fillWidth: true }
            CtrlBtn {
                icon: (player?.isPlaying ?? false) ? "ic_pause" : "ic_play"
                iconSize: 30
                usable: player?.canTogglePlaying ?? false
                onClicked: player.togglePlaying()
            }
            Item { Layout.fillWidth: true }
            CtrlBtn {
                icon: "ic_next"
                usable: player?.canGoNext ?? false
                onClicked: player.next()
            }
            Item { Layout.fillWidth: true }
            CtrlBtn {
                icon: "mdi_repeat"; iconSize: 18
                on: player && player.loopState !== MprisLoopState.None
                usable: player?.loopSupported ?? false
                opacity: usable ? 1 : 0
                onClicked: {
                    if (player.loopState === MprisLoopState.None) player.loopState = MprisLoopState.Playlist
                    else if (player.loopState === MprisLoopState.Playlist) player.loopState = MprisLoopState.Track
                    else player.loopState = MprisLoopState.None
                }
            }
        }
    }
}

