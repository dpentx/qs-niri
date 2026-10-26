import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import "../../../components"
import "../../../components/effects"
import "../../../config" as QsConfig
import "../../../services" as QsServices

// Samsung DeX 3-button navigation cluster:
// - Recents (III): Toggles overview / dashboard / task switcher
// - Home: Closes all panels, returns to desktop
// - Back (<): Dismisses active popup/panel or focuses previous window
Item {
    id: root

    property var launcher
    property var controlCenter
    property var sidebar
    property var dashboard
    property var bar

    readonly property var pywal: QsServices.Pywal
    readonly property var appearance: QsConfig.Appearance

    implicitWidth: navRow.implicitWidth
    implicitHeight: 38

    function closePanels() {
        if (root.launcher && root.launcher.shouldShow) root.launcher.shouldShow = false
        if (root.controlCenter && root.controlCenter.shouldShow) root.controlCenter.shouldShow = false
        if (root.sidebar && root.sidebar.shouldShow) root.sidebar.shouldShow = false
        if (root.dashboard && root.dashboard.shouldShow) root.dashboard.shouldShow = false
        if (root.bar) root.bar.closePopup()
    }

    readonly property bool anyPanelOpen: (root.launcher?.shouldShow ?? false)
        || (root.controlCenter?.shouldShow ?? false)
        || (root.sidebar?.shouldShow ?? false)
        || (root.dashboard?.shouldShow ?? false)
        || (root.bar?.hasPopup ?? false)

    Row {
        id: navRow
        anchors.centerIn: parent
        spacing: 2

        // ═══ RECENTS (III) ═══
        Item {
            id: recentsBtn
            width: 32
            height: 32
            activeFocusOnTab: true
            readonly property bool open: root.dashboard?.shouldShow ?? false

            Rectangle {
                anchors.fill: parent
                radius: appearance.radius.s
                color: pywal.foreground
                opacity: recentsMouse.containsMouse || recentsBtn.open ? 0.14 : 0
                border.width: recentsBtn.activeFocus ? QsConfig.Appearance.border.focus : 0
                border.color: pywal.primary
                Behavior on opacity { NumberAnimation { duration: OneUIMotion.short3 } }
            }

            OneUIIcon {
                anchors.centerIn: parent
                name: "ic_samsung_sysbar_recent"
                size: 18
                color: recentsBtn.open ? pywal.primary : pywal.foreground
                scale: recentsMouse.pressed ? OneUIMotion.pressedScale : (recentsMouse.containsMouse ? 1.05 : 1.0)
                Behavior on color { ColorAnimation { duration: OneUIMotion.short2 } }
                Behavior on scale { NumberAnimation { duration: OneUIMotion.short2 } }
            }

            MouseArea {
                id: recentsMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.dashboard) {
                        root.dashboard.shouldShow = !root.dashboard.shouldShow
                        if (root.dashboard.shouldShow) {
                            if (root.launcher) root.launcher.shouldShow = false
                            if (root.controlCenter) root.controlCenter.shouldShow = false
                            if (root.sidebar) root.sidebar.shouldShow = false
                            if (root.bar) root.bar.closePopup()
                        }
                    } else {
                        Quickshell.execDetached(["niri", "msg", "action", "focus-window-previous"])
                    }
                }
            }
        }

        // ═══ HOME ═══
        Item {
            id: homeBtn
            width: 32
            height: 32
            activeFocusOnTab: true

            Rectangle {
                anchors.fill: parent
                radius: appearance.radius.s
                color: pywal.foreground
                opacity: homeMouse.containsMouse ? 0.14 : 0
                border.width: homeBtn.activeFocus ? QsConfig.Appearance.border.focus : 0
                border.color: pywal.primary
                Behavior on opacity { NumberAnimation { duration: OneUIMotion.short3 } }
            }

            OneUIIcon {
                anchors.centerIn: parent
                name: "ic_samsung_sysbar_home"
                size: 18
                color: homeMouse.containsMouse ? pywal.primary : pywal.foreground
                scale: homeMouse.pressed ? OneUIMotion.pressedScale : (homeMouse.containsMouse ? 1.05 : 1.0)
                Behavior on color { ColorAnimation { duration: OneUIMotion.short2 } }
                Behavior on scale { NumberAnimation { duration: OneUIMotion.short2 } }
            }

            MouseArea {
                id: homeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.closePanels()
                }
            }
        }

        // ═══ BACK (<) ═══
        Item {
            id: backBtn
            width: 32
            height: 32
            activeFocusOnTab: true

            Rectangle {
                anchors.fill: parent
                radius: appearance.radius.s
                color: pywal.foreground
                opacity: backMouse.containsMouse ? 0.14 : 0
                border.width: backBtn.activeFocus ? QsConfig.Appearance.border.focus : 0
                border.color: pywal.primary
                Behavior on opacity { NumberAnimation { duration: OneUIMotion.short3 } }
            }

            OneUIIcon {
                anchors.centerIn: parent
                name: "ic_samsung_sysbar_back"
                size: 18
                color: backMouse.containsMouse ? pywal.primary : pywal.foreground
                scale: backMouse.pressed ? OneUIMotion.pressedScale : (backMouse.containsMouse ? 1.05 : 1.0)
                Behavior on color { ColorAnimation { duration: OneUIMotion.short2 } }
                Behavior on scale { NumberAnimation { duration: OneUIMotion.short2 } }
            }

            MouseArea {
                id: backMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.anyPanelOpen) {
                        root.closePanels()
                    } else {
                        Quickshell.execDetached(["niri", "msg", "action", "focus-window-previous"])
                    }
                }
            }
        }
    }
}
