import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../config" as QsConfig
import "../../services" as QsServices
import "../../components"
import "../../components/effects"
import "binds.js" as Binds

// Keyboard shortcuts, read from the niri config (`binds { }` in ~/.config/niri/config.kdl). Type to filter.
// `touch /tmp/qs-keys` toggles it.
FloatingWindow {
    id: root

    BackgroundEffect.blurRegion: QsConfig.Appearance.blur && shouldShow && panel.opacity > 0.98 && Math.abs(panel.scale - 1) < 0.002 && Math.abs(panel.revealOffset) < 0.5 ? _blur : null
    Region { id: _blur; item: panel; radius: blurSurface.radius }

    property bool shouldShow: false
    visible: shouldShow || panel.opacity > 0
    title: "Keyboard shortcuts"
    implicitWidth: 640
    implicitHeight: 600
    minimumSize: Qt.size(420, 360)
    color: "transparent"

    readonly property var pywal: QsServices.Pywal
    property var binds: []
    readonly property var shown: {
        const q = search.text.trim().toLowerCase()
        return q === "" ? binds : binds.filter(b => (b.key + " " + b.title + " " + b.action).toLowerCase().includes(q))
    }

    FileView {
        path: Quickshell.env("HOME") + "/.config/niri/config.kdl"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.binds = Binds.parseBinds(text())
    }

    FocusScope {
        id: panel
        anchors.fill: parent

        property real revealOffset: root.shouldShow ? 0 : -20
        scale: root.shouldShow ? 1.0 : 0.97
        opacity: root.shouldShow ? 1.0 : 0.0
        focus: root.shouldShow
        transform: Translate { y: panel.revealOffset }

        Behavior on scale { NumberAnimation { duration: OneUIMotion.medium1; easing.bezierCurve: OneUIMotion.springGentle } }
        Behavior on opacity { NumberAnimation { duration: OneUIMotion.short4; easing.type: Easing.OutQuad } }
        Behavior on revealOffset { NumberAnimation { duration: OneUIMotion.medium1; easing.bezierCurve: OneUIMotion.emphasizedDecelerate } }

        Keys.onEscapePressed: root.shouldShow = false

        AuroraSurface {
            id: blurSurface
            anchors.fill: parent
            radius: QsConfig.Appearance.radius.l
            color: root.pywal.surfaceContainerHighest
            borderWidth: 0
            accentColor: root.pywal.primary
        }

        DexCaption { id: caption; title: "Keyboard shortcuts"; onHideRequested: root.shouldShow = false; onCloseRequested: root.shouldShow = false }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            anchors.topMargin: 16 + caption.height
            spacing: 10

            Rectangle {
                Layout.fillWidth: true
                height: 38
                radius: height / 2
                color: root.pywal.surfaceContainerHigh
                TextInput {
                    id: search
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    verticalAlignment: TextInput.AlignVCenter
                    color: root.pywal.foreground
                    selectionColor: root.pywal.primary
                    font.family: QsConfig.Config.appearance.fontFamily
                    font.pixelSize: QsConfig.Appearance.fontSize.m
                    focus: root.shouldShow
                    clip: true
                    Text {
                        visible: search.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Search shortcuts"
                        color: root.pywal.onSurfaceMuted
                        font: search.font
                    }
                }
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 4
                model: root.shown
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    required property var modelData
                    width: ListView.view.width
                    height: 40
                    radius: QsConfig.Appearance.radius.m
                    color: Qt.rgba(root.pywal.foreground.r, root.pywal.foreground.g, root.pywal.foreground.b, 0.04)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 4
                        Repeater {
                            model: modelData.key.split("+")
                            Rectangle {
                                required property string modelData
                                implicitWidth: kt.implicitWidth + 14
                                implicitHeight: 24
                                radius: 7
                                color: Qt.rgba(root.pywal.primary.r, root.pywal.primary.g, root.pywal.primary.b, 0.22)
                                Text {
                                    id: kt
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: root.pywal.foreground
                                    font.family: QsConfig.Config.appearance.fontFamily
                                    font.pixelSize: QsConfig.Appearance.fontSize.s
                                    font.weight: Font.DemiBold
                                }
                            }
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            Layout.maximumWidth: parent.width * 0.55
                            text: modelData.title || modelData.action
                            elide: Text.ElideRight
                            color: root.pywal.onSurfaceMuted
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: QsConfig.Appearance.fontSize.s
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: parent.count === 0
                    text: root.binds.length === 0 ? "No binds found in ~/.config/niri/config.kdl" : "Nothing matches"
                    color: root.pywal.onSurfaceMuted
                    font.family: QsConfig.Config.appearance.fontFamily
                    font.pixelSize: QsConfig.Appearance.fontSize.m
                }
            }
        }
    }
}
