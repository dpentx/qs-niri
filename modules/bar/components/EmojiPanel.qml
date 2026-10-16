import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell.Io
import "../../../services" as QsServices
import "../../../config" as QsConfig
import "../../../components"
import "emojiData.js" as EmojiData

// Emoji picker: search, "recent" and one tab per category, like a phone keyboard.
// A click copies the emoji with wl-copy. Recents are kept in user.json.
FocusScope {
    id: popupPanel

    property bool shouldShow: false
    signal closeRequested()

    readonly property var pywal: QsServices.Pywal
    property string filterText: ""
    property int tab: 0   // 0 = recent, 1..8 = categories in emojiData order

    // Drop the file at assets/fonts/oneui8-emoji.ttf to use it. Glyphs it lacks, or all of
    // them when it is missing, fall back through fontconfig (Noto Color Emoji).
    FontLoader { id: oneuiEmoji; source: "../../../assets/fonts/oneui8-emoji.ttf" }
    readonly property string emojiFamily: oneuiEmoji.status === FontLoader.Ready ? oneuiEmoji.name : "Noto Color Emoji"

    readonly property var tabs: [
        { icon: "ic_clock_black_24dp" },
        { glyph: "😀" }, { glyph: "🐱" }, { glyph: "🍴" }, { glyph: "🏠" },
        { glyph: "⚽" }, { glyph: "💡" }, { glyph: "🔣" }, { glyph: "🏁" }
    ]

    readonly property var recent: QsConfig.Config.data.emoji?.recent ?? []

    readonly property var visibleEmojis: {
        const q = filterText.trim().toLowerCase()
        if (q) return EmojiData.all.filter(x => x[2].includes(q)).map(x => x[0])
        if (tab === 0) return recent
        return EmojiData.all.filter(x => x[1] === tab - 1).map(x => x[0])
    }

    implicitWidth: 380
    implicitHeight: 440
    focus: true

    Keys.onEscapePressed: closeRequested()

    onShouldShowChanged: {
        if (!shouldShow) return
        filterText = ""
        searchField.text = ""
        tab = recent.length > 0 ? 0 : 1
    }

    Process { id: copyProc }

    function copyEmoji(emoji) {
        copyProc.exec(["wl-copy", emoji])
        QsConfig.Config.set("emoji.recent", [emoji].concat(recent.filter(x => x !== emoji)).slice(0, 32))
        closeRequested()
    }

    Rectangle {
        anchors.fill: parent
        radius: QsConfig.Appearance.radius.l
        color: pywal.popupSurface
        opacity: 0.98
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            radius: height / 2
            color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.08)

            OneUIIcon {
                id: searchIcon
                name: "ic_search_24dp"
                size: 16
                color: pywal.foreground
                opacity: 0.6
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
            }

            TextInput {
                id: searchField
                anchors.left: searchIcon.right
                anchors.right: parent.right
                anchors.leftMargin: 8
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                focus: true
                color: pywal.foreground
                font.family: "OneUI Sans"
                font.pixelSize: QsConfig.Appearance.fontSize.m
                clip: true
                onTextChanged: popupPanel.filterText = text
                Keys.onReturnPressed: if (popupPanel.visibleEmojis.length > 0) popupPanel.copyEmoji(popupPanel.visibleEmojis[0])

                Text {
                    text: "Search (heart, cat, fire...)"
                    visible: searchField.text.length === 0
                    color: pywal.foreground
                    opacity: 0.4
                    font: searchField.font
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            Layout.maximumHeight: 34
            spacing: 0

            Repeater {
                model: popupPanel.tabs

                Item {
                    required property int index
                    required property var modelData
                    readonly property bool active: popupPanel.filterText === "" && popupPanel.tab === index

                    Layout.fillWidth: true
                    Layout.preferredHeight: 34

                    OneUIIcon {
                        visible: modelData.icon !== undefined
                        name: modelData.icon ?? ""
                        size: 18
                        color: pywal.foreground
                        anchors.centerIn: parent
                        opacity: parent.active ? 1 : 0.5
                    }
                    Text {
                        visible: modelData.glyph !== undefined
                        text: modelData.glyph ?? ""
                        font.family: popupPanel.emojiFamily
                        font.pixelSize: 18
                        anchors.centerIn: parent
                        opacity: parent.active ? 1 : 0.5
                    }
                    Rectangle {
                        height: 2
                        radius: 1
                        width: parent.width * 0.5
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        color: pywal.primary
                        visible: parent.active
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            searchField.text = ""
                            popupPanel.tab = index
                        }
                    }
                }
            }
        }

        GridView {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            cellWidth: Math.floor(width / 8)
            cellHeight: cellWidth
            model: popupPanel.visibleEmojis
            // Without this the grid keeps its scroll position when the tab changes.
            onModelChanged: positionViewAtBeginning()

            delegate: Item {
                required property string modelData
                width: grid.cellWidth
                height: grid.cellHeight

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: QsConfig.Appearance.radius.s
                    color: cellMouse.containsMouse ? Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.1) : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        font.family: popupPanel.emojiFamily
                        font.pixelSize: 24
                    }

                    MouseArea {
                        id: cellMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popupPanel.copyEmoji(modelData)
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: popupPanel.visibleEmojis.length === 0
                text: popupPanel.filterText ? "No results" : "No recent emoji"
                color: pywal.foreground
                opacity: 0.4
                font.family: "OneUI Sans"
                font.pixelSize: QsConfig.Appearance.fontSize.m
            }
        }
    }
}
