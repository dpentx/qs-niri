import Quickshell
import Quickshell.Wayland
import QtQuick 6.10
import Quickshell.Io
import "../../config" as QsConfig
import "../../services" as QsServices

Scope {
    id: wrapper
    readonly property var config: QsConfig.Config
    
    // Popup windows removed — popups are now hosted inline inside the bar PanelWindow
    
    // Control Center window
    Loader {
        id: controlCenterLoader
        source: "../controlcenter/ControlCenterWindow.qml"
        asynchronous: true
        
        property var controlCenter: item
        
        onStatusChanged: {
            QsServices.Logger.debug(
                "BarWrapper",
                `Control Center loader status: ${status === Loader.Ready ? "READY" : status === Loader.Loading ? "LOADING" : status === Loader.Error ? "ERROR" : "NULL"}`
            )
            if (status === Loader.Error) {
                QsServices.Logger.error("BarWrapper", "Control Center failed to load")
            }
            if (status === Loader.Ready) {
                QsServices.Logger.debug("BarWrapper", `Control Center loaded, item: ${item ? "EXISTS" : "NULL"}`)
            }
        }
    }

    Loader {
        id: launcherLoader
        source: "../launcher/LauncherWindow.qml"
        asynchronous: true

        property var launcher: item
    }

    Loader {
        id: systoolsLoader
        source: "../systools/SystemToolsWindow.qml"
        asynchronous: true

        property var systools: item
    }

    Loader {
        id: taskmanagerLoader
        active: QsConfig.Config.features.taskManager
        source: "../taskmanager/TaskManagerWindow.qml"
        asynchronous: true
    }

    Loader {
        id: speedtestLoader
        active: QsConfig.Config.features.speedtest
        source: "../speedtest/SpeedtestWindow.qml"
        asynchronous: true
    }

    Loader {
        id: filesLoader
        active: QsConfig.Config.features.files
        source: "../files/FilesWindow.qml"
        asynchronous: true
    }

    Loader {
        id: wallSwitchLoader
        active: QsConfig.Config.features.wallSwitch
        source: "../wallswitch/WallSwitchWindow.qml"
        asynchronous: true
    }

    Loader {
        id: castLoader
        active: QsConfig.Config.features.cast
        source: "../cast/CastWindow.qml"
        asynchronous: true
    }

    Loader {
        id: clockLoader
        active: QsConfig.Config.features.clock
        source: "../clock/ClockWindow.qml"
        asynchronous: true
    }

    Loader {
        id: lockLoader
        active: QsConfig.Config.features.lock
        source: "../lock/LockScreen.qml"
    }

    Loader {
        id: hotspotqrLoader
        active: QsConfig.Config.features.hotspot
        source: "../hotspot/HotspotQrWindow.qml"
        asynchronous: true
    }

    // Starts the cliphist watcher (see services/Clipboard.qml).
    readonly property var _clipboard: QsServices.Clipboard

    Loader {
        id: sidebarLoader
        source: "../sidebar/SidebarWindow.qml"
        asynchronous: true

        property var sidebar: item
    }

    Loader {
        id: dashboardLoader
        source: "../dashboard/DashboardWindow.qml"
        asynchronous: true

        property var dashboard: item
    }

    Loader {
        id: powerMenuLoader
        source: "../powermenu/PowerMenuWindow.qml"
        asynchronous: true

        property var powerMenu: item
    }
    
    // Click-outside-to-close: while any panel is open, a transparent
    // full-screen layer sits between the apps and the panels (panels are on
    // the Overlay layer, this is on Top). A click on it closes every panel.
    readonly property var _panels: [
        controlCenterLoader.item, launcherLoader.item, systoolsLoader.item,
        sidebarLoader.item, dashboardLoader.item, taskmanagerLoader.item, speedtestLoader.item,
        hotspotqrLoader.item, filesLoader.item
    ]
    // Inline bar popups (network, bluetooth, media, ...) live inside the bar
    // window, which is on the Overlay layer above this dismiss layer, so they
    // stay clickable while a click anywhere else closes them.
    property int barPopupsOpen: 0
    signal dismissBarPopups()
    signal popupRequested(string name)  // open/close an inline bar popup
    readonly property bool anyPanelOpen: barPopupsOpen > 0 || _panels.some(p => p && p.shouldShow)

    function closeAllPanels() {
        for (const p of _panels) if (p && p.shouldShow) p.shouldShow = false
        dismissBarPopups()
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            visible: anyPanelOpen
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.namespace: "quickshell:dismiss"

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                onPressed: closeAllPanels()
            }
        }
    }

    FileView {
    id: launcherToggle
    path: "/tmp/qs-launcher"
    watchChanges: true
    onFileChanged: {
        if (launcherLoader.item) {
            launcherLoader.item.shouldShow = !launcherLoader.item.shouldShow
          }
       }
    } 

    FileView {
        id: speedtestToggle
        path: "/tmp/qs-speedtest"
        watchChanges: true
        onFileChanged: {
            if (speedtestLoader.item)
                speedtestLoader.item.shouldShow = !speedtestLoader.item.shouldShow
        }
    }

    // Lock only (never unlocks): `touch /tmp/qs-lock`, e.g. from a niri keybind.
    FileView {
        id: lockToggle
        path: "/tmp/qs-lock"
        watchChanges: true
        onFileChanged: if (lockLoader.item) lockLoader.item.shouldShow = true
    }

    FileView {
        id: hotspotqrToggle
        path: "/tmp/qs-hotspotqr"
        watchChanges: true
        onFileChanged: {
            if (hotspotqrLoader.item && QsServices.Network.hotspotActive)
                hotspotqrLoader.item.shouldShow = !hotspotqrLoader.item.shouldShow
        }
    }

    // Clipboard history popup (bar popup, anchored to the connectivity pill).
    FileView {
        id: clipboardToggle
        path: "/tmp/qs-clipboard"
        watchChanges: true
        onFileChanged: wrapper.popupRequested("clipboard")
    }

    // Emoji picker popup, same anchor as the clipboard one.
    FileView {
        id: emojiToggle
        path: "/tmp/qs-emoji"
        watchChanges: true
        onFileChanged: wrapper.popupRequested("emoji")
    }

    FileView {
        id: mediaToggle
        path: "/tmp/qs-media"
        watchChanges: true
        onFileChanged: wrapper.popupRequested("media")
    }

    FileView {
        id: volumeToggle
        path: "/tmp/qs-volume"
        watchChanges: true
        onFileChanged: wrapper.popupRequested("volume")
    }

    FileView {
        id: castToggle
        path: "/tmp/qs-cast"
        watchChanges: true
        onFileChanged: if (castLoader.item) castLoader.item.trigger()
    }

    FileView {
        id: clockToggle
        path: "/tmp/qs-clock"
        watchChanges: true
        onFileChanged: if (clockLoader.item) clockLoader.item.trigger()
    }

    FileView {
        id: wallSwitchToggle
        path: "/tmp/qs-wallswitch"
        watchChanges: true
        onFileChanged: if (wallSwitchLoader.item) wallSwitchLoader.item.trigger()
    }

    FileView {
        id: filesToggle
        path: "/tmp/qs-files"
        watchChanges: true
        onFileChanged: {
            if (filesLoader.item)
                filesLoader.item.shouldShow = !filesLoader.item.shouldShow
        }
    }

    FileView {
        id: taskmanagerToggle
        path: "/tmp/qs-taskmanager"
        watchChanges: true
        onFileChanged: {
            if (taskmanagerLoader.item)
                taskmanagerLoader.item.shouldShow = !taskmanagerLoader.item.shouldShow
        }
    }

    FileView {
    id: systoolsToggle
    path: "/tmp/qs-systools"
    watchChanges: true
    onFileChanged: {
        if (systoolsLoader.item) {
            systoolsLoader.item.shouldShow = !systoolsLoader.item.shouldShow
          }
       }
    }

    // Same touch-a-file convention as the toggles above, for the surfaces
    // that were previously only reachable from the bar. Handy for niri
    // keybinds (`touch /tmp/qs-controlcenter`) and used by ci/screenshots.sh
    // to open each surface in the headless screenshot pipeline.
    FileView {
        id: controlCenterToggle
        path: "/tmp/qs-controlcenter"
        watchChanges: true
        onFileChanged: {
            if (controlCenterLoader.item) {
                controlCenterLoader.item.shouldShow = !controlCenterLoader.item.shouldShow
            }
        }
    }

    FileView {
        id: sidebarToggle
        path: "/tmp/qs-sidebar"
        watchChanges: true
        onFileChanged: {
            if (sidebarLoader.item) {
                sidebarLoader.item.shouldShow = !sidebarLoader.item.shouldShow
            }
        }
    }

    FileView {
        id: dashboardToggle
        path: "/tmp/qs-dashboard"
        watchChanges: true
        onFileChanged: {
            if (dashboardLoader.item) {
                dashboardLoader.item.shouldShow = !dashboardLoader.item.shouldShow
            }
        }
    }

    FileView {
        id: powerMenuToggle
        path: "/tmp/qs-powermenu"
        watchChanges: true
        onFileChanged: QsServices.UIState.powerMenuOpen = !QsServices.UIState.powerMenuOpen
    }

    // Screenshot.qml (singleton service) is the single source of truth for
    // recording state — both the panel button and this keybind now toggle
    // through the same isRecording/startRecording/stopRecording, so they
    // can never race or start two overlapping gpu-screen-recorder processes.
    FileView {
    id: recordToggle
    path: "/tmp/qs-record"
    watchChanges: true
    onFileChanged: QsServices.Screenshot.toggleRecording()
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window
            
            property var modelData
            
            screen: modelData
            anchors {
                bottom: true
                left: true
                right: true
            }

            // Fixed exclusive zone: only the bar strip reserves space
            exclusiveZone: config.bar.height
            
            // Dynamic height: bar + inline popup area
            implicitHeight: config.bar.height + (barLoader.item?.popupAreaHeight ?? 0)
            color: "transparent"

            // Blur behind the taskbar strip (compositor-side, ext-background-effect-v1). A fixed rect
            // at the window's bottom: an item-bound region keeps its old spot when the window grows
            // upwards for a popup (it showed as a dark band across the screen).
            BackgroundEffect.blurRegion: QsConfig.Appearance.blur && !(barLoader.item?.barHidden ?? false) ? pillBlur : null
            Region {
                id: pillBlur
                x: 0
                y: window.height - config.bar.height
                width: window.width
                height: config.bar.height
            }

            // Top sits BELOW fullscreen windows in niri ("only the overlay layer shows above
            // fullscreen"), so the bar hides when an app goes fullscreen. While a panel or bar popup
            // is open it moves to Overlay: it must stay above the click-outside layer (also Top)
            // and stay usable, e.g. when opened from a keybind over a fullscreen app.
            WlrLayershell.layer: (!QsConfig.Config.barHideOnFullscreen || wrapper.anyPanelOpen) ? WlrLayer.Overlay : WlrLayer.Top
            
            readonly property bool popupOpen: barLoader.item?.hasPopup ?? false
            onPopupOpenChanged: wrapper.barPopupsOpen += popupOpen ? 1 : -1
            Connections {
                target: wrapper
                function onDismissBarPopups() { barLoader.item?.closePopup() }
            }

            // Allow keyboard focus when a popup is open
            WlrLayershell.keyboardFocus: (barLoader.item?.hasPopup ?? false) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
            
            // Bar content (fills window: bar strip at bottom, popup host above)
            Loader {
                id: barLoader
                anchors.fill: parent
                source: "Bar.qml"
                
                Connections {
                    target: wrapper
                    function onPopupRequested(name) { barLoader.item?.togglePopup(name) }
                }

                onStatusChanged: {
                    if (status === Loader.Ready) {
                        item.screen = Qt.binding(() => modelData)
                        item.barWindow = Qt.binding(() => window)
                        item.controlCenter = Qt.binding(() => controlCenterLoader.item)
                        item.launcher = Qt.binding(() => launcherLoader.item)
                        item.sidebar = Qt.binding(() => sidebarLoader.item)
                        item.dashboard = Qt.binding(() => dashboardLoader.item)
                    }
                }
            }
        }
    }
}
