pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Camera access switch. PipeWire exposes each v4l2 camera as a "Video/Device" that WirePlumber keeps
// in profile "On"; setting profile "off" removes its nodes, so browsers and portal apps (Flatpak,
// Teams, Meet, ...) no longer see it. Apps that open /dev/video* directly are NOT blocked.
// Read from `pw-dump`; switched with `wpctl set-profile`.
Singleton {
    id: root

    // [{ id, offIndex, onIndex, on }]
    property var devices: []
    readonly property bool available: devices.length > 0
    readonly property bool enabled: devices.some(d => d.on)

    function refresh() { if (!dump.running) dump.running = true }

    function toggle() {
        const want = !enabled
        // one shell call, devices handled one by one: wpctl set-profile ID INDEX
        const cmds = devices.map(d => `wpctl set-profile ${d.id} ${want ? d.onIndex : d.offIndex}`).join("; ")
        setProc.command = ["sh", "-c", cmds]
        setProc.running = true
    }

    Process {
        id: dump
        command: ["pw-dump"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.devices = JSON.parse(text)
                        .filter(o => o.type === "PipeWire:Interface:Device" && o.info?.props?.["media.class"] === "Video/Device")
                        .map(o => {
                            const profs = o.info?.params?.EnumProfile ?? []
                            const cur = (o.info?.params?.Profile ?? [])[0]
                            const off = profs.find(p => p.name === "off")
                            const on = profs.find(p => p.name !== "off")
                            return { id: o.id, offIndex: off?.index ?? 0, onIndex: on?.index ?? 1, on: cur ? cur.name !== "off" : true }
                        })
                } catch (e) { root.devices = [] }
            }
        }
    }
    Process { id: setProc; onExited: Qt.callLater(root.refresh) }

    Timer { interval: 10000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
}
