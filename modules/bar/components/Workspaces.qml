import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../../services" as QsServices

Row {
    id: wsWidget
    spacing: 6

    property var screen
    readonly property var pywal: QsServices.Pywal
    property color activeColor:   pywal.primary
    property color inactiveColor: pywal.onSurfaceVariant
    property var workspaces: []

    function mapWorkspaces(list) {
        return list
            .slice()
            .sort((a, b) => a.idx - b.idx)
            .map(ws => ({
                id:      ws.id,
                focused: ws.is_focused,
                idx:     ws.idx  // niri idx is already 1-based
            }))
    }

    // Initial snapshot
    Process {
        id: niriInitial
        command: ["niri", "msg", "-j", "workspaces"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text)
                    wsWidget.workspaces = wsWidget.mapWorkspaces(data)
                } catch (e) {}
            }
        }
    }

    // Live event stream — no polling, near-zero idle CPU
    Process {
        id: niriEvents
        command: ["niri", "msg", "-j", "event-stream"]
        running: true

        stdout: SplitParser {
            onRead: line => {
                try {
                    const ev = JSON.parse(line)

                    if (ev.WorkspacesChanged) {
                        wsWidget.workspaces = wsWidget.mapWorkspaces(ev.WorkspacesChanged.workspaces)
                    } else if (ev.WorkspaceActivated) {
                        const id = ev.WorkspaceActivated.id
                        wsWidget.workspaces = wsWidget.workspaces.map(ws => ({
                            id: ws.id,
                            idx: ws.idx,
                            focused: ws.id === id
                        }))
                    }
                } catch (e) {}
            }
        }

        // If niri restarts / stream dies, try to relaunch after a short delay
        onExited: restartTimer.start()
    }

    Timer {
        id: restartTimer
        interval: 2000
        repeat: false
        onTriggered: {
            niriEvents.running = false
            niriEvents.running = true
        }
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

    // wheel over the dots: previous / next workspace
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: e => {
            const l = wsWidget.workspaces, i = l.findIndex(w => w.focused), n = i + (e.angleDelta.y > 0 ? -1 : 1)
            if (i >= 0 && n >= 0 && n < l.length) wsWidget.focusWs(l[n].idx)
        }
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
