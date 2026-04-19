import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Row {
    id: wsWidget
    spacing: 6

    property var screen
    property color activeColor:   "#E69875"
    property color inactiveColor: "#7A8478"
    property var workspaces: []

    Process {
        id: niriPoller
        command: ["niri", "msg", "-j", "workspaces"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text)
                    wsWidget.workspaces = data
                        .sort((a, b) => a.idx - b.idx)
                        .map(ws => ({
                            id:      ws.id,
                            focused: ws.is_focused,
                            idx:     ws.idx + 1  // 0-tabanlı → 1-tabanlı
                        }))
                } catch(e) {}
            }
        }
    }

    Timer {
        interval: 800
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: niriPoller.running = true
    }

    Process {
        id: switchProc
        property string target: "1"
        command: ["niri", "msg", "action", "focus-workspace", target]
    }

    function focusWs(idx) {
        switchProc.target = String(idx)
        switchProc.running = true
    }

    Repeater {
        model: wsWidget.workspaces

        Rectangle {
            required property var modelData

            width:  modelData.focused ? 20 : 8
            height: 8
            radius: 4
            color:  modelData.focused ? wsWidget.activeColor : wsWidget.inactiveColor

            Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation  { duration: 180 } }

            MouseArea {
                anchors.fill: parent
                cursorShape:  Qt.PointingHandCursor
                onClicked:    wsWidget.focusWs(modelData.idx)
            }
        }
    }
}
