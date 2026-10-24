import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import Quickshell.Io
import "../../../services" as QsServices
import "../../../components"
import "../../../components/effects"
import "../../../config" as QsConfig

// Per-network IPv4 settings (NetworkManager profile named after the SSID): automatic or manual
// address / netmask / gateway plus DNS servers. Everything goes to nmcli as separate arguments,
// never through a shell, and is validated first. IPv6 is left alone.
Item {
    id: root

    property string ssid: ""
    property bool isOpen: false
    property bool manual: false
    property string current: ""     // live values of the active connection
    property string errorText: ""
    property bool busy: false
    property bool wasActive: false

    readonly property var pywal: QsServices.Pywal
    readonly property color cText: pywal.foreground
    readonly property color cSub: Qt.rgba(cText.r, cText.g, cText.b, 0.6)
    readonly property color cField: Qt.rgba(cText.r, cText.g, cText.b, 0.08)

    anchors.fill: parent
    visible: opacity > 0
    opacity: isOpen ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: OneUIMotion.short3 } }

    function openFor(name, active) {
        ssid = name; wasActive = active
        errorText = ""; current = ""
        ipField.text = ""; maskField.text = ""; gwField.text = ""; dnsField.text = ""
        manual = false
        readProc.running = false
        readProc.running = true
        isOpen = true
    }
    function close() { isOpen = false }

    // ── helpers ──
    function ipOk(s) { return /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/.test(s) && s.split(".").every(n => +n <= 255) }
    function prefixToMask(p) {
        const out = []
        for (let i = 0; i < 4; i++) { const b = Math.max(0, Math.min(8, p - i * 8)); out.push(256 - Math.pow(2, 8 - b)) }
        return out.join(".")
    }
    // "24" or "255.255.255.0" -> 24, or -1 when invalid
    function toPrefix(s) {
        s = s.trim()
        if (/^\d{1,2}$/.test(s)) return +s <= 32 ? +s : -1
        if (!ipOk(s)) return -1
        const bits = s.split(".").map(n => (+n).toString(2).padStart(8, "0")).join("")
        return /^1*0*$/.test(bits) ? bits.indexOf("0") === -1 ? 32 : bits.indexOf("0") : -1
    }

    function save() {
        const dns = dnsField.text.split(/[\s,]+/).filter(d => d.length > 0)
        if (!dns.every(ipOk)) { errorText = "DNS servers must be IPv4 addresses"; return }
        let args = ["nmcli", "connection", "modify", "id", ssid]
        if (manual) {
            const p = toPrefix(maskField.text)
            if (!ipOk(ipField.text.trim())) { errorText = "Invalid IP address"; return }
            if (p < 0) { errorText = "Invalid netmask"; return }
            if (gwField.text.trim() !== "" && !ipOk(gwField.text.trim())) { errorText = "Invalid gateway"; return }
            args = args.concat(["ipv4.method", "manual", "ipv4.addresses", ipField.text.trim() + "/" + p,
                                "ipv4.gateway", gwField.text.trim()])
        } else {
            args = args.concat(["ipv4.method", "auto", "ipv4.addresses", "", "ipv4.gateway", ""])
        }
        // Custom DNS on an automatic profile must not be overridden by the DHCP-provided ones.
        args = args.concat(["ipv4.dns", dns.join(" "), "ipv4.ignore-auto-dns", dns.length > 0 ? "yes" : "no"])
        errorText = ""; busy = true
        saveProc.command = args
        saveProc.running = true
    }

    Process {
        id: readProc
        command: ["nmcli", "-t", "-f", "ipv4.method,ipv4.addresses,ipv4.gateway,ipv4.dns,IP4.ADDRESS,IP4.GATEWAY,IP4.DNS",
                  "connection", "show", "id", root.ssid]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = {}, live = { addr: [], dns: [] }
                text.split("\n").forEach(l => {
                    const i = l.indexOf(":"); if (i < 0) return
                    const k = l.slice(0, i), val = l.slice(i + 1).replace(/\\:/g, ":")
                    if (k.startsWith("IP4.ADDRESS")) live.addr.push(val)
                    else if (k.startsWith("IP4.DNS")) live.dns.push(val)
                    else if (k === "IP4.GATEWAY") live.gw = val
                    else v[k] = val
                })
                root.manual = v["ipv4.method"] === "manual"
                const first = (v["ipv4.addresses"] ?? "").split(",")[0].trim()
                if (first.includes("/")) {
                    ipField.text = first.split("/")[0]
                    maskField.text = root.prefixToMask(+first.split("/")[1])
                }
                gwField.text = v["ipv4.gateway"] ?? ""
                dnsField.text = (v["ipv4.dns"] ?? "").split(/[\s,]+/).filter(d => d).join(", ")
                if (live.addr.length > 0) {
                    const [a, p] = live.addr[0].split("/")
                    root.current = `${a}  ·  ${root.prefixToMask(+p)}  ·  gw ${live.gw || "-"}  ·  dns ${live.dns.join(", ") || "-"}`
                }
            }
        }
    }

    Process {
        id: saveProc
        stderr: StdioCollector { id: saveErr }
        onExited: (code) => {
            root.busy = false
            if (code !== 0) { root.errorText = saveErr.text.trim().split("\n").pop() || "nmcli failed"; return }
            // apply to the running connection right away
            if (root.wasActive) Quickshell.execDetached(["nmcli", "connection", "up", "id", root.ssid])
            root.close()
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.5)
        radius: QsConfig.Appearance.radius.l
        MouseArea { anchors.fill: parent; onClicked: root.close() }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(parent.width - 24, 320)
        height: Math.min(parent.height - 24, col.implicitHeight + 36)
        radius: QsConfig.Appearance.radius.m
        color: pywal.background
        scale: root.isOpen ? 1 : 0.92
        Behavior on scale { NumberAnimation { duration: OneUIMotion.short4; easing.type: Easing.OutBack } }
        clip: true

        ColumnLayout {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
            spacing: 10

            Text {
                text: root.ssid
                font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.xl; font.weight: Font.Bold
                color: root.cText
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Text {
                visible: root.current !== ""
                text: root.current
                font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.xxs
                color: root.cSub
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            // Automatic / Manual
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 34; radius: 17
                color: root.cField
                Rectangle {
                    width: parent.width / 2 - 3; height: parent.height - 6; y: 3
                    x: root.manual ? parent.width / 2 : 3
                    radius: 14; color: root.pywal.primary
                    Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                }
                Row {
                    anchors.fill: parent
                    Repeater {
                        model: ["Automatic (DHCP)", "Manual"]
                        Item {
                            required property string modelData
                            required property int index
                            width: parent.width / 2; height: parent.height
                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.xs; font.weight: 600
                                color: root.manual === (index === 1) ? root.pywal.onPrimary : root.cSub
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.manual = index === 1 }
                        }
                    }
                }
            }

            Field { id: ipField;   label: "IP address";            visible: root.manual }
            Field { id: maskField; label: "Netmask (or prefix)";  visible: root.manual; placeholder: "255.255.255.0" }
            Field { id: gwField;   label: "Gateway";               visible: root.manual }
            Field { id: dnsField;  label: "DNS servers (comma separated)"; placeholder: "1.1.1.1, 8.8.8.8" }

            Text {
                visible: root.errorText !== ""
                text: root.errorText
                font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.xs
                color: root.pywal.error
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Rectangle {
                    Layout.fillWidth: true; implicitHeight: 38; radius: 19
                    color: root.cField
                    Text { anchors.centerIn: parent; text: "Cancel"; font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.s; color: root.cText }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.close() }
                }
                Rectangle {
                    Layout.fillWidth: true; implicitHeight: 38; radius: 19
                    color: root.pywal.primary
                    opacity: root.busy ? 0.5 : 1
                    Text { anchors.centerIn: parent; text: root.busy ? "Saving…" : "Save"; font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.s; font.weight: 600; color: root.pywal.onPrimary }
                    MouseArea { anchors.fill: parent; enabled: !root.busy; cursorShape: Qt.PointingHandCursor; onClicked: root.save() }
                }
            }
        }
    }

    component Field: ColumnLayout {
        property alias text: input.text
        property string label: ""
        property string placeholder: ""
        Layout.fillWidth: true
        spacing: 3
        Text {
            text: parent.label
            font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.xxs
            color: root.cSub
        }
        Rectangle {
            Layout.fillWidth: true; implicitHeight: 34; radius: 12
            color: root.cField
            border.width: input.activeFocus ? 2 : 0
            border.color: root.pywal.primary
            TextInput {
                id: input
                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                verticalAlignment: TextInput.AlignVCenter
                font.family: "OneUI Sans"; font.pixelSize: QsConfig.Appearance.fontSize.s
                color: root.cText
                clip: true
                selectByMouse: true
                Keys.onReturnPressed: root.save()
                Keys.onEscapePressed: root.close()
            }
            Text {
                anchors { fill: parent; leftMargin: 12 }
                verticalAlignment: Text.AlignVCenter
                visible: input.text === "" && !input.activeFocus
                text: parent.parent.placeholder
                font: input.font
                color: Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.3)
            }
        }
    }
}
