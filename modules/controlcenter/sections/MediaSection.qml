import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10
import Quickshell
import "../../../services" as QsServices

Item {
    id: root
    
    readonly property var pywal: QsServices.Pywal
    readonly property var players: QsServices.Players
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16
        
        Text {
            text: "Media Player"
            font.family: "Inter"
            font.pixelSize: 16
            font.weight: Font.Bold
            color: pywal.foreground
        }
        
        // Player content or no player message
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            // No player active
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 12
                visible: !players.active
                
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "󰝚"
                    font.family: "Material Design Icons"
                    font.pixelSize: 48
                    color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.3)
                }
                
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "No media playing"
                    font.family: "Inter"
                    font.pixelSize: 14
                    color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.5)
                }
            }
            
            // Active player
            ColumnLayout {
                anchors.fill: parent
                spacing: 16
                visible: players.active
                
                // Album art
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 280
                    radius: 12
                    color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.05)
                    clip: true
                    
                    Image {
                        anchors.fill: parent
                        source: players.active ? players.active.trackArtUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                        
                        // Fallback icon if no album art
                        Text {
                            anchors.centerIn: parent
                            text: "󰝚"
                            font.family: "Material Design Icons"
                            font.pixelSize: 64
                            color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.2)
                            visible: !parent.source || parent.status !== Image.Ready
                        }
                    }
                    
                    // Gradient overlay for text readability
                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.4) }
                        }
                    }
                }
                
                // Track info
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    
                    Text {
                        Layout.fillWidth: true
                        text: players.active ? players.active.trackTitle : ""
                        font.family: "Inter"
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        color: pywal.foreground
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                    
                    Text {
                        Layout.fillWidth: true
                        text: players.active ? players.active.trackArtist : ""
                        font.family: "Inter"
                        font.pixelSize: 13
                        color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.7)
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                    
                    Text {
                        Layout.fillWidth: true
                        text: players.active ? players.active.trackAlbum : ""
                        font.family: "Inter"
                        font.pixelSize: 11
                        color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.5)
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                }
                
                // Seek bar
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    
                    Slider {
                        id: seekSlider
                        Layout.fillWidth: true
                        from: 0
                        to: players.active ? players.active.length : 100
                        value: players.active ? players.active.position : 0
                        
                        onMoved: {
                            if (players.active) {
                                players.active.setPosition(value)
                            }
                        }
                        
                        background: Rectangle {
                            x: seekSlider.leftPadding
                            y: seekSlider.topPadding + seekSlider.availableHeight / 2 - height / 2
                            width: seekSlider.availableWidth
                            height: 4
                            radius: 2
                            color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.15)
                            
                            Rectangle {
                                width: seekSlider.visualPosition * parent.width
                                height: parent.height
                                color: pywal.color2
                                radius: 2
                            }
                        }
                        
                        handle: Rectangle {
                            x: seekSlider.leftPadding + seekSlider.visualPosition * (seekSlider.availableWidth - width)
                            y: seekSlider.topPadding + seekSlider.availableHeight / 2 - height / 2
                            width: 16
                            height: 16
                            radius: 8
                            color: pywal.foreground
                            border.color: pywal.color2
                            border.width: 2
                        }
                    }
                    
                    // Time labels
                    RowLayout {
                        Layout.fillWidth: true
                        
                        Text {
                            text: formatTime(players.active ? players.active.position : 0)
                            font.family: "Inter"
                            font.pixelSize: 10
                            color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.6)
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        Text {
                            text: formatTime(players.active ? players.active.length : 0)
                            font.family: "Inter"
                            font.pixelSize: 10
                            color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.6)
                        }
                    }
                }
                
                // Playback controls
                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 16
                    
                    // Previous button
                    Rectangle {
                        width: 48
                        height: 48
                        radius: 24
                        color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.05)
                        
                        Text {
                            anchors.centerIn: parent
                            text: "󰒮"
                            font.family: "Material Design Icons"
                            font.pixelSize: 24
                            color: pywal.foreground
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (players.active) {
                                    players.active.previous()
                                }
                            }
                            onPressed: parent.color = Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.15)
                            onReleased: parent.color = Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.05)
                        }
                    }
                    
                    // Play/Pause button (larger)
                    Rectangle {
                        width: 60
                        height: 60
                        radius: 30
                        color: pywal.color2
                        
                        Text {
                            anchors.centerIn: parent
                            text: (players.active && players.active.isPlaying) ? "󰏤" : "󰐊"
                            font.family: "Material Design Icons"
                            font.pixelSize: 32
                            color: pywal.background
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (players.active) {
                                    players.active.togglePlaying()
                                }
                            }
                            onPressed: parent.opacity = 0.8
                            onReleased: parent.opacity = 1.0
                        }
                        
                        Behavior on opacity {
                            NumberAnimation { duration: 100 }
                        }
                    }
                    
                    // Next button
                    Rectangle {
                        width: 48
                        height: 48
                        radius: 24
                        color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.05)
                        
                        Text {
                            anchors.centerIn: parent
                            text: "󰒭"
                            font.family: "Material Design Icons"
                            font.pixelSize: 24
                            color: pywal.foreground
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (players.active) {
                                    players.active.next()
                                }
                            }
                            onPressed: parent.color = Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.15)
                            onReleased: parent.color = Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.05)
                        }
                    }
                }
                
                Item { Layout.fillHeight: true }
            }
        }
    }
    
    // Helper function to format time
    function formatTime(seconds) {
        if (!seconds || seconds < 0) return "0:00"
        var mins = Math.floor(seconds / 60)
        var secs = Math.floor(seconds % 60)
        return mins + ":" + (secs < 10 ? "0" : "") + secs
    }
}
