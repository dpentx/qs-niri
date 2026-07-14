import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell.Io
import "../../../services" as QsServices

// Inline Emoji Picker Panel — searchable grid, click copies via wl-copy
FocusScope {
    id: popupPanel

    property bool shouldShow: false
    signal closeRequested()

    readonly property var pywal: QsServices.Pywal
    property string filterText: ""

    // {e: emoji, k: space-separated keywords}
    readonly property var allEmojis: [
        {e:"😀",k:"gülen yüz mutlu happy smile"}, {e:"😂",k:"gülme ağlama laugh joy"},
        {e:"🥹",k:"duygusal touched"}, {e:"😍",k:"aşık sevgi love heart eyes"},
        {e:"😘",k:"öpücük kiss"}, {e:"😉",k:"göz kırpma wink"},
        {e:"😎",k:"güneş gözlüğü cool sunglasses"}, {e:"🤔",k:"düşünme thinking"},
        {e:"😅",k:"terli gülümseme sweat smile"}, {e:"😭",k:"ağlama cry sad"},
        {e:"😢",k:"üzgün sad tear"}, {e:"😡",k:"kızgın angry mad"},
        {e:"😱",k:"şok scream shock"}, {e:"🥳",k:"parti kutlama party celebrate"},
        {e:"😴",k:"uyku sleep tired"}, {e:"🤯",k:"patlayan kafa mind blown"},
        {e:"🙄",k:"göz devirme eyeroll"}, {e:"😬",k:"gergin grimace awkward"},
        {e:"🤗",k:"sarılma hug"}, {e:"🥰",k:"sevgi dolu adoring love"},
        {e:"😏",k:"kurnaz smirk"}, {e:"🤤",k:"salya drool"},
        {e:"🤡",k:"palyaço clown"}, {e:"👻",k:"hayalet ghost"},
        {e:"💀",k:"kafatası skull dead"}, {e:"🔥",k:"ateş fire hot lit"},
        {e:"✨",k:"parıltı sparkle magic"}, {e:"💯",k:"yüz hundred perfect"},
        {e:"🎉",k:"kutlama parti confetti party"}, {e:"🎂",k:"doğum günü pasta cake birthday"},
        {e:"❤️",k:"kalp kırmızı heart love"}, {e:"🧡",k:"kalp turuncu heart orange"},
        {e:"💛",k:"kalp sarı heart yellow"}, {e:"💚",k:"kalp yeşil heart green"},
        {e:"💙",k:"kalp mavi heart blue"}, {e:"💜",k:"kalp mor heart purple"},
        {e:"🖤",k:"kalp siyah heart black"}, {e:"💔",k:"kırık kalp broken heart"},
        {e:"💕",k:"kalpler hearts love"}, {e:"👍",k:"beğeni tamam like thumbs up ok"},
        {e:"👎",k:"beğenmeme dislike thumbs down"}, {e:"👌",k:"tamam ok"},
        {e:"✌️",k:"barış peace victory"}, {e:"🤞",k:"parmak çaprazlama fingers crossed luck"},
        {e:"👏",k:"alkış clap applause"}, {e:"🙏",k:"dua ricam please thanks pray"},
        {e:"💪",k:"güçlü kas strong muscle"}, {e:"👋",k:"el sallama wave hi bye"},
        {e:"🤝",k:"el sıkışma handshake deal"}, {e:"🖕",k:"orta parmak middle finger"},
        {e:"👀",k:"gözler eyes looking"}, {e:"🧠",k:"beyin brain smart"},
        {e:"🦴",k:"kemik bone dog"}, {e:"🐱",k:"kedi cat"},
        {e:"🐶",k:"köpek dog"}, {e:"🐼",k:"panda"},
        {e:"🦊",k:"tilki fox"}, {e:"🐸",k:"kurbağa frog"},
        {e:"🐧",k:"penguen penguin linux"}, {e:"🦉",k:"baykuş owl"},
        {e:"🐢",k:"kaplumbağa turtle slow"}, {e:"🦄",k:"unicorn"},
        {e:"🍕",k:"pizza"}, {e:"🍔",k:"burger hamburger"},
        {e:"☕",k:"kahve coffee"}, {e:"🍺",k:"bira beer"},
        {e:"🍻",k:"kadeh tokuşturma cheers beer"}, {e:"🍰",k:"pasta cake"},
        {e:"🍿",k:"patlamış mısır popcorn movie"}, {e:"🍎",k:"elma apple"},
        {e:"🚀",k:"roket rocket launch fast"}, {e:"💻",k:"bilgisayar laptop computer code"},
        {e:"⌨️",k:"klavye keyboard"}, {e:"🖥️",k:"masaüstü desktop monitor"},
        {e:"📱",k:"telefon phone mobile"}, {e:"🐧",k:"linux tux penguin"},
        {e:"🐛",k:"böcek bug hata"}, {e:"⚙️",k:"ayar gear settings config"},
        {e:"🔧",k:"anahtar tool wrench fix"}, {e:"🔨",k:"çekiç hammer build"},
        {e:"📦",k:"paket kutu package box"}, {e:"🗂️",k:"klasör folder files"},
        {e:"💾",k:"disket save floppy disk"}, {e:"🔒",k:"kilit lock secure"},
        {e:"🔓",k:"açık kilit unlock"}, {e:"🔑",k:"anahtar key"},
        {e:"⚡",k:"şimşek yıldırım lightning fast power"}, {e:"🎮",k:"oyun kolu gamepad gaming"},
        {e:"🎵",k:"nota müzik music note"}, {e:"🎧",k:"kulaklık headphones"},
        {e:"📷",k:"kamera camera photo"}, {e:"🎬",k:"film clapper movie"},
        {e:"📺",k:"tv televizyon"}, {e:"🌙",k:"ay moon night"},
        {e:"☀️",k:"güneş sun day"}, {e:"⭐",k:"yıldız star"},
        {e:"🌈",k:"gökkuşağı rainbow"}, {e:"☁️",k:"bulut cloud"},
        {e:"⛅",k:"parçalı bulutlu partly cloudy"}, {e:"❄️",k:"kar tanesi snowflake snow"},
        {e:"✅",k:"onay tamam check done ok"}, {e:"❌",k:"çarpı hata cross no wrong"},
        {e:"⚠️",k:"uyarı warning alert"}, {e:"❓",k:"soru question mark"},
        {e:"❗",k:"ünlem exclamation important"}, {e:"➡️",k:"sağ ok arrow right"},
        {e:"⬅️",k:"sol ok arrow left"}, {e:"⬆️",k:"yukarı ok arrow up"},
        {e:"⬇️",k:"aşağı ok arrow down"}, {e:"🔁",k:"tekrar repeat loop"},
        {e:"🔀",k:"karıştır shuffle"}, {e:"⏯️",k:"oynat duraklat play pause"},
        {e:"⏭️",k:"sonraki next skip"}, {e:"⏮️",k:"önceki previous"},
        {e:"🕐",k:"saat clock time"}, {e:"📅",k:"takvim calendar date"},
        {e:"📌",k:"pin sabitle pinned"}, {e:"📎",k:"ataç clip attachment"},
        {e:"🔗",k:"link bağlantı chain"}, {e:"🏠",k:"ev home house"},
        {e:"🇹🇷",k:"türkiye turkey flag bayrak"}, {e:"🇯🇵",k:"japonya japan flag bayrak"},
    ]

    readonly property var filteredEmojis: {
        if (!filterText) return allEmojis
        const q = filterText.toLowerCase()
        return allEmojis.filter(x => x.k.includes(q))
    }

    implicitWidth: 320
    implicitHeight: 380
    focus: true

    Keys.onEscapePressed: closeRequested()

    onShouldShowChanged: {
        if (shouldShow) {
            filterText = ""
            searchField.text = ""
        }
    }

    Process {
        id: copyProc
    }

    function copyEmoji(emoji) {
        copyProc.exec(["wl-copy", emoji])
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

        Text {
            text: "Emoji Seçici"
            color: pywal.foreground || "#cdd6f4"
            font.family: "Inter"
            font.pixelSize: 14
            font.bold: true
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
                    text: "Ara... (örn. kalp, kedi, ateş)"
                    visible: searchField.text.length === 0
                    color: pywal.foreground || "#cdd6f4"
                    opacity: 0.4
                    font.pixelSize: 12
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        GridView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            cellWidth: width / 7
            cellHeight: cellWidth
            model: popupPanel.filteredEmojis

            delegate: Item {
                width: GridView.view.cellWidth
                height: GridView.view.cellHeight

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: 8
                    color: emojiHover.containsMouse ? Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.1) : "transparent"

                    Behavior on color { ColorAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        text: modelData.e
                        font.pixelSize: 22
                    }

                    MouseArea {
                        id: emojiHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popupPanel.copyEmoji(modelData.e)
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: popupPanel.filteredEmojis.length === 0
                text: "Sonuç yok"
                color: pywal.foreground || "#cdd6f4"
                opacity: 0.4
                font.pixelSize: 12
            }
        }
    }
}
