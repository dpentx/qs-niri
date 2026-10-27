import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
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
    property var topWindow
    property var controlCenter
    property var launcher
    property var sidebar
    property var dashboard

    property string activePopup: ""
    readonly property bool hasPopup: activePopup !== ""
    readonly property real popupAreaHeight: hasPopup ? popupHost.height : 0

    function togglePopup(name: string) {
        if (activePopup === name) {
            activePopup = ""
        } else {
            activePopup = name
        }
    }

    function closePopup() {
        activePopup = ""
    }

    function popupAnchorTarget() {
        if (activePopup === "network" || activePopup === "bluetooth" || activePopup === "wallpaper" || activePopup === "clipboard" || activePopup === "emoji")
            return connectivityRow
        if (activePopup === "volume")
            return volumeLoader.item ?? connectivityRow
        if (activePopup === "battery")
            return batteryLoader
        return rightSection
    }

    readonly property var config: QsConfig.Config
    readonly property var appearance: QsConfig.Appearance
    readonly property var pywal: QsServices.Pywal

    readonly property bool shouldAutoHide: QsServices.NiriFullscreen.focusedFullscreen && !root.hasPopup
    property bool revealedByHover: false
    readonly property bool barHidden: shouldAutoHide && !revealedByHover

    Timer {
        id: hideDelayTimer
        interval: 500
        onTriggered: root.revealedByHover = false
    }

    MouseArea {
        id: topEdgeReveal
        anchors { top: parent.top; left: parent.left; right: parent.right }
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
        anchors.top: parent.top
        anchors.topMargin: root.barHidden ? -(height + 4) : 0
        height: QsConfig.Config.bar.baseTopBarHeight

        Behavior on anchors.topMargin {
            NumberAnimation {
                duration: OneUIMotion.short4
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            id: barStrip
            anchors.fill: parent
            color: Qt.rgba(pywal.background.r, pywal.background.g, pywal.background.b, QsConfig.Appearance.blur ? 0.65 : 0.94)
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: pywal.divider
            }
        }

        Row {
            id: leftSection
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Loader {
                id: clockLoader
                anchors.verticalCenter: parent.verticalCenter
                asynchronous: true
                source: "components/Clock.qml"

                Binding {
                    target: clockLoader.item
                    property: "inlineMode"
                    value: true
                    when: clockLoader.status === Loader.Ready
                }
                Binding {
                    target: clockLoader.item
                    property: "launcher"
                    value: root.launcher
                    when: clockLoader.status === Loader.Ready
                }
                Binding {
                    target: clockLoader.item
                    property: "controlCenter"
                    value: root.controlCenter
                    when: clockLoader.status === Loader.Ready
                }
                Binding {
                    target: clockLoader.item
                    property: "sidebar"
                    value: root.sidebar
                    when: clockLoader.status === Loader.Ready
                }
                Binding {
                    target: clockLoader.item
                    property: "dashboard"
                    value: root.dashboard
                    when: clockLoader.status === Loader.Ready
                }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 12
                radius: 0.5
                color: pywal.divider
            }

            Loader {
                id: notifCenterLoader
                anchors.verticalCenter: parent.verticalCenter
                asynchronous: true
                source: "components/NotificationCenterToggle.qml"

                Binding {
                    target: notifCenterLoader.item
                    property: "sidebar"
                    value: root.sidebar
                    when: notifCenterLoader.status === Loader.Ready
                }
                Binding {
                    target: notifCenterLoader.item
                    property: "controlCenter"
                    value: root.controlCenter
                    when: notifCenterLoader.status === Loader.Ready
                }
                Binding {
                    target: notifCenterLoader.item
                    property: "launcher"
                    value: root.launcher
                    when: notifCenterLoader.status === Loader.Ready
                }
            }

            Loader {
                id: mediaPlayerLoader
                anchors.verticalCenter: parent.verticalCenter
                asynchronous: true
                source: "components/MediaPlayer.qml"

                Binding { target: mediaPlayerLoader.item; property: "barWindow"; value: root.topWindow; when: mediaPlayerLoader.status === Loader.Ready && root.topWindow !== undefined }
                Binding { target: mediaPlayerLoader.item; property: "bar"; value: root; when: mediaPlayerLoader.status === Loader.Ready }
            }
        }

        Loader {
            id: workspacesLoader
            anchors.centerIn: parent
            asynchronous: true
            source: "components/Workspaces.qml"

            Binding {
                target: workspacesLoader.item
                property: "screen"
                value: root.screen
                when: workspacesLoader.status === Loader.Ready && root.screen !== undefined
            }
        }

        Row {
            id: rightSection
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            // User-chosen widgets (cpu, memory, custom commands...), status indicators and the tray
            Loader {
                anchors.verticalCenter: parent.verticalCenter
                source: "components/BarWidgets.qml"
            }

            Loader {
                id: statusIndicatorsLoader
                anchors.verticalCenter: parent.verticalCenter
                asynchronous: true
                source: "components/StatusIndicators.qml"
                visible: item?.hasActiveIndicators ?? false
            }

            Loader {
                id: systemTrayLoader
                anchors.verticalCenter: parent.verticalCenter
                asynchronous: true
                source: "components/SystemTray.qml"
                visible: item?.hasItems ?? false
            }

            Row {
                id: connectivityRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Column {
                    visible: QsConfig.Config.features.netSpeed
                    anchors.verticalCenter: parent.verticalCenter
                    width: 36
                    function rate(b) {
                        return b >= 1048576 ? (b / 1048576).toFixed(1) + "M"
                             : b >= 1024 ? Math.round(b / 1024) + "K" : "0K"
                    }
                    Repeater {
                        model: [
                            { arrow: "↑", v: QsServices.SystemUsage.uploadSpeed },
                            { arrow: "↓", v: QsServices.SystemUsage.downloadSpeed }
                        ]
                        Text {
                            required property var modelData
                            width: 36
                            horizontalAlignment: Text.AlignRight
                            text: modelData.arrow + " " + parent.rate(modelData.v)
                            color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, modelData.v >= 1024 ? 0.85 : 0.4)
                            font.family: "monospace"
                            font.pixelSize: 8
                        }
                    }
                }

                Loader {
                    id: capsLoader
                    anchors.verticalCenter: parent.verticalCenter
                    asynchronous: true
                    source: "components/CapsLock.qml"
                }

                Loader {
                    anchors.verticalCenter: parent.verticalCenter
                    source: "components/KeyboardLayout.qml"
                }

                BarComponents.BarIconButton {
                    id: wifiButton
                    visible: QsServices.Network.hasWifiDevice
                    anchors.verticalCenter: parent.verticalCenter
                    readonly property var net: QsServices.Network
                    readonly property int level: !net.connected ? 0 : net.signalStrength >= 80 ? 4 : net.signalStrength >= 60 ? 3 : net.signalStrength >= 40 ? 2 : net.signalStrength >= 20 ? 1 : 0
                    iconName: !net.wifiEnabled ? "ic_signal_wifi_off" : "sec_ic_wifi_signal_" + level
                    tint: !net.wifiEnabled ? pywal.divider : (net.connected ? pywal.foreground : Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.6))
                    open: root.activePopup === "network"
                    onClicked: root.togglePopup("network")
                }

                BarComponents.BarIconButton {
                    id: btButton
                    visible: QsServices.Bluetooth.available
                    anchors.verticalCenter: parent.verticalCenter
                    readonly property var adapter: Bluetooth.defaultAdapter
                    readonly property bool powered: adapter?.enabled ?? false
                    readonly property bool hasConnection: Bluetooth.devices.values.some(d => d.connected)
                    iconName: !powered ? "mdi_bluetooth_off" : (hasConnection ? "ic_qs_bluetooth_connected" : "ic_qs_bluetooth_on")
                    tint: !powered ? pywal.divider : (hasConnection ? pywal.foreground : Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.6))
                    open: root.activePopup === "bluetooth"
                    onClicked: root.togglePopup("bluetooth")
                }

                Loader {
                    id: volumeLoader
                    anchors.verticalCenter: parent.verticalCenter
                    asynchronous: true
                    source: "components/Volume.qml"

                    Connections {
                        target: volumeLoader.item
                        function onPanelRequested() { root.togglePopup("volume") }
                    }

                    Binding {
                        target: volumeLoader.item
                        property: "barWindow"
                        value: root.topWindow
                        when: volumeLoader.status === Loader.Ready && root.topWindow !== undefined
                        restoreMode: Binding.RestoreBinding
                    }
                }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 12
                radius: 0.5
                color: pywal.divider
            }

            Loader {
                id: batteryLoader
                anchors.verticalCenter: parent.verticalCenter
                asynchronous: true
                source: "components/Battery.qml"

                Binding {
                    target: batteryLoader.item
                    property: "controlCenter"
                    value: root.controlCenter
                    when: batteryLoader.status === Loader.Ready && root.controlCenter !== undefined
                }
            }

            Item {
                id: qsTrigger
                anchors.verticalCenter: parent.verticalCenter
                width: 24; height: 24
                activeFocusOnTab: true

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: pywal.foreground
                    opacity: qsTriggerHover.containsMouse ? 0.12 : 0
                    Behavior on opacity { NumberAnimation { duration: OneUIMotion.short3 } }
                }

                OneUIIcon {
                    anchors.centerIn: parent
                    name: "ic_qs_footer_settings"
                    size: 16
                    color: root.controlCenter?.shouldShow ? pywal.primary : (qsTriggerHover.containsMouse ? pywal.primary : pywal.foreground)
                    Behavior on color { ColorAnimation { duration: OneUIMotion.short2 } }
                }

                MouseArea {
                    id: qsTriggerHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.controlCenter)
                            root.controlCenter.shouldShow = !root.controlCenter.shouldShow
                    }
                    ToolTip.visible: containsMouse
                    ToolTip.delay: 450
                    ToolTip.text: "Quick Settings"
                }
            }
        }
    }

    Item {
        id: popupHost
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: barContainer.bottom
        anchors.topMargin: 4
        height: root.hasPopup ? popupContentWrapper.height + 8 : 0
        clip: false

        property bool mouseInside: popupHoverHandler.hovered
        property bool mouseHasEntered: false

        Behavior on height {
            NumberAnimation {
                duration: OneUIMotion.medium2
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
            visible: root.hasPopup
            onClicked: root.closePopup()
        }

        Item {
            id: popupContentWrapper
            y: 4
            x: {
                const w = width
                const hostPadding = 12
                const anchor = root.popupAnchorTarget()
                if (anchor) {
                    const centerInHost = anchor.mapToItem(popupHost, anchor.width / 2, 0).x
                    return Math.max(hostPadding, Math.min(popupHost.width - w - hostPadding, centerInHost - (w / 2)))
                }
                return Math.max(hostPadding, popupHost.width - w - hostPadding)
            }
            width: activePopup === "volume" ? 300 : activePopup === "network" ? 340 : activePopup === "wallpaper" ? 360 : activePopup === "emoji" || activePopup === "media" ? 380 : 320
            height: {
                if (btPanelLoader.active && btPanelLoader.item)
                    return btPanelLoader.item.implicitHeight
                if (netPanelLoader.active && netPanelLoader.item)
                    return netPanelLoader.item.implicitHeight
                if (wallpaperPanelLoader.active && wallpaperPanelLoader.item)
                    return wallpaperPanelLoader.item.implicitHeight
                if (mediaPanelLoader.active && mediaPanelLoader.item)
                    return mediaPanelLoader.item.implicitHeight
                if (volumePanelLoader.active && volumePanelLoader.item)
                    return volumePanelLoader.item.implicitHeight
                if (clipboardPanelLoader.active && clipboardPanelLoader.item)
                    return clipboardPanelLoader.item.implicitHeight
                if (emojiPanelLoader.active && emojiPanelLoader.item)
                    return emojiPanelLoader.item.implicitHeight
                return 0
            }

            scale: root.hasPopup ? 1.0 : 0.92
            opacity: root.hasPopup ? 1 : 0
            transformOrigin: Item.TopRight

            Behavior on scale {
                NumberAnimation {
                    duration: OneUIMotion.medium2
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.1
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: OneUIMotion.short4
                    easing.type: Easing.OutCubic
                }
            }

            HoverHandler {
                id: popupHoverHandler
                onHoveredChanged: {
                    if (hovered) {
                        popupHost.mouseHasEntered = true
                    }
                }
            }

            Loader {
                id: btPanelLoader
                anchors.fill: parent
                active: root.activePopup === "bluetooth"
                source: "components/BluetoothPanel.qml"
                onLoaded: {
                    item.shouldShow = true
                    item.forceActiveFocus()
                }
                Connections {
                    target: btPanelLoader.item
                    function onCloseRequested() { root.closePopup() }
                }
            }

            Loader {
                id: netPanelLoader
                anchors.fill: parent
                active: root.activePopup === "network"
                source: "components/NetworkPanel.qml"
                onLoaded: {
                    item.shouldShow = true
                    item.forceActiveFocus()
                }
                Connections {
                    target: netPanelLoader.item
                    function onCloseRequested() { root.closePopup() }
                }
            }

            Loader {
                id: wallpaperPanelLoader
                anchors.fill: parent
                active: root.activePopup === "wallpaper"
                source: "components/WallpaperPanel.qml"
                onLoaded: {
                    item.shouldShow = true
                }
                Connections {
                    target: wallpaperPanelLoader.item
                    function onCloseRequested() { root.closePopup() }
                }
            }

            Loader {
                id: mediaPanelLoader
                anchors.fill: parent
                active: root.activePopup === "media"
                source: "components/MediaPopupPanel.qml"
                onLoaded: {
                    item.shouldShow = true
                    item.forceActiveFocus()
                }
                Connections {
                    target: mediaPanelLoader.item
                    function onCloseRequested() { root.closePopup() }
                }
            }

            Loader {
                id: clipboardPanelLoader
                anchors.fill: parent
                active: root.activePopup === "clipboard"
                source: "components/ClipboardPanel.qml"
                onLoaded: {
                    item.shouldShow = true
                    item.forceActiveFocus()
                }
                Connections {
                    target: clipboardPanelLoader.item
                    function onCloseRequested() { root.closePopup() }
                }
            }

            Loader {
                id: volumePanelLoader
                anchors.fill: parent
                active: root.activePopup === "volume"
                source: "components/VolumePanel.qml"
                onLoaded: {
                    item.shouldShow = true
                    item.forceActiveFocus()
                }
                Connections {
                    target: volumePanelLoader.item
                    function onCloseRequested() { root.closePopup() }
                }
            }

            Loader {
                id: emojiPanelLoader
                anchors.fill: parent
                active: root.activePopup === "emoji"
                source: "components/EmojiPanel.qml"
                onLoaded: {
                    item.shouldShow = true
                    item.forceActiveFocus()
                }
                Connections {
                    target: emojiPanelLoader.item
                    function onCloseRequested() { root.closePopup() }
                }
            }
        }
    }
}
