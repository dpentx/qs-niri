pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// What the hardware is (CPU model, GPUs, disks) and per-adapter network rates, for the task
// manager's performance tab. Static facts are read once, on first `active`; the adapter rates
// are polled every 2 s while `active` (the task manager sets it while it is open).
Singleton {
    id: root

    property bool active: false

    property var cpu: ({})        // lscpu fields, e.g. cpu["Model name"]
    property real cpuMhz: 0       // average current clock
    property var gpus: []         // [{ slot, driver, name, vram (bytes, 0 = unknown) }]
    property var disks: []        // [{ name, size (bytes), rotational, model, link, rpm }]
    property var ifaces: []       // [{ name, kind: "eth" | "wifi", state, speed (Mbit/s), ip, rx, tx (bytes/s) }]

    property bool _loaded: false
    property var _prev: ({})
    onActiveChanged: {
        if (!active || _loaded) return
        _loaded = true
        cpuProc.running = true
        gpuProc.running = true
        diskProc.running = true
    }

    function hasKind(kind) { return ifaces.some(i => i.kind === kind) }
    function rate(kind) {
        let rx = 0, tx = 0
        for (const i of ifaces) if (i.kind === kind) { rx += i.rx; tx += i.tx }
        return { rx, tx }
    }
    function first(kind) { return ifaces.find(i => i.kind === kind) ?? null }

    // lscpu -J: [{ field: "Model name:", data, children? }], flattened into { "Model name": data }
    Process {
        id: cpuProc
        command: ["env", "LC_ALL=C", "lscpu", "-J"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = {}
                const walk = list => { for (const e of list ?? []) { out[e.field.replace(/:\s*$/, "")] = e.data; walk(e.children) } }
                try { walk(JSON.parse(text).lscpu) } catch (e) {}
                root.cpu = out
            }
        }
    }

    Process {
        id: gpuProc
        command: ["sh", "-c",
            "for d in /sys/class/drm/card[0-9]*/device; do " +
            "[ -e \"$d/class\" ] || continue; " +
            "case \"$(cat $d/class)\" in 0x03*) ;; *) continue ;; esac; " +
            "slot=$(basename \"$(readlink -f $d)\"); " +
            "drv=$(basename \"$(readlink $d/driver 2>/dev/null)\"); " +
            "name=$(lspci -s \"$slot\" -mm 2>/dev/null | awk -F'\"' '{print $4\" \"$6}'); " +
            "echo \"$slot|$drv|$name|$(cat $d/mem_info_vram_total 2>/dev/null)\"; done"]
        stdout: StdioCollector {
            onStreamFinished: root.gpus = text.split("\n").filter(l => l.trim()).map(l => {
                const p = l.split("|")
                return { slot: p[0], driver: p[1], name: (p[2] ?? "").trim(), vram: Number(p[3]) || 0 }
            })
        }
    }

    // Disks: link = "pcie:<speed>:<width>" | "sata:<speed>" | "usb" | "". The ATA rotation rate is in the
    // udev database (set as root by udev), so it can be read without privileges; SATA HDDs only.
    Process {
        id: diskProc
        command: ["sh", "-c",
            "for b in /sys/block/*; do n=$(basename $b); " +
            "case $n in loop*|ram*|zram*|sr*|dm-*|md*|fd*) continue ;; esac; " +
            "p=$(readlink -f $b/device); link=''; q=$p; " +
            "for i in 1 2 3 4 5 6; do if [ -e $q/current_link_speed ]; then " +
            "link=\"pcie:$(cat $q/current_link_speed):$(cat $q/current_link_width)\"; break; fi; q=$(dirname $q); done; " +
            "case $p in *usb*) link=usb ;; */ata[0-9]*) a=$(echo $p | grep -o '/ata[0-9]*' | head -1 | tr -d '/a-z'); " +
            "s=$(cat /sys/class/ata_link/link$a/sata_spd 2>/dev/null); [ -n \"$s\" ] && link=\"sata:$s\" ;; esac; " +
            "rpm=$(udevadm info --query=property --name=/dev/$n 2>/dev/null | sed -n 's/^ID_ATA_ROTATION_RATE_RPM=//p'); " +
            "echo \"$n|$(cat $b/size)|$(cat $b/queue/rotational)|$(cat $b/device/model 2>/dev/null | sed 's/ *$//')|$link|$rpm\"; done"]
        stdout: StdioCollector {
            onStreamFinished: root.disks = text.split("\n").filter(l => l.trim()).map(l => {
                const p = l.split("|")
                return { name: p[0], size: Number(p[1]) * 512, rotational: p[2] === "1", model: p[3] ?? "", link: p[4] ?? "", rpm: Number(p[5]) || 0 }
            })
        }
    }

    // Physical adapters only (they have a `device` link; bridges, veth, VPNs do not).
    Process {
        id: netProc
        command: ["sh", "-c",
            "awk '/^cpu MHz/{s+=$4;n++} END{if(n) print \"cpu|\" s/n}' /proc/cpuinfo; " +
            "for i in /sys/class/net/*; do n=$(basename $i); [ \"$n\" = lo ] && continue; [ -e $i/device ] || continue; " +
            "if [ -d $i/wireless ] || [ -d $i/phy80211 ]; then k=wifi; else k=eth; fi; " +
            "ip=$(ip -4 -o addr show dev $n 2>/dev/null | awk '{print $4}' | head -1); " +
            "echo \"net|$n|$k|$(cat $i/operstate)|$(cat $i/speed 2>/dev/null)|$ip|$(cat $i/statistics/rx_bytes)|$(cat $i/statistics/tx_bytes)\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const now = Date.now() / 1000
                const prev = root._prev, seen = {}, list = []
                for (const line of text.split("\n")) {
                    const p = line.split("|")
                    if (p[0] === "cpu") { root.cpuMhz = Number(p[1]) || 0; continue }
                    if (p[0] !== "net") continue
                    const rx = Number(p[6]), tx = Number(p[7]), old = prev[p[1]]
                    const dt = old ? now - old.t : 0
                    seen[p[1]] = { rx, tx, t: now }
                    list.push({
                        name: p[1], kind: p[2], state: p[3], speed: Number(p[4]) || 0, ip: p[5] ?? "",
                        rx: dt > 0 ? Math.max(0, (rx - old.rx) / dt) : 0,
                        tx: dt > 0 ? Math.max(0, (tx - old.tx) / dt) : 0
                    })
                }
                root._prev = seen
                root.ifaces = list
            }
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: if (!netProc.running) netProc.running = true
    }
}
