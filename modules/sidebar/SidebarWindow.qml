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

    // Blur only while the panel is fully shown: the region is a fixed rect and would otherwise be
    // drawn before the panel has faded in (and stay after it has gone).
    BackgroundEffect.blurRegion: QsConfig.Appearance.blur && shouldShow && panel.opacity > 0.98 && Math.abs(panel.scale - 1) < 0.002 && Math.abs(panel.revealOffset) < 0.5 ? _blur : null
    Region { id: _blur; item: blurSurface; radius: blurSurface.radius }

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
        if (mins < 60) return `${mins} min left`
        const hours = Math.floor(mins / 60)
        const remMins = mins % 60
        return remMins > 0 ? `${hours} h ${remMins} min left` : `${hours} h left`
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
    exclusionMode: ExclusionMode.Ignore
    anchors {
        top: true
        left: true
    }
    margins {
        top: (config.bar.topBarHeight ?? 30) + 6
        left: config.sidebar.margin
    }
    implicitWidth: Math.round(config.sidebar.width * QsConfig.Config.uiScale)
    implicitHeight: shouldShow || panel.opacity > 0 ? Math.min(screen.height - margins.top - (config.bar.height ?? 48) - 18, Math.round(760 * QsConfig.Config.uiScale)) : 0
    visible: config.sidebar.enabled && (shouldShow || panel.opacity > 0)
    color: "transparent"

    // Overlay, so the click-outside dismiss layer (Top) stays beneath the panel
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shouldShow ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    FocusScope {
        id: panel
        // laid out at design size, scaled down as a whole (corner stays on the screen edge)
        anchors.top: parent.top
        anchors.left: parent.left
        width: parent.width / QsConfig.Config.uiScale
        height: parent.height / QsConfig.Config.uiScale
        property real revealOffset: shouldShow ? 0 : -18
        scale: (shouldShow ? 1.0 : 0.975) * QsConfig.Config.uiScale
        opacity: shouldShow ? 1.0 : 0.0
        focus: root.shouldShow
        transformOrigin: Item.TopLeft
        transform: Translate { y: panel.revealOffset }

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
            id: blurSurface
            anchors.fill: parent
            radius: QsConfig.Appearance.radius.l
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
                        radius: QsConfig.Appearance.radius.m
                        color: Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.14)

                        OneUIIcon {
                            anchors.centerIn: parent
                            name: root.notifs.dnd ? "ic_notifications_mute" : "ic_notification_bell"
                            size: 20
                            color: root.cPrimary
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "Notification Center"
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: QsConfig.Appearance.fontSize.xxl
                            font.weight: Font.Bold
                            color: root.cText
                        }

                        Text {
                            text: root.notifs.dnd
                                ? (root.notifs.dndUntil > 0
                                    ? `Do Not Disturb — ${root.dndRemainingLabel}`
                                    : "Do Not Disturb on")
                                : `${root.visibleNotifications.length} notification${root.visibleNotifications.length === 1 ? "" : "s"} in history`
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: QsConfig.Appearance.fontSize.s
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

                        OneUIIcon {
                            anchors.centerIn: parent
                            name: "ic_alarm"
                            size: 15
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

                    SettingsSwitch {
                        id: dndSwitch
                        checked: root.notifs.dnd
                        onToggled: checked => {
                            if (checked) {
                                root.notifs.dnd = true
                            } else {
                                root.notifs.disableDnd()
                            }
                            root.dndPresetsOpen = false
                        }
                    }
                    // SettingsSwitch flips itself on click, which detaches the
                    // `checked:` binding; keep it following the real DND state.
                    Binding { target: dndSwitch; property: "checked"; value: root.notifs.dnd }
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
                                { label: "1 hour", minutes: 60 },
                                { label: "3 hours", minutes: 180 },
                                { label: "Until evening", evening: true }
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
                                    font.pixelSize: QsConfig.Appearance.fontSize.xs
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

                        OneUIIcon {
                            name: "ic_search_24dp"
                            size: 13
                            color: root.cSubText
                        }

                        TextInput {
                            id: searchField
                            Layout.fillWidth: true
                            color: root.cText
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: QsConfig.Appearance.fontSize.m
                            clip: true
                            onTextChanged: root.searchQuery = text

                            Text {
                                text: "Search notifications..."
                                visible: searchField.text.length === 0
                                color: root.cSubText
                                font.pixelSize: QsConfig.Appearance.fontSize.m
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Text {
                            visible: searchField.text.length > 0
                            text: "✕"
                            font.pixelSize: QsConfig.Appearance.fontSize.s
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
                                text: "All"
                                font.family: QsConfig.Config.appearance.fontFamily
                                font.pixelSize: QsConfig.Appearance.fontSize.xs
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
                                    font.pixelSize: QsConfig.Appearance.fontSize.xs
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
                                font.pixelSize: QsConfig.Appearance.fontSize.s
                                font.weight: Font.Medium
                                color: root.cText
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: "Last 24h"
                                font.family: QsConfig.Config.appearance.fontFamily
                                font.pixelSize: QsConfig.Appearance.fontSize.s
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
                            font.pixelSize: QsConfig.Appearance.fontSize.s
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
                        radius: QsConfig.Appearance.radius.l
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
                                    radius: QsConfig.Appearance.radius.m
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
                                        font.pixelSize: QsConfig.Appearance.fontSize.xxl
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
                                        font.pixelSize: QsConfig.Appearance.fontSize.l
                                        font.weight: Font.DemiBold
                                        color: root.cText
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: card.modelData.appName || "Unknown app"
                                        font.family: QsConfig.Config.appearance.fontFamily
                                        font.pixelSize: QsConfig.Appearance.fontSize.s
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
                                        font.pixelSize: QsConfig.Appearance.fontSize.xs
                                        color: root.cSubText
                                    }
                                }
                            }

                            Text {
                                id: bodyText
                                Layout.fillWidth: true
                                text: card.modelData.body || ""
                                visible: text.length > 0
                                wrapMode: Text.WordWrap
                                maximumLineCount: card.expanded ? 40 : 2
                                elide: Text.ElideRight
                                font.family: QsConfig.Config.appearance.fontFamily
                                font.pixelSize: QsConfig.Appearance.fontSize.s
                                color: root.cSubText
                            }

                            NotifProgress {
                                Layout.fillWidth: true
                                value: card.modelData.progress ?? -1
                                color: root.cPrimary
                            }

                            // long text is cut after two lines: open / close it here (a click on the card does the same)
                            Text {
                                visible: card.expanded ? bodyText.lineCount > 2 : bodyText.truncated
                                text: card.expanded ? "Show less" : "Show more"
                                font.family: QsConfig.Config.appearance.fontFamily
                                font.pixelSize: QsConfig.Appearance.fontSize.s
                                font.weight: Font.DemiBold
                                color: root.cPrimary
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -6
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { card.expanded = !card.expanded; card.modelData.read = true }
                                }
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
                                            font.pixelSize: QsConfig.Appearance.fontSize.s
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
                                        font.pixelSize: QsConfig.Appearance.fontSize.xs
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
                                        font.pixelSize: QsConfig.Appearance.fontSize.xs
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

                        OneUIIcon {
                            Layout.alignment: Qt.AlignHCenter
                            name: "ic_notification_bell"
                            size: 46
                            color: Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.22)
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "No notifications right now"
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: QsConfig.Appearance.fontSize.l
                            font.weight: Font.Medium
                            color: root.cSubText
                        }
                    }
                }
            }
        }
    }
}