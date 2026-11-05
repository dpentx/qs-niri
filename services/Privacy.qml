pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Is something recording from the microphone? `pactl list short source-outputs` lists the apps reading an
// input; polled every 3 s once the first bar reads it (singletons start on first use).
// shortcut: microphone only; camera use cannot be told apart reliably without opening the devices.
Singleton {
    id: root

    property bool micActive: false

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!probe.running) probe.running = true
    }
    Process {
        id: probe
        command: ["sh", "-c", "pactl list short source-outputs 2>/dev/null | grep -c ."]
        stdout: StdioCollector { onStreamFinished: root.micActive = parseInt(text) > 0 }
    }
}
