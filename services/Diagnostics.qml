pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "." as QsServices

// What went wrong, and how to report it.
//   * a configuration file that cannot be read (Config.qml reports it here), or
//   * a Quickshell crash report left by the previous session
// both raise `kind`, which the DiagnosticsPopup shows with a ready-made GitHub issue.
// Home directories are replaced by "~" in everything that ends up in the popup or the issue.
Singleton {
    id: root

    readonly property string repo: "dpentx/qs-niri"
    readonly property string home: Quickshell.env("HOME")
    readonly property string shellPath: Qt.resolvedUrl("../").toString().replace("file://", "").replace(/\/$/, "")
    readonly property string stateDir: `${home}/.local/state/quickshell-local`

    property string version: "unknown"     // short commit, from git or the REV file of a Nix install
    property string qsVersion: ""

    property string kind: ""               // "" | "config" | "crash"
    property string title: ""
    property string detail: ""
    property string file: ""               // config file the problem is about
    property string crashDir: ""
    readonly property bool active: kind !== ""

    function scrub(t) { return (t || "").split(home).join("~") }

    function configError(path, message) {
        if (kind === "crash") return
        file = path
        kind = "config"
        title = "Configuration problem"
        detail = scrub(`${path}: ${message}`) + "\nThe shell keeps running with its defaults for this file."
    }
    function configOk(path) {
        if (kind === "config" && file === path) dismiss()
    }
    function dismiss() { kind = ""; title = ""; detail = ""; crashDir = "" }

    function issueUrl() {
        let body = `**What happened**\n${kind === "crash" ? "The shell crashed." : "The shell reported a configuration problem."}\n\n`
            + `**Details**\n\`\`\`\n${detail}\n\`\`\`\n\n`
            + `**Versions**\n- qs-niri: ${version}\n- ${qsVersion || "quickshell: unknown"}\n\n`
            + `**Config**\nPlease paste the relevant part of your shell.json / user.json here (remove anything private).\n`
        if (body.length > 5500) body = body.slice(0, 5500) + "\n…(truncated)"
        const t = kind === "crash" ? "Shell crashed" : "Configuration problem: " + scrub(file).split("/").pop()
        return `https://github.com/${repo}/issues/new?title=${encodeURIComponent(t)}&body=${encodeURIComponent(body)}`
    }
    function openUrl(u) { Quickshell.execDetached(["xdg-open", u]) }
    function infoText() { return `qs-niri ${version}\n${qsVersion}\nshell: ${scrub(shellPath)}` }
    function copyInfo() { Quickshell.execDetached(["wl-copy", "--", infoText()]) }
    function openIssue() { Quickshell.execDetached(["xdg-open", issueUrl()]) }
    function openFile() { if (file) Quickshell.execDetached(["xdg-open", file]) }
    function openCrashFolder() { if (crashDir) Quickshell.execDetached(["xdg-open", crashDir]) }

    // ── versions ──────────────────────────────────────────────
    Process {
        id: versionProc
        command: ["sh", "-c", 'cd "$1" && { git rev-parse --short HEAD 2>/dev/null || cat REV 2>/dev/null || echo unknown; }; quickshell --version 2>&1 | head -1', "sh", root.shellPath]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim().split("\n")
                root.version = l[0] || "unknown"
                root.qsVersion = l[1] || ""
            }
        }
    }

    // ── crash left by the previous session ───────────────────
    // The Quickshell crash reporter keeps one folder per crash (report.txt, log); the newest
    // one is compared with a marker so every crash is shown once.
    // shortcut: the reporter's folder is searched in the usual cache/state/runtime places, not read from Quickshell.
    Process {
        id: crashProc
        command: ["sh", "-c", `
            mkdir -p "$2"; marker="$2/last-crash"
            newest=$(for d in "\${XDG_CACHE_HOME:-$HOME/.cache}" "\${XDG_STATE_HOME:-$HOME/.local/state}" "\${XDG_RUNTIME_DIR:-/nonexistent}"; do
                find "$d/quickshell/crashes" -mindepth 1 -maxdepth 1 -type d -mtime -7 2>/dev/null
            done | xargs -r ls -1dt 2>/dev/null | head -1)
            [ -n "$newest" ] || exit 0
            [ "$(cat "$marker" 2>/dev/null)" = "$newest" ] && exit 0
            echo "$newest" > "$marker"
            echo "$newest"; head -n 40 "$newest/report.txt" 2>/dev/null`, "sh", root.home, root.stateDir]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.split("\n")
                if (!l[0].length || root.kind === "config") return
                root.crashDir = l[0]
                root.file = ""
                root.kind = "crash"
                root.title = "The shell crashed last time"
                root.detail = root.scrub(l.slice(1).join("\n").trim() || "No report text found in " + l[0])
            }
        }
    }
}
