import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10
import Quickshell
import "../../../components"
import "../../../components/effects"
import "../../../config" as QsConfig
import "../../../services" as QsServices

// OneUI-style quick settings tile.
// Square tile, icon centered in a circular badge on top, label underneath.
// Badge roles come from the shared palette (Pywal.tileOn / tileGlyphOn /
// tileOff / tileGlyphOff): "on" is a light fill with a dark glyph, "off" is a
// dim fill with a muted glyph.
// States: default, hover (state layer), pressed (scale), keyboard focus
// (ring + Enter/Space activation), active.
Rectangle {
    id: root

    readonly property var pywal: QsServices.Pywal

    property string icon: ""
    property string label: ""
    property string subLabel: "" // kept for API compat, not shown in OneUI style (tiles are compact)
    property bool active: false
    property color activeColor: pywal.primary
    property color surfaceColor: Qt.rgba(0, 0, 0, 0.24) // qs_tile_container_bg-ish
    property color textColor: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.9)
    // Dense, icon-only mode for OneUI's secondary toggle grid (DND,
    // airplane mode, torch, etc. — no visible label, smaller badge).
    // WiFi/Bluetooth-tier toggles stay in the labeled, non-compact form.
    property bool compact: false
    signal clicked()

    Layout.fillWidth: true
    Layout.preferredHeight: compact ? 60 : 88 // ~ qs_tile_height (80dp) + label breathing room

    radius: QsConfig.Appearance.radius.l
    color: surfaceColor
    clip: true

    // Keyboard reachability: focusable, Enter/Space activate, ring shows focus
    activeFocusOnTab: true
    Keys.onReturnPressed: root.clicked()
    Keys.onEnterPressed: root.clicked()
    Keys.onSpacePressed: root.clicked()
    border.width: root.activeFocus ? QsConfig.Appearance.border.focus : QsConfig.Appearance.border.none
    border.color: pywal.primary

    // Press scale, same feel as before
    scale: toggleMouse.pressed ? OneUIMotion.pressedScale : 1.0
    Behavior on scale {
        NumberAnimation {
            duration: OneUIMotion.short2
            easing.bezierCurve: OneUIMotion.springGentle
        }
    }

    // Hover state layer
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: pywal.foreground
        opacity: toggleMouse.containsMouse ? OneUIMotion.hoverOpacity : 0
        Behavior on opacity {
            NumberAnimation { duration: OneUIMotion.short3; easing.bezierCurve: OneUIMotion.standard }
        }
    }

    MouseArea {
        id: toggleMouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: {
            root.forceActiveFocus()
            root.clicked()
        }
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

            color: active ? pywal.tileOn : pywal.tileOff

            Behavior on color {
                ColorAnimation {
                    duration: OneUIMotion.medium2
                    easing.bezierCurve: OneUIMotion.standard
                }
            }

            OneUIIcon {
                anchors.centerIn: parent
                name: root.icon
                size: compact ? 18 : 22
                color: active ? pywal.tileGlyphOn : pywal.tileGlyphOff

                Behavior on color {
                    ColorAnimation {
                        duration: OneUIMotion.medium2
                        easing.bezierCurve: OneUIMotion.standard
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
