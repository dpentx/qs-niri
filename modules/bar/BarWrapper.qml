import Quickshell
import Quickshell.Wayland
import QtQuick 6.10
import Quickshell.Io
import "../../config" as QsConfig
import "../../services" as QsServices

Scope {
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
    id: systoolsToggle
    path: "/tmp/qs-systools"
    watchChanges: true
    onFileChanged: {
        if (systoolsLoader.item) {
            systoolsLoader.item.shouldShow = !systoolsLoader.item.shouldShow
          }
       }
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
                top: true
                left: true
                right: true
            }
            
            // Fixed exclusive zone: only the bar strip reserves space
            exclusiveZone: config.bar.height
            
            // Dynamic height: bar + inline popup area
            implicitHeight: config.bar.height + (barLoader.item?.popupAreaHeight ?? 0)
            color: "transparent"
            
            // Overlay layer — Top (the implicit default) sits BELOW
            // fullscreen surfaces in wlr-layer-shell, so the bar would get
            // covered by any fullscreen app (or a window rule that
            // auto-fullscreens). Overlay is the layer meant for things
            // that must stay visible no matter what's fullscreened.
            WlrLayershell.layer: WlrLayer.Overlay
            
            // Allow keyboard focus when a popup is open
            WlrLayershell.keyboardFocus: (barLoader.item?.hasPopup ?? false) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
            
            // Bar content (fills window: bar strip at top, popup host below)
            Loader {
                id: barLoader
                anchors.fill: parent
                source: "Bar.qml"
                
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
