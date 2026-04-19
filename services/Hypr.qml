pragma Singleton

import Quickshell
import QtQuick 6.10

Singleton {
    id: root

    readonly property var toplevels: []
    readonly property var workspaces: []
    readonly property var monitors: []
    readonly property var activeToplevel: null
    readonly property var focusedWorkspace: null
    readonly property var focusedMonitor: null
    readonly property int activeWsId: 1

    function dispatch(request: string): void {}

    function monitorFor(screen: var): var {
        return null
    }

    function getOccupiedWorkspaces(): var {
        return {}
    }
}
