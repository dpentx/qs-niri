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
