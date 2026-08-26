import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10 as QQC
import Quickshell
import Quickshell.Wayland
import "../../config" as QsConfig
import "../../services" as QsServices
import "../../components"

PanelWindow {
    id: root

    property bool shouldShow: false

    readonly property var config: QsConfig.Config
    readonly property var pywal: QsServices.Pywal
    readonly property var notifs: QsServices.Notifs
    readonly property color cSurface: pywal.surfaceContainerHighest
    readonly property color cSurfaceContainer: pywal.surfaceContainerHigh
    readonly property color cSurfaceContainerHigh: pywal.surfaceContainerHigh
    readonly property color cPrimary: pywal.primary
    readonly property color cText: pywal.foreground
    readonly property color cSubText: pywal.onSurfaceMuted
    readonly property color cBorder: pywal.outlineVariant
    readonly property var visibleNotifications: {
        let list = (notifs.recentNotifications ?? [])
        if (root.appFilter.length > 0) {
            list = list.filter(n => n.appName === root.appFilter)
        }
        if (root.searchQuery.length > 0) {
            const q = root.searchQuery.toLowerCase()
            list = list.filter(n =>
                (n.summary ?? "").toLowerCase().includes(q) ||
                (n.body ?? "").toLowerCase().includes(q) ||
                (n.appName ?? "").toLowerCase().includes(q)
            )
        }
        return list.slice(0, config.sidebar.maxHistory)
    }
    property string searchQuery: ""
    property string appFilter: ""

    // Distinct app names present in the last 24h of history, for filter chips
    readonly property var availableApps: {
        const seen = {}
        const out = []
        for (const n of (notifs.recentNotifications ?? [])) {
            const app = n.appName ?? "Unknown"
            if (!seen[app]) { seen[app] = true; out.push(app) }
        }
        return out
    }
    property bool dndPresetsOpen: false

    // Ticks once a minute so dndRemainingLabel stays fresh while the panel is open
    property double _clockTick: Date.now()
    Timer {
        interval: 30000
        running: root.notifs.dnd && root.notifs.dndUntil > 0
        repeat: true
        onTriggered: root._clockTick = Date.now()
    }

    readonly property string dndRemainingLabel: {
        void root._clockTick  // dependency for periodic refresh
        const msLeft = notifs.dndUntil - Date.now()
        if (msLeft <= 0) return ""
        const mins = Math.ceil(msLeft / 60000)
        if (mins < 60) return `${mins} dk kaldı`
        const hours = Math.floor(mins / 60)
        const remMins = mins % 60
        return remMins > 0 ? `${hours} sa ${remMins} dk kaldı` : `${hours} sa kaldı`
    }

    function closeSidebar() {
        shouldShow = false
    }

    function iconSourceFor(notification) {
        if (!notification?.appIcon)
            return ""
        if (notification.appIcon.startsWith("/") || notification.appIcon.startsWith("file://"))
            return notification.appIcon
        return "image://icon/" + notification.appIcon
    }

    function urgencyColor(notification) {
        if (notification?.urgency === 2)
            return pywal.error
        if (notification?.urgency === 0)
            return Qt.rgba(cText.r, cText.g, cText.b, 0.5)
        return cPrimary
    }

    onShouldShowChanged: {
        if (shouldShow) {
            notifs.markAllRead()
            Qt.callLater(() => panel.forceActiveFocus())
        }
    }

    screen: Quickshell.screens[0]
    anchors {
        top: true
        right: true
    }
    margins {
        top: (config.bar.height ?? 34) + config.sidebar.margin + 6
        right: config.sidebar.margin
    }
    implicitWidth: config.sidebar.width
    implicitHeight: shouldShow || panel.opacity > 0 ? Math.min(screen.height - margins.top - 18, 760) : 0
    visible: config.sidebar.enabled && (shouldShow || panel.opacity > 0)
    color: "transparent"

    WlrLayershell.keyboardFocus: shouldShow ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    FocusScope {
        id: panel
        anchors.fill: parent
        property real revealOffset: shouldShow ? 0 : 18
        scale: shouldShow ? 1.0 : 0.975
        opacity: shouldShow ? 1.0 : 0.0
        focus: root.shouldShow
        transform: Translate { x: panel.revealOffset }

        Keys.onEscapePressed: root.closeSidebar()

        Behavior on scale {
            NumberAnimation { duration: 220; easing.bezierCurve: [0.22, 1.0, 0.36, 1.0] }
        }

        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
        }

        Behavior on revealOffset {
            NumberAnimation { duration: 240; easing.bezierCurve: [0.05, 0.7, 0.1, 1.0] }
        }

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
                anchors.margins: 18
                spacing: 16

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 42
                        radius: 14
                        color: Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.14)

                        Text {
                            anchors.centerIn: parent
                            text: root.notifs.dnd ? "󰂛" : "󰂚"
                            font.family: "Material Design Icons"
                            font.pixelSize: 20
                            color: root.cPrimary
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "Notification Center"
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: 16
                            font.weight: Font.Bold
                            color: root.cText
                        }

                        Text {
                            text: root.notifs.dnd
                                ? (root.notifs.dndUntil > 0
                                    ? `Rahatsız Etme — ${root.dndRemainingLabel}`
                                    : "Rahatsız Etme açık")
                                : `${root.visibleNotifications.length} notification${root.visibleNotifications.length === 1 ? "" : "s"} in history`
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: 11
                            color: root.cSubText
                        }
                    }

                    // Timed DND presets toggle
                    Rectangle {
                        Layout.preferredWidth: 30
                        Layout.preferredHeight: 30
                        radius: 15
                        color: dndTimerHover.containsMouse || root.dndPresetsOpen
                            ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.15) : "transparent"

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: "󰅐"
                            font.family: "Material Design Icons"
                            font.pixelSize: 15
                            color: root.dndPresetsOpen ? root.cPrimary : root.cSubText
                        }

                        MouseArea {
                            id: dndTimerHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.dndPresetsOpen = !root.dndPresetsOpen
                        }
                    }

                    QQC.Switch {
                        id: dndSwitch
                        checked: root.notifs.dnd
                        onToggled: {
                            if (checked) {
                                root.notifs.dnd = true
                            } else {
                                root.notifs.disableDnd()
                            }
                            root.dndPresetsOpen = false
                        }
                    }
                }

                // Timed DND presets — collapsible row
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.dndPresetsOpen ? 40 : 0
                    clip: true
                    color: "transparent"

                    Behavior on Layout.preferredHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                    RowLayout {
                        anchors.fill: parent
                        spacing: 8

                        Repeater {
                            model: [
                                { label: "1 saat", minutes: 60 },
                                { label: "3 saat", minutes: 180 },
                                { label: "Akşama kadar", evening: true }
                            ]

                            Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: 30
                                radius: 15
                                color: presetHover.containsMouse
                                    ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.18)
                                    : Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.06)

                                Behavior on color { ColorAnimation { duration: 100 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    font.family: QsConfig.Config.appearance.fontFamily
                                    font.pixelSize: 10
                                    color: root.cText
                                }

                                MouseArea {
                                    id: presetHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (modelData.evening) root.notifs.enableDndUntilEvening()
                                        else root.notifs.enableDndFor(modelData.minutes)
                                        root.dndPresetsOpen = false
                                    }
                                }
                            }
                        }
                    }
                }

                // Search field
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    radius: 17
                    color: root.cSurfaceContainer

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        Text {
                            text: "󰍉"
                            font.family: "Material Design Icons"
                            font.pixelSize: 13
                            color: root.cSubText
                        }

                        TextInput {
                            id: searchField
                            Layout.fillWidth: true
                            color: root.cText
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: 12
                            clip: true
                            onTextChanged: root.searchQuery = text

                            Text {
                                text: "Bildirimlerde ara..."
                                visible: searchField.text.length === 0
                                color: root.cSubText
                                font.pixelSize: 12
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Text {
                            visible: searchField.text.length > 0
                            text: "✕"
                            font.pixelSize: 11
                            color: root.cSubText

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -6
                                cursorShape: Qt.PointingHandCursor
                                onClicked: searchField.text = ""
                            }
                        }
                    }
                }

                // App filter chips
                Flickable {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.availableApps.length > 1 ? 30 : 0
                    visible: root.availableApps.length > 1
                    contentWidth: chipsRow.implicitWidth
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Row {
                        id: chipsRow
                        spacing: 6
                        height: parent.height

                        Rectangle {
                            width: allChipText.implicitWidth + 18
                            height: 26
                            radius: 13
                            anchors.verticalCenter: parent.verticalCenter
                            color: root.appFilter === ""
                                ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.2)
                                : root.cSurfaceContainer

                            Text {
                                id: allChipText
                                anchors.centerIn: parent
                                text: "Tümü"
                                font.family: QsConfig.Config.appearance.fontFamily
                                font.pixelSize: 10
                                color: root.appFilter === "" ? root.cPrimary : root.cSubText
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.appFilter = ""
                            }
                        }

                        Repeater {
                            model: root.availableApps

                            Rectangle {
                                required property string modelData
                                width: chipText.implicitWidth + 18
                                height: 26
                                radius: 13
                                anchors.verticalCenter: parent.verticalCenter
                                color: root.appFilter === modelData
                                    ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.2)
                                    : root.cSurfaceContainer

                                Behavior on color { ColorAnimation { duration: 100 } }

                                Text {
                                    id: chipText
                                    anchors.centerIn: parent
                                    text: modelData
                                    font.family: QsConfig.Config.appearance.fontFamily
                                    font.pixelSize: 10
                                    color: root.appFilter === modelData ? root.cPrimary : root.cSubText
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.appFilter = (root.appFilter === modelData ? "" : modelData)
                                }
                            }
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
                        color: root.cSurfaceContainer

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10

                            Text {
                                text: root.notifs.unreadCount > 0 ? `${root.notifs.unreadCount} unread` : "All caught up"
                                font.family: QsConfig.Config.appearance.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: root.cText
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: "Last 24h"
                                font.family: QsConfig.Config.appearance.fontFamily
                                font.pixelSize: 11
                                color: root.cSubText
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: clearText.implicitWidth + 20
                        Layout.preferredHeight: 34
                        radius: 17
                        color: clearMouse.containsMouse ? root.cSurfaceContainerHigh : root.cSurfaceContainer
                        visible: root.visibleNotifications.length > 0

                        Text {
                            id: clearText
                            anchors.centerIn: parent
                            text: "Clear"
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: root.cText
                        }

                        MouseArea {
                            id: clearMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.notifs.clearAll()
                        }
                    }
                }

                ListView {
                    id: listView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 10
                    model: root.visibleNotifications

                    delegate: Rectangle {
                        id: card
                        required property var modelData
                        required property int index
                        property bool expanded: false

                        width: listView.width
                        height: content.implicitHeight + 22
                        radius: 20
                        color: cardMouse.containsMouse ? root.cSurfaceContainerHigh : root.cSurfaceContainer
                        opacity: modelData.closed ? 0.55 : 1.0
                        border.width: modelData.closed ? 0 : (modelData.read ? 1 : 1.25)
                        border.color: modelData.read
                            ? Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.05)
                            : Qt.rgba(root.urgencyColor(modelData).r, root.urgencyColor(modelData).g, root.urgencyColor(modelData).b, 0.32)

                        Behavior on opacity { NumberAnimation { duration: 150 } }
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        MouseArea {
                            id: cardMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                card.expanded = !card.expanded
                                card.modelData.read = true
                            }
                        }

                        ColumnLayout {
                            id: content
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 10

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                Rectangle {
                                    Layout.preferredWidth: 40
                                    Layout.preferredHeight: 40
                                    radius: 14
                                    color: Qt.rgba(root.urgencyColor(card.modelData).r, root.urgencyColor(card.modelData).g, root.urgencyColor(card.modelData).b, 0.12)

                                    Image {
                                        anchors.centerIn: parent
                                        width: 22
                                        height: 22
                                        source: root.iconSourceFor(card.modelData)
                                        visible: status === Image.Ready
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        visible: !parent.children[0].visible
                                        text: (card.modelData.appName ?? "N").slice(0, 1).toUpperCase()
                                        font.family: QsConfig.Config.appearance.fontFamily
                                        font.pixelSize: 16
                                        font.weight: Font.Bold
                                        color: root.urgencyColor(card.modelData)
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        Layout.fillWidth: true
                                        text: card.modelData.summary || "Notification"
                                        font.family: QsConfig.Config.appearance.fontFamily
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                        color: root.cText
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: card.modelData.appName || "Unknown app"
                                        font.family: QsConfig.Config.appearance.fontFamily
                                        font.pixelSize: 11
                                        color: root.cSubText
                                        elide: Text.ElideRight
                                    }
                                }

                                ColumnLayout {
                                    spacing: 4

                                    Rectangle {
                                        Layout.alignment: Qt.AlignRight
                                        width: 8
                                        height: 8
                                        radius: 4
                                        visible: !card.modelData.read
                                        color: root.cPrimary
                                    }

                                    Text {
                                        Layout.alignment: Qt.AlignRight
                                        text: card.modelData.timeString
                                        font.family: QsConfig.Config.appearance.fontFamily
                                        font.pixelSize: 10
                                        color: root.cSubText
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: card.modelData.body || ""
                                visible: text.length > 0
                                wrapMode: Text.WordWrap
                                maximumLineCount: card.expanded ? 8 : 2
                                elide: Text.ElideRight
                                font.family: QsConfig.Config.appearance.fontFamily
                                font.pixelSize: 11
                                color: root.cSubText
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                visible: card.expanded && ((card.modelData.actions?.length ?? 0) > 0)

                                Repeater {
                                    model: card.modelData.actions ?? []

                                    Rectangle {
                                        required property var modelData
                                        Layout.preferredHeight: 30
                                        Layout.preferredWidth: Math.min(140, label.implicitWidth + 18)
                                        radius: 15
                                        color: actionMouse.containsMouse
                                            ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.18)
                                            : Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.12)

                                        Text {
                                            id: label
                                            anchors.centerIn: parent
                                            text: modelData.text
                                            font.family: QsConfig.Config.appearance.fontFamily
                                            font.pixelSize: 11
                                            font.weight: Font.Medium
                                            color: root.cPrimary
                                        }

                                        MouseArea {
                                            id: actionMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                card.modelData.read = true
                                                modelData.invoke()
                                            }
                                        }
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    Layout.preferredWidth: 78
                                    Layout.preferredHeight: 28
                                    radius: 14
                                    color: closeMouse.containsMouse
                                        ? Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.12)
                                        : Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.06)

                                    Text {
                                        anchors.centerIn: parent
                                        text: card.modelData.closed ? "Dismissed" : "Dismiss"
                                        font.family: QsConfig.Config.appearance.fontFamily
                                        font.pixelSize: 10
                                        color: root.cText
                                    }

                                    MouseArea {
                                        id: closeMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            card.modelData.read = true
                                            card.modelData.close()
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.preferredWidth: 70
                                    Layout.preferredHeight: 28
                                    radius: 14
                                    color: deleteMouse.containsMouse
                                        ? Qt.rgba(pywal.error.r, pywal.error.g, pywal.error.b, 0.16)
                                        : Qt.rgba(pywal.error.r, pywal.error.g, pywal.error.b, 0.10)

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Delete"
                                        font.family: QsConfig.Config.appearance.fontFamily
                                        font.pixelSize: 10
                                        color: pywal.error
                                    }

                                    MouseArea {
                                        id: deleteMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.notifs.deleteNotification(card.modelData)
                                    }
                                }
                            }
                        }
                    }

                    footer: Item {
                        width: listView.width
                        height: 10
                    }

                    QQC.ScrollBar.vertical: QQC.ScrollBar {
                        policy: QQC.ScrollBar.AsNeeded
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        visible: root.visibleNotifications.length === 0

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "󰂜"
                            font.family: "Material Design Icons"
                            font.pixelSize: 46
                            color: Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.22)
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "No notifications right now"
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: root.cSubText
                        }
                    }
                }
            }
        }
    }
}