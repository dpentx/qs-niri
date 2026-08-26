import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import Quickshell.Io
import "../../../services" as QsServices
import "../../../config" as QsConfig

// Inline Recordings Gallery Panel — thumbnails of gpu-screen-recorder captures
FocusScope {
    id: popupPanel

    property bool shouldShow: false
    signal closeRequested()

    readonly property var pywal: QsServices.Pywal
    readonly property string recordingsDir: QsConfig.Config.paths.screenshotsDir
    readonly property string thumbCacheDir: `${Quickshell.env("HOME")}/.cache/qs-recording-thumbs`

    property var recordings: []   // [{path, name, thumb}]
    property bool loading: false

    implicitWidth: 320
    implicitHeight: 420
    focus: true

    Keys.onEscapePressed: closeRequested()

    onShouldShowChanged: {
        if (shouldShow) refresh()
    }

    function refresh() {
        loading = true
        const cmd = `mkdir -p "${recordingsDir}" "${thumbCacheDir}"; ` +
            `find "${recordingsDir}" -maxdepth 1 -type f -iname 'recording-*.mp4' 2>/dev/null | sort -r | while IFS= read -r f; do ` +
            `  b=$(basename "$f"); t="${thumbCacheDir}/$b.jpg"; ` +
            `  [ -f "$t" ] || ffmpeg -y -ss 00:00:01 -i "$f" -frames:v 1 -vf "scale=280:-1" "$t" >>/tmp/qs-recording-thumb.log 2>&1; ` +
            `  echo "$f"; ` +
            `done`
        listProc.exec(["sh", "-c", cmd])
    }

    Process {
        id: listProc
        stdout: StdioCollector {
            onStreamFinished: {
                const paths = text.split("\n").filter(l => l.length > 0)
                popupPanel.recordings = paths.map(p => {
                    const name = p.split("/").pop()
                    return {
                        path: p,
                        name: name,
                        thumb: `${popupPanel.thumbCacheDir}/${name}.jpg`
                    }
                })
                popupPanel.loading = false
            }
        }
    }

    Process { id: playProc }

    function playRecording(path) {
        playProc.exec(["xdg-open", path])
    }

    Process {
        id: deleteProc
        onExited: popupPanel.refresh()
    }

    function deleteRecording(path) {
        deleteProc.exec(["rm", "-f", path])
    }

    Process { id: revealProc }

    function revealFolder() {
        revealProc.exec(["xdg-open", recordingsDir])
        closeRequested()
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
        anchors {
            fill: parent
            margins: 14
        }
        spacing: 10

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Kayıtlar"
                color: pywal.foreground || "#cdd6f4"
                font.family: "Inter"
                font.pixelSize: 14
                font.bold: true
                Layout.fillWidth: true
            }

            Text {
                text: "󰑐"
                font.family: "Material Design Icons"
                font.pixelSize: 14
                color: pywal.foreground || "#cdd6f4"
                opacity: popupPanel.loading ? 1 : 0.5

                RotationAnimation on rotation {
                    running: popupPanel.loading
                    from: 0; to: 360; duration: 900; loops: Animation.Infinite
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: popupPanel.refresh()
                }
            }

            Text {
                text: "Klasörü Aç"
                color: pywal.foreground || "#cdd6f4"
                opacity: folderHover.containsMouse ? 0.9 : 0.5
                font.pixelSize: 11

                MouseArea {
                    id: folderHover
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: popupPanel.revealFolder()
                }
            }
        }

        GridView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            cellWidth: width / 2
            cellHeight: cellWidth * 0.85
            model: popupPanel.recordings

            delegate: Item {
                width: GridView.view.cellWidth
                height: GridView.view.cellHeight

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 5
                    radius: 10
                    color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.06)
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: `file://${modelData.thumb}`
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 34
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.75) }
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.right: deleteBtn.left
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 8
                            anchors.rightMargin: 4
                            text: modelData.name.replace("recording-", "").replace(".mp4", "")
                            color: "#ffffff"
                            font.pixelSize: 9
                            elide: Text.ElideRight
                        }

                        Text {
                            id: deleteBtn
                            anchors.right: parent.right
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰆴"
                            font.family: "Material Design Icons"
                            font.pixelSize: 13
                            color: delHover.containsMouse ? "#e57373" : "#ffffff"

                            MouseArea {
                                id: delHover
                                anchors.fill: parent
                                anchors.margins: -6
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: popupPanel.deleteRecording(modelData.path)
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "󰐊"
                        font.family: "Material Design Icons"
                        font.pixelSize: 26
                        color: "#ffffff"
                        opacity: playHover.containsMouse ? 0.95 : 0.0

                        Behavior on opacity { NumberAnimation { duration: 100 } }
                    }

                    MouseArea {
                        id: playHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popupPanel.playRecording(modelData.path)
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: !popupPanel.loading && popupPanel.recordings.length === 0
                text: "Henüz kayıt yok"
                color: pywal.foreground || "#cdd6f4"
                opacity: 0.4
                font.pixelSize: 12
            }
        }
    }
}
