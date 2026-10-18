import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import "../../../services" as QsServices
import "../../../config" as QsConfig
import "../../../components"

// Inline Media Panel - hosted inside bar window, same pattern as NetworkPanel/BluetoothPanel
FocusScope {
    id: popupPanel

    property bool shouldShow: false
    signal closeRequested()

    readonly property var pywal: QsServices.Pywal
    readonly property var audio: QsServices.Audio
    readonly property var players: QsServices.Players.list
    property var selectedPlayer: null
    property bool showOutputs: false   // the output device list opens from the "Media output" pill
    readonly property var player: (selectedPlayer && players.indexOf(selectedPlayer) !== -1) ? selectedPlayer : QsServices.Players.active
    readonly property var appVolume: QsServices.AppVolume

    // Every time the popup is opened, forget any manual tab pick and
    // default to whatever's actually playing right now.
    onShouldShowChanged: if (shouldShow) { selectedPlayer = null; showOutputs = false }

    implicitWidth: 380
    implicitHeight: contentColumn.implicitHeight
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

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        spacing: 12

        NowPlayingCard {
            Layout.fillWidth: true
            player: popupPanel.player
            active: popupPanel.shouldShow
            showOutputButton: true
            outputsOpen: popupPanel.showOutputs
            onOutputClicked: popupPanel.showOutputs = !popupPanel.showOutputs
        }

        // Tabs, app volume and output list sit on their own surface so the card stands alone.
        Rectangle {
            Layout.fillWidth: true
            visible: popupPanel.players.length > 1 || popupPanel.appVolume.ready || (popupPanel.showOutputs && audio.sinks.length > 0)
            implicitHeight: extrasCol.implicitHeight + 24
            radius: QsConfig.Appearance.radius.l
            color: pywal.popupSurface

            ColumnLayout {
                id: extrasCol
                anchors { fill: parent; margins: 12 }
                spacing: 12

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
                            radius: QsConfig.Appearance.radius.s
                            color: isSelected
                                ? Qt.rgba((pywal.primary).r, (pywal.primary).g, (pywal.primary).b, 0.25)
                                : (tabHover.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent")
                            border.width: isSelected ? 1 : 0
                            border.color: pywal.primary

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

                            OneUIIcon {
                                anchors.centerIn: parent
                                visible: !tabIcon.visible
                                name: "mdi_music_note"
                                size: 16
                                color: playerTab.isSelected ? (pywal.primary) : pywal.foreground
                                opacity: playerTab.isSelected ? 1 : 0.6
                            }

                            // Playing / paused indicator
                            Rectangle {
                                width: 6
                                height: 6
                                radius: 3
                                color: playerTab.modelData?.isPlaying ? pywal.success : pywal.outline
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

                // Volume — controls the app's own audio stream (per-app volume,
                // like the Windows volume mixer), not the MPRIS Volume property
                // (most apps, browsers especially, don't implement that at all).
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    spacing: 10
                    visible: popupPanel.appVolume.ready

                    OneUIIcon {
                        name: popupPanel.appVolume.muted ? "ic_speaker_mute" : "ic_speaker_on"
                        size: 15
                        color: pywal.foreground
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
                            color: pywal.primary
                            opacity: 0.3

                            Rectangle {
                                width: volTrack.width * parent.parent.ratio
                                height: parent.height
                                radius: 2.5
                                color: pywal.primary

                                Behavior on width {
                                    enabled: !volArea.pressed
                                    NumberAnimation { duration: 100 }
                                }
                            }

                            Rectangle {
                                width: 10
                                height: 10
                                radius: 5
                                color: pywal.foreground
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

                // Media output — device picker (OneUI quick panel's "Media
                // output" tab). Only shown when there's actually more than one
                // device to choose between.
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    spacing: 4
                    visible: popupPanel.showOutputs && audio.sinks.length > 0

                    Text {
                        text: "Media output"
                        font.family: "OneUI Sans"
                        font.pixelSize: QsConfig.Appearance.fontSize.s
                        font.weight: Font.DemiBold
                        color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.6)
                        Layout.bottomMargin: 2
                    }

                    Repeater {
                        model: audio.sinks

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            radius: QsConfig.Appearance.radius.m
                            color: modelData.isDefault
                                ? Qt.rgba(pywal.primary.r, pywal.primary.g, pywal.primary.b, 0.16)
                                : (sinkRowMouse.containsMouse ? Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.06) : "transparent")

                            Behavior on color { ColorAnimation { duration: 120 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 10

                                OneUIIcon {
                                    name: {
                                        const n = modelData.name.toLowerCase()
                                        if (n.includes("bluetooth") || n.includes("buds") || n.includes("airpods") || n.includes("headphone"))
                                            return "ic_headphone"
                                        if (n.includes("hdmi") || n.includes("display"))
                                            return "mdi_monitor"
                                        return "ic_speaker_rounded"
                                    }
                                    size: 16
                                    color: modelData.isDefault ? pywal.primary : pywal.foreground
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    font.family: "OneUI Sans"
                                    font.pixelSize: QsConfig.Appearance.fontSize.m
                                    font.weight: modelData.isDefault ? Font.DemiBold : Font.Normal
                                    color: pywal.foreground
                                    elide: Text.ElideRight
                                }

                                OneUIIcon {
                                    visible: modelData.isDefault
                                    name: "mdi_check"
                                    size: 14
                                    color: pywal.primary
                                }
                            }

                            MouseArea {
                                id: sinkRowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (!modelData.isDefault)
                                        audio.setDefaultSink(modelData.id)
                                }
                            }
                        }
                    }
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
