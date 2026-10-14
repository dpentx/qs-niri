import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Effects
import Quickshell
import "../../config" as QsConfig
import "../../services" as QsServices
import "../../components"

// What the lock screen shows on one monitor: blurred wallpaper, big clock,
// user and a password pill. Typing goes to a hidden TextInput.
// The same view is the greeter's login screen: the `lock` object then sets
// askUser (editable user name), showPower and wallpaper.
Item {
    id: root

    required property var lock

    readonly property var pywal: QsServices.Pywal
    readonly property string wallpaper: lock.wallpaper || QsConfig.Config.lock.wallpaper || pywal.wallpaper
    readonly property bool askUser: lock.askUser === true
    readonly property string user: askUser ? (userInput.text || "?") : (Quickshell.env("USER") || "user")
    readonly property string fontFamily: QsConfig.Config.appearance.fontFamily

    opacity: 0
    Component.onCompleted: { opacity = 1; (askUser && !userInput.text ? userInput : input).forceActiveFocus() }
    Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutQuad } }

    // ── Background ───────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.darker(root.pywal.primary, 3.4) }
            GradientStop { position: 1; color: root.pywal.background }
        }
    }
    Image {
        anchors.fill: parent
        source: root.wallpaper ? "file://" + root.wallpaper : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: status === Image.Ready
        layer.enabled: true
        layer.effect: MultiEffect { blurEnabled: true; blur: 1.0; blurMax: 48; brightness: -0.2 }
    }
    Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.22) }

    MouseArea { anchors.fill: parent; onPressed: input.forceActiveFocus() }

    // ── Clock ────────────────────────────────────────────────────
    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height * 0.14)
        spacing: 4

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatTime(QsServices.Time.date, "HH:mm")
            color: "white"
            font.family: root.fontFamily
            font.pixelSize: Math.round(root.height * 0.15)
            font.weight: Font.Light
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDate(QsServices.Time.date, "dddd, d MMMM")
            color: Qt.rgba(1, 1, 1, 0.85)
            font.family: root.fontFamily
            font.pixelSize: Math.round(root.height * 0.026)
        }
    }

    // ── User + password ──────────────────────────────────────────
    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height * 0.6)
        spacing: 12

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 76
            Layout.preferredHeight: 76
            radius: width / 2
            color: Qt.rgba(root.pywal.primary.r, root.pywal.primary.g, root.pywal.primary.b, 0.9)
            Text {
                anchors.centerIn: parent
                text: root.user.slice(0, 1).toUpperCase()
                color: root.pywal.onPrimary
                font.family: root.fontFamily
                font.pixelSize: 34
                font.weight: Font.DemiBold
            }
        }
        Text {
            visible: !root.askUser
            Layout.alignment: Qt.AlignHCenter
            text: root.user
            color: "white"
            font.family: root.fontFamily
            font.pixelSize: 20
            font.weight: Font.Medium
        }

        Rectangle {
            visible: root.askUser
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 320
            Layout.preferredHeight: 46
            radius: height / 2
            color: Qt.rgba(1, 1, 1, 0.12)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, userInput.activeFocus ? 0.45 : 0.2)
            Text {
                anchors.centerIn: parent
                visible: userInput.text.length === 0
                text: "Kullanıcı adı"
                color: Qt.rgba(1, 1, 1, 0.6)
                font.family: root.fontFamily
                font.pixelSize: 15
            }
            TextInput {
                id: userInput
                anchors.fill: parent
                anchors.leftMargin: 20; anchors.rightMargin: 20
                verticalAlignment: TextInput.AlignVCenter
                horizontalAlignment: TextInput.AlignHCenter
                text: root.lock.userName ?? ""
                color: "white"
                font.family: root.fontFamily
                font.pixelSize: 16
                onTextChanged: if (root.askUser) root.lock.userName = text
                onAccepted: input.forceActiveFocus()
            }
        }

        Rectangle {
            id: pill
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 6
            Layout.preferredWidth: 320
            Layout.preferredHeight: 54
            radius: height / 2
            color: Qt.rgba(1, 1, 1, 0.16)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, input.activeFocus ? 0.45 : 0.22)
            opacity: root.lock.busy ? 0.6 : 1
            transform: Translate { id: shake; x: 0 }

            Text {
                anchors.centerIn: parent
                visible: input.text.length === 0
                text: root.lock.busy ? "Doğrulanıyor…" : "Parola"
                color: Qt.rgba(1, 1, 1, 0.6)
                font.family: root.fontFamily
                font.pixelSize: 16
            }
            Row {
                anchors.centerIn: parent
                spacing: 7
                Repeater {
                    model: Math.min(input.text.length, 20)
                    Rectangle { width: 9; height: 9; radius: 4.5; color: "white" }
                }
            }
            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 7
                anchors.verticalCenter: parent.verticalCenter
                width: 40; height: 40; radius: 20
                color: input.text.length > 0 ? root.pywal.primary : Qt.rgba(1, 1, 1, 0.14)
                Behavior on color { ColorAnimation { duration: 150 } }
                OneUIIcon {
                    anchors.centerIn: parent
                    name: "mdi_arrow_right"
                    size: 20
                    color: input.text.length > 0 ? root.pywal.onPrimary : Qt.rgba(1, 1, 1, 0.7)
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.lock.submit(input.text) }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 20
            text: root.lock.error
            color: "#ff8a80"
            font.family: root.fontFamily
            font.pixelSize: 14
        }
    }

    // Greeter only: reboot / power off
    Row {
        visible: root.lock.showPower === true
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 36
        spacing: 12
        Repeater {
            model: [
                { label: "Yeniden başlat", cmd: ["systemctl", "reboot"] },
                { label: "Kapat", cmd: ["systemctl", "poweroff"] }
            ]
            Rectangle {
                required property var modelData
                width: powerLabel.implicitWidth + 36; height: 38; radius: 19
                color: Qt.rgba(1, 1, 1, powerArea.containsMouse ? 0.22 : 0.12)
                Text {
                    id: powerLabel
                    anchors.centerIn: parent
                    text: parent.modelData.label
                    color: "white"
                    font.family: root.fontFamily
                    font.pixelSize: 14
                }
                MouseArea {
                    id: powerArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Quickshell.execDetached(parent.modelData.cmd)
                }
            }
        }
    }

    TextInput {
        id: input
        width: 1; height: 1; opacity: 0
        echoMode: TextInput.Password
        focus: true
        onAccepted: root.lock.submit(text)
        Keys.onEscapePressed: text = ""
    }

    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: shake; property: "x"; to: -14; duration: 50 }
        NumberAnimation { target: shake; property: "x"; to: 14; duration: 90 }
        NumberAnimation { target: shake; property: "x"; to: -10; duration: 80 }
        NumberAnimation { target: shake; property: "x"; to: 0; duration: 60 }
    }

    Connections {
        target: root.lock
        function onAttemptFinished() {
            input.text = ""
            if (root.lock.error) shakeAnim.restart()
            input.forceActiveFocus()
        }
    }
}
