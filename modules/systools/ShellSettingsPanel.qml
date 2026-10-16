import QtQuick 6.10
import QtQuick.Layouts 6.10
import "../../services" as QsServices
import "../../config" as QsConfig
import "../../components"

// Shell settings: profile, feature switches, lock and gaming. Writes go to
// user.json through Config.set(), which wins over shell.json.
FocusScope {
    id: panel

    property bool shouldShow: false
    signal closeRequested()

    readonly property var pywal: QsServices.Pywal
    readonly property var cfg: QsConfig.Config

    readonly property var featureList: [
        { id: "gaming",       label: "Oyun modu" },
        { id: "recording",    label: "Ekran kaydı" },
        { id: "hotspot",      label: "Hotspot" },
        { id: "speedtest",    label: "Hız testi" },
        { id: "taskManager",  label: "Görev yöneticisi" },
        { id: "clipboard",    label: "Pano geçmişi" },
        { id: "lock",         label: "Kilit ekranı" },
        { id: "quickToggles", label: "Gece ışığı, uçak modu, VPN" },
        { id: "netSpeed",     label: "Barda ağ hızı" },
        { id: "taskbar",      label: "Açık pencere simgeleri" }
    ]

    function setWidgets(list) { cfg.set("bar.widgets", list) }

    function moveWidget(i, d) {
        const l = cfg.barWidgets.slice()
        const j = i + d
        if (j < 0 || j >= l.length) return
        const t = l[i]; l[i] = l[j]; l[j] = t
        setWidgets(l)
    }

    function widgetLabel(id) {
        const w = cfg.barAvailable.find(x => x.id === id)
        return w ? (w.label ?? w.id) : id
    }

    focus: true
    Keys.onEscapePressed: closeRequested()

    component Section: Text {
        Layout.topMargin: 6
        color: panel.pywal.primary
        font.family: "OneUI Sans"
        font.pixelSize: QsConfig.Appearance.fontSize.s
        font.bold: true
    }

    component SwitchRow: RowLayout {
        id: row
        property string label
        property bool value: false
        signal flipped(bool on)
        Layout.fillWidth: true
        Layout.preferredHeight: 34

        Text {
            text: row.label
            color: panel.pywal.foreground
            font.family: "OneUI Sans"
            font.pixelSize: QsConfig.Appearance.fontSize.m
            Layout.fillWidth: true
            elide: Text.ElideRight
        }
        SettingsSwitch {
            id: sw
            onToggled: on => row.flipped(on)
        }
        // SettingsSwitch flips itself on click; keep it following the real value.
        Binding { target: sw; property: "checked"; value: row.value }
    }

    component Chip: Rectangle {
        id: chip
        property string label
        property bool active: false
        signal clicked()
        Layout.fillWidth: true
        Layout.preferredHeight: 34
        radius: height / 2
        color: active ? panel.pywal.primary : panel.pywal.tileOff
        implicitWidth: chipText.implicitWidth + 28
        implicitHeight: 34
        Text {
            id: chipText
            anchors.centerIn: parent
            text: chip.label
            color: chip.active ? panel.pywal.onPrimary : panel.pywal.foreground
            font.family: "OneUI Sans"
            font.pixelSize: QsConfig.Appearance.fontSize.s
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: chip.clicked()
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: QsConfig.Appearance.radius.l
        color: panel.pywal.popupSurface
        opacity: 0.98
    }

    Flickable {
        anchors.fill: parent
        anchors.margins: 14
        contentHeight: col.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: col
            width: parent.width
            spacing: 4

            Text {
                text: "Shell"
                color: panel.pywal.foreground
                font.family: "OneUI Sans"
                font.pixelSize: QsConfig.Appearance.fontSize.xl
                font.bold: true
            }

            Section { text: "Profil" }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Repeater {
                    model: ["minimal", "base", "bloated"]
                    Chip {
                        required property string modelData
                        label: modelData
                        active: panel.cfg.profile === modelData
                        onClicked: {
                            // A new profile starts from its own defaults.
                            panel.cfg.set("features", {})
                            panel.cfg.set("profile", modelData)
                        }
                    }
                }
            }

            Section { text: "Bar widget'ları" }
            Repeater {
                model: panel.cfg.barWidgets
                RowLayout {
                    required property int index
                    required property string modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    spacing: 4
                    Text {
                        text: panel.widgetLabel(modelData)
                        color: panel.pywal.foreground
                        font.family: "OneUI Sans"
                        font.pixelSize: QsConfig.Appearance.fontSize.m
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    Chip { label: "↑"; Layout.fillWidth: false; Layout.preferredWidth: 34; onClicked: panel.moveWidget(index, -1) }
                    Chip { label: "↓"; Layout.fillWidth: false; Layout.preferredWidth: 34; onClicked: panel.moveWidget(index, 1) }
                    Chip {
                        label: "✕"; Layout.fillWidth: false; Layout.preferredWidth: 34
                        onClicked: panel.setWidgets(panel.cfg.barWidgets.filter((_, i) => i !== index))
                    }
                }
            }
            Flow {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: panel.cfg.barAvailable.filter(w => !panel.cfg.barWidgets.includes(w.id))
                    Chip {
                        required property var modelData
                        Layout.fillWidth: false
                        label: "+ " + (modelData.label ?? modelData.id)
                        onClicked: panel.setWidgets(panel.cfg.barWidgets.concat([modelData.id]))
                    }
                }
            }

            Section { text: "Özellikler" }
            Repeater {
                model: panel.featureList
                SwitchRow {
                    required property var modelData
                    label: modelData.label
                    value: panel.cfg.features[modelData.id]
                    onFlipped: on => panel.cfg.set("features." + modelData.id, on)
                }
            }

            Section { text: "Kilit ekranı" }
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                Text {
                    text: "Boşta kilitle"
                    color: panel.pywal.foreground
                    font.family: "OneUI Sans"
                    font.pixelSize: QsConfig.Appearance.fontSize.m
                    Layout.fillWidth: true
                }
                Chip {
                    label: "−"
                    Layout.fillWidth: false
                    Layout.preferredWidth: 34
                    onClicked: panel.cfg.set("lock.idleMinutes", Math.max(0, panel.cfg.lock.idleMinutes - 1))
                }
                Text {
                    text: panel.cfg.lock.idleMinutes > 0 ? panel.cfg.lock.idleMinutes + " dk" : "Kapalı"
                    color: panel.pywal.foreground
                    font.family: "OneUI Sans"
                    font.pixelSize: QsConfig.Appearance.fontSize.m
                    horizontalAlignment: Text.AlignHCenter
                    Layout.preferredWidth: 56
                }
                Chip {
                    label: "+"
                    Layout.fillWidth: false
                    Layout.preferredWidth: 34
                    onClicked: panel.cfg.set("lock.idleMinutes", panel.cfg.lock.idleMinutes + 1)
                }
            }

            Section { text: "Oyun modu" }
            SwitchRow {
                label: "Oyunu otomatik algıla"
                value: panel.cfg.gaming.autoDetect
                onFlipped: on => panel.cfg.set("gaming.autoDetect", on)
            }
            SwitchRow {
                label: "Oyun sırasında Rahatsız Etme"
                value: panel.cfg.gaming.dnd
                onFlipped: on => panel.cfg.set("gaming.dnd", on)
            }

            Chip {
                Layout.topMargin: 12
                label: "Varsayılanlara dön"
                onClicked: panel.cfg.resetUser()
            }

            Text {
                Layout.fillWidth: true
                Layout.topMargin: 6
                wrapMode: Text.WordWrap
                text: "Değişiklikler ~/.config/quickshell-local/user.json dosyasına yazılır ve shell.json'un üstüne biner."
                color: panel.pywal.onSurfaceMuted
                font.family: "OneUI Sans"
                font.pixelSize: QsConfig.Appearance.fontSize.xs
            }
        }
    }
}
