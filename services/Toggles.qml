pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../config" as QsConfig

// Control Center toggles that wrap a system tool: night light (wlsunset),
// airplane mode (rfkill) and VPN (NetworkManager VPN/WireGuard profiles).
// State is re-read after a toggle and every 10 s.
Singleton {
    id: root

    property bool nightLight: false
    property bool airplane: false
    property var vpnProfiles: []   // [{name, active}]
    readonly property bool hasVpn: vpnProfiles.length > 0
    readonly property bool vpnActive: vpnProfiles.some(p => p.active)
    readonly property string vpnLabel: (vpnProfiles.find(p => p.active) ?? vpnProfiles[0])?.name ?? "VPN"

    function toggleNightLight() {
        // Fixed ~4000 K (low and high temperature differ by 1 K so the
        // day/night schedule is irrelevant). Stops again if already running.
        Quickshell.execDetached(["sh", "-c",
            "pkill -x wlsunset || exec wlsunset -t 4000 -T 4001 -S 06:00 -s 18:00"])
        recheck.restart()
    }

    function toggleAirplane() {
        Quickshell.execDetached(["rfkill", airplane ? "unblock" : "block", "all"])
        recheck.restart()
    }

    function toggleVpn() {
        const active = vpnProfiles.filter(p => p.active)
        if (active.length > 0)
            for (const p of active) Quickshell.execDetached(["nmcli", "connection", "down", "id", p.name])
        else if (hasVpn)
            Quickshell.execDetached(["nmcli", "connection", "up", "id", vpnProfiles[0].name])
        recheck.restart()
    }

    function refresh() {
        nlProc.running = true
        rfProc.running = true
        vpnProc.running = true
    }

    Timer { id: recheck; interval: 700; onTriggered: root.refresh() }
    Timer { interval: 10000; running: QsConfig.Config.features.quickToggles; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }

    Process { id: nlProc; command: ["pgrep", "-x", "wlsunset"]; onExited: code => root.nightLight = code === 0 }

    Process {
        id: rfProc
        command: ["rfkill", "-n", "-o", "SOFT", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.split("\n").map(x => x.trim()).filter(x => x)
                root.airplane = l.length > 0 && l.every(x => x === "blocked")
            }
        }
    }

    Process {
        id: vpnProc
        command: ["nmcli", "-t", "-f", "NAME,TYPE,STATE", "connection", "show"]
        environment: ({ LANG: "C.UTF-8", LC_ALL: "C.UTF-8" })
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                for (const line of text.split("\n")) {
                    const f = line.split(":")
                    if (f.length < 3) continue
                    const state = f.pop(), type = f.pop()
                    if (type !== "vpn" && type !== "wireguard") continue
                    out.push({ name: f.join(":").replace(/\\:/g, ":"), active: state === "activated" })
                }
                root.vpnProfiles = out
            }
        }
    }
}
