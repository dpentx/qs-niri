import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10
import "../../services" as QsServices
import "../../config" as QsConfig

// Month calendar plus reminders (QsServices.Reminders). Time field: 18:30 | +45 (minutes) | 2026-11-02 09:00.
RowLayout {
    id: ag
    readonly property var pywal: QsServices.Pywal
    property date month: { const d = new Date(); d.setDate(1); d.setHours(0, 0, 0, 0); return d }
    readonly property int offset: (month.getDay() + 6) % 7      // week starts on Monday
    readonly property int days: new Date(month.getFullYear(), month.getMonth() + 1, 0).getDate()
    property int sel: 0     // selected day of `month` (0: none, the list shows everything)
    readonly property int selKey: sel > 0 ? month.getFullYear() * 10000 + month.getMonth() * 100 + sel : 0
    readonly property var rem: QsServices.Reminders.list.filter(r => !selKey || dayKey(r.at) === selKey)

    spacing: 24

    function dayKey(t) { const d = new Date(t); return d.getFullYear() * 10000 + d.getMonth() * 100 + d.getDate() }
    function hasRem(day) { const k = month.getFullYear() * 10000 + month.getMonth() * 100 + day; return QsServices.Reminders.list.some(r => dayKey(r.at) === k) }
    function shift(n) { month = new Date(month.getFullYear(), month.getMonth() + n, 1); sel = 0 }

    component Btn: Rectangle {
        property string label
        signal clicked()
        implicitWidth: t.implicitWidth + 24; implicitHeight: 32; radius: 16
        color: ag.pywal.surfaceContainerHighest
        Text { id: t; anchors.centerIn: parent; text: parent.label; color: ag.pywal.foreground; font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.m }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: parent.clicked() }
    }

    ColumnLayout {
        Layout.preferredWidth: 330
        Layout.alignment: Qt.AlignTop
        spacing: 8
        RowLayout {
            Layout.fillWidth: true
            Btn { label: "‹"; onClicked: ag.shift(-1) }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: Qt.formatDate(ag.month, "MMMM yyyy")
                color: ag.pywal.foreground; font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.xxl; font.weight: 600
            }
            Btn { label: "›"; onClicked: ag.shift(1) }
        }
        GridLayout {
            columns: 7; rowSpacing: 2; columnSpacing: 2
            Repeater {
                model: ["M", "T", "W", "T", "F", "S", "S"]
                Text {
                    required property string modelData
                    Layout.preferredWidth: 44; horizontalAlignment: Text.AlignHCenter
                    text: modelData; color: ag.pywal.onSurfaceMuted; font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.s
                }
            }
            Repeater {
                model: ag.offset + ag.days
                Rectangle {
                    required property int index
                    readonly property int day: index - ag.offset + 1
                    readonly property bool today: day > 0 && ag.dayKey(Date.now()) === ag.month.getFullYear() * 10000 + ag.month.getMonth() * 100 + day
                    Layout.preferredWidth: 44; Layout.preferredHeight: 38; radius: 19
                    color: today ? ag.pywal.primary : "transparent"
                    border.width: day > 0 && day === ag.sel ? 2 : 0
                    border.color: ag.pywal.primary
                    Text {
                        anchors.centerIn: parent
                        visible: parent.day > 0
                        text: parent.day
                        color: parent.today ? ag.pywal.onPrimary : ag.pywal.foreground
                        font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.l
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: parent.day > 0
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ag.sel = parent.day === ag.sel ? 0 : parent.day   // second click: back to everything
                    }
                    Rectangle {
                        visible: parent.day > 0 && ag.hasRem(parent.day)
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 3 }
                        width: 5; height: 5; radius: 2.5
                        color: parent.today ? ag.pywal.onPrimary : ag.pywal.primary
                    }
                }
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignTop
        spacing: 8

        Text { text: ag.sel > 0 ? "Reminders · " + Qt.formatDate(new Date(ag.month.getFullYear(), ag.month.getMonth(), ag.sel), "ddd d MMM") : "Reminders"; color: ag.pywal.foreground; font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.xxl; font.weight: 600 }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            TextField {
                id: what
                Layout.fillWidth: true
                placeholderText: "What"
                color: ag.pywal.foreground
                background: Rectangle { radius: 16; color: ag.pywal.surfaceContainerHighest }
                onAccepted: when.forceActiveFocus()
            }
            TextField {
                id: when
                Layout.preferredWidth: 110
                placeholderText: ag.sel > 0 ? "18:30 (blank 09:00)" : "18:30 or +45"
                color: ag.pywal.foreground
                background: Rectangle { radius: 16; color: ag.pywal.surfaceContainerHighest; border.width: when.bad ? 1 : 0; border.color: ag.pywal.error }
                property bool bad: false
                onAccepted: add.clicked()
            }
            Btn {
                id: add
                label: "Add"
                onClicked: {
                    // a day is selected: the time is on that day (blank = 09:00), else the usual forms
                    const t = when.text.trim()
                    const w = ag.sel > 0 && (t === "" || /^\d{1,2}:\d{2}$/.test(t))
                        ? Qt.formatDate(new Date(ag.month.getFullYear(), ag.month.getMonth(), ag.sel), "yyyy-MM-dd") + " " + (t || "09:00") : when.text
                    when.bad = !QsServices.Reminders.add(what.text, w)
                    if (!when.bad) { what.text = ""; when.text = "" }
                }
            }
        }

        Repeater {
            model: ag.rem
            RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 8
                opacity: modelData.fired ? 0.45 : 1
                Text {
                    text: Qt.formatDateTime(new Date(modelData.at), "ddd d MMM HH:mm")
                    color: ag.pywal.primary; font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.m
                }
                Text {
                    Layout.fillWidth: true
                    text: modelData.text; elide: Text.ElideRight
                    color: ag.pywal.foreground; font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.m
                }
                Btn { label: "✕"; onClicked: QsServices.Reminders.remove(modelData.id) }
            }
        }
        Text {
            visible: ag.rem.length === 0
            text: ag.sel > 0 ? "Nothing on this day" : "Nothing planned"
            color: ag.pywal.onSurfaceMuted; font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.m
        }
    }
}
