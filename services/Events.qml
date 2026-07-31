pragma Singleton

import QtQuick 6.10
import Quickshell
import "." as QsServices

// Simple event bus for shell-wide events
Singleton {
    id: root

    signal shellOutsideClick(var data)

    function emitShellOutsideClick(x, y, globalX, globalY) {
        var payload = { x: x, y: y, globalX: globalX, globalY: globalY }
        root.shellOutsideClick(payload)
        QsServices.Logger && QsServices.Logger.debug && QsServices.Logger.debug("Events", "shellOutsideClick emitted: " + JSON.stringify(payload))
    }
}
