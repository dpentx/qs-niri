import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland
import "../../../services" as QsServices
import "../../../config" as QsConfig
import "../../../components"

// ═════════════════════════════════════════════════════════════════════════════════
// One UI Notification Popups — Revamped
// ═════════════════════════════════════════════════════════════════════════════════
PanelWindow {
    id: root

    readonly property var pywal: QsServices.Pywal
    readonly property var notifs: QsServices.Notifs
    readonly property var logger: QsServices.Logger
    readonly property var config: QsConfig.Config

    // ── Color Tokens (semantic, from Pywal) ──
    readonly property color m3Surface: pywal.notificationSurface
    readonly property color m3SurfaceContainer: pywal.surfaceContainer
    readonly property color m3SurfaceContainerHigh: pywal.surfaceContainerHigh
    readonly property color m3Primary: pywal.primary
    readonly property color m3OnSurface: pywal.foreground
    readonly property color m3OnSurfaceVariant: Qt.rgba(m3OnSurface.r, m3OnSurface.g, m3OnSurface.b, 0.55)
    readonly property color m3Error: pywal.error
    readonly property color m3Warning: pywal.warning
    readonly property color m3Success: pywal.success
    readonly property color m3Border: Qt.rgba(m3OnSurface.r, m3OnSurface.g, m3OnSurface.b, 0.06)

    // Swipe dismiss threshold (fraction of popup width)
    readonly property real swipeThreshold: 0.30

    function _urgencyColor(u) {
        if (u === NotificationUrgency.Critical) return m3Error
        if (u === NotificationUrgency.Low) return m3OnSurfaceVariant
        return m3Primary
    }

    // Active popups — newest first, capped to maxVisible
    readonly property var activePopups: (notifs.notifications || [])
        .filter(n => !!n && !n.closed)
        .slice(0, config.notifications.maxVisible)

    // ── Window Setup ──
    screen: Quickshell.screens[0]
    anchors { top: true; right: true }
    
    // Stay visible over fullscreen apps/games — see BarWrapper.qml for the
    // full explanation of Top vs Overlay layer-shell layers. Notifications
    // in particular shouldn't be silently swallowed by a fullscreen window.
    WlrLayershell.layer: WlrLayer.Overlay
    margins { top: config.notifications.margin; right: config.notifications.margin }
    visible: activePopups.length > 0
    color: "transparent"
    implicitWidth: config.notifications.popupWidth
    implicitHeight: notifColumn.implicitHeight

    Behavior on implicitHeight {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    // ══════════════════════════════════════════════════
    // NOTIFICATION STACK
    // ══════════════════════════════════════════════════
    // Compositor blur behind the toast stack (ext-background-effect-v1)
    BackgroundEffect.blurRegion: QsConfig.Appearance.blur ? _toastBlur : null
    Region { id: _toastBlur; item: notifColumn; radius: QsConfig.Appearance.radius.l }

    Column {
        id: notifColumn
        width: parent.width
        spacing: config.notifications.spacing

        move: Transition {
            NumberAnimation {
                properties: "y"
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        Repeater {
            model: root.activePopups

            // ─────────────────────────────────────────────────────
            // NOTIFICATION CARD
            // ─────────────────────────────────────────────────────
            Item {
                id: notifCard

                required property var modelData
                required property int index

                width: config.notifications.popupWidth
                height: cardWrapper.height
                clip: true

                // ── State ──
                property bool isVisible: true
                property bool isHovered: false
                property bool isDragging: false
                property bool isExpanded: false
                property real dragX: 0
                property real timeoutProgress: 1.0

                // ── Entrance animation properties ──
                property real entryScale: 0.82
                property real entryY: -24
                property real entryOpacity: 0
                property real entryRotation: 0

                Component.onCompleted: {
                    if (!modelData.hasAnimated) {
                        modelData.hasAnimated = true
                        entranceAnim.start()
                    } else {
                        entryScale = 1.0
                        entryY = 0
                        entryOpacity = 1.0
                    }
                }

                // ── Entrance: spring drop-in from above ──
                SequentialAnimation {
                    id: entranceAnim

                    PauseAnimation { duration: notifCard.index * 35 }

                    ParallelAnimation {
                        NumberAnimation {
                            target: notifCard; property: "entryOpacity"
                            from: 0; to: 1.0
                            duration: 100; easing.type: Easing.OutQuad
                        }
                        NumberAnimation {
                            target: notifCard; property: "entryScale"
                            from: 0.82; to: 1.0
                            duration: 380
                            easing.type: Easing.OutBack; easing.overshoot: 1.6
                        }
                        NumberAnimation {
                            target: notifCard; property: "entryY"
                            from: -28; to: 0
                            duration: 380
                            easing.type: Easing.OutBack; easing.overshoot: 1.2
                        }
                    }
                }

                // ── Exit: swipe right ──
                SequentialAnimation {
                    id: exitRight

                    ParallelAnimation {
                        NumberAnimation {
                            target: notifCard; property: "dragX"
                            to: config.notifications.popupWidth + 60
                            duration: 180; easing.type: Easing.InCubic
                        }
                        NumberAnimation {
                            target: notifCard; property: "entryRotation"
                            to: 4; duration: 180; easing.type: Easing.InQuad
                        }
                        NumberAnimation {
                            target: notifCard; property: "entryOpacity"
                            to: 0.3; duration: 180; easing.type: Easing.InQuad
                        }
                    }
                    NumberAnimation {
                        target: notifCard; property: "height"
                        to: 0; duration: 120; easing.type: Easing.InCubic
                    }
                    ScriptAction { script: modelData.close() }
                }

                // ── Exit: swipe left ──
                SequentialAnimation {
                    id: exitLeft

                    ParallelAnimation {
                        NumberAnimation {
                            target: notifCard; property: "dragX"
                            to: -(config.notifications.popupWidth + 60)
                            duration: 180; easing.type: Easing.InCubic
                        }
                        NumberAnimation {
                            target: notifCard; property: "entryRotation"
                            to: -4; duration: 180; easing.type: Easing.InQuad
                        }
                        NumberAnimation {
                            target: notifCard; property: "entryOpacity"
                            to: 0.3; duration: 180; easing.type: Easing.InQuad
                        }
                    }
                    NumberAnimation {
                        target: notifCard; property: "height"
                        to: 0; duration: 120; easing.type: Easing.InCubic
                    }
                    ScriptAction { script: modelData.close() }
                }

                // ── Snap back (spring) ──
                ParallelAnimation {
                    id: snapBack

                    NumberAnimation {
                        target: notifCard; property: "dragX"
                        to: 0; duration: 280
                        easing.type: Easing.OutBack; easing.overshoot: 1.3
                    }
                    NumberAnimation {
                        target: notifCard; property: "entryRotation"
                        to: 0; duration: 200; easing.type: Easing.OutCubic
                    }
                }

                // ── Standard dismiss (scale + fade) ──
                SequentialAnimation {
                    id: dismissAnim

                    ParallelAnimation {
                        NumberAnimation {
                            target: notifCard; property: "entryScale"
                            to: 0.88; duration: 160; easing.type: Easing.InCubic
                        }
                        NumberAnimation {
                            target: notifCard; property: "entryOpacity"
                            to: 0; duration: 160; easing.type: Easing.InQuad
                        }
                    }
                    NumberAnimation {
                        target: notifCard; property: "height"
                        to: 0; duration: 100; easing.type: Easing.InCubic
                    }
                    ScriptAction { script: modelData.close() }
                }

                function dismiss() {
                    isVisible = false
                    dismissAnim.start()
                }

                function swipeDismiss(direction) {
                    isVisible = false
                    if (direction > 0) exitRight.start()
                    else exitLeft.start()
                }

                // ──────────────────────────────────────────────
                // CARD WRAPPER (holds swipe transforms)
                // ──────────────────────────────────────────────────
                Item {
                    id: cardWrapper
                    width: parent.width
                    height: cardBg.height
                    x: notifCard.dragX
                    scale: notifCard.entryScale
                    opacity: notifCard.entryOpacity
                    transformOrigin: Item.Top

                    // Physics-feel rotation during drag
                    rotation: notifCard.entryRotation +
                              (notifCard.isDragging ? notifCard.dragX * 0.015 : 0)

                    transform: Translate { y: notifCard.entryY }

                    // ── Swipe indicator (behind card) ──
                    Rectangle {
                        anchors.fill: cardBg
                        radius: cardBg.radius
                        visible: Math.abs(notifCard.dragX) > 20
                        opacity: Math.min(0.85,
                            Math.abs(notifCard.dragX) /
                            (config.notifications.popupWidth * root.swipeThreshold * 1.5))

                        color: notifCard.dragX > 0
                            ? Qt.rgba(root.m3Error.r, root.m3Error.g, root.m3Error.b, 0.06)
                            : Qt.rgba(root.m3Primary.r, root.m3Primary.g, root.m3Primary.b, 0.06)

                        OneUIIcon {
                            anchors.centerIn: parent
                            name: notifCard.dragX > 0 ? "ic_close" : "ic_notifications_mute"
                            size: 26
                            color: notifCard.dragX > 0 ? root.m3Error : root.m3Primary
                            opacity: 0.55
                        }
                    }

                    // ════════════════════════════════════════════════
                    // CARD BACKGROUND
                    // ════════════════════════════════════════════════
                    Rectangle {
                        id: cardBg
                        width: parent.width
                        height: contentCol.implicitHeight + 34
                        radius: QsConfig.Appearance.radius.l
                        color: root.m3Surface

                        // OneUI notification cards are flat — no colored
                        // hover/urgency border. The existing hover-glow
                        // overlay and urgency-tint layers below already
                        // carry that signal without a OneUI-style
                        // "state layer" border.
                        border.width: 0

                        // Elevation shadow — lifts on hover
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: Qt.rgba(0, 0, 0,
                                notifCard.isHovered ? 0.28 : 0.16)
                            shadowBlur: notifCard.isHovered ? 0.9 : 0.55
                            shadowVerticalOffset: notifCard.isHovered ? 8 : 4
                        }

                        // ── Top accent stripe (urgency indicator) ──
                        Rectangle {
                            anchors {
                                top: parent.top
                                left: parent.left
                                right: parent.right
                                topMargin: 1
                                leftMargin: 20
                                rightMargin: 20
                            }
                            height: 2.5
                            radius: 1.25
                            color: root._urgencyColor(modelData.urgency)
                            opacity: modelData.urgency === NotificationUrgency.Low ? 0.3 : 0.65

                            // Gentle pulse for critical
                            SequentialAnimation on opacity {
                                running: modelData.urgency === NotificationUrgency.Critical
                                loops: Animation.Infinite
                                NumberAnimation {
                                    to: 0.3; duration: 1000
                                    easing.type: Easing.InOutSine
                                }
                                NumberAnimation {
                                    to: 0.9; duration: 1000
                                    easing.type: Easing.InOutSine
                                }
                            }
                        }

                        // ── Hover glow overlay ──
                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: root.m3OnSurface
                            opacity: notifCard.isHovered && !notifCard.isDragging ? 0.035 : 0

                            Behavior on opacity {
                                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                            }
                        }

                        // ── Urgency tint (low / critical only) ──
                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            z: -1
                            visible: modelData.urgency !== NotificationUrgency.Normal
                            color: {
                                const c = root._urgencyColor(modelData.urgency)
                                if (modelData.urgency === NotificationUrgency.Critical)
                                    return Qt.rgba(c.r, c.g, c.b, 0.08)
                                return Qt.rgba(c.r, c.g, c.b, 0.04)
                            }
                        }

                        // ── Progress bar (bottom sweep) ──
                        Rectangle {
                            id: progressTrack
                            anchors {
                                bottom: parent.bottom
                                left: parent.left
                                right: parent.right
                                bottomMargin: 7
                                leftMargin: 18
                                rightMargin: 18
                            }
                            height: 2
                            radius: 1
                            color: Qt.rgba(root.m3OnSurface.r, root.m3OnSurface.g,
                                           root.m3OnSurface.b, 0.04)
                            visible: notifCard.isVisible && !notifCard.isHovered
                            clip: true

                            Rectangle {
                                anchors {
                                    left: parent.left
                                    top: parent.top
                                    bottom: parent.bottom
                                }
                                width: progressTrack.width * notifCard.timeoutProgress
                                radius: parent.radius
                                color: {
                                    const c = root._urgencyColor(modelData.urgency)
                                    return Qt.rgba(c.r, c.g, c.b, 0.45)
                                }

                                NumberAnimation {
                                    id: progressAnim
                                    target: notifCard
                                    property: "timeoutProgress"
                                    from: 1.0; to: 0
                                    duration: config.notifications.timeoutMs
                                    running: notifCard.isVisible
                                    onFinished: if (notifCard.isVisible) notifCard.dismiss()
                                }
                            }
                        }

                        // Pause progress on hover / drag
                        Connections {
                            target: notifCard
                            function onIsHoveredChanged() {
                                if (progressAnim.running)
                                    progressAnim.paused = notifCard.isHovered || notifCard.isDragging
                            }
                            function onIsDraggingChanged() {
                                if (progressAnim.running)
                                    progressAnim.paused = notifCard.isHovered || notifCard.isDragging
                            }
                        }

                        // ════════════════════════════════════════════
                        // GESTURE AREA
                        // ════════════════════════════════════════════
                        MouseArea {
                            id: gestureArea
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton

                            property real startX: 0
                            property bool gestureStarted: false
                            property real scrollAccum: 0
                            property bool isScrolling: false

                            onEntered: notifCard.isHovered = true
                            onExited: {
                                if (!pressed && !isScrolling)
                                    notifCard.isHovered = false
                            }

                            // ── Two-finger swipe (trackpad) ──
                            onWheel: wheel => {
                                if (Math.abs(wheel.angleDelta.x) > Math.abs(wheel.angleDelta.y)) {
                                    wheel.accepted = true
                                    scrollAccum += wheel.angleDelta.x * 0.5
                                    notifCard.dragX = scrollAccum
                                    isScrolling = true
                                    notifCard.isDragging = true
                                    scrollTimer.restart()

                                    const thresh = config.notifications.popupWidth * root.swipeThreshold
                                    if (Math.abs(scrollAccum) > thresh) {
                                        scrollTimer.stop()
                                        isScrolling = false
                                        notifCard.swipeDismiss(scrollAccum)
                                        scrollAccum = 0
                                    }
                                }
                            }

                            Timer {
                                id: scrollTimer
                                interval: 300
                                onTriggered: {
                                    gestureArea.isScrolling = false
                                    notifCard.isDragging = false
                                    const thresh = config.notifications.popupWidth * root.swipeThreshold
                                    if (Math.abs(gestureArea.scrollAccum) > thresh)
                                        notifCard.swipeDismiss(gestureArea.scrollAccum)
                                    else
                                        snapBack.start()
                                    gestureArea.scrollAccum = 0
                                }
                            }

                            // ── Drag gesture ──
                            onPressed: mouse => {
                                startX = mouse.x
                                gestureStarted = false
                                notifCard.isDragging = false
                                scrollAccum = 0
                            }

                            onPositionChanged: mouse => {
                                if (!pressed) return
                                const dx = mouse.x - startX
                                if (!gestureStarted && Math.abs(dx) > 10) {
                                    gestureStarted = true
                                    notifCard.isDragging = true
                                }
                                if (notifCard.isDragging)
                                    notifCard.dragX = dx * 0.8
                            }

                            onReleased: mouse => {
                                notifCard.isDragging = false
                                if (!containsMouse) notifCard.isHovered = false
                                const thresh = config.notifications.popupWidth * root.swipeThreshold
                                if (Math.abs(notifCard.dragX) > thresh)
                                    notifCard.swipeDismiss(notifCard.dragX)
                                else
                                    snapBack.start()
                            }

                            onClicked: mouse => {
                                if (mouse.button === Qt.MiddleButton) {
                                    notifCard.dismiss()
                                } else if (!gestureStarted) {
                                    // Single action → invoke; else toggle expand
                                    if (modelData.actions && modelData.actions.length === 1) {
                                        modelData.actions[0].invoke()
                                        notifCard.dismiss()
                                    } else {
                                        notifCard.isExpanded = !notifCard.isExpanded
                                    }
                                }
                            }
                        }

                        // ════════════════════════════════════════════
                        // CONTENT LAYOUT
                        // ════════════════════════════════════════════
                        ColumnLayout {
                            id: contentCol
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: 16
                                topMargin: 18
                            }
                            spacing: 6

                            // ── Header: round icon | title + time / body | chevron ──
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                Rectangle {
                                    Layout.preferredWidth: 40
                                    Layout.preferredHeight: 40
                                    Layout.alignment: Qt.AlignTop
                                    radius: 20
                                    color: Qt.rgba(root._urgencyColor(modelData.urgency).r,
                                                   root._urgencyColor(modelData.urgency).g,
                                                   root._urgencyColor(modelData.urgency).b, 0.16)

                                    Image {
                                        anchors.centerIn: parent
                                        width: 22; height: 22
                                        visible: modelData.appIcon && modelData.appIcon.length > 0
                                        source: {
                                            if (!modelData.appIcon) return ""
                                            if (modelData.appIcon.startsWith("/") ||
                                                modelData.appIcon.startsWith("file://"))
                                                return modelData.appIcon
                                            return "image://icon/" + modelData.appIcon
                                        }
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true; cache: true; asynchronous: true
                                        onStatusChanged: {
                                            if (status === Image.Error)
                                                parent.visible = false
                                        }
                                    }

                                    OneUIIcon {
                                        anchors.centerIn: parent
                                        visible: !modelData.appIcon || modelData.appIcon.length === 0
                                        name: "ic_notification_bell"
                                        size: 18
                                        color: root._urgencyColor(modelData.urgency)
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.summary || modelData.appName || "Notification"
                                            font.pixelSize: QsConfig.Appearance.fontSize.l
                                            font.weight: Font.Bold
                                            font.family: "OneUI Sans"
                                            color: root.m3OnSurface
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            text: modelData.timeString || "now"
                                            font.pixelSize: QsConfig.Appearance.fontSize.xxs
                                            font.family: "OneUI Sans"
                                            color: root.m3OnSurfaceVariant
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.body || ""
                                        font.pixelSize: QsConfig.Appearance.fontSize.m
                                        font.family: "OneUI Sans"
                                        color: root.m3OnSurfaceVariant
                                        wrapMode: Text.Wrap
                                        maximumLineCount: notifCard.isExpanded ? 12 : 2
                                        elide: Text.ElideRight
                                        lineHeight: 1.3
                                        visible: text.length > 0
                                    }
                                }

                                // Chevron toggles expand (Android heads-up style)
                                Item {
                                    Layout.preferredWidth: 28
                                    Layout.preferredHeight: 28
                                    Layout.alignment: Qt.AlignTop

                                    OneUIIcon {
                                        anchors.centerIn: parent
                                        name: "ic_chevron_right"
                                        size: 16
                                        color: root.m3OnSurfaceVariant
                                        rotation: notifCard.isExpanded ? -90 : 90
                                        Behavior on rotation {
                                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: mouse => {
                                            mouse.accepted = true
                                            notifCard.isExpanded = !notifCard.isExpanded
                                        }
                                    }
                                }
                            }

                            // ── Image preview ──
                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 100
                                Layout.topMargin: 4
                                visible: modelData.image && modelData.image.length > 0

                                Rectangle {
                                    anchors.fill: parent
                                    radius: QsConfig.Appearance.radius.m
                                    clip: true
                                    color: root.m3SurfaceContainer

                                    Image {
                                        anchors.fill: parent
                                        anchors.margins: 1
                                        source: {
                                            if (!modelData.image) return ""
                                            if (modelData.image.startsWith("/") ||
                                                modelData.image.startsWith("file://"))
                                                return modelData.image
                                            return "image://icon/" + modelData.image
                                        }
                                        fillMode: Image.PreserveAspectCrop
                                        smooth: true; cache: true; asynchronous: true

                                        layer.enabled: true
                                        layer.effect: MultiEffect {
                                            maskEnabled: true
                                            maskThresholdMin: 0.5
                                            maskSpreadAtMin: 1.0
                                            maskSource: ShaderEffectSource {
                                                sourceItem: Rectangle {
                                                    width: 1; height: 1; radius: 11
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // ── Action row: text-only buttons, thin dividers ──
                            RowLayout {
                                id: actionsRow
                                Layout.fillWidth: true
                                Layout.topMargin: 4
                                spacing: 0
                                visible: modelData.actions && modelData.actions.length > 0

                                Repeater {
                                    id: actionsRepeater
                                    property var notifCardRef: notifCard
                                    model: notifCard.modelData.actions || []

                                    RowLayout {
                                        required property var modelData
                                        required property int index
                                        spacing: 0
                                        Layout.fillWidth: true

                                        Rectangle {
                                            visible: index > 0
                                            Layout.preferredWidth: 1
                                            Layout.preferredHeight: 16
                                            color: Qt.rgba(root.m3OnSurface.r, root.m3OnSurface.g,
                                                           root.m3OnSurface.b, 0.18)
                                        }

                                        Item {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 32

                                            Text {
                                                anchors.centerIn: parent
                                                width: parent.width - 8
                                                horizontalAlignment: Text.AlignHCenter
                                                elide: Text.ElideRight
                                                text: modelData.text || modelData.identifier
                                                font.pixelSize: QsConfig.Appearance.fontSize.m
                                                font.weight: Font.Medium
                                                font.family: "OneUI Sans"
                                                color: root.m3Primary
                                                opacity: actMA.pressed ? 0.6 : 1
                                            }

                                            MouseArea {
                                                id: actMA
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    modelData.invoke()
                                                    actionsRepeater.notifCardRef.dismiss()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
