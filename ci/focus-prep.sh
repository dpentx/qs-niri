export CI_RES=1920x1080   # full HD (the user's screen)
# Bar widgets under test: cpu + memory pills (bar.widgets)
python3 - "$XDG_CONFIG_HOME/quickshell/shell.json" <<'PYW'
import sys, json
p = sys.argv[1]; d = json.load(open(p)); d.setdefault("bar", {})["widgets"] = ["cpu", "memory"]
json.dump(d, open(p, "w"))
PYW
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

# Task manager hardware view: tiles are picked with /tmp/qs-ci-pk-<key>; the CI VM has no Wi-Fi, GPU or NVMe, so fake ones are added
python3 - "$REPO/modules/taskmanager/TaskManagerWindow.qml" "$REPO/services/HardwareInfo.qml" "$REPO/services/SystemUsage.qml" <<'PYX'
import sys
tm, hw, su = sys.argv[1:4]
s = open(tm).read()
old = '    property string perfKey: "cpu"'
assert s.count(old) == 1
s = s.replace("import Quickshell\n", "import Quickshell\nimport Quickshell.Io\n", 1)
s = s.replace(old, old + "".join('\n    FileView { path: "/tmp/qs-ci-pk-%s"; watchChanges: true; onFileChanged: root.perfKey = "%s" }' % (k, k) for k in ["cpu", "disk", "eth", "wifi", "gpu"]), 1)
open(tm, "w").write(s)
s = open(hw).read()
for old, new in [
    ("root.ifaces = list", 'list.push({ name: "wlan0", kind: "wifi", state: "up", speed: 0, ip: "192.168.1.23/24", rx: 250000, tx: 40000 }); root.ifaces = list'),
    ("root.gpus = text.split", 'root.gpus = [{ slot: "01:00.0", driver: "nvidia", name: "NVIDIA GeForce RTX 3060", vram: 12884901888 }].concat(text.split'),
    ("root.disks = text.split", 'root.disks = [{ name: "nvme0n1", size: 512110190592, rotational: false, model: "Samsung SSD 970 EVO", link: "pcie:8.0 GT/s PCIe:4", rpm: 0 }, { name: "sda", size: 1000204886016, rotational: true, model: "WDC WD10EZEX", link: "sata:6.0 Gbps", rpm: 7200 }].concat(text.split'),
]:
    assert s.count(old) == 1, old
    s = s.replace(old, new, 1)
# the two .concat( calls need closing: the maps end with "})" on their own line
s = s.replace('return { slot: p[0], driver: p[1], name: (p[2] ?? "").trim(), vram: Number(p[3]) || 0 }\n            })', 'return { slot: p[0], driver: p[1], name: (p[2] ?? "").trim(), vram: Number(p[3]) || 0 }\n            }))', 1)
s = s.replace('rotational: p[2] === "1", model: p[3] ?? "", link: p[4] ?? "", rpm: Number(p[5]) || 0 }\n            })', 'rotational: p[2] === "1", model: p[3] ?? "", link: p[4] ?? "", rpm: Number(p[5]) || 0 }\n            }))', 1)
open(hw, "w").write(s)
s = open(su).read()
old = "hasGpu = type !== \"none\""
assert s.count(old) == 1
open(su, "w").write(s.replace(old, "hasGpu = true", 1))
PYX
for k in cpu disk eth wifi gpu; do : >/tmp/qs-ci-pk-$k; done
# Layout test: pretend a recording and gaming mode run (StatusPills in the dex top bar; the classic bar has its own pills)
python3 - "$REPO/modules/bar/components/StatusPills.qml" <<'PYX'
import sys
p = sys.argv[1]; s = open(p).read()
s = s.replace("on: QsConfig.Config.features.recording && QsServices.Screenshot.isRecording", "on: true", 1)
s = s.replace("(row.now - QsServices.Screenshot.recordStart)", "83000", 1)
s = s.replace("on: QsConfig.Config.features.gaming && QsServices.GamingMode.enabled", "on: true", 1)
open(p, "w").write(s)
PYX
# Feature tour hooks: clock opens on the Agenda, system tools on the Display/sound/power page,
# and /tmp/qs-ci-edit opens the screenshot editor on the wallpaper with a sample arrow + box
# (/tmp/qs-ci-save then renders it to <name>-edited.png).
sed -i 's/^    property int mode: 0 .*/    property int mode: 3/' "$REPO/modules/clock/ClockWindow.qml"
sed -i 's/^    property string selectedTab: "network".*/    property string selectedTab: "shell"/; s/^    property string shellPage: "profile"/    property string shellPage: "system"/' "$REPO/modules/systools/SystemToolsWindow.qml"
python3 - "$REPO/services/Screenshot.qml" "$REPO/modules/screenshot/EditorWindow.qml" "$WORK/bg.png" <<'PYX'
import sys
p, e, bg = sys.argv[1:4]
s = open(p).read()
s = s.replace("import Quickshell.Io\n", "import Quickshell.Io\n", 1)
s = s.replace("    property string editPath: \"\"\n", "    property string editPath: \"\"\n    FileView { path: \"/tmp/qs-ci-edit\"; watchChanges: true; onFileChanged: root.editPath = \"" + bg + "\" }\n", 1)
open(p, "w").write(s)
s = open(e).read()
s = s.replace("    onPathChanged: { shapes = []; crop = null; drag = null }", "    onPathChanged: { shapes = [{ t: \"arrow\", c: \"#ff3b30\", pts: [{x: 400, y: 700}, {x: 900, y: 400}] }, { t: \"box\", c: \"#ffcc00\", pts: [{x: 1000, y: 300}, {x: 1500, y: 700}] }, { t: \"hide\", c: \"#000\", pts: [{x: 200, y: 200}, {x: 500, y: 300}] }]; crop = null; drag = null }\n    FileView { path: \"/tmp/qs-ci-save\"; watchChanges: true; onFileChanged: root.render(() => {}) }", 1)
s = s.replace("import Quickshell.Io\n", "import Quickshell.Io\n", 1)
open(e, "w").write(s)
PYX
