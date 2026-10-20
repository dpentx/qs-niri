import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../config" as QsConfig
import "../../services" as QsServices
import "../../components"
import "../../components/effects"

PanelWindow {
    id: root

    // Blur only while the panel is fully shown: the region is a fixed rect and would otherwise be
    // drawn before the panel has faded in (and stay after it has gone).
    BackgroundEffect.blurRegion: QsConfig.Appearance.blur && shouldShow && panel.opacity > 0.98 ? _blur : null
    // The window covers the whole screen, so the blur follows the panel item, not the window.
    Region { id: _blur; item: panel; radius: root.cornerRadius.l }

    property bool shouldShow: false
    property string selectedTab: "network"  // network | bluetooth | wallpaper | clipboard | recordings | shell

    readonly property var config: QsConfig.Config
    readonly property var pywal: QsServices.Pywal
    readonly property var cornerRadius: QsConfig.Appearance.radius
    readonly property color cSurface: pywal.surfaceContainerHighest
    readonly property color cSurfaceContainer: pywal.surfaceContainerHigh
    readonly property color cPrimary: pywal.primary
    readonly property color cText: pywal.foreground
    readonly property color cSubText: pywal.onSurfaceMuted
    readonly property color cBorder: pywal.outlineVariant

    readonly property var tabs: [
        { id: "network",   glyph: "sec_ic_wifi_signal_4", label: "Network" },
        { id: "bluetooth", glyph: "ic_qs_bluetooth_on", label: "Bluetooth" },
        { id: "wallpaper", glyph: "mdi_wallpaper", label: "Wallpaper" },
        { id: "clipboard", glyph: "clipboard_full", label: "Clipboard" },
        { id: "recordings", glyph: "qs_screen_record_icon", label: "Recordings" },
        { id: "shell",     glyph: "ic_settings", label: "Shell" }
    ]
    // Choosing "Shell" swaps the rail for the shell settings pages.
    property string shellPage: "profile"
    readonly property bool inShell: selectedTab === "shell"
    readonly property var shellTabs: [
        { id: "profile",  glyph: "ic_settings",         label: "Profile" },
        { id: "bar",      glyph: "mdi_memory",          label: "Bar widgets" },
        { id: "features", glyph: "ic_apps_expressive",  label: "Features" },
        { id: "theme",    glyph: "mdi_wallpaper",       label: "Theme" },
        { id: "lock",     glyph: "ic_device_lock_on",   label: "Lock screen" },
        { id: "gaming",   glyph: "ic_media_game_console", label: "Gaming" },
        { id: "keyboard", glyph: "btkeyboard_btn_ic_shortcut_enter", label: "Keyboard" },
        { id: "about",    glyph: "ic_info_outline",     label: "About" }
    ]
    readonly property var railTabs: inShell ? shellTabs : tabs
    readonly property string railActive: inShell ? shellPage : selectedTab
    readonly property int selectedTabIndex: railTabs.findIndex(t => t.id === railActive)

    function closeTools() {
        shouldShow = false
    }

    function openTools() {
        shouldShow = true
        selectedTab = "network"
        shellPage = "profile"
    }

    Process {
        id: localsendProc
        command: ["localsend"]
    }

    screen: Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    // The window covers the screen; only the panel takes input and it can be moved/resized (PanelGeometry).
    mask: Region { item: panel }
    PanelGeometry {
        id: geo
        screen: root.screen
        name: "systemTools"
        minW: 520
        minH: 360
        defaultW: 620
        defaultH: 560
        defaultY: (config.bar.height ?? 34) + 22
    }
    color: "transparent"
    visible: shouldShow || panel.opacity > 0

    // Overlay, so the click-outside dismiss layer (Top) stays beneath the panel
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shouldShow ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    FocusScope {
        id: panel
        x: geo.x; y: geo.y; width: geo.w; height: geo.h

        PanelGrips { geo: geo; color: root.cText }
        property real revealOffset: shouldShow ? 0 : -20
        scale: shouldShow ? 1.0 : 0.97
        opacity: shouldShow ? 1.0 : 0.0
        focus: root.shouldShow
        transform: Translate { y: panel.revealOffset }

        Keys.onEscapePressed: root.closeTools()

        Behavior on scale { NumberAnimation { duration: OneUIMotion.medium1; easing.bezierCurve: OneUIMotion.springGentle } }
        Behavior on opacity { NumberAnimation { duration: OneUIMotion.short4; easing.type: Easing.OutQuad } }
        Behavior on revealOffset { NumberAnimation { duration: OneUIMotion.medium1; easing.bezierCurve: OneUIMotion.emphasizedDecelerate } }

        AuroraSurface {
            id: blurSurface
            anchors.fill: parent
            radius: root.cornerRadius.l
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

                        Behavior on color { ColorAnimation { duration: OneUIMotion.short2 } }

                        scale: topBtnMouse.pressed ? 0.9 : 1.0
                        Behavior on scale { NumberAnimation { duration: OneUIMotion.short2 } }

                        OneUIIcon {
                            anchors.centerIn: parent
                            name: topBtn.icon
                            size: 15
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
                        icon: "mdi_memory"
                        onClicked: {
                            root.closeTools()
                            Quickshell.execDetached(["touch", "/tmp/qs-taskmanager"])
                        }
                    }

                    TopIconButton {
                        icon: "ic_qs_footer_power"
                        tintColor: pywal.error
                        onClicked: {
                            root.closeTools()
                            QsServices.UIState.powerMenuOpen = true
                        }
                    }

                    TopIconButton {
                        icon: "ic_close"
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
                            text: root.inShell ? "‹ Settings" : "Settings"
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: QsConfig.Appearance.fontSize.s
                            font.weight: Font.Medium
                            color: root.cSubText

                            MouseArea {
                                anchors.fill: parent
                                enabled: root.inShell
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectedTab = "network"
                            }
                        }
                        Text {
                            text: "Shell"
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: QsConfig.Appearance.fontSize.xl
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
                                NumberAnimation { duration: OneUIMotion.short4; easing.bezierCurve: OneUIMotion.springGentle }
                            }
                        }

                        Column {
                            id: tabsColumn
                            width: parent.width
                            spacing: 6

                            Repeater {
                                model: root.railTabs

                                Rectangle {
                                    required property var modelData
                                    width: tabsColumn.width
                                    height: 44
                                    radius: root.cornerRadius.m
                                    color: root.railActive === modelData.id
                                        ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.18)
                                        : tabHover.containsMouse ? root.cSurfaceContainer : "transparent"

                                    Behavior on color { ColorAnimation { duration: OneUIMotion.short2 } }

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
                                            color: root.railActive === modelData.id
                                                ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.22)
                                                : Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.08)

                                            OneUIIcon {
                                                anchors.centerIn: parent
                                                name: modelData.glyph
                                                size: 15
                                                color: root.railActive === modelData.id ? root.cPrimary : root.cText

                                                Behavior on color { ColorAnimation { duration: OneUIMotion.short3 } }
                                            }
                                        }

                                        Text {
                                            text: modelData.label
                                            font.family: QsConfig.Config.appearance.fontFamily
                                            font.pixelSize: QsConfig.Appearance.fontSize.m
                                            font.weight: root.railActive === modelData.id ? Font.DemiBold : Font.Normal
                                            color: root.railActive === modelData.id ? root.cText : root.cSubText
                                            Layout.fillWidth: true

                                            Behavior on color { ColorAnimation { duration: OneUIMotion.short3 } }
                                        }
                                    }

                                    MouseArea {
                                        id: tabHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.inShell ? root.shellPage = modelData.id : root.selectedTab = modelData.id
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // LocalSend — quick-launch, not a hosted panel (no reliable CLI to embed)
                    Rectangle {
                        visible: !root.inShell
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        radius: root.cornerRadius.s
                        color: localsendHover.containsMouse ? root.cSurfaceContainer : "transparent"

                        Behavior on color { ColorAnimation { duration: OneUIMotion.short2 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10

                            OneUIIcon {
                                name: "mdi_send"
                                size: 16
                                color: root.cText
                            }

                            Text {
                                text: "LocalSend"
                                font.family: QsConfig.Config.appearance.fontFamily
                                font.pixelSize: QsConfig.Appearance.fontSize.m
                                color: root.cSubText
                                Layout.fillWidth: true
                            }

                            OneUIIcon {
                                name: "ic_open_in_new"
                                size: 12
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

                    Loader {
                        id: shellLoader
                        anchors.fill: parent
                        active: root.selectedTab === "shell"
                        source: "ShellSettingsPanel.qml"
                        onLoaded: { item.shouldShow = true; item.forceActiveFocus() }
                        Binding { target: shellLoader.item; property: "page"; value: root.shellPage; when: shellLoader.item !== null }
                        Connections {
                            target: shellLoader.item
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
