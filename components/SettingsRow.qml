import QtQuick 6.10
import QtQuick.Layouts 6.10
import "../services" as QsServices
import "effects"

// OneUI-style settings/preference row.
// Modeled directly on the decoded SecSettings.apk layouts:
//   preference.xml / preference_material.xml -> icon | title+summary | trailing widget
//   sesl_list_preferred_item_height_small (56dp) -> row height
// Icon badge follows the same 40dp circular convention already used for
// QuickToggle and the Network/Bluetooth panel list rows, so it reads as
// one consistent icon language across the whole shell.
Rectangle {
    id: root

    property string icon: ""
    property string title: ""
    property string summary: ""     // optional secondary line, like preference's android:id/summary
    property bool showChevron: false
    property color iconTint: pywal.foreground
    property color iconBadgeColor: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.08)
    property bool pressedFeedback: true

    signal clicked()

    // trailing widget slot (switch, value label, etc.) — mirrors
    // preference_material.xml's @android:id/widget_frame
    default property alias trailing: trailingSlot.data

    readonly property var pywal: QsServices.Pywal

    Layout.fillWidth: true
    Layout.preferredHeight: 56 // sesl_list_preferred_item_height_small
    radius: 14
    color: rowMouse.pressed && pressedFeedback
        ? Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.08)
        : (rowMouse.containsMouse ? Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.04) : "transparent")

    Behavior on color { ColorAnimation { duration: 100 } }

    // Press feedback — same scale target/curve as QuickToggle and
    // PrimaryToggleRow, so every tap target in the shell feels identical.
    scale: rowMouse.pressed && pressedFeedback ? 0.96 : 1.0
    Behavior on scale {
        NumberAnimation {
            duration: Material3Anim.short2
            easing.bezierCurve: Material3Anim.springGentle
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 14
        spacing: 12

        // Icon badge (40dp circle) — only shown if an icon was given
        Rectangle {
            visible: root.icon !== ""
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            radius: 20
            color: root.iconBadgeColor

            Text {
                anchors.centerIn: parent
                text: root.icon
                font.family: "Material Design Icons"
                font.pixelSize: 18
                color: root.iconTint
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: root.title
                font.family: "OneUI Sans"
                font.pixelSize: 14
                font.weight: Font.Medium
                color: pywal.foreground
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: root.summary !== ""
                text: root.summary
                font.family: "OneUI Sans"
                font.pixelSize: 12
                color: pywal.onSurfaceMuted
                elide: Text.ElideRight
            }
        }

        // Trailing content — switches, value text, etc.
        RowLayout {
            id: trailingSlot
            spacing: 8
        }

        Text {
            visible: root.showChevron
            text: "󰅂"
            font.family: "Material Design Icons"
            font.pixelSize: 16
            color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.45)
        }
    }

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
