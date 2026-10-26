export CI_RES=1366x768   # small screen: checks Config.uiScale
# Runs before quickshell starts (CI_PREPARE): patch the checkout so the panel under test opens as needed.
# Taskbar menu / pin hooks (the real ones are a right-click and a menu click, which CI cannot send):
# touching /tmp/qs-ci-taskmenu opens the menu of the "firefox" icon, /tmp/qs-ci-pintoggle pins/unpins it.
python3 - "$REPO/modules/bar/components/Taskbar.qml" <<'PYX'
import sys
p = sys.argv[1]; s = open(p).read()
s = s.replace("import Quickshell\n", "import Quickshell\nimport Quickshell.Io\n", 1)
hook = ('                HoverHandler { id: hover }\n'
        '                FileView { path: "/tmp/qs-ci-taskmenu"; watchChanges: true; onFileChanged: if (cell.modelData.key === "firefox") menu.visible = true }\n'
        '                FileView { path: "/tmp/qs-ci-pintoggle"; watchChanges: true; onFileChanged: if (cell.modelData.key === "firefox") QsConfig.Config.togglePin(cell.entry) }\n')
assert s.count("                HoverHandler { id: hover }\n") == 1
s = s.replace("                HoverHandler { id: hover }\n", hook, 1)
open(p, "w").write(s)
PYX
: >/tmp/qs-ci-taskmenu
: >/tmp/qs-ci-pintoggle
# Launcher hooks: /tmp/qs-ci-launchact enters the actions view of the 2nd entry (Firefox) with the last action
# (the pin toggle) picked; /tmp/qs-ci-launchpin runs the picked action.
python3 - "$REPO/modules/launcher/LauncherWindow.qml" <<'PYX'
import sys
p = sys.argv[1]; s = open(p).read()
s = s.replace("import Quickshell\n", "import Quickshell\nimport Quickshell.Io\n", 1)
old = "    readonly property var currentActions: {"
assert s.count(old) == 1
s = s.replace(old, '    FileView { path: "/tmp/qs-ci-launchact"; watchChanges: true; onFileChanged: { root.selectedIndex = 1; root.enterActions(); root.actionIndex = root.currentActions.length - 1 } }\n'
                   '    FileView { path: "/tmp/qs-ci-launchpin"; watchChanges: true; onFileChanged: root.runAction(root.actionIndex) }\n' + old, 1)
open(p, "w").write(s)
PYX
: >/tmp/qs-ci-launchact
: >/tmp/qs-ci-launchpin
# Lock screen hook: touching /tmp/qs-ci-wrongpw sends a wrong password to the real PAM (the typed one is a click/keys).
python3 - "$REPO/modules/lock/LockScreen.qml" <<'PYX'
import sys
p = sys.argv[1]; s = open(p).read()
old = "    function submit(password) {"
assert s.count(old) == 1
s = s.replace(old, '    FileView { path: "/tmp/qs-ci-wrongpw"; watchChanges: true; onFileChanged: root.submit("definitely-not-the-password") }\n' + old, 1)
open(p, "w").write(s)
PYX
: >/tmp/qs-ci-wrongpw
