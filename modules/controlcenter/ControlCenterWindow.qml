import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../../services" as QsServices
import "../../config" as QsConfig
import "../../components"
import "../../components/effects"
import "components"

PanelWindow {
    id: root
    
    // Services
    readonly property var logger: QsServices.Logger
    readonly property var config: QsConfig.Config
    readonly property var pywal: QsServices.Pywal
    readonly property var network: QsServices.Network
    readonly property var bluetooth: QsServices.Bluetooth
    readonly property var audio: QsServices.Audio
    readonly property var brightness: QsServices.Brightness
    readonly property var mpris: QsServices.Players
    readonly property var notifs: QsServices.Notifs
    readonly property var systemUsage: QsServices.SystemUsage
    readonly property var powerProfiles: QsServices.PowerProfiles
    readonly property var screenshot: QsServices.Screenshot
    readonly property var idleInhibitor: QsServices.IdleInhibitor
    
    // Process launchers for header buttons
    Process {
        id: systoolsProcess
        // Mirrors niri's own Mod+S keybind (`touch /tmp/qs-systools`) —
        // BarWrapper.qml's FileView watches that path and toggles the
        // System Tools window. Previously this button spawned the external,
        // unstyled `nm-connection-editor` instead of our own OneUI panel.
        command: ["touch", "/tmp/qs-systools"]
        onStarted: root.shouldShow = false
    }
    
    Process {
        id: lockProcess
        command: ["loginctl", "lock-session"]
        onStarted: root.shouldShow = false
    }
    
    Process {
        id: screenshotsProcess
        command: ["xdg-open", root.screenshot.screenshotsDir]
        onStarted: root.shouldShow = false
    }
    
    // Solid UI Color Tokens - Professional dark theme
    readonly property color cSurface: pywal.surfaceContainerHighest
    readonly property color cSurfaceContainer: pywal.surfaceContainerHigh
    readonly property color cSurfaceContainerHigh: pywal.surfaceContainerHigh
    readonly property color cBorder: pywal.outlineVariant
    readonly property color cPrimary: pywal.primary
    readonly property color cSecondary: pywal.secondary
    readonly property color cOnSurface: pywal.foreground
    readonly property color cOnSurfaceVariant: pywal.onSurfaceMuted
    readonly property color cOnSurfaceDim: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.5)
    
    screen: Quickshell.screens[0]
    
    anchors {
        top: true
        right: true
    }
    
    margins {
        right: 12
        top: 12
    }
    
    implicitWidth: 340
    implicitHeight: Math.min(620, screen.height - 24)
    color: "transparent"
    
    visible: shouldShow || panelContent.opacity > 0
    
    property bool shouldShow: false
    
    WlrLayershell.keyboardFocus: shouldShow ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    
    // Main Panel Container
    FocusScope {
        id: panelContent
        anchors.fill: parent
        
        transformOrigin: Item.TopRight
        property real revealOffsetX: root.shouldShow ? 0 : 20
        property real revealOffsetY: root.shouldShow ? 0 : -10
        scale: root.shouldShow ? 1.0 : 0.965
        opacity: root.shouldShow ? 1.0 : 0.0
        transform: Translate { x: panelContent.revealOffsetX; y: panelContent.revealOffsetY }
        
        focus: true
        
        Keys.onEscapePressed: root.shouldShow = false
        
        // Track if mouse has entered at least once
        property bool mouseHasEntered: false
        property bool mouseInside: hoverHandler.hovered
        
        // Reset when panel opens/closes
        Connections {
            target: root
            function onShouldShowChanged() {
                if (root.shouldShow) {
                    panelContent.mouseHasEntered = false
                    closeTimer.stop()
                }
            }
        }
        
        // Timer to delay close
        Timer {
            id: closeTimer
            interval: 400
            onTriggered: {
                if (!panelContent.mouseInside && panelContent.mouseHasEntered && root.shouldShow) {
                    root.shouldShow = false
                }
            }
        }
        
        // HoverHandler works regardless of child item stacking
        HoverHandler {
            id: hoverHandler
            onHoveredChanged: {
                if (hovered) {
                    panelContent.mouseHasEntered = true
                    closeTimer.stop()
                } else if (panelContent.mouseHasEntered && root.shouldShow) {
                    closeTimer.restart()
                }
            }
        }
        
        onVisibleChanged: {
            if (visible) forceActiveFocus()
        }
        
        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: root.shouldShow = false
        }
        
        Behavior on scale {
            NumberAnimation { duration: 260; easing.bezierCurve: [0.22, 1.0, 0.36, 1.0] }
        }

        Behavior on opacity {
            NumberAnimation { duration: 180; easing.bezierCurve: Material3Anim.standard }
        }

        Behavior on revealOffsetX {
            NumberAnimation { duration: 260; easing.bezierCurve: Material3Anim.emphasizedDecelerate }
        }

        Behavior on revealOffsetY {
            NumberAnimation { duration: 260; easing.bezierCurve: Material3Anim.emphasizedDecelerate }
        }
        
        // Main Panel Background — OneUI style: flat matte black, no accent wash, no heavy shadow
        AuroraSurface {
            id: panel
            anchors.fill: parent
            color: "#000000"       // sec_panel_background_color
            radius: 20             // notification_panel_background_radius
            borderWidth: 0         // OneUI panels have no outline stroke
            strokeColor: "transparent"
            clip: true
            accentColor: root.cPrimary
            elevation: 1           // OneUI shadow is minimal/near-flat, not Material elevation
            highlighted: false     // avoid pywal override + accent color wash on the surface
            
            Behavior on color {
                ColorAnimation {
                    duration: Material3Anim.medium2
                    easing.bezierCurve: Material3Anim.standard
                }
            }
            
            // Block clicks from passing through
            MouseArea {
                anchors.fill: parent
                onClicked: (mouse) => { mouse.accepted = true }
            }
            
            // Content Layout
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16
                
                // Header Section
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56
                    spacing: 12
                    
                    // Time & Date
                    ColumnLayout {
                        spacing: 2
                        
                        Text {
                            id: timeText
                            text: Qt.formatTime(new Date(), "hh:mm")
                            font.family: "OneUI Sans"
                            font.pixelSize: 32
                            font.weight: Font.Bold
                            color: root.cOnSurface
                        }
                        
                        Text {
                            text: Qt.formatDate(new Date(), "dddd, MMMM d")
                            font.family: "OneUI Sans"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: root.cOnSurfaceVariant
                        }
                        
                        Timer {
                            interval: 1000
                            running: true
                            repeat: true
                            onTriggered: timeText.text = Qt.formatTime(new Date(), "hh:mm")
                        }
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    // Header Actions — OneUI-style circular icon buttons.
                    // Colors already ride on the centralized OneUI palette
                    // (root.cSurfaceContainerHigh / root.cOnSurface); only the
                    // power button gets its own subtle red tint, matching the
                    // "Power off" accent used in OneUI's quick panel.
                    RowLayout {
                        spacing: 6
                        
                        HeaderButton {
                            icon: "󰒓"
                            tooltip: "Settings"
                            onClicked: systoolsProcess.running = true
                        }
                        HeaderButton {
                            icon: "󰍜"
                            tooltip: "Lock Screen"
                            onClicked: lockProcess.running = true
                        }
                        HeaderButton {
                            icon: "󰐥"
                            tooltip: "Power Menu"
                            tintColor: "#ff453a"
                            onClicked: {
                                root.shouldShow = false
                                QsServices.UIState.powerMenuOpen = true
                            }
                        }
                    }
                }
                
                // Scrollable Content
                Flickable {
                    id: contentFlick
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    contentHeight: contentColumn.height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    flickDeceleration: 3000
                    maximumFlickVelocity: 2000
                    
                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        width: 4
                        
                        contentItem: Rectangle {
                            radius: 2
                            color: Qt.rgba(root.cOnSurface.r, root.cOnSurface.g, root.cOnSurface.b, 0.2)
                        }
                    }
                    
                    ColumnLayout {
                        id: contentColumn
                        width: contentFlick.width
                        spacing: 14
                        
                        // Primary connectivity toggles — OneUI puts WiFi/
                        // Bluetooth in wide, labeled rows (they carry real
                        // status text: network name, device count) above
                        // the dense icon-only grid for everything else.
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            PrimaryToggleRow {
                                Layout.fillWidth: true
                                icon: "󰖩"
                                label: "Wi-Fi"
                                statusText: root.network.connected ? root.network.ssid : "Disconnected"
                                active: root.network.wifiEnabled
                                onToggled: root.network.toggleWifi()
                            }

                            PrimaryToggleRow {
                                Layout.fillWidth: true
                                icon: "󰂯"
                                label: "Bluetooth"
                                statusText: root.bluetooth.powered ? "On" : "Off"
                                active: root.bluetooth.powered
                                onToggled: root.bluetooth.togglePower()
                            }
                        }

                        // Secondary toggles — dense, icon-only grid (OneUI
                        // style: no visible label, more items per row)
                        GridLayout {
                            Layout.fillWidth: true
                            columns: 5
                            columnSpacing: 8
                            rowSpacing: 8
                            
                            QuickToggle {
                                Layout.fillWidth: true
                                compact: true
                                icon: "󰔎"
                                label: "Do Not Disturb"
                                active: root.notifs.dnd
                                activeColor: pywal.warning
                                surfaceColor: root.cSurfaceContainerHigh
                                textColor: root.cOnSurface
                                onClicked: root.notifs.toggleDnd()
                            }
                            
                            QuickToggle {
                                Layout.fillWidth: true
                                compact: true
                                icon: "󰅶"
                                label: "Caffeine"
                                active: root.idleInhibitor.inhibited
                                activeColor: pywal.info
                                surfaceColor: root.cSurfaceContainerHigh
                                textColor: root.cOnSurface
                                onClicked: root.idleInhibitor.inhibited = !root.idleInhibitor.inhibited
                            }
                            
                            QuickToggle {
                                Layout.fillWidth: true
                                compact: true
                                icon: "󰹑"
                                label: "Screenshot"
                                active: false
                                activeColor: root.cSecondary
                                surfaceColor: root.cSurfaceContainerHigh
                                textColor: root.cOnSurface
                                onClicked: root.screenshot.takeScreenshot("screen")
                            }

                            QuickToggle {
                                Layout.fillWidth: true
                                compact: true
                                icon: root.screenshot.isRecording ? "󰛿" : "󰻃"
                                label: root.screenshot.isRecording ? "Stop Recording" : "Record Screen"
                                active: root.screenshot.isRecording
                                activeColor: pywal.error
                                surfaceColor: root.cSurfaceContainerHigh
                                textColor: root.cOnSurface
                                onClicked: {
                                    if (root.screenshot.isRecording)
                                        root.screenshot.stopRecording()
                                    else
                                        root.screenshot.startRecording()
                                }
                            }

                            QuickToggle {
                                Layout.fillWidth: true
                                compact: true
                                icon: "󰉋"
                                label: "Open Captures"
                                active: false
                                activeColor: root.cSecondary
                                surfaceColor: root.cSurfaceContainerHigh
                                textColor: root.cOnSurface
                                onClicked: screenshotsProcess.running = true
                            }
                        }
                        
                        // Divider
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: root.cBorder
                        }
                        
                        // Sliders Section
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            
                            VolumeSlider {
                                Layout.fillWidth: true
                                audio: root.audio
                                pywal: root.pywal
                            }
                            
                            BrightnessSlider {
                                Layout.fillWidth: true
                                brightness: root.brightness
                                pywal: root.pywal
                            }
                        }
                        
                        // Divider
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: root.cBorder
                        }

                        // Focus Timer Section
                        FocusTimer {
                            Layout.fillWidth: true
                            pywal: root.pywal
                        }
                        
                        // Divider
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: root.cBorder
                        }
                        
                        // System Stats
                        SystemStats {
                            Layout.fillWidth: true
                            systemUsage: root.systemUsage
                            pywal: root.pywal
                        }
                        
                        // Media Card
                        MediaCard {
                            Layout.fillWidth: true
                            mpris: root.mpris
                            pywal: root.pywal
                        }
                        
                        // Notifications
                        NotificationList {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.min(260, Math.max(80, root.height - 600))
                            notifs: root.notifs
                            pywal: root.pywal
                        }
                        
                        // Bottom padding
                        Item { Layout.preferredHeight: 4 }
                    }
                }
            }
        }
    }
    
    // Primary connectivity toggle row — OneUI-style wide row for WiFi/
    // Bluetooth: icon badge + title + live status text, tinted background
    // when active. Whole row toggles power on click (matches the tap
    // target size/behavior of the compact grid tiles, just wider).
    component PrimaryToggleRow: Rectangle {
        id: primaryRow

        property string icon: ""
        property string label: ""
        property string statusText: ""
        property bool active: false
        signal toggled()

        Layout.preferredHeight: 64
        radius: 18
        color: active
            ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.16)
            : root.cSurfaceContainerHigh

        Behavior on color { ColorAnimation { duration: 150 } }

        scale: rowMouse.pressed ? 0.96 : 1.0
        Behavior on scale {
            NumberAnimation {
                duration: Material3Anim.short2
                easing.bezierCurve: Material3Anim.springGentle
            }
        }

        MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: primaryRow.toggled()
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                radius: 20
                color: primaryRow.active ? "#fffcfcff" : "#40000000"
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: primaryRow.icon
                    font.family: "Material Design Icons"
                    font.pixelSize: 18
                    color: primaryRow.active ? "#d9252528" : "#80fcfcff"
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: primaryRow.label
                    font.family: "OneUI Sans"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    color: root.cOnSurface
                }
                Text {
                    text: primaryRow.statusText
                    font.family: "OneUI Sans"
                    font.pixelSize: 11
                    color: Qt.rgba(root.cOnSurface.r, root.cOnSurface.g, root.cOnSurface.b, 0.6)
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }
    }

    // Header Button Component — OneUI-style circular icon button
    component HeaderButton: Rectangle {
        id: headerBtn
        property string icon
        property string tooltip: ""
        // Optional accent tint (used by the power button for OneUI's
        // subtle red "power off" cue). Falls back to neutral cOnSurface.
        property color tintColor: root.cOnSurface
        signal clicked()
        
        width: 40
        height: 40
        radius: 20
        color: headerBtnMouse.containsMouse 
            ? Qt.rgba(headerBtn.tintColor.r, headerBtn.tintColor.g, headerBtn.tintColor.b, 0.16) 
            : root.cSurfaceContainer
        
        Behavior on color {
            ColorAnimation {
                duration: Material3Anim.short3
                easing.bezierCurve: Material3Anim.standard
            }
        }
        
        scale: headerBtnMouse.pressed ? 0.92 : 1.0
        
        Behavior on scale {
            NumberAnimation {
                duration: Material3Anim.short2
                easing.bezierCurve: Material3Anim.standard
            }
        }
        
        Text {
            anchors.centerIn: parent
            text: headerBtn.icon
            font.family: "Material Design Icons"
            font.pixelSize: 18
            color: headerBtn.tintColor
        }
        
        MouseArea {
            id: headerBtnMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: headerBtn.clicked()
        }
        
        ToolTip.visible: headerBtnMouse.containsMouse && headerBtn.tooltip !== ""
        ToolTip.text: headerBtn.tooltip
        ToolTip.delay: 500
    }
}
