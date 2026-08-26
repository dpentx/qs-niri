import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell.Io
import "../../../services" as QsServices

// Inline Clipboard History Panel — lists cliphist entries, click to copy
FocusScope {
    id: popupPanel

    property bool shouldShow: false
    signal closeRequested()

    readonly property var pywal: QsServices.Pywal
    property var entries: []          // [{id, preview}]
    property string filterText: ""
    readonly property var filteredEntries: {
        if (!filterText) return entries
        const q = filterText.toLowerCase()
        return entries.filter(e => e.preview.toLowerCase().includes(q))
    }

    implicitWidth: 320
    implicitHeight: 420
    focus: true

    Keys.onEscapePressed: closeRequested()

    onShouldShowChanged: {
        if (shouldShow) {
            filterText = ""
            searchField.text = ""
            listProc.running = true
        }
    }

    function refresh() { listProc.running = true }

    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n").filter(l => l.length > 0)
                popupPanel.entries = lines.map(line => {
                    const tabIdx = line.indexOf("\t")
                    return {
                        id: tabIdx >= 0 ? line.slice(0, tabIdx) : line,
                        preview: tabIdx >= 0 ? line.slice(tabIdx + 1) : line
                    }
                })
            }
        }
    }

    Process {
        id: copyProc
    }

    function copyEntry(id) {
        copyProc.exec(["sh", "-c", `cliphist decode ${id} | wl-copy`])
        closeRequested()
    }

    Process {
        id: wipeProc
        command: ["cliphist", "wipe"]
        onExited: popupPanel.refresh()
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
                text: "Pano Geçmişi"
                color: pywal.foreground || "#cdd6f4"
                font.family: "Inter"
                font.pixelSize: 14
                font.bold: true
                Layout.fillWidth: true
            }

            Text {
                text: "Temizle"
                color: pywal.foreground || "#cdd6f4"
                opacity: clearHover.containsMouse ? 0.9 : 0.5
                font.pixelSize: 11

                MouseArea {
                    id: clearHover
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: wipeProc.running = true
                }
            }
        }

        // Search field
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: 8
            color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.06)
            border.width: 1
            border.color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.1)

            TextInput {
                id: searchField
                anchors.fill: parent
                anchors.margins: 8
                verticalAlignment: TextInput.AlignVCenter
                color: pywal.foreground || "#cdd6f4"
                font.pixelSize: 12
                clip: true
                onTextChanged: popupPanel.filterText = text

                Text {
                    text: "Ara..."
                    visible: searchField.text.length === 0
                    color: pywal.foreground || "#cdd6f4"
                    opacity: 0.4
                    font.pixelSize: 12
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // Entry list
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            model: popupPanel.filteredEntries

            delegate: Rectangle {
                width: ListView.view.width
                height: 40
                radius: 8
                color: entryHover.containsMouse ? Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.08) : "transparent"

                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    anchors.fill: parent
                    anchors.margins: 10
                    verticalAlignment: Text.AlignVCenter
                    text: modelData.preview
                    color: pywal.foreground || "#cdd6f4"
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }

                MouseArea {
                    id: entryHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: popupPanel.copyEntry(modelData.id)
                }
            }

            Text {
                anchors.centerIn: parent
                visible: popupPanel.filteredEntries.length === 0
                text: "Pano geçmişi boş"
                color: pywal.foreground || "#cdd6f4"
                opacity: 0.4
                font.pixelSize: 12
            }
        }
    }
}
