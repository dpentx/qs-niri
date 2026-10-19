import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import Quickshell.Wayland
import "../config" as QsConfig
import "../services" as QsServices

// Shown when the shell found a broken config file or a crash report from the last session.
// "Report issue" opens a GitHub issue with the details filled in (see services/Diagnostics.qml).
PanelWindow {
    id: root

    readonly property var diag: QsServices.Diagnostics
    readonly property var pywal: QsServices.Pywal

    screen: Quickshell.screens[0]
    anchors { top: true }
    margins { top: (QsConfig.Config.bar.height ?? 34) + 14 }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    visible: diag.active
    color: "transparent"
    implicitWidth: 460
    implicitHeight: card.implicitHeight

    Rectangle {
        id: card
        width: parent.width
        implicitHeight: content.implicitHeight + 36
        radius: 24
        color: root.pywal.popupSurface
        border.width: 1
        border.color: root.pywal.outlineVariant

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: 18
            spacing: 10

            Text {
                Layout.fillWidth: true
                text: root.diag.title
                color: root.pywal.foreground
                font.family: QsConfig.Config.appearance.fontFamily
                font.pixelSize: QsConfig.Appearance.fontSize.l
                font.weight: Font.DemiBold
            }
            Text {
                Layout.fillWidth: true
                Layout.maximumHeight: 150
                text: root.diag.detail
                color: root.pywal.onSurfaceMuted
                wrapMode: Text.Wrap
                elide: Text.ElideRight
                font.family: QsConfig.Config.appearance.fontFamily
                font.pixelSize: QsConfig.Appearance.fontSize.s
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: [
                        { label: "Report issue", primary: true,  show: true,                         act: () => root.diag.openIssue() },
                        { label: "Open file",    primary: false, show: root.diag.kind === "config", act: () => root.diag.openFile() },
                        { label: "Crash folder", primary: false, show: root.diag.kind === "crash",  act: () => root.diag.openCrashFolder() },
                        { label: "Dismiss",      primary: false, show: true,                         act: () => root.diag.dismiss() }
                    ]
                    Rectangle {
                        id: btn
                        required property var modelData
                        visible: modelData.show
                        Layout.preferredHeight: 34
                        Layout.preferredWidth: btnText.implicitWidth + 28
                        radius: 17
                        color: modelData.primary ? root.pywal.primary : root.pywal.tileOff
                        Text {
                            id: btnText
                            anchors.centerIn: parent
                            text: btn.modelData.label
                            color: btn.modelData.primary ? root.pywal.onPrimary : root.pywal.foreground
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: QsConfig.Appearance.fontSize.s
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: btn.modelData.act()
                        }
                    }
                }
                Item { Layout.fillWidth: true }
            }
        }
    }
}
