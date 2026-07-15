import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import "../../../services" as QsServices

// Inline Media Panel - hosted inside bar window, same pattern as NetworkPanel/BluetoothPanel
FocusScope {
    id: popupPanel

    property bool shouldShow: false
    signal closeRequested()

    readonly property var pywal: QsServices.Pywal
    readonly property var players: QsServices.Players.list
    property var selectedPlayer: null
    readonly property var player: (selectedPlayer && players.indexOf(selectedPlayer) !== -1) ? selectedPlayer : QsServices.Players.active
    readonly property var appVolume: QsServices.AppVolume

    // Every time the popup is opened, forget any manual tab pick and
    // default to whatever's actually playing right now.
    onShouldShowChanged: if (shouldShow) selectedPlayer = null

    implicitWidth: 320
    implicitHeight: contentColumn.implicitHeight + 32
    focus: true

    Keys.onEscapePressed: closeRequested()

    // Point the per-app volume service at whichever app is currently
    // playing, but only while this popup is actually visible (no need to
    // keep polling pactl in the background otherwise).
    readonly property string playerIdentity: player?.identity ?? ""
    Binding {
        target: QsServices.AppVolume
        property: "targetIdentity"
        value: popupPanel.shouldShow ? popupPanel.playerIdentity : ""
    }

    // Keep position live while playing (position doesn't update reactively on its own)
    Timer {
        interval: 500
        running: popupPanel.shouldShow && (player?.isPlaying ?? false)
        repeat: true
        onTriggered: player.positionChanged()
    }

    // Background
    Rectangle {
        anchors.fill: parent
        radius: 16
        color: pywal.background || "#1e1e2e"
        border.width: 1
        border.color: pywal.color2 || "#89b4fa"
        opacity: 0.98
    }

    ColumnLayout {
        id: contentColumn

        anchors {
            fill: parent
            margins: 16
        }
        spacing: 14

        // Source tabs — one per app currently exposing MPRIS media (browser
        // tabs, Spotify, etc). Only shown when there's more than one, same
        // as Android's media carousel / Plasma's media widget: no point
        // showing tab chrome for a single source.
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: popupPanel.players.length > 1

            Repeater {
                model: popupPanel.players

                Rectangle {
                    id: playerTab
                    required property var modelData
                    readonly property bool isSelected: modelData === popupPanel.player

                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    radius: 10
                    color: isSelected
                        ? Qt.rgba((pywal.color2 || "#cba6f7").r, (pywal.color2 || "#cba6f7").g, (pywal.color2 || "#cba6f7").b, 0.25)
                        : (tabHover.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent")
                    border.width: isSelected ? 1 : 0
                    border.color: pywal.color2 || "#cba6f7"

                    Behavior on color { ColorAnimation { duration: 120 } }

                    // App icon once a theme (e.g. Papirus) provides one for
                    // this desktop entry; falls back to a generic note glyph
                    // until then, or for apps with no matching .desktop file.
                    IconImage {
                        id: tabIcon
                        anchors.centerIn: parent
                        width: 20
                        height: 20
                        source: playerTab.modelData?.desktopEntry ? Quickshell.iconPath(playerTab.modelData.desktopEntry) : ""
                        visible: status === Image.Ready
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: !tabIcon.visible
                        text: "󰝚"
                        font.family: "Material Design Icons"
                        font.pixelSize: 16
                        color: playerTab.isSelected ? (pywal.color2 || "#cba6f7") : pywal.foreground
                        opacity: playerTab.isSelected ? 1 : 0.6
                    }

                    // Playing / paused indicator
                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: playerTab.modelData?.isPlaying ? "#a6e3a1" : "#6c7086"
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 2
                    }

                    MouseArea {
                        id: tabHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popupPanel.selectedPlayer = playerTab.modelData
                    }
                }
            }

            Item { Layout.fillWidth: true }
        }

        // Album Art
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 240
            Layout.preferredHeight: 240

            color: pywal.color1 || "#89b4fa"
            radius: 12
            clip: true

            Item {
                id: artStack
                anchors.fill: parent
                anchors.margins: 2
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

            Text {
                anchors.centerIn: parent
                text: "🎵"
                font.pixelSize: 70
                visible: !(player?.trackArtUrl ?? false)
                opacity: 0.6
            }
        }

        // Track Info
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: player?.trackTitle || "Çalan medya yok"
                color: pywal.foreground || "#cdd6f4"
                font.family: "Inter"
                font.pixelSize: 15
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: player?.trackArtist ?? ""
                color: pywal.foreground || "#cdd6f4"
                opacity: 0.75
                font.family: "Inter"
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
        }

        // Seekable progress bar
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 18
            Layout.topMargin: 4

            readonly property bool canSeek: (player?.canSeek ?? false) && (player?.positionSupported ?? false)
            readonly property real ratio: (player && player.length > 0) ? Math.min(1, Math.max(0, player.position / player.length)) : 0

            Rectangle {
                id: track
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 6
                radius: 3
                color: pywal.color1 || "#89b4fa"
                opacity: 0.3

                Rectangle {
                    width: track.width * parent.parent.ratio
                    height: parent.height
                    radius: 3
                    color: pywal.color2 || "#cba6f7"

                    Behavior on width {
                        enabled: !seekArea.pressed
                        NumberAnimation { duration: 150 }
                    }
                }

                // Playhead handle
                Rectangle {
                    visible: parent.parent.canSeek
                    width: 12
                    height: 12
                    radius: 6
                    color: pywal.foreground || "#cdd6f4"
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.min(track.width - width, Math.max(0, track.width * parent.parent.ratio - width / 2))
                }
            }

            MouseArea {
                id: seekArea
                anchors.fill: parent
                enabled: parent.canSeek
                cursorShape: parent.canSeek ? Qt.PointingHandCursor : Qt.ArrowCursor

                function seekToX(x) {
                    if (!player || player.length <= 0) return
                    const ratio = Math.min(1, Math.max(0, x / width))
                    player.position = ratio * player.length
                }

                onPressed: mouse => seekToX(mouse.x)
                onPositionChanged: mouse => { if (pressed) seekToX(mouse.x) }
            }
        }

        // Time labels
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: formatTime(player?.position ?? 0)
                color: pywal.foreground || "#cdd6f4"
                opacity: 0.6
                font.pixelSize: 10
            }

            Item { Layout.fillWidth: true }

            Text {
                text: formatTime(player?.length ?? 0)
                color: pywal.foreground || "#cdd6f4"
                opacity: 0.6
                font.pixelSize: 10
            }
        }

        // Playback Controls
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 20

            Item { Layout.fillWidth: true }

            // Previous
            Rectangle {
                Layout.preferredWidth: 42
                Layout.preferredHeight: 42
                radius: 21
                color: prevHover.containsMouse ? Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.12) : "transparent"
                opacity: (player?.canGoPrevious ?? false) ? 1 : 0.35

                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰒮"
                    font.family: "Material Design Icons"
                    font.pixelSize: 20
                    color: pywal.foreground || "#cdd6f4"
                }

                MouseArea {
                    id: prevHover
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: player?.canGoPrevious ?? false
                    cursorShape: Qt.PointingHandCursor
                    onClicked: player.previous()
                }
            }

            // Play/Pause
            Rectangle {
                Layout.preferredWidth: 54
                Layout.preferredHeight: 54
                radius: 27
                color: playHover.containsMouse ? Qt.lighter(pywal.color2 || "#cba6f7", 1.08) : (pywal.color2 || "#cba6f7")

                Behavior on color { ColorAnimation { duration: 120 } }
                scale: playHover.pressed ? 0.92 : 1.0
                Behavior on scale { NumberAnimation { duration: 80 } }

                Text {
                    id: playPauseIcon
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: (player?.isPlaying ?? false) ? 0 : 1
                    text: (player?.isPlaying ?? false) ? "󰏤" : "󰐊"
                    font.family: "Material Design Icons"
                    font.pixelSize: 22
                    color: pywal.background || "#1e1e2e"
                    scale: 1.0

                    onTextChanged: popIconAnim.restart()

                    SequentialAnimation {
                        id: popIconAnim
                        NumberAnimation { target: playPauseIcon; property: "scale"; from: 0.45; to: 1.15; duration: 150; easing.type: Easing.OutBack }
                        NumberAnimation { target: playPauseIcon; property: "scale"; to: 1.0; duration: 110; easing.type: Easing.OutCubic }
                    }
                }

                MouseArea {
                    id: playHover
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: player?.canTogglePlaying ?? false
                    cursorShape: Qt.PointingHandCursor
                    onClicked: player.togglePlaying()
                }
            }

            // Next
            Rectangle {
                Layout.preferredWidth: 42
                Layout.preferredHeight: 42
                radius: 21
                color: nextHover.containsMouse ? Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.12) : "transparent"
                opacity: (player?.canGoNext ?? false) ? 1 : 0.35

                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰒭"
                    font.family: "Material Design Icons"
                    font.pixelSize: 20
                    color: pywal.foreground || "#cdd6f4"
                }

                MouseArea {
                    id: nextHover
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: player?.canGoNext ?? false
                    cursorShape: Qt.PointingHandCursor
                    onClicked: player.next()
                }
            }

            Item { Layout.fillWidth: true }
        }

        // Shuffle / Repeat
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 2
            spacing: 28

            Item { Layout.fillWidth: true }

            // Shuffle toggle
            Rectangle {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                radius: 17
                visible: player?.shuffleSupported ?? false
                color: (player?.shuffle ?? false)
                    ? Qt.rgba(pywal.color2.r, pywal.color2.g, pywal.color2.b, 0.25)
                    : (shuffleHover.containsMouse ? Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.1) : "transparent")

                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰒟"
                    font.family: "Material Design Icons"
                    font.pixelSize: 16
                    color: (player?.shuffle ?? false) ? (pywal.color2 || "#cba6f7") : pywal.foreground
                }

                MouseArea {
                    id: shuffleHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: player.shuffle = !player.shuffle
                }
            }

            // Repeat / loop cycle: None -> Track -> Playlist -> None
            Rectangle {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                radius: 17
                visible: player?.loopSupported ?? false
                color: (player && player.loopState !== MprisLoopState.None)
                    ? Qt.rgba(pywal.color2.r, pywal.color2.g, pywal.color2.b, 0.25)
                    : (loopHover.containsMouse ? Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.1) : "transparent")

                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: (player && player.loopState === MprisLoopState.Track) ? "󰑖" : "󰑖"
                    font.family: "Material Design Icons"
                    font.pixelSize: 16
                    color: (player && player.loopState !== MprisLoopState.None) ? (pywal.color2 || "#cba6f7") : pywal.foreground

                    // Small "1" badge when looping a single track
                    Text {
                        visible: player && player.loopState === MprisLoopState.Track
                        text: "1"
                        font.pixelSize: 8
                        font.bold: true
                        color: parent.color
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                    }
                }

                MouseArea {
                    id: loopHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!player) return
                        if (player.loopState === MprisLoopState.None) player.loopState = MprisLoopState.Playlist
                        else if (player.loopState === MprisLoopState.Playlist) player.loopState = MprisLoopState.Track
                        else player.loopState = MprisLoopState.None
                    }
                }
            }

            Item { Layout.fillWidth: true }
        }

        // Volume — controls the app's own audio stream (per-app volume,
        // like the Windows volume mixer), not the MPRIS Volume property
        // (most apps, browsers especially, don't implement that at all).
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 2
            spacing: 10
            visible: popupPanel.appVolume.ready

            Text {
                text: popupPanel.appVolume.muted ? "󰝟" : "󰕾"
                font.family: "Material Design Icons"
                font.pixelSize: 15
                color: pywal.foreground || "#cdd6f4"
                opacity: 0.75

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: popupPanel.appVolume.setMuted(!popupPanel.appVolume.muted)
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 14

                readonly property real ratio: Math.min(1, Math.max(0, popupPanel.appVolume.volume))

                Rectangle {
                    id: volTrack
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 5
                    radius: 2.5
                    color: pywal.color1 || "#89b4fa"
                    opacity: 0.3

                    Rectangle {
                        width: volTrack.width * parent.parent.ratio
                        height: parent.height
                        radius: 2.5
                        color: pywal.color2 || "#cba6f7"

                        Behavior on width {
                            enabled: !volArea.pressed
                            NumberAnimation { duration: 100 }
                        }
                    }

                    Rectangle {
                        width: 10
                        height: 10
                        radius: 5
                        color: pywal.foreground || "#cdd6f4"
                        anchors.verticalCenter: parent.verticalCenter
                        x: Math.min(volTrack.width - width, Math.max(0, volTrack.width * parent.parent.ratio - width / 2))
                    }
                }

                MouseArea {
                    id: volArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    function setFromX(x) {
                        popupPanel.appVolume.setVolume(x / width)
                    }

                    onPressed: mouse => setFromX(mouse.x)
                    onPositionChanged: mouse => { if (pressed) setFromX(mouse.x) }
                }
            }
        }
    }

    function formatTime(seconds) {
        if (!seconds || seconds <= 0) return "0:00"
        const mins = Math.floor(seconds / 60)
        const secs = Math.floor(seconds % 60)
        return mins + ":" + (secs < 10 ? "0" : "") + secs
    }
}
