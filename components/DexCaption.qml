import QtQuick 6.10
import Quickshell
import "../services" as QsServices

// Samsung DeX window caption for our own toplevel windows (Files, Task manager, ...): handle menu
// (snap left/right) and title on the left; hide, maximize, full screen, close on the right.
// Real windows are moved/resized by niri (Mod+drag); the caption drives them through `niri msg action`.
Item {
    id: cap
    property string title: ""
    signal hideRequested()
    signal closeRequested()

    readonly property var pywal: QsServices.Pywal
    property bool menuOpen: false

    height: 34
    anchors { left: parent.left; right: parent.right; top: parent.top }

    function act(...args) { Quickshell.execDetached(["niri", "msg", "action", ...args]) }
    function snap(toLast) { act("set-column-width", "50%"); act(toLast ? "move-column-to-last" : "move-column-to-first"); menuOpen = false }

    component CapButton: Item {
        id: b
        property string icon
        property bool danger: false
        signal clicked()
        width: 30; height: 26
        anchors.verticalCenter: parent.verticalCenter
        Rectangle {
            anchors.fill: parent; radius: 8
            color: b.danger ? cap.pywal.error : cap.pywal.foreground
            opacity: ma.containsMouse ? (b.danger ? 0.9 : 0.14) : 0
        }
        OneUIIcon { anchors.centerIn: parent; name: b.icon; size: 16; color: b.danger && ma.containsMouse ? cap.pywal.onError : cap.pywal.foreground }
        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: b.clicked() }
    }

    // double click on the title area maximizes, like a desktop title bar
    MouseArea { anchors.fill: parent; onDoubleClicked: cap.act("maximize-column") }

    Row {
        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
        spacing: 6
        CapButton { icon: "mw_caption_desktop_button_expand_menu"; onClicked: cap.menuOpen = !cap.menuOpen }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: cap.title
            color: cap.pywal.foreground
            font.family: "OneUI Sans"; font.pixelSize: 12; font.weight: Font.DemiBold
        }
    }

    Row {
        anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
        spacing: 2
        CapButton { icon: "mw_caption_button_minimize"; onClicked: cap.hideRequested() }
        CapButton { icon: "mw_caption_button_maximize"; onClicked: cap.act("maximize-column") }
        CapButton { icon: "desktop_mode_ic_handle_menu_fullscreen"; onClicked: cap.act("fullscreen-window") }
        CapButton { icon: "desktop_mode_header_ic_close"; danger: true; onClicked: cap.closeRequested() }
    }

    // handle menu
    Rectangle {
        visible: cap.menuOpen
        z: 10
        x: 10; y: 32
        width: 190; height: menuCol.implicitHeight + 12
        radius: 14
        color: cap.pywal.surfaceContainerHighest
        border.width: 1; border.color: cap.pywal.outlineVariant
        Column {
            id: menuCol
            anchors { fill: parent; margins: 6 }
            Repeater {
                model: [{ t: "Snap to left", i: "mw_caption_button_snap_to_left", last: false }, { t: "Snap to right", i: "mw_caption_button_snap_to_right", last: true }]
                Rectangle {
                    required property var modelData
                    width: parent.width; height: 34; radius: 10
                    color: mh.containsMouse ? Qt.rgba(cap.pywal.foreground.r, cap.pywal.foreground.g, cap.pywal.foreground.b, 0.1) : "transparent"
                    Row {
                        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                        spacing: 10
                        OneUIIcon { name: modelData.i; size: 16; color: cap.pywal.foreground; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: modelData.t; color: cap.pywal.foreground; font.family: "OneUI Sans"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea { id: mh; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: cap.snap(modelData.last) }
                }
            }
        }
    }
}
