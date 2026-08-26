import QtQuick 6.10
import "../services" as QsServices

// OneUI-style capsule switch. Modeled on the decoded SecSettings.apk tokens:
//   sesl_switch_thumb_off_color / _on_color   -> basic_token_gray_01 (#fcfcff)
//   sesl_switch_track_off_color_dark          -> basic_token_gray_60 (#636368)
//   track "on" reuses the accent blue already used for QS tiles
//   (sec_qs_switch_on_background_color, #598fff) so switches and QS
//   toggles read as the same control language.
Item {
    id: root

    property bool checked: false
    signal toggled(bool checked)

    readonly property var pywal: QsServices.Pywal

    implicitWidth: 46
    implicitHeight: 26

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? "#598fff" : "#636368"

        Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
    }

    Rectangle {
        id: thumb
        width: 20
        height: 20
        radius: 10
        color: "#fcfcff"
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? parent.width - width - 3 : 3

        Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

        scale: mouse.pressed ? 0.92 : 1.0
        Behavior on scale { NumberAnimation { duration: 100 } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.checked = !root.checked
            root.toggled(root.checked)
        }
    }
}
