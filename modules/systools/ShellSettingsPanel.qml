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
    property string page: "profile"   // profile | bar | features | theme | lock | gaming | about
    signal closeRequested()

    readonly property var pywal: QsServices.Pywal
    readonly property var cfg: QsConfig.Config

    readonly property var featureList: [
        { id: "gaming",       label: "Gaming mode" },
        { id: "recording",    label: "Screen recording" },
        { id: "hotspot",      label: "Hotspot" },
        { id: "speedtest",    label: "Speed test" },
        { id: "taskManager",  label: "Task manager" },
        { id: "clipboard",    label: "Clipboard history" },
        { id: "lock",         label: "Lock screen" },
        { id: "files",        label: "File manager" },
        { id: "quickToggles", label: "Night Light, Airplane mode, VPN" },
        { id: "netSpeed",     label: "Network speed in the bar" },
        { id: "taskbar",      label: "Open window icons" }
    ]

    readonly property var pageTitles: ({
        profile: "Profile", bar: "Bar widgets", features: "Features",
        theme: "Theme", lock: "Lock screen", gaming: "Gaming mode", about: "About"
    })

    readonly property var schemes: [
        { id: "scheme-tonal-spot",  label: "Tonal spot" },
        { id: "scheme-content",     label: "Content" },
        { id: "scheme-expressive",  label: "Expressive" },
        { id: "scheme-fidelity",    label: "Fidelity" },
        { id: "scheme-fruit-salad", label: "Fruit salad" },
        { id: "scheme-rainbow",     label: "Rainbow" },
        { id: "scheme-neutral",     label: "Neutral" },
        { id: "scheme-monochrome",  label: "Monochrome" }
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
        visible: false
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
                text: panel.pageTitles[panel.page] ?? "Shell"
                color: panel.pywal.foreground
                font.family: "OneUI Sans"
                font.pixelSize: QsConfig.Appearance.fontSize.xl
                font.bold: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                visible: panel.page === "profile"

            Section { text: "Profile" }
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
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                visible: panel.page === "bar"

            Section { text: "Bar widgets" }
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
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                visible: panel.page === "features"

            Section { text: "Features" }
            Repeater {
                model: panel.featureList
                SwitchRow {
                    required property var modelData
                    label: modelData.label
                    value: panel.cfg.features[modelData.id]
                    onFlipped: on => panel.cfg.set("features." + modelData.id, on)
                }
            }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                visible: panel.page === "lock"

            Section { text: "Lock screen" }
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                Text {
                    text: "Lock when idle"
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
                    text: panel.cfg.lock.idleMinutes > 0 ? panel.cfg.lock.idleMinutes + " min" : "Off"
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
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                visible: panel.page === "gaming"

            Section { text: "Gaming mode" }
            SwitchRow {
                label: "Detect games automatically"
                value: panel.cfg.gaming.autoDetect
                onFlipped: on => panel.cfg.set("gaming.autoDetect", on)
            }
            SwitchRow {
                label: "Do Not Disturb while gaming"
                value: panel.cfg.gaming.dnd
                onFlipped: on => panel.cfg.set("gaming.dnd", on)
            }
            SwitchRow {
                label: "Keep the screen awake while gaming"
                value: panel.cfg.gaming.inhibitIdle
                onFlipped: on => panel.cfg.set("gaming.inhibitIdle", on)
            }
            SwitchRow {
                label: "Boost brightness while gaming"
                value: panel.cfg.gaming.boostBrightness
                onFlipped: on => panel.cfg.set("gaming.boostBrightness", on)
            }

            Text {
                Layout.topMargin: 6
                text: "Extra game app IDs (regex, matched against the window's app_id)"
                color: panel.pywal.onSurfaceMuted
                font.family: "OneUI Sans"
                font.pixelSize: QsConfig.Appearance.fontSize.s
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
            Flow {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: panel.cfg.gaming.appIds
                    Chip {
                        required property string modelData
                        Layout.fillWidth: false
                        label: modelData + "  ✕"
                        onClicked: panel.cfg.set("gaming.appIds", panel.cfg.gaming.appIds.filter(a => a !== modelData))
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    radius: 17
                    color: panel.pywal.tileOff
                    TextInput {
                        id: appIdInput
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        verticalAlignment: TextInput.AlignVCenter
                        clip: true
                        color: panel.pywal.foreground
                        font.family: "OneUI Sans"
                        font.pixelSize: QsConfig.Appearance.fontSize.m
                        onAccepted: addAppId.clicked()
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !appIdInput.text.length
                            text: "e.g. ^minecraft"
                            color: panel.pywal.onSurfaceMuted
                            font: appIdInput.font
                        }
                    }
                }
                Chip {
                    id: addAppId
                    label: "Add"
                    Layout.fillWidth: false
                    Layout.preferredWidth: 64
                    onClicked: {
                        const v = appIdInput.text.trim()
                        if (!v.length || panel.cfg.gaming.appIds.includes(v)) return
                        panel.cfg.set("gaming.appIds", panel.cfg.gaming.appIds.concat([v]))
                        appIdInput.text = ""
                    }
                }
            }
            }

            ColumnLayout {
                id: kbPage
                Layout.fillWidth: true
                spacing: 6
                visible: panel.page === "keyboard"

                property var kbLayoutIn
                property var kbVariantIn
                readonly property var layouts: panel.cfg.keyboard.layouts
                readonly property var common: ["us", "gb", "tr", "de", "fr", "es", "it", "ru", "ua", "pl", "pt", "br", "jp", "kr"]
                function save(list) {
                    panel.cfg.set("keyboard.layouts", list)
                    QsServices.KeyboardLayout.write(list)
                }
                function add(layout, variant) {
                    if (!/^[a-z0-9_]+$/.test(layout) || !/^[a-z0-9_]*$/.test(variant)) return
                    if (layouts.some(x => x.layout === layout && (x.variant ?? "") === variant)) return
                    save(layouts.concat([{ layout: layout, variant: variant }]))
                }
                function move(i, d) {
                    const l = layouts.slice()
                    const j = i + d
                    if (j < 0 || j >= l.length) return
                    const t = l[i]; l[i] = l[j]; l[j] = t
                    save(l)
                }

                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: "niri only reads keyboard layouts from its config. The list below is written to ~/.config/niri/qs-keyboard.kdl; add this line to your niri config once (remove your own xkb layout line), and niri reloads it by itself:"
                    color: panel.pywal.onSurfaceMuted
                    font.family: "OneUI Sans"
                    font.pixelSize: QsConfig.Appearance.fontSize.s
                }
                Text {
                    Layout.fillWidth: true
                    text: 'include "qs-keyboard.kdl"'
                    color: panel.pywal.foreground
                    font.family: "monospace"
                    font.pixelSize: QsConfig.Appearance.fontSize.m
                    textFormat: Text.PlainText
                }
                Text {
                    Layout.fillWidth: true
                    visible: QsServices.KeyboardLayout.names.length > 0
                    wrapMode: Text.WordWrap
                    text: "niri is using now: " + QsServices.KeyboardLayout.names.join(", ")
                    color: panel.pywal.onSurfaceMuted
                    font.family: "OneUI Sans"
                    font.pixelSize: QsConfig.Appearance.fontSize.xs
                }

                Text {
                    Layout.topMargin: 6
                    text: "Layouts (the first one is the default)"
                    color: panel.pywal.primary
                    font.family: "OneUI Sans"
                    font.pixelSize: QsConfig.Appearance.fontSize.s
                    font.bold: true
                }
                Repeater {
                    model: kbPage.layouts
                    RowLayout {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        spacing: 6
                        Text {
                            Layout.fillWidth: true
                            text: modelData.layout + (modelData.variant ? "  (" + modelData.variant + ")" : "")
                            color: panel.pywal.foreground
                            font.family: "OneUI Sans"
                            font.pixelSize: QsConfig.Appearance.fontSize.m
                        }
                        Chip { Layout.fillWidth: false; Layout.preferredWidth: 40; label: "↑"; visible: index > 0; onClicked: kbPage.move(index, -1) }
                        Chip { Layout.fillWidth: false; Layout.preferredWidth: 40; label: "↓"; visible: index < kbPage.layouts.length - 1; onClicked: kbPage.move(index, 1) }
                        Chip {
                            Layout.fillWidth: false
                            Layout.preferredWidth: 40
                            label: "✕"
                            visible: kbPage.layouts.length > 1
                            onClicked: kbPage.save(kbPage.layouts.filter((x, i) => i !== index))
                        }
                    }
                }
                Text {
                    visible: kbPage.layouts.length === 0
                    text: "Nothing yet. Pick layouts below."
                    color: panel.pywal.onSurfaceMuted
                    font.family: "OneUI Sans"
                    font.pixelSize: QsConfig.Appearance.fontSize.s
                }

                Text {
                    Layout.topMargin: 6
                    text: "Add"
                    color: panel.pywal.primary
                    font.family: "OneUI Sans"
                    font.pixelSize: QsConfig.Appearance.fontSize.s
                    font.bold: true
                }
                Flow {
                    Layout.fillWidth: true
                    spacing: 6
                    Repeater {
                        model: kbPage.common
                        Chip {
                            required property string modelData
                            Layout.fillWidth: false
                            label: modelData
                            onClicked: kbPage.add(modelData, "")
                        }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Repeater {
                        model: [{ id: "kbLayoutIn", hint: "layout, e.g. tr" }, { id: "kbVariantIn", hint: "variant, e.g. intl (optional)" }]
                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 34
                            radius: 17
                            color: panel.pywal.tileOff
                            TextInput {
                                id: field
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14
                                verticalAlignment: TextInput.AlignVCenter
                                clip: true
                                color: panel.pywal.foreground
                                font.family: "OneUI Sans"
                                font.pixelSize: QsConfig.Appearance.fontSize.m
                                Component.onCompleted: kbPage[modelData.id] = field
                                onAccepted: kbAdd.clicked()
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: !field.text.length
                                    text: parent.parent.modelData.hint
                                    color: panel.pywal.onSurfaceMuted
                                    font: field.font
                                }
                            }
                        }
                    }
                    Chip {
                        id: kbAdd
                        label: "Add"
                        Layout.fillWidth: false
                        Layout.preferredWidth: 64
                        onClicked: {
                            const lay = kbPage.kbLayoutIn, v = kbPage.kbVariantIn
                            if (!lay) return
                            kbPage.add(lay.text.trim().toLowerCase(), v.text.trim().toLowerCase())
                            lay.text = ""; v.text = ""
                        }
                    }
                }
                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: "Names are xkb ids (tr, us, de ...; list: localectl list-x11-keymap-layouts). Switch layouts with a niri keybind (switch-layout) or by clicking the bar pill."
                    color: panel.pywal.onSurfaceMuted
                    font.family: "OneUI Sans"
                    font.pixelSize: QsConfig.Appearance.fontSize.xs
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                visible: panel.page === "about"

                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: "A Samsung One UI 8 style desktop shell for niri, written in QML on top of Quickshell."
                    color: panel.pywal.onSurfaceMuted
                    font.family: "OneUI Sans"
                    font.pixelSize: QsConfig.Appearance.fontSize.s
                }

                Repeater {
                    model: [
                        { k: "Version",      v: QsServices.Diagnostics.version },
                        { k: "Quickshell",   v: QsServices.Diagnostics.qsVersion || "unknown" },
                        { k: "Shell folder", v: QsServices.Diagnostics.scrub(QsServices.Diagnostics.shellPath) },
                        { k: "shell.json",   v: "~/.config/quickshell/shell.json" },
                        { k: "user.json",    v: "~/.config/quickshell-local/user.json" },
                        { k: "License",      v: "MIT" }
                    ]
                    RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 10
                        Text {
                            Layout.preferredWidth: 96
                            text: modelData.k
                            color: panel.pywal.onSurfaceMuted
                            font.family: "OneUI Sans"
                            font.pixelSize: QsConfig.Appearance.fontSize.s
                        }
                        Text {
                            Layout.fillWidth: true
                            text: modelData.v
                            elide: Text.ElideMiddle
                            color: panel.pywal.foreground
                            font.family: "OneUI Sans"
                            font.pixelSize: QsConfig.Appearance.fontSize.m
                        }
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    spacing: 6
                    Chip { label: "GitHub"; Layout.fillWidth: false; onClicked: QsServices.Diagnostics.openUrl("https://github.com/" + QsServices.Diagnostics.repo) }
                    Chip { label: "Report an issue"; Layout.fillWidth: false; onClicked: QsServices.Diagnostics.openUrl("https://github.com/" + QsServices.Diagnostics.repo + "/issues/new") }
                    Chip { label: "Copy version info"; Layout.fillWidth: false; onClicked: QsServices.Diagnostics.copyInfo() }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: 10
                    wrapMode: Text.WordWrap
                    text: "Fork of tripathiji1312/quickshell (MIT), reworked for niri. One UI is a Samsung design language; this is an independent project and is not affiliated with Samsung."
                    color: panel.pywal.onSurfaceMuted
                    font.family: "OneUI Sans"
                    font.pixelSize: QsConfig.Appearance.fontSize.xs
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: panel.page === "theme"

                Text {
                    text: "Mode"
                    color: panel.pywal.onSurfaceMuted
                    font.family: "OneUI Sans"
                    font.pixelSize: QsConfig.Appearance.fontSize.s
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Repeater {
                        model: ["dark", "light", "smart"]
                        Chip {
                            required property string modelData
                            label: modelData
                            active: panel.cfg.theme.mode === modelData
                            onClicked: panel.cfg.set("theme.mode", modelData)
                        }
                    }
                }

                Text {
                    Layout.topMargin: 6
                    text: "Palette style"
                    color: panel.pywal.onSurfaceMuted
                    font.family: "OneUI Sans"
                    font.pixelSize: QsConfig.Appearance.fontSize.s
                }
                Flow {
                    Layout.fillWidth: true
                    spacing: 6
                    Repeater {
                        model: panel.schemes
                        Chip {
                            required property var modelData
                            Layout.fillWidth: false
                            label: modelData.label
                            active: panel.cfg.theme.scheme === modelData.id
                            onClicked: panel.cfg.set("theme.scheme", modelData.id)
                        }
                    }
                }

                Text {
                    Layout.topMargin: 6
                    text: "Current palette"
                    color: panel.pywal.onSurfaceMuted
                    font.family: "OneUI Sans"
                    font.pixelSize: QsConfig.Appearance.fontSize.s
                }
                Row {
                    spacing: 8
                    Repeater {
                        model: [panel.pywal.primary, panel.pywal.secondary, panel.pywal.tertiary,
                                panel.pywal.error, panel.pywal.surfaceContainerHighest]
                        Rectangle {
                            required property color modelData
                            width: 34; height: 34; radius: 17
                            color: modelData
                            border.width: 1
                            border.color: panel.pywal.outlineVariant
                        }
                    }
                }

                Text {
                    Layout.topMargin: 6
                    text: "Source"
                    color: panel.pywal.onSurfaceMuted
                    font.family: "OneUI Sans"
                    font.pixelSize: QsConfig.Appearance.fontSize.s
                }
                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WrapAnywhere
                    text: panel.pywal.wallpaper !== "" ? panel.pywal.wallpaper
                          : "No wallpaper themed yet. Pick one in the Wallpaper tab."
                    color: panel.pywal.foreground
                    font.family: "OneUI Sans"
                    font.pixelSize: QsConfig.Appearance.fontSize.s
                }
                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WrapAnywhere
                    visible: panel.cfg.theme.image !== ""
                    text: "Pinned at start-up: " + panel.cfg.theme.image
                    color: panel.pywal.onSurfaceMuted
                    font.family: "OneUI Sans"
                    font.pixelSize: QsConfig.Appearance.fontSize.xs
                }
                Flow {
                    Layout.fillWidth: true
                    spacing: 6
                    Chip {
                        Layout.fillWidth: false
                        label: "Regenerate"
                        onClicked: panel.pywal.generate(panel.pywal.wallpaper)
                    }
                    Chip {
                        Layout.fillWidth: false
                        label: "Pin as start-up image"
                        onClicked: if (panel.pywal.wallpaper !== "") panel.cfg.set("theme.image", panel.pywal.wallpaper)
                    }
                    Chip {
                        Layout.fillWidth: false
                        label: "Unpin"
                        visible: panel.cfg.theme.image !== ""
                        onClicked: panel.cfg.set("theme.image", "")
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    wrapMode: Text.WordWrap
                    text: "Needs matugen. It also runs the templates in ~/.config/matugen/config.toml."
                    color: panel.pywal.onSurfaceMuted
                    font.family: "OneUI Sans"
                    font.pixelSize: QsConfig.Appearance.fontSize.xs
                }
            }

            Chip {
                visible: panel.page === "profile"
                Layout.topMargin: 12
                label: "Reset to defaults"
                onClicked: panel.cfg.resetUser()
            }

            Text {
                Layout.fillWidth: true
                Layout.topMargin: 6
                wrapMode: Text.WordWrap
                text: "Changes are saved to ~/.config/quickshell-local/user.json and layered over shell.json."
                color: panel.pywal.onSurfaceMuted
                font.family: "OneUI Sans"
                font.pixelSize: QsConfig.Appearance.fontSize.xs
            }
        }
    }
}
