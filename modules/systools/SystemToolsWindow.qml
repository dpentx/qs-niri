import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../config" as QsConfig
import "../../services" as QsServices
import "../../components"

PanelWindow {
    id: root

    property bool shouldShow: false
    property string selectedTab: "network"  // network | bluetooth | wallpaper | clipboard | emoji

    readonly property var config: QsConfig.Config
    readonly property var pywal: QsServices.Pywal
    readonly property color cSurface: pywal.surfaceContainerHighest
    readonly property color cSurfaceContainer: pywal.surfaceContainerHigh
    readonly property color cPrimary: pywal.primary
    readonly property color cText: pywal.foreground
    readonly property color cSubText: pywal.onSurfaceMuted
    readonly property color cBorder: pywal.outlineVariant

    readonly property var tabs: [
        { id: "network",   glyph: "󰖩", label: "Ağ" },
        { id: "bluetooth", glyph: "󰂯", label: "Bluetooth" },
        { id: "wallpaper", glyph: "󰸉", label: "Duvar Kağıdı" },
        { id: "clipboard", glyph: "󰅍", label: "Pano" },
        { id: "emoji",     glyph: "󰱨", label: "Emoji" },
        { id: "recordings", glyph: "󰑋", label: "Kayıtlar" }
    ]
    readonly property int selectedTabIndex: tabs.findIndex(t => t.id === selectedTab)

    function closeTools() {
        shouldShow = false
    }

    function openTools() {
        shouldShow = true
        selectedTab = "network"
    }

    Process {
        id: localsendProc
        command: ["localsend"]
    }

    screen: Quickshell.screens[0]
    anchors {
        top: true
        left: true
    }
    margins {
        top: (config.bar.height ?? 34) + 22
        left: Math.max(0, Math.round((screen.width - root.implicitWidth) / 2))
    }
    implicitWidth: 620
    implicitHeight: shouldShow || panel.opacity > 0 ? 460 : 0
    color: "transparent"
    visible: shouldShow || panel.opacity > 0

    WlrLayershell.keyboardFocus: shouldShow ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    FocusScope {
        id: panel
        anchors.fill: parent
        property real revealOffset: shouldShow ? 0 : -20
        scale: shouldShow ? 1.0 : 0.97
        opacity: shouldShow ? 1.0 : 0.0
        focus: root.shouldShow
        transform: Translate { y: panel.revealOffset }

        Keys.onEscapePressed: root.closeTools()

        Behavior on scale { NumberAnimation { duration: 240; easing.bezierCurve: [0.22, 1.0, 0.36, 1.0] } }
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
        Behavior on revealOffset { NumberAnimation { duration: 260; easing.bezierCurve: [0.05, 0.7, 0.1, 1.0] } }

        AuroraSurface {
            anchors.fill: parent
            radius: 20
            color: root.cSurface
            borderWidth: 0
            accentColor: root.cPrimary
            elevation: 1
            highlighted: false

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                // Top-right icon row — matches the small icon toolbar
                // (edit/power/settings/profile) sitting above the toggle
                // grid in the real OneUI tablet quick panel. No title text
                // here since the sidebar breadcrumb below already labels
                // the panel; keeping this row icon-only avoids duplicating it.
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Item { Layout.fillWidth: true }

                    component TopIconButton: Rectangle {
                        id: topBtn
                        property string icon: ""
                        property color tintColor: root.cText
                        signal clicked()

                        width: 32
                        height: 32
                        radius: 16
                        color: topBtnMouse.containsMouse
                            ? Qt.rgba(topBtn.tintColor.r, topBtn.tintColor.g, topBtn.tintColor.b, 0.14)
                            : "transparent"

                        Behavior on color { ColorAnimation { duration: 120 } }

                        scale: topBtnMouse.pressed ? 0.9 : 1.0
                        Behavior on scale { NumberAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: topBtn.icon
                            font.family: "Material Design Icons"
                            font.pixelSize: 15
                            color: topBtn.tintColor
                        }

                        MouseArea {
                            id: topBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: topBtn.clicked()
                        }
                    }

                    TopIconButton {
                        icon: "󰐥"
                        tintColor: "#ff453a"
                        onClicked: {
                            root.closeTools()
                            QsServices.UIState.powerMenuOpen = true
                        }
                    }

                    TopIconButton {
                        icon: "󰅖"
                        onClicked: root.closeTools()
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 14

                // Left tab rail — width is intentionally hard-locked
                // (min == max == preferred) rather than left as just a
                // preferred-width hint, since a wide implicit size from
                // whatever panel is loaded on the right (e.g. the
                // wallpaper grid) was pushing this column wider than its
                // content and swallowing the right pane.
                ColumnLayout {
                    Layout.preferredWidth: 168
                    Layout.minimumWidth: 168
                    Layout.maximumWidth: 168
                    Layout.fillHeight: true
                    spacing: 6

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Layout.bottomMargin: 6
                        Layout.leftMargin: 4

                        // Breadcrumb — frames this panel as a page inside
                        // the OneUI/DeX "Ayarlar" app rather than a
                        // standalone floating tool palette.
                        Text {
                            text: "Ayarlar"
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: root.cSubText
                        }
                        Text {
                            text: "Shell"
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: 15
                            font.weight: Font.Bold
                            color: root.cText
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: tabsColumn.implicitHeight

                        // Sliding active-tab indicator
                        Rectangle {
                            width: 3
                            radius: 1.5
                            height: 24
                            x: 0
                            y: Math.max(0, root.selectedTabIndex) * 50 + 10
                            color: root.cPrimary
                            visible: root.selectedTabIndex >= 0

                            Behavior on y {
                                NumberAnimation { duration: 220; easing.bezierCurve: [0.22, 1.0, 0.36, 1.0] }
                            }
                        }

                        Column {
                            id: tabsColumn
                            width: parent.width
                            spacing: 6

                            Repeater {
                                model: root.tabs

                                Rectangle {
                                    required property var modelData
                                    width: tabsColumn.width
                                    height: 44
                                    radius: 14
                                    color: root.selectedTab === modelData.id
                                        ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.18)
                                        : tabHover.containsMouse ? root.cSurfaceContainer : "transparent"

                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 10
                                        spacing: 10

                                        // Icon badge — same 40dp circular
                                        // convention as SettingsRow, so this
                                        // reads as a settings-app page list
                                        // rather than a tool palette.
                                        Rectangle {
                                            Layout.preferredWidth: 32
                                            Layout.preferredHeight: 32
                                            radius: 16
                                            color: root.selectedTab === modelData.id
                                                ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.22)
                                                : Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.08)

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.glyph
                                                font.family: "Material Design Icons"
                                                font.pixelSize: 15
                                                color: root.selectedTab === modelData.id ? root.cPrimary : root.cText

                                                Behavior on color { ColorAnimation { duration: 150 } }
                                            }
                                        }

                                        Text {
                                            text: modelData.label
                                            font.family: QsConfig.Config.appearance.fontFamily
                                            font.pixelSize: 12
                                            font.weight: root.selectedTab === modelData.id ? Font.DemiBold : Font.Normal
                                            color: root.selectedTab === modelData.id ? root.cText : root.cSubText
                                            Layout.fillWidth: true

                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }
                                    }

                                    MouseArea {
                                        id: tabHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.selectedTab = modelData.id
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // LocalSend — quick-launch, not a hosted panel (no reliable CLI to embed)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        radius: 12
                        color: localsendHover.containsMouse ? root.cSurfaceContainer : "transparent"

                        Behavior on color { ColorAnimation { duration: 120 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10

                            Text {
                                text: "󰒺"
                                font.family: "Material Design Icons"
                                font.pixelSize: 16
                                color: root.cText
                            }

                            Text {
                                text: "LocalSend"
                                font.family: QsConfig.Config.appearance.fontFamily
                                font.pixelSize: 12
                                color: root.cSubText
                                Layout.fillWidth: true
                            }

                            Text {
                                text: "󰏌"
                                font.family: "Material Design Icons"
                                font.pixelSize: 12
                                color: root.cSubText
                            }
                        }

                        MouseArea {
                            id: localsendHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                localsendProc.running = true
                                root.closeTools()
                            }
                        }
                    }
                }

                // Separator
                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.fillHeight: true
                    color: root.cBorder
                }

                // Content area
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumWidth: 0
                    clip: true

                    Loader {
                        id: networkLoader
                        anchors.fill: parent
                        active: root.selectedTab === "network"
                        source: "../bar/components/NetworkPanel.qml"
                        onLoaded: { item.shouldShow = true }
                        Connections {
                            target: networkLoader.item
                            function onCloseRequested() { root.closeTools() }
                        }
                    }

                    Loader {
                        id: bluetoothLoader
                        anchors.fill: parent
                        active: root.selectedTab === "bluetooth"
                        source: "../bar/components/BluetoothPanel.qml"
                        onLoaded: { item.shouldShow = true }
                        Connections {
                            target: bluetoothLoader.item
                            function onCloseRequested() { root.closeTools() }
                        }
                    }

                    Loader {
                        id: wallpaperLoader
                        anchors.fill: parent
                        active: root.selectedTab === "wallpaper"
                        source: "../bar/components/WallpaperPanel.qml"
                        onLoaded: { item.shouldShow = true }
                        Connections {
                            target: wallpaperLoader.item
                            function onCloseRequested() { root.closeTools() }
                        }
                    }

                    Loader {
                        id: clipboardLoader
                        anchors.fill: parent
                        active: root.selectedTab === "clipboard"
                        source: "../bar/components/ClipboardPanel.qml"
                        onLoaded: { item.shouldShow = true; item.forceActiveFocus() }
                        Connections {
                            target: clipboardLoader.item
                            function onCloseRequested() { root.closeTools() }
                        }
                    }

                    Loader {
                        id: emojiLoader
                        anchors.fill: parent
                        active: root.selectedTab === "emoji"
                        source: "../bar/components/EmojiPanel.qml"
                        onLoaded: { item.shouldShow = true; item.forceActiveFocus() }
                        Connections {
                            target: emojiLoader.item
                            function onCloseRequested() { root.closeTools() }
                        }
                    }

                    Loader {
                        id: recordingsLoader
                        anchors.fill: parent
                        active: root.selectedTab === "recordings"
                        source: "../bar/components/RecordingsPanel.qml"
                        onLoaded: { item.shouldShow = true; item.forceActiveFocus() }
                        Connections {
                            target: recordingsLoader.item
                            function onCloseRequested() { root.closeTools() }
                        }
                    }
                }
            }
        }
        }

        // NOTE: previously this was a full-window MouseArea listening for
        // Qt.RightButton. Accepting the right mouse button here makes Qt
        // run its context-menu synthesis path (QWindowPrivate::
        // maybeSynthesizeContextMenuEvent -> QQuickDeliveryAgentPrivate::
        // contextMenuTargets -> QQuickItem::mapToScene) on every right click
        // anywhere in this window, which crashes quickshell on this Qt/
        // Quickshell build. Right-click-to-close is not worth that crash,
        // so it has been removed. Escape still closes (see
        // Keys.onEscapePressed above), and clicking a tab or LocalSend
        // still works as before.
    }
}
