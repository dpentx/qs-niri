pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick 6.10

// Keyboard layouts from niri: `niri msg -j keyboard-layouts` gives {names, current_idx}; the event stream
// says when a layout was switched (by a keybind, or by us).
Singleton {
    id: root

    property var names: []
    property int current: 0
    readonly property bool multiple: names.length > 1
    readonly property string currentName: names[current] ?? ""
    // "Turkish" -> TR, "English (US)" -> EN; unknown names fall back to their first two letters.
    readonly property string code: {
        const known = { turkish: "TR", english: "EN", german: "DE", french: "FR", spanish: "ES", russian: "RU", italian: "IT",
                        arabic: "AR", japanese: "JA", korean: "KO", portuguese: "PT", polish: "PL", ukrainian: "UK" }
        const word = currentName.split(/[ (]/)[0].toLowerCase()
        return known[word] ?? currentName.slice(0, 2).toUpperCase()
    }

    function next(): void { switchProc.running = true }

    // niri reads layouts only from its config, so the layouts chosen in Settings are written to a KDL file
    // that the user includes once (`include "qs-keyboard.kdl"`); niri reloads it by itself.
    readonly property string kdlName: "qs-keyboard.kdl"
    function write(list): void {
        const ok = x => /^[a-z0-9_]+$/.test(x.layout) && /^[a-z0-9_]*$/.test(x.variant ?? "")
        const l = list.filter(ok)
        if (!l.length) return
        const variants = l.some(x => x.variant) ? `            variant "${l.map(x => x.variant ?? "").join(",")}"\n` : ""
        const kdl = "// Written by qs-niri (Settings > Shell > Keyboard). Include it from your niri config.\n" +
            `input {\n    keyboard {\n        xkb {\n            layout "${l.map(x => x.layout).join(",")}"\n${variants}        }\n    }\n}\n`
        writeProc.command = ["sh", "-c", 'd="${XDG_CONFIG_HOME:-$HOME/.config}/niri"; mkdir -p "$d" && printf "%s" "$1" > "$d/$2"', "sh", kdl, kdlName]
        writeProc.running = true
    }

    Process { id: writeProc }

    Process {
        id: switchProc
        command: ["niri", "msg", "action", "switch-layout", "next"]
        onExited: queryProc.running = true
    }

    Process {
        id: queryProc
        command: ["niri", "msg", "-j", "keyboard-layouts"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text)
                    root.names = d.names ?? []
                    root.current = d.current_idx ?? 0
                } catch (e) {
                    // not niri, or a bad read: keep what we had
                }
            }
        }
    }

    Process {
        id: events
        command: ["niri", "msg", "-j", "event-stream"]
        running: true
        stdout: SplitParser {
            onRead: line => { if (line.includes("KeyboardLayout")) queryProc.running = true }
        }
    }
}
