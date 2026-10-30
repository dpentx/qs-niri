pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../services" as QsServices

Singleton {
    id: root

    Component.onCompleted: file.reload()

    // shell.json is the base (may be read-only under Nix); user.json holds what the
    // settings panel changes and wins. Objects merge key by key, everything else is replaced.
    property var shellData: ({})
    property var userData: ({})
    readonly property var data: _merge(shellData, userData)

    function _merge(a, b) {
        const out = Object.assign({}, a)
        for (const k in b) {
            const isObj = v => v !== null && typeof v === "object" && !Array.isArray(v)
            out[k] = isObj(b[k]) && isObj(out[k]) ? _merge(out[k], b[k]) : b[k]
        }
        return out
    }

    // Persist one setting to user.json: set("lock.idleMinutes", 5), set("profile", "minimal").
    function set(path, value) {
        const next = JSON.parse(JSON.stringify(userData))
        const keys = path.split(".")
        let o = next
        keys.slice(0, -1).forEach(k => { if (typeof o[k] !== "object" || o[k] === null) o[k] = {}; o = o[k] })
        o[keys[keys.length - 1]] = value
        userData = next
        userFile.setText(JSON.stringify(next, null, 2))
    }

    // Drop every override made from the panel.
    function resetUser() {
        userData = ({})
        userFile.setText("{}")
    }

    function _expandHome(p) {
        if (!p || typeof p !== "string") return p
        if (p.startsWith("~/")) return `${Quickshell.env("HOME")}/${p.slice(2)}`
        return p
    }

    // ── Profiles ────────────────────────────────────────────────
    // "minimal" = core shell only, "base" = the everyday set, "bloated" =
    // everything. Individual switches can be overridden in shell.json:
    //   { "profile": "minimal", "features": { "clipboard": true } }
    readonly property string profile: ["minimal", "base", "bloated"].includes(data.profile) ? data.profile : "base"
    readonly property var _profileFeatures: ({
        //          gaming  recording hotspot speedtest taskManager clipboard quickToggles netSpeed taskbar lock files wallSwitch clock cast
        minimal: [  false,  false,    false,  false,    false,      false,    false,       false,   false,  false,  false,  false,  false,  false ],
        base:    [  true,   true,     true,   true,     true,       true,     false,       false,   false,  true,   true,   false,  true,   true  ],
        bloated: [  true,   true,     true,   true,     true,       true,     true,        true,    true,   true,   true,   true,   true,   true  ]
    })
    readonly property var features: {
        const names = ["gaming", "recording", "hotspot", "speedtest", "taskManager", "clipboard", "quickToggles", "netSpeed", "taskbar", "lock", "files", "wallSwitch", "clock", "cast"]
        const d = _profileFeatures[profile]
        const out = {}
        names.forEach((n, i) => out[n] = data.features?.[n] ?? d[i])
        return out
    }

    // Shell-wide size factor: 1 at 1080p and up, smaller on short screens (1366x768 ~ 0.87).
    // Override with appearance.uiScale in user.json.
    // shortcut: follows the first screen only, switch to per-screen if mixed monitors matter.
    readonly property real uiScale: data.appearance?.uiScale
        ?? Math.max(0.8, Math.min(1, 0.55 + 0.45 * (Quickshell.screens[0]?.height ?? 1080) / 1080))

    readonly property var appearance: ({
        fontFamily: data.appearance?.fontFamily ?? "OneUI Sans",
        materialIconFont: data.appearance?.materialIconFont ?? "Material Design Icons"
    })

    // Material You theme from matugen. `image` (optional) is themed at start-up when it
    // differs from the wallpaper last used; the wallpaper panel re-themes on every pick.
    readonly property var theme: ({
        mode: ["dark", "light", "smart"].includes(data.theme?.mode) ? data.theme.mode : "dark",
        scheme: data.theme?.scheme ?? "scheme-tonal-spot",
        image: _expandHome(data.theme?.image ?? "")
    })

    readonly property var paths: ({
        screenshotsDir: _expandHome(data.paths?.screenshotsDir ?? "~/Pictures/Screenshots")
    })

    readonly property var osd: ({
        volumeTimeoutMs: data.osd?.volumeTimeoutMs ?? 2000,
        brightnessTimeoutMs: data.osd?.brightnessTimeoutMs ?? 2000
    })

    readonly property var notifications: ({
        popupWidth: data.notifications?.popupWidth ?? 420,
        maxVisible: data.notifications?.maxVisible ?? 5,
        timeoutMs: data.notifications?.timeoutMs ?? 7000,
        registerServer: data.notifications?.registerServer ?? true,
        spacing: data.notifications?.spacing ?? 8,
        margin: data.notifications?.margin ?? 8
    })

    // Remembered position/size of the floating panels ({ files: { x, y, w, h }, ... }).
    readonly property var panels: data.panels ?? ({})

    // Gaming mode: switches power-profiles-daemon to "performance" and turns on
    // Do Not Disturb while a game is focused (or when toggled by hand).
    readonly property var gaming: ({
        autoDetect: features.gaming && (data.gaming?.autoDetect ?? true),
        // Extra regexes matched against the focused window's app_id, on top of
        // the built-ins (Steam/Proton `steam_app_<id>`, gamescope, Wine `*.exe`).
        appIds: data.gaming?.appIds ?? [],
        dnd: data.gaming?.dnd ?? true,
        inhibitIdle: data.gaming?.inhibitIdle ?? true,
        boostBrightness: data.gaming?.boostBrightness ?? false,
        graceSeconds: data.gaming?.graceSeconds ?? 6
    })

    // Lock screen (ext-session-lock + PAM). `pamService` is a file in
    // /etc/pam.d; "login" exists on every distro. `idleMinutes` 0 = never lock on idle.
    // Bar widgets: `barWidgets` is the enabled ids in order, `barCustom` your own definitions.
    readonly property var barBuiltins: [
        { id: "cpu",    label: "CPU", icon: "mdi_chip" },
        { id: "memory", label: "Memory",  icon: "mdi_memory" },
        { id: "disk",   label: "Disk",    icon: "mdi_harddisk" },
        { id: "gpu",    label: "GPU",     icon: "mdi_speedometer" }
    ]
    readonly property var barCustom: (data.bar?.custom ?? []).filter(w => typeof w?.id === "string" && typeof w?.exec === "string")
    readonly property var barAvailable: barBuiltins.concat(barCustom)
    // true: a fullscreen app covers the bar (it sits on the Top layer); false: the bar stays above fullscreen apps
    readonly property bool barHideOnFullscreen: data.bar?.hideOnFullscreen ?? true
    readonly property var barWidgets: Array.isArray(data.bar?.widgets) ? data.bar.widgets : []

    // Keyboard layouts managed from Settings: [{ layout: "us", variant: "" }, ...], first is the default.
    readonly property var keyboard: ({ layouts: Array.isArray(data.keyboard?.layouts) ? data.keyboard.layouts : [] })

    readonly property var lock: ({
        pamService: data.lock?.pamService ?? "",   // "" = modules/lock/pam/qs-lock
        idleMinutes: data.lock?.idleMinutes ?? 0,
        wallpaper: _expandHome(data.lock?.wallpaper ?? "")
    })

    // Pinned + open-window icons in the bar (on by default).
    readonly property var taskbar: ({
        enabled: data.taskbar?.enabled ?? true,
        maxItems: data.taskbar?.maxItems ?? 12,
        // pinned apps (desktop-entry ids or names); follows the launcher favourites until the first pin/unpin
        pinned: Array.isArray(data.taskbar?.pinned) ? data.taskbar.pinned : launcher.favorites
    })

    function isPinned(entry) {
        return !!entry && taskbar.pinned.some(f => f === entry.id || f === entry.name)
    }
    function togglePin(entry) {
        if (!entry) return
        const list = taskbar.pinned
        set("taskbar.pinned", isPinned(entry) ? list.filter(f => f !== entry.id && f !== entry.name) : [...list, entry.id])
    }

    // "dex": top status bar + bottom dock; "classic": the single full-width bottom bar
    readonly property string barLayout: data.bar?.layout === "classic" ? "classic" : "dex"

    // Samsung DeX layout and navigation options
    readonly property var dex: ({
        showNavButtons: data.dex?.showNavButtons ?? true,
        showCaptureButton: data.dex?.showCaptureButton ?? true,
        showDesktopButton: data.dex?.showDesktopButton ?? true
    })

    readonly property var launcher: ({
        enabled: data.launcher?.enabled ?? true,
        width: data.launcher?.width ?? 600,
        maxResults: data.launcher?.maxResults ?? 40,
        terminalCommand: data.launcher?.terminalCommand ?? ["foot"],
        favorites: data.launcher?.favorites ?? [
            "org.wezfurlong.wezterm",
            "kitty",
            "Alacritty",
            "firefox",
            "zen-browser",
            "thunar",
            "org.gnome.Nautilus",
            "code",
            "Code"
        ]
    })

    readonly property var sidebar: ({
        enabled: data.sidebar?.enabled ?? true,
        width: data.sidebar?.width ?? 420,
        margin: data.sidebar?.margin ?? 12,
        maxHistory: data.sidebar?.maxHistory ?? 80
    })

    readonly property var dashboard: ({
        enabled: data.dashboard?.enabled ?? true,
        width: data.dashboard?.width ?? 620,
        height: data.dashboard?.height ?? 460,
        margin: data.dashboard?.margin ?? 12
    })

    readonly property BarConfig bar: BarConfig {}
    readonly property AppearanceConfig appearanceTokens: AppearanceConfig {}

    FileView {
        id: file
        path: {
            const home = Quickshell.env("HOME")
            const xdg = Quickshell.env("XDG_CONFIG_HOME")
            const cfgHome = (xdg && xdg.length > 0) ? xdg : `${home}/.config`
            return `${cfgHome}/quickshell/shell.json`
        }
        watchChanges: true

        onLoaded: {
            try {
                const parsed = JSON.parse(text())
                root.shellData = parsed
                QsServices.Logger.debug("Config", "shell.json loaded")
                QsServices.Diagnostics.configOk(file.path)
            } catch (e) {
                QsServices.Logger.warn("Config", `Failed to parse shell.json: ${e?.message ?? e}`)
                QsServices.Diagnostics.configError(file.path, `not valid JSON (${e?.message ?? e})`)
            }
        }

        onFileChanged: {
            file.reload()
        }

        onLoadFailed: err => {
            if (err !== FileViewError.FileNotFound)
            {
                QsServices.Logger.warn("Config", `Failed to read shell.json: ${FileViewError.toString(err)}`)
                QsServices.Diagnostics.configError(file.path, FileViewError.toString(err))
            }
        }
    }

    readonly property string localDir: `${Quickshell.env("HOME")}/.config/quickshell-local`

    // The file must exist for inotify to see later edits.
    Process {
        id: mkLocal
        command: ["sh", "-c", `mkdir -p "${root.localDir}"; [ -e "${root.localDir}/user.json" ] || echo '{}' > "${root.localDir}/user.json"`]
        onExited: userFile.reload()
    }

    FileView {
        id: userFile
        path: `${root.localDir}/user.json`
        watchChanges: true
        Component.onCompleted: mkLocal.running = true

        onLoaded: {
            try {
                const parsed = JSON.parse(text())
                if (parsed && typeof parsed === "object") root.userData = parsed
                QsServices.Diagnostics.configOk(userFile.path)
            } catch (e) {
                QsServices.Logger.warn("Config", `user.json is not valid JSON, ignoring: ${e?.message ?? e}`)
                QsServices.Diagnostics.configError(userFile.path, `not valid JSON, ignored (${e?.message ?? e})`)
            }
        }
        onFileChanged: reload()
        onLoadFailed: err => {
            if (err !== FileViewError.FileNotFound)
            {
                QsServices.Logger.warn("Config", `Failed to read user.json: ${FileViewError.toString(err)}`)
                QsServices.Diagnostics.configError(userFile.path, FileViewError.toString(err))
            }
        }
    }

    // Backwards-compatible aliases used across the repo
    readonly property var controlCenter: ({
        width: 340,
        maxHeight: 600,
        padding: 14,
        spacing: 10,
        margin: 4,
        cornerRadius: 20
    })

    readonly property var popups: ({
        width: 280,
        minHeight: 100,
        maxHeight: 400,
        hoverDelay: 300,
        margin: 6
    })
}
