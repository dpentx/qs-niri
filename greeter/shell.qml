//@ pragma Env QS_NO_RELOAD_POPUP=1

import Quickshell
import Quickshell.Services.Greetd
import QtQuick 6.10
import "../modules/lock"

// One UI login screen for greetd. Run it inside a kiosk compositor:
//   cage -s -- env QS_GREETER_USER=kullanici quickshell -p <qs-niri>/greeter
// (nix/nixos.nix sets this up). Environment:
//   QS_GREETER_USER       user name to prefill
//   QS_GREETER_CMD        session command, default "niri-session"
//   QS_GREETER_WALLPAPER  wallpaper image (must be readable by the greeter user)
ShellRoot {
    id: root

    // Same interface the lock screen gives LockContent.
    property bool busy: false
    property string error: ""
    property string userName: Quickshell.env("QS_GREETER_USER") || ""
    property string pending: ""
    readonly property bool askUser: true
    readonly property bool showPower: true
    readonly property string wallpaper: Quickshell.env("QS_GREETER_WALLPAPER") || ""
    signal attemptFinished()

    function fail(message) {
        busy = false
        pending = ""
        error = message
        attemptFinished()
    }

    function submit(password) {
        if (busy || password.length === 0 || userName.length === 0) return
        if (!Greetd.available) { fail("greetd bulunamadı (GREETD_SOCK yok)"); return }
        busy = true
        error = ""
        pending = password
        Greetd.createSession(userName)
    }

    Connections {
        target: Greetd
        function onAuthMessage(message, isError, responseRequired, echoResponse) {
            if (responseRequired) Greetd.respond(root.pending)
            else if (isError) root.error = message
        }
        function onAuthFailure(message) { root.fail("Kullanıcı adı ya da parola yanlış") }
        function onError(message) { root.fail(message) }
        function onReadyToLaunch() {
            Greetd.launch((Quickshell.env("QS_GREETER_CMD") || "niri-session").split(" "))
        }
    }

    // xdg-toplevel, so any kiosk compositor (cage) can make it fullscreen.
    FloatingWindow {
        visible: true
        color: "black"
        implicitWidth: 1280
        implicitHeight: 720
        LockContent { anchors.fill: parent; lock: root }
    }
}
