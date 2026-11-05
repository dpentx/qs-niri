import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import Quickshell.Wayland
import "../../config" as QsConfig
import "../../services" as QsServices
import "../../components"
import "../../components/effects"

// Window switcher. Bind Alt+Tab to `touch /tmp/qs-alttab` in the niri config: the first press opens it on the
// previous window, further presses (Shift+Alt+Tab: back) step on, releasing Alt switches. Enter / click also
// switch, Esc cancels. Most recently used first.
// shortcut: if the Alt release is missed (it happened before the keyboard focus arrived) the choice is taken
// after 2.5 s without a key press.
PanelWindow {
    id: root

    BackgroundEffect.blurRegion: QsConfig.Appearance.blur && shouldShow && card.opacity > 0.98 ? _blur : null
    Region { id: _blur; item: card; radius: card.radius }

    property bool shouldShow: false
    property var items: []
    property int sel: 0
    readonly property var pywal: QsServices.Pywal

    visible: shouldShow || card.opacity > 0
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shouldShow ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell:alttab"
    anchors { top: true; bottom: true; left: true; right: true }
    mask: Region { item: card }     // only the card takes input; the rest of the screen stays usable

    function open() {
        if (shouldShow) { step(1); return }
        items = QsServices.Windows.list.slice().sort((a, b) => b.focusTs - a.focusTs)
        if (items.length === 0) return
        sel = items.length > 1 ? 1 : 0
        shouldShow = true
        idle.restart()
    }
    function step(d) { if (items.length) { sel = (sel + d + items.length) % items.length; idle.restart() } }
    function commit() {
        const w = items[sel]
        shouldShow = false
        idle.stop()
        if (w) QsServices.Windows.focus(w.id)
    }
    function cancel() { shouldShow = false; idle.stop() }

    Timer { id: idle; interval: 2500; onTriggered: root.commit() }

    Rectangle {
        id: card
        anchors.centerIn: parent
        radius: QsConfig.Appearance.radius.xl
        color: root.pywal.surfaceContainerHighest
        width: Math.min(root.width - 80, row.implicitWidth + 40)
        height: row.implicitHeight + 40
        opacity: root.shouldShow ? 1 : 0
        scale: root.shouldShow ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: OneUIMotion.short3; easing.type: Easing.OutQuad } }
        Behavior on scale { NumberAnimation { duration: OneUIMotion.medium1; easing.bezierCurve: OneUIMotion.samsungEnter } }

        focus: root.shouldShow
        Keys.onPressed: e => {
            e.accepted = true
            if (e.key === Qt.Key_Tab) root.step(1)
            else if (e.key === Qt.Key_Backtab) root.step(-1)
            else if (e.key === Qt.Key_Right) root.step(1)
            else if (e.key === Qt.Key_Left) root.step(-1)
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) root.commit()
            else if (e.key === Qt.Key_Escape) root.cancel()
            else e.accepted = false
        }
        Keys.onReleased: e => { if (e.key === Qt.Key_Alt && !e.isAutoRepeat) root.commit() }

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: 12

            Repeater {
                model: root.items
                Rectangle {
                    required property var modelData
                    required property int index
                    readonly property var entry: DesktopEntries.heuristicLookup(modelData.appId)
                    readonly property bool current: index === root.sel
                    implicitWidth: 112
                    implicitHeight: 124
                    radius: QsConfig.Appearance.radius.l
                    color: current ? Qt.rgba(root.pywal.primary.r, root.pywal.primary.g, root.pywal.primary.b, 0.28) : "transparent"
                    border.width: current ? 2 : 0
                    border.color: root.pywal.primary

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 6
                        Image {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 56
                            Layout.preferredHeight: 56
                            sourceSize: Qt.size(112, 112)
                            source: Quickshell.iconPath(entry?.icon ?? modelData.appId.toLowerCase(), true) || ""
                            smooth: true
                            mipmap: true
                        }
                        Text {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData.title || modelData.appId
                            elide: Text.ElideRight
                            maximumLineCount: 2
                            wrapMode: Text.Wrap
                            color: root.pywal.foreground
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: QsConfig.Appearance.fontSize.s
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { root.sel = index; root.commit() }
                    }
                }
            }
        }
    }
}
