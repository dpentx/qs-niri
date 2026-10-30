import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell.Io
import "../../../services" as QsServices
import "../../../config" as QsConfig

// Inline Clipboard History Panel — lists cliphist entries, click to copy
FocusScope {
    id: popupPanel

    property bool shouldShow: false
    signal closeRequested()

    readonly property var pywal: QsServices.Pywal
    property var entries: []          // [{id, preview}]
    property string filterText: ""
    // Pinned texts (clipboard.pins in user.json) stay on top and survive a wipe.
    readonly property var pins: QsConfig.Config.data.clipboard?.pins ?? []
    readonly property var allEntries: pins.map(t => ({ id: "", preview: t.replace(/\s+/g, " "), pinned: true, text: t })).concat(entries)
    readonly property var filteredEntries: {
        if (!filterText) return allEntries
        const q = filterText.toLowerCase()
        return allEntries.filter(e => e.preview.toLowerCase().includes(q))
    }

    function unpin(t) { QsConfig.Config.set("clipboard.pins", pins.filter(x => x !== t)) }
    property string _pinning: ""
    Process {
        id: pinProc
        stdout: StdioCollector {
            onStreamFinished: {
                // shortcut: text entries only, a binary entry decodes to nothing and is skipped
                const t = text
                if (t.trim() && !popupPanel.pins.includes(t)) QsConfig.Config.set("clipboard.pins", [t, ...popupPanel.pins].slice(0, 20))
            }
        }
    }
    function pin(id) { pinProc.exec(["cliphist", "decode", String(id)]) }

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

    function copyEntry(e) {
        if (e.pinned) copyProc.exec(["wl-copy", "--", e.text])
        else copyProc.exec(["sh", "-c", `cliphist decode ${e.id} | wl-copy`])
        closeRequested()
    }

    Process {
        id: wipeProc
        command: ["cliphist", "wipe"]
        onExited: popupPanel.refresh()
    }

    // Background
    // OneUI panels are flat — no outline stroke (the always-on green
    // border here was a leftover default, unrelated to any real state)
    Rectangle {
        anchors.fill: parent
        radius: QsConfig.Appearance.radius.l
        color: pywal.popupSurface
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
                text: "Clipboard History"
                color: pywal.foreground
                font.family: "OneUI Sans"
                font.pixelSize: QsConfig.Appearance.fontSize.xl
                font.bold: true
                Layout.fillWidth: true
            }

            Text {
                text: "Clear"
                color: pywal.foreground
                opacity: clearHover.containsMouse ? 0.9 : 0.5
                font.pixelSize: QsConfig.Appearance.fontSize.s

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
            radius: QsConfig.Appearance.radius.s
            color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.06)
            border.width: 1
            border.color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.1)

            TextInput {
                id: searchField
                anchors.fill: parent
                anchors.margins: 8
                verticalAlignment: TextInput.AlignVCenter
                color: pywal.foreground
                font.pixelSize: QsConfig.Appearance.fontSize.m
                clip: true
                onTextChanged: popupPanel.filterText = text

                Text {
                    text: "Search..."
                    visible: searchField.text.length === 0
                    color: pywal.foreground
                    opacity: 0.4
                    font.pixelSize: QsConfig.Appearance.fontSize.m
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
                radius: QsConfig.Appearance.radius.m
                color: entryHover.containsMouse ? Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.08) : "transparent"

                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    anchors.fill: parent
                    anchors.margins: 10
                    anchors.rightMargin: 34
                    verticalAlignment: Text.AlignVCenter
                    text: modelData.preview
                    color: pywal.foreground
                    font.pixelSize: QsConfig.Appearance.fontSize.m
                    elide: Text.ElideRight
                }

                MouseArea {
                    id: entryHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: popupPanel.copyEntry(modelData)
                }

                // star: pin a history entry / unpin a pinned one
                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.pinned ? "★" : "☆"
                    color: modelData.pinned ? pywal.primary : pywal.foreground
                    opacity: modelData.pinned || entryHover.containsMouse || starArea.containsMouse ? 1 : 0
                    font.pixelSize: QsConfig.Appearance.fontSize.l
                    MouseArea {
                        id: starArea
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: modelData.pinned ? popupPanel.unpin(modelData.text) : popupPanel.pin(modelData.id)
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: popupPanel.filteredEntries.length === 0
                text: "Clipboard history is empty"
                color: pywal.foreground
                opacity: 0.4
                font.pixelSize: QsConfig.Appearance.fontSize.m
            }
        }
    }
}
