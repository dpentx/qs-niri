import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10
import qs.services
import "../../../components/effects"
import "../../../config" as QsConfig

Item {
    id: root

    property var launcher
    property var controlCenter
    property var sidebar
    property var dashboard
    property bool inlineMode: false
    
    implicitWidth: inlineMode ? inlineClockRow.implicitWidth : clockRow.implicitWidth
    implicitHeight: inlineMode ? inlineClockRow.implicitHeight : clockRow.implicitHeight

    Row {
        id: inlineClockRow
        visible: root.inlineMode
        anchors.centerIn: parent
        spacing: 6

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                text: Time.format("hh")
                color: Pywal.foreground
                font.pixelSize: QsConfig.Appearance.fontSize.m
                font.weight: Font.Bold
                font.family: "OneUI Sans"
            }

            Text {
                text: ":"
                color: Pywal.primary
                font.pixelSize: QsConfig.Appearance.fontSize.m
                font.weight: Font.Bold
                font.family: "OneUI Sans"
                SequentialAnimation on opacity {
                    running: true
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.4; duration: 800; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutSine }
                }
            }

            Text {
                text: Time.format("mm")
                color: Pywal.foreground
                font.pixelSize: QsConfig.Appearance.fontSize.m
                font.weight: Font.Bold
                font.family: "OneUI Sans"
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Time.format("ddd, d MMM")
            color: Qt.rgba(Pywal.foreground.r, Pywal.foreground.g, Pywal.foreground.b, 0.65)
            font.pixelSize: QsConfig.Appearance.fontSize.s
            font.weight: Font.Medium
            font.family: "OneUI Sans"
        }
    }
    
    Column {
        id: clockRow
        visible: !root.inlineMode
        anchors.centerIn: parent
        spacing: 0
        
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 1
            
            Text {
                id: hoursText
                text: Time.format("hh")
                color: Pywal.foreground
                font.pixelSize: QsConfig.Appearance.fontSize.l
                font.weight: Font.DemiBold
                font.family: "OneUI Sans"
                font.letterSpacing: 0.3
            }
            
            Text {
                id: colonSeparator
                text: ":"
                color: Pywal.primary
                font.pixelSize: QsConfig.Appearance.fontSize.l
                font.weight: Font.DemiBold
                font.family: "OneUI Sans"
                
                SequentialAnimation on opacity {
                    running: true
                    loops: Animation.Infinite
                    
                    NumberAnimation { to: 0.4; duration: 800; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutSine }
                }
            }
            
            Text {
                id: minutesText
                text: Time.format("mm")
                color: Pywal.foreground
                font.pixelSize: QsConfig.Appearance.fontSize.l
                font.weight: Font.DemiBold
                font.family: "OneUI Sans"
                font.letterSpacing: 0.3
            }
        }
        
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Time.format("ddd, d/M")
            color: Qt.rgba(Pywal.foreground.r, Pywal.foreground.g, Pywal.foreground.b, 0.6)
            font.pixelSize: QsConfig.Appearance.fontSize.s
            font.weight: Font.Medium
            font.family: "OneUI Sans"
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            if (!root.dashboard)
                return

            root.dashboard.shouldShow = !root.dashboard.shouldShow
            if (root.dashboard.shouldShow) {
                if (root.launcher)
                    root.launcher.shouldShow = false
                if (root.controlCenter)
                    root.controlCenter.shouldShow = false
                if (root.sidebar)
                    root.sidebar.shouldShow = false
            }
        }

        ToolTip.visible: containsMouse
        ToolTip.delay: 450
        ToolTip.text: Time.format("dddd, MMMM d, yyyy")
    }
}
