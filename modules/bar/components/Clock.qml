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
    
    implicitWidth: clockRow.implicitWidth
    implicitHeight: clockRow.implicitHeight
    
    Column {
        id: clockRow
        anchors.centerIn: parent
        spacing: 0
        
        // Compact time display
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 1
            
            // Hours
            Text {
                id: hoursText
                text: Time.format("hh")
                color: Pywal.foreground
                font.pixelSize: QsConfig.Appearance.fontSize.l
                font.weight: Font.DemiBold
                font.family: "OneUI Sans"
                font.letterSpacing: 0.3
            }
            
            // Animated colon separator
            Text {
                id: colonSeparator
                text: ":"
                color: Pywal.primary
                font.pixelSize: QsConfig.Appearance.fontSize.l
                font.weight: Font.DemiBold
                font.family: "OneUI Sans"
                
                // Subtle pulse animation
                SequentialAnimation on opacity {
                    running: true
                    loops: Animation.Infinite
                    
                    NumberAnimation { to: 0.4; duration: 800; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutSine }
                }
            }
            
            // Minutes
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
        
        // Compact date
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Time.format("ddd, d/M")
            color: Qt.rgba(Pywal.foreground.r, Pywal.foreground.g, Pywal.foreground.b, 0.6)
            font.pixelSize: QsConfig.Appearance.fontSize.s
            font.weight: Font.Medium
            font.family: "OneUI Sans"
        }
    }

    // Click: dashboard (DeX opens its notification/quick panel from the clock)
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
