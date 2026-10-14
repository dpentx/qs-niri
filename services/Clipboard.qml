pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../config" as QsConfig

// Keeps the cliphist database filled so the clipboard history panel has
// something to show. Needs wl-clipboard and cliphist; without them it does
// nothing. A watcher that is already running (e.g. from the compositor
// config) is left alone.
Singleton {
    Process {
        running: QsConfig.Config.features.clipboard
        command: ["sh", "-c",
            "command -v cliphist >/dev/null && command -v wl-paste >/dev/null || exit 0; " +
            "pgrep -f 'wl-paste.*cliphist store' >/dev/null && exit 0; " +
            "wl-paste --type text --watch cliphist store & " +
            "exec wl-paste --type image --watch cliphist store"]
    }
}
