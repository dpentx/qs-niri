import QtQuick 6.10
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import "../../config" as QsConfig

// Session lock: ext-session-lock-v1 covers every screen, PAM checks the password.
//
// `shouldShow` can only be switched ON from outside (touch /tmp/qs-lock, the
// Control Center, the power menu, idle timeout); unlocking needs the password.
//
// If the shell dies while locked the compositor keeps the session locked, so a
// marker file in $XDG_RUNTIME_DIR makes the next shell start lock again and
// ask for the password, instead of leaving you with a dead screen.
Scope {
    id: root

    property bool shouldShow: false
    property bool busy: false
    property string error: ""
    signal attemptFinished()

    // LockContent is shared with the greeter, which overrides these.
    readonly property bool askUser: false
    readonly property bool showPower: false
    readonly property string wallpaper: ""
    property string userName: ""

    readonly property string marker: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/qs-niri-locked"

    onShouldShowChanged: Quickshell.execDetached(["sh", "-c", shouldShow ? 'touch "$1"' : 'rm -f "$1"', "sh", marker])

    // Re-lock after a crash / reload that happened while locked.
    Process {
        command: ["test", "-e", root.marker]
        running: true
        onExited: code => { if (code === 0) root.shouldShow = true }
    }

    // `loginctl lock-session` (and anything else that asks logind to lock) emits Session.Lock; suspending
    // emits Manager.PrepareForSleep(true). Both lock the screen. shortcut: no systemd delay inhibitor is held,
    // so on a fast suspend the lock surface may not be up before the machine sleeps; wake shows it anyway.
    Process {
        id: logind
        property bool sleepSignal: false
        command: ["dbus-monitor", "--system",
                  "type='signal',interface='org.freedesktop.login1.Session',member='Lock'",
                  "type='signal',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                if (line.includes("member=Lock")) root.shouldShow = true
                else if (line.includes("member=PrepareForSleep")) logind.sleepSignal = true
                else if (logind.sleepSignal && line.includes("boolean")) {
                    if (line.includes("true")) root.shouldShow = true
                    logind.sleepSignal = false
                }
            }
        }
    }

    function submit(password) {
        if (busy || password.length === 0) return
        busy = true
        error = ""
        pam.pending = password
        if (!pam.start()) {
            busy = false
            error = "Could not start PAM"
            attemptFinished()
        }
    }

    PamContext {
        id: pam
        config: QsConfig.Config.lock.pamService
        property string pending: ""

        onPamMessage: if (responseRequired) respond(pending)
        onCompleted: result => {
            pending = ""
            root.busy = false
            if (result === PamResult.Success) {
                root.error = ""
                root.shouldShow = false
            } else {
                root.error = result === PamResult.Error ? "Authentication failed (PAM error)" : "Wrong password"
            }
            root.attemptFinished()
        }
    }

    IdleMonitor {
        enabled: QsConfig.Config.lock.idleMinutes > 0 && !root.shouldShow
        timeout: QsConfig.Config.lock.idleMinutes * 60
        respectInhibitors: true
        onIsIdleChanged: if (isIdle) root.shouldShow = true
    }

    WlSessionLock {
        locked: root.shouldShow

        WlSessionLockSurface {
            color: "black"
            LockContent { anchors.fill: parent; lock: root }
        }
    }
}
