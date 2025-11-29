pragma Singleton

import Quickshell
import Quickshell.Services.Mpris
import QtQuick 6.10

Singleton {
    id: root

    readonly property var list: Mpris.players.values
    
    // Consumer visibility control - set to false to pause polling when UI is hidden
    property bool visible: true
    
    // Active player should be the currently playing one, or first in list if none playing
    property var active: {
        // Find the first playing player
        for (var i = 0; i < list.length; i++) {
            if (list[i]?.isPlaying) {
                return list[i]
            }
        }
        // If no player is playing, return the first one
        return list[0] ?? null
    }
    
    // React to MPRIS player changes via Connections (event-driven)
    Connections {
        target: Mpris.players
        
        function onValuesChanged() {
            root.updateActivePlayer()
        }
    }
    
    function updateActivePlayer() {
        var newActive = null
        // Find the first playing player
        for (var i = 0; i < list.length; i++) {
            if (list[i]?.isPlaying) {
                newActive = list[i]
                break
            }
        }
        // If no player is playing, use first one
        if (!newActive && list.length > 0) {
            newActive = list[0]
        }
        // Update active if changed
        if (active !== newActive) {
            active = newActive
        }
    }
    
    // Fallback timer for edge cases (only runs when visible)
    Timer {
        interval: 2000  // Increased from 1000ms since we have event-driven updates
        running: root.visible && list.length > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: root.updateActivePlayer()
    }

    function getIdentity(player: var): string {
        return player?.identity ?? "Unknown";
    }
}
