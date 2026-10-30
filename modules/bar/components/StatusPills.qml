import QtQuick 6.10
import Quickshell
import "../../../services" as QsServices
import "../../../components"
import "../../../config" as QsConfig

// Recording / screen-sharing / gaming pills (they were separate pills in the classic bar).
// Each one only takes space while it is active; click stops it (sharing opens the Cast panel).
Row {
    id: row
    spacing: 6
    readonly property var pywal: QsServices.Pywal
    property real now: Date.now()

    component Pill: Rectangle {
        id: pill
        property bool on: false
        property color bg: row.pywal.error
        property color fg: row.pywal.onError
        property string icon: ""
        property string label: ""
        property bool blink: true
        signal clicked()
        anchors.verticalCenter: parent.verticalCenter
        height: 22
        radius: height / 2
        visible: on
        width: on ? inner.implicitWidth + 16 : 0
        color: hover.hovered ? Qt.lighter(bg, 1.1) : bg
        HoverHandler { id: hover }
        Row {
            id: inner
            anchors.centerIn: parent
            spacing: 5
            OneUIIcon {
                anchors.verticalCenter: parent.verticalCenter
                visible: pill.icon !== ""
                name: pill.icon
                size: 12
                color: pill.fg
                SequentialAnimation on opacity {
                    running: pill.on && pill.blink
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.45; duration: 700 }
                    NumberAnimation { to: 1.0; duration: 700 }
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: pill.label
                color: pill.fg
                font.family: QsConfig.Config.appearance.fontFamily
                font.pixelSize: QsConfig.Appearance.fontSize.s
                font.weight: Font.DemiBold
            }
        }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: pill.clicked() }
    }

    Pill {
        id: rec
        on: QsConfig.Config.features.recording && QsServices.Screenshot.isRecording
        icon: "qs_screen_record_icon"
        readonly property int s: on ? Math.max(0, Math.floor((row.now - QsServices.Screenshot.recordStart) / 1000)) : 0
        label: Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0")
        onClicked: QsServices.Screenshot.stopRecording()
    }
    Timer { interval: 1000; running: rec.on; repeat: true; onTriggered: row.now = Date.now() }

    Pill {
        on: QsConfig.Config.features.cast && QsServices.Casts.count > 0
        label: "Sharing"
        onClicked: Quickshell.execDetached(["touch", "/tmp/qs-cast"])
    }

    Pill {
        on: QsConfig.Config.features.gaming && QsServices.GamingMode.enabled
        bg: row.pywal.primary
        fg: row.pywal.onPrimary
        icon: "ic_play_games"
        blink: false
        label: QsServices.GamingMode.auto ? "Auto" : "Gaming"
        onClicked: QsServices.GamingMode.toggle()
    }
}
