import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10
import Quickshell
import "../../../components/effects"

// OneUI-style quick settings tile.
// Square tile, icon centered in a circular badge on top, label underneath.
// Colors sourced from decoded OneUI SystemUI res/values:
//   qs_tile_round_background_on   #fffcfcff
//   qs_tile_round_background_off  #40000000
//   qs_tile_icon_on_dim_tint_color  #d9252528
//   qs_tile_icon_off_tint_color     #80fcfcff
//   sec_qs_switch_on_background_color #598fff (kept as default activeColor)
Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property string subLabel: "" // kept for API compat, not shown in OneUI style (tiles are compact)
    property bool active: false
    property color activeColor: "#598fff"
    property color surfaceColor: Qt.rgba(0, 0, 0, 0.24) // qs_tile_container_bg-ish
    property color textColor: "#e6e6e6"
    // Dense, icon-only mode for OneUI's secondary toggle grid (DND,
    // airplane mode, torch, etc. — no visible label, smaller badge).
    // WiFi/Bluetooth-tier toggles stay in the labeled, non-compact form.
    property bool compact: false
    signal clicked()

    Layout.fillWidth: true
    Layout.preferredHeight: compact ? 60 : 88 // ~ qs_tile_height (80dp) + label breathing room

    radius: 20 // notification_panel_background_radius-derived tile radius
    color: surfaceColor
    clip: true

    // Press scale, same feel as before
    scale: toggleMouse.pressed ? 0.96 : 1.0
    Behavior on scale {
        NumberAnimation {
            duration: Material3Anim.short2
            easing.bezierCurve: Material3Anim.springGentle
        }
    }

    MouseArea {
        id: toggleMouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: root.clicked()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: compact ? 8 : 12
        anchors.bottomMargin: compact ? 8 : 10
        spacing: 6

        // Icon badge — circular, fills most of the tile like OneUI's round toggle
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: compact ? 36 : 44
            Layout.preferredHeight: compact ? 36 : 44
            radius: width / 2

            // active: near-white fill (qs_tile_round_background_on)
            // inactive: dim dark fill (qs_tile_round_background_off)
            color: active ? "#fffcfcff" : "#40000000"

            Behavior on color {
                ColorAnimation {
                    duration: Material3Anim.medium2
                    easing.bezierCurve: Material3Anim.standard
                }
            }

            Text {
                anchors.centerIn: parent
                text: root.icon
                font.family: "Material Design Icons"
                font.pixelSize: compact ? 16 : 20
                // active: dark icon on light badge (qs_tile_icon_on_dim_tint_color)
                // inactive: dim light icon (qs_tile_icon_off_tint_color)
                color: active ? "#d9252528" : "#80fcfcff"

                Behavior on color {
                    ColorAnimation {
                        duration: Material3Anim.medium2
                        easing.bezierCurve: Material3Anim.standard
                    }
                }
            }
        }

        Text {
            visible: !compact
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            text: root.label
            font.family: "OneUI Sans"
            font.pixelSize: 12
            font.weight: Font.Medium
            color: root.textColor
            elide: Text.ElideRight
        }
    }
}
