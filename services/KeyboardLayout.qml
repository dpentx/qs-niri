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
