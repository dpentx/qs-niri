pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "." as QsServices
import "../config" as QsConfig

// Gaming mode.
//
// On:  power-profiles-daemon -> "performance" (no sudo, no sysfs writes),
//      Do Not Disturb, optional brightness boost.
// Off: the previous power profile and DND state come back.
//
// It can be toggled by hand, and (config `gaming.autoDetect`) turns itself on
// while the focused niri window looks like a game, judged by its app_id:
//   * Steam / Proton       steam_app_<id>
//   * gamescope            gamescope
//   * Wine / Proton exes   anything ending in .exe
//   * your own regexes     `gaming.appIds` in shell.json
// Alt-tabbing out does not flip it straight back: it stays on for
// `gaming.graceSeconds` after the game loses focus.
Singleton {
    id: root

    readonly property var cfg: QsConfig.Config.gaming

    property bool enabled: false          // gaming mode is currently on
    property bool manual: false           // switched on by hand (auto-detect never turns it off)
    property bool gameDetected: false     // focused window matches a game
    property string focusedAppId: ""

    readonly property bool auto: enabled && !manual

    // What to restore on exit
    property string _prevProfile: ""
    property bool _prevDnd: false

    readonly property var builtinPatterns: [
        "^steam_app_\\d+$",
        "^gamescope$",
        "\\.exe$"
    ]

    function isGame(appId) {
        if (!appId) return false
        const pats = builtinPatterns.concat(cfg.appIds ?? [])
        for (const p of pats) {
            try {
                if (new RegExp(p, "i").test(appId)) return true
            } catch (e) {
                QsServices.Logger.warn("GamingMode", `Bad gaming.appIds pattern: ${p}`)
            }
        }
        return false
    }

    function toggle() {
        if (enabled) {
            manual = false
            enabled = false
        } else {
            manual = true
            enabled = true
        }
    }

    onEnabledChanged: {
        QsServices.Logger.info("GamingMode", `Gaming mode ${enabled ? "ENABLED" : "DISABLED"}${auto ? " (auto)" : ""}`)
        if (enabled) {
            _prevProfile = pp.activeProfile
            _prevDnd = notifs.dnd
            if (pp.activeProfile !== "performance") pp.setProfile("performance")
            if (cfg.dnd) notifs.dnd = true
            if (cfg.boostBrightness && brightness.brightness < 0.8)
                brightness.setBrightness(1.0)
        } else {
            if (_prevProfile && _prevProfile !== "performance") pp.setProfile(_prevProfile)
            if (cfg.dnd) notifs.dnd = _prevDnd
        }
    }

    // ── focused window -> app_id ──────────────────────────────────
    Process {
        id: focusedProc
        command: ["niri", "msg", "-j", "focused-window"]
        stdout: StdioCollector {
            onStreamFinished: {
                let id = ""
                try { id = JSON.parse(text)?.app_id ?? "" } catch (e) { /* null / no window */ }
                root.focusedAppId = id
                root.gameDetected = root.isGame(id)
            }
        }
    }

    Timer {
        interval: 2000
        running: root.cfg.autoDetect
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!focusedProc.running) focusedProc.running = true
    }

    onGameDetectedChanged: {
        if (gameDetected) {
            graceTimer.stop()
            if (!enabled) { manual = false; enabled = true }
        } else if (auto) {
            graceTimer.restart()
        }
    }

    Timer {
        id: graceTimer
        interval: Math.max(0, root.cfg.graceSeconds) * 1000
        onTriggered: if (root.auto && !root.gameDetected) root.enabled = false
    }

    // Services this one drives
    readonly property var pp: QsServices.PowerProfiles
    readonly property var notifs: QsServices.Notifs
    readonly property var brightness: QsServices.Brightness
}
