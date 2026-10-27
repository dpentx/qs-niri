import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import Quickshell.Io
import "../../../services" as QsServices
import "../../../components"
import "../../../config" as QsConfig

// User-chosen pills in the bar (bar.widgets in shell.json / user.json, in order).
// Built-ins come from Config.barBuiltins; bar.custom adds your own:
//   { "id": "up", "label": "Uptime", "icon": "mdi_console", "exec": "uptime -p", "interval": 60, "onClick": "foot -e htop" }
Row {
    id: root

    readonly property var pywal: QsServices.Pywal
    readonly property var usage: QsServices.SystemUsage
    readonly property var cfg: QsConfig.Config

    spacing: 6
    visible: repeater.count > 0

    Repeater {
        id: repeater
        model: root.cfg.barWidgets.map(id => root.cfg.barAvailable.find(w => w.id === id)).filter(w => w)

        AuroraSurface {
            id: pill
            required property var modelData
            readonly property bool custom: modelData.exec !== undefined
            property string customText: ""
            readonly property string text: {
                switch (modelData.id) {
                case "cpu": return Math.round(root.usage.cpuPerc * 100) + "%"
                case "memory": return Math.round(root.usage.memPerc * 100) + "%"
                case "disk": return Math.round(root.usage.diskPerc * 100) + "%"
                case "gpu": return Math.round(root.usage.gpuUsage) + "%"
                default: return customText
                }
            }

            visible: modelData.id !== "gpu" || root.usage.hasGpu
            height: 24   // fits the 30 px top bar
            width: row.implicitWidth + 18
            radius: QsConfig.Appearance.radius.m
            color: hover.hovered ? pywal.barPillHover : pywal.barPill
            borderWidth: 0
            accentColor: pywal.secondary
            elevation: 0

            HoverHandler { id: hover }

            Row {
                id: row
                anchors.centerIn: parent
                spacing: 5

                OneUIIcon {
                    visible: (modelData.icon ?? "") !== ""
                    name: modelData.icon ?? ""
                    size: 14
                    color: pywal.foreground
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: pill.text
                    color: pywal.foreground
                    font.family: "OneUI Sans"
                    font.pixelSize: QsConfig.Appearance.fontSize.s
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Process {
                id: runner
                command: ["sh", "-c", modelData.exec ?? "true"]
                stdout: StdioCollector { onStreamFinished: pill.customText = text.trim().split("\n")[0] }
            }
            Timer {
                running: pill.custom && pill.visible
                repeat: true
                triggeredOnStart: true
                interval: Math.max(1, modelData.interval ?? 30) * 1000
                onTriggered: if (!runner.running) runner.running = true
            }

            // Custom widgets run their onClick; the built-in ones open the task manager.
            readonly property bool opensTaskManager: !custom && root.cfg.features.taskManager

            MouseArea {
                anchors.fill: parent
                enabled: (modelData.onClick ?? "") !== "" || pill.opensTaskManager
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if ((modelData.onClick ?? "") !== "")
                        Quickshell.execDetached(["sh", "-c", modelData.onClick])
                    else
                        Quickshell.execDetached(["touch", "/tmp/qs-taskmanager"])
                }
            }
        }
    }
}
