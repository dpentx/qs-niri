import Quickshell
import Quickshell.Io
import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10
import QtQuick.Effects
import "components" as BarComponents
import "../../components"
import "../../components/effects"
import "../../config" as QsConfig
import "../../services" as QsServices

Item {
    id: root

    property var screen
    property var barWindow
    property var controlCenter
    property var launcher
    property var sidebar
    property var dashboard

    readonly property bool hasPopup: false
    readonly property real popupAreaHeight: 0
    function closePopup() {}
    function togglePopup(name: string) {}

    readonly property var config: QsConfig.Config
    readonly property var appearance: QsConfig.Appearance
    readonly property var pywal: QsServices.Pywal

    readonly property bool shouldAutoHide: QsServices.NiriFullscreen.focusedFullscreen
    property bool revealedByHover: false
    readonly property bool barHidden: shouldAutoHide && !revealedByHover

    Timer {
        id: hideDelayTimer
        interval: 500
        onTriggered: root.revealedByHover = false
    }

    MouseArea {
        id: bottomEdgeReveal
        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
        height: 6
        hoverEnabled: true
        z: 10
        onContainsMouseChanged: {
            if (containsMouse) {
                hideDelayTimer.stop()
                root.revealedByHover = true
            } else if (root.shouldAutoHide) {
                hideDelayTimer.restart()
            }
        }
    }

    Item {
        id: barContainer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.barHidden ? -(height + 4) : 0
        height: config.bar.baseHeight

        Behavior on anchors.bottomMargin {
            NumberAnimation {
                duration: OneUIMotion.short4
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            id: barStrip
            anchors.fill: parent
            color: Qt.rgba(pywal.background.r, pywal.background.g, pywal.background.b, QsConfig.Appearance.blur ? 0.62 : 0.94)
            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: 1
                color: pywal.divider
            }
        }

        Item {
            id: appsButton
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 38; height: 38
            activeFocusOnTab: true
            readonly property bool open: root.launcher?.shouldShow ?? false
            function toggle() {
                if (!root.launcher) return
                root.launcher.shouldShow = !root.launcher.shouldShow
                if (root.launcher.shouldShow) {
                    if (root.controlCenter) root.controlCenter.shouldShow = false
                    if (root.sidebar) root.sidebar.shouldShow = false
                    if (root.dashboard) root.dashboard.shouldShow = false
                }
            }
            Keys.onReturnPressed: toggle()
            Keys.onSpacePressed: toggle()

            Rectangle {
                anchors.fill: parent
                radius: appearance.radius.m
                color: pywal.foreground
                opacity: appsMouse.containsMouse || appsButton.open ? 0.14 : 0
                border.width: appsButton.activeFocus ? QsConfig.Appearance.border.focus : 0
                border.color: pywal.primary
                Behavior on opacity { NumberAnimation { duration: OneUIMotion.short3 } }
            }
            OneUIIcon {
                anchors.centerIn: parent
                name: "ic_apps_expressive"
                size: 22
                color: appsButton.open ? pywal.primary : pywal.foreground
                Behavior on color { ColorAnimation { duration: OneUIMotion.short2 } }
            }
            MouseArea {
                id: appsMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: appsButton.toggle()
            }
        }

        Loader {
            id: navButtonsLoader
            anchors.left: appsButton.right
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            active: QsConfig.Config.dex.showNavButtons
            visible: active
            source: "components/NavigationButtons.qml"

            onStatusChanged: {
                if (status === Loader.Ready) {
                    item.launcher = Qt.binding(() => root.launcher)
                    item.controlCenter = Qt.binding(() => root.controlCenter)
                    item.sidebar = Qt.binding(() => root.sidebar)
                    item.dashboard = Qt.binding(() => root.dashboard)
                    item.bar = Qt.binding(() => root)
                }
            }
        }

        AuroraSurface {
            id: taskPill
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            height: 38
            visible: QsConfig.Config.taskbar.enabled && (taskbarLoader.item?.hasItems ?? false)
            width: visible ? taskbarLoader.item.implicitWidth + 14 : 0
            Behavior on width { NumberAnimation { duration: OneUIMotion.medium2; easing.bezierCurve: OneUIMotion.standard } }

            radius: appearance.radius.m
            color: "transparent"
            borderWidth: 0
            accentColor: pywal.secondary
            elevation: 0
            clip: true

            Loader {
                id: taskbarLoader
                anchors.centerIn: parent
                asynchronous: true
                source: "components/Taskbar.qml"

                Binding {
                    target: taskbarLoader.item
                    property: "barWindow"
                    value: root.barWindow
                    when: taskbarLoader.status === Loader.Ready && root.barWindow !== undefined
                    restoreMode: Binding.RestoreBinding
                }
            }
        }

        Row {
            id: rightControls
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            BarComponents.CaptureButton {
                anchors.verticalCenter: parent.verticalCenter
                visible: QsConfig.Config.dex.showCaptureButton
            }

            Rectangle {
                id: showDesktopButton
                width: 5
                height: 26
                radius: 2.5
                anchors.verticalCenter: parent.verticalCenter
                visible: QsConfig.Config.dex.showDesktopButton
                color: pywal.foreground
                opacity: showDesktopMouse.containsMouse ? 0.35 : 0.10
                Behavior on opacity { NumberAnimation { duration: OneUIMotion.short2 } }

                MouseArea {
                    id: showDesktopMouse
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.launcher) root.launcher.shouldShow = false
                        if (root.controlCenter) root.controlCenter.shouldShow = false
                        if (root.sidebar) root.sidebar.shouldShow = false
                        if (root.dashboard) root.dashboard.shouldShow = false
                        Quickshell.execDetached(["niri", "msg", "action", "close-overview"])
                    }
                }

            }
        }
    }
}
