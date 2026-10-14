pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "." as QsServices

Singleton {
    id: root

    readonly property list<AccessPoint> networks: []
    readonly property AccessPoint active: networks.find(n => n.active) ?? null
    property bool wifiEnabled: true
    readonly property bool scanning: rescanProc.running
    
    // Convenience properties for Control Center
    readonly property bool connected: active !== null
    readonly property string ssid: active?.ssid ?? "Not Connected"
    readonly property int signalStrength: active?.strength ?? 0
    
    property var savedNetworks: []
    
    // Consumer visibility control - set to false to pause polling when UI is hidden
    property bool pollingActive: true

    // Connection attempt feedback — lets the UI show a spinner while connecting
    // and surface a clear error (instead of silently doing nothing) on failure.
    property string connectingSsid: ""
    property string _lastConnectError: ""
    signal connectSucceeded(string ssid)
    signal connectFailed(string ssid, string reason)

    function enableWifi(enabled: bool): void {
        const cmd = enabled ? "on" : "off";
        enableWifiProc.exec(["nmcli", "radio", "wifi", cmd]);
    }

    function toggleWifi(): void {
        const cmd = wifiEnabled ? "off" : "on";
        enableWifiProc.exec(["nmcli", "radio", "wifi", cmd]);
    }

    function rescanWifi(): void {
        rescanProc.running = true;
    }

    function connectToNetwork(ssid: string, password: string): void {
        // Validate SSID to prevent command injection
        if (!ssid || ssid.trim().length === 0) {
            QsServices.Logger.warn("Network", "Invalid SSID: empty")
            return
        }
        
        // Check for dangerous characters that could be used for injection
        const dangerousChars = [";", "`", "$", "|", "&", "\n", "\r", "\\"]
        for (let i = 0; i < dangerousChars.length; i++) {
            if (ssid.includes(dangerousChars[i])) {
                QsServices.Logger.warn("Network", "Invalid SSID: contains dangerous character")
                return
            }
        }
        
        QsServices.Logger.info("Network", `Connecting to: ${ssid} ${password.length > 0 ? "(with password)" : "(saved)"}`)
        
        root.connectingSsid = ssid
        root._lastConnectError = ""
        
        if (password && password.length > 0) {
            // Connect to new network with password
            connectProc.exec(["nmcli", "dev", "wifi", "connect", ssid, "password", password]);
        } else {
            // Connect to saved network using connection name (which is usually the SSID)
            connectProc.exec(["nmcli", "connection", "up", "id", ssid]);
        }
    }

    function forgetNetwork(ssid: string): void {
        if (!ssid || ssid.trim().length === 0) return
        forgetProc.exec(["nmcli", "connection", "delete", "id", ssid]);
    }

    function refreshSavedNetworks(): void {
        checkSavedProc.running = true;
    }
    
    function isNetworkSaved(ssid: string): bool {
        refreshSavedNetworks();
        return savedNetworks.includes(ssid);
    }

    function disconnectFromNetwork(): void {
        if (active) {
            disconnectProc.exec(["nmcli", "connection", "down", active.ssid]);
        }
    }

    function getWifiStatus(): void {
        wifiStatusProc.running = true;
    }

    Process {
        running: true
        command: ["nmcli", "m"]
        stdout: SplitParser {
            onRead: { getNetworks.running = true; root.refreshDevices() }
        }
    }

    Process {
        id: wifiStatusProc

        running: true
        command: ["nmcli", "radio", "wifi"]
        environment: ({
                LANG: "C.UTF-8",
                LC_ALL: "C.UTF-8"
            })
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiEnabled = text.trim() === "enabled";
            }
        }
    }

    Process {
        id: enableWifiProc

        onExited: {
            root.getWifiStatus();
            getNetworks.running = true;
        }
    }

    Process {
        id: rescanProc

        command: ["nmcli", "dev", "wifi", "list", "--rescan", "yes"]
        onExited: {
            getNetworks.running = true;
        }
    }

    Process {
        id: connectProc

        stdout: SplitParser {
            onRead: data => {
                QsServices.Logger.debug("Network", `Connection output: ${data}`)
                getNetworks.running = true
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                root._lastConnectError = text.trim()
                if (text.trim().length > 0) {
                    QsServices.Logger.warn("Network", `Connection error: ${text.trim()}`)
                }
            }
        }
        onExited: (code, status) => {
            QsServices.Logger.debug("Network", `Connection exited code=${code} status=${status}`)
            getNetworks.running = true
            const attemptedSsid = root.connectingSsid
            root.connectingSsid = ""
            if (code === 0) {
                root.connectSucceeded(attemptedSsid)
            } else {
                root.connectFailed(attemptedSsid, root._lastConnectError)
            }
        }
    }

    Process {
        id: forgetProc
        onExited: {
            root.refreshSavedNetworks();
            getNetworks.running = true;
        }
    }

    Process {
        id: disconnectProc

        stdout: SplitParser {
            onRead: getNetworks.running = true
        }
    }
    
    Process {
        id: checkSavedProc
        
        command: ["nmcli", "-g", "NAME", "connection", "show"]
        environment: ({
                LANG: "C.UTF-8",
                LC_ALL: "C.UTF-8"
            })
        stdout: StdioCollector {
            onStreamFinished: {
                root.savedNetworks = text.trim().split('\n').filter(n => n.length > 0);
                // Keep logs quiet during periodic refresh; only emit on actual changes.
                const current = root.savedNetworks
                const prev = root._prevSavedNetworks
                let changed = current.length !== prev.length
                if (!changed) {
                    for (let i = 0; i < current.length; i++) {
                        if (current[i] !== prev[i]) {
                            changed = true
                            break
                        }
                    }
                }
                if (changed) {
                    root._prevSavedNetworks = current.slice(0)
                    QsServices.Logger.debug("Network", `Saved networks: ${root.savedNetworks.length}`)
                }
            }
        }
    }

    property var _prevSavedNetworks: []
    
    Component.onCompleted: {
        refreshSavedNetworks();
    }
    
    Timer {
        interval: 10000 // Update saved networks every 10 seconds
        running: root.pollingActive  // Pause when no consumer is visible
        repeat: true
        onTriggered: refreshSavedNetworks()
    }

    Process {
        id: getNetworks

        running: true
        command: ["nmcli", "-g", "ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY", "d", "w"]
        environment: ({
                LANG: "C.UTF-8",
                LC_ALL: "C.UTF-8"
            })
        stdout: StdioCollector {
            onStreamFinished: {
                const PLACEHOLDER = "STRINGWHICHHOPEFULLYWONTBEUSED";
                const rep = new RegExp("\\\\:", "g");
                const rep2 = new RegExp(PLACEHOLDER, "g");

                const allNetworks = text.trim().split("\n").map(n => {
                    const net = n.replace(rep, PLACEHOLDER).split(":");
                    return {
                        active: net[0] === "yes",
                        strength: parseInt(net[1]),
                        frequency: parseInt(net[2]),
                        ssid: net[3]?.replace(rep2, ":") ?? "",
                        bssid: net[4]?.replace(rep2, ":") ?? "",
                        security: net[5] ?? ""
                    };
                }).filter(n => n.ssid && n.ssid.length > 0);

                // Group networks by SSID and prioritize connected ones
                const networkMap = new Map();
                for (const network of allNetworks) {
                    const existing = networkMap.get(network.ssid);
                    if (!existing) {
                        networkMap.set(network.ssid, network);
                    } else {
                        // Prioritize active/connected networks
                        if (network.active && !existing.active) {
                            networkMap.set(network.ssid, network);
                        } else if (!network.active && !existing.active) {
                            // If both are inactive, keep the one with better signal
                            if (network.strength > existing.strength) {
                                networkMap.set(network.ssid, network);
                            }
                        }
                        // If existing is active and new is not, keep existing
                    }
                }

                const networks = Array.from(networkMap.values());

                const rNetworks = root.networks;

                const destroyed = rNetworks.filter(rn => !networks.find(n => n.frequency === rn.frequency && n.ssid === rn.ssid && n.bssid === rn.bssid));
                for (const network of destroyed)
                    rNetworks.splice(rNetworks.indexOf(network), 1).forEach(n => n.destroy());

                for (const network of networks) {
                    const match = rNetworks.find(n => n.frequency === network.frequency && n.ssid === network.ssid && n.bssid === network.bssid);
                    if (match) {
                        match.lastIpcObject = network;
                    } else {
                        rNetworks.push(apComp.createObject(root, {
                            lastIpcObject: network
                        }));
                    }
                }
            }
        }
    }

    // ── Adapters and hotspot ──────────────────────────────────────
    property bool hasWifiDevice: false
    property string wifiDevice: ""
    property bool hasEthernet: false
    property bool ethernetConnected: false
    property bool hotspotActive: false
    property bool hotspotBusy: false
    property string hotspotPsk: ""
    property bool _wantQr: false
    signal hotspotReady()
    readonly property string hotspotName: "qs-hotspot"
    readonly property string hotspotSsid: "qs-niri"

    function refreshDevices(): void {
        devDebounce.restart()
    }

    function toggleHotspot(): void {
        if (hotspotBusy || !hasWifiDevice) return
        hotspotBusy = true
        _wantQr = !hotspotActive
        if (hotspotActive) {
            hotspotProc.command = ["nmcli", "connection", "down", "id", hotspotName]
        } else {
            // Reuse the saved profile (and its password); otherwise create one
            // with a random password. The QR panel shows the credentials afterwards.
            const script = 'if nmcli -g NAME connection show | grep -qx "$2"; then nmcli connection up id "$2"; ' +
                'else pw=$(head -c 24 /dev/urandom | base64 | tr -dc "A-Za-z0-9" | head -c 10); ' +
                'nmcli device wifi hotspot ifname "$1" con-name "$2" ssid "$3" password "$pw"; fi'
            hotspotProc.command = ["sh", "-c", script, "sh", wifiDevice, hotspotName, hotspotSsid]
        }
        hotspotProc.running = true
    }

    Timer { id: devDebounce; interval: 300; onTriggered: { devProc.running = true; activeConnProc.running = true } }

    Timer {
        interval: 8000
        running: root.pollingActive
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshDevices()
    }

    Process {
        id: devProc
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE", "device"]
        environment: ({ LANG: "C.UTF-8", LC_ALL: "C.UTF-8" })
        stdout: StdioCollector {
            onStreamFinished: {
                let wifi = "", eth = false, ethUp = false
                for (const line of text.trim().split("\n")) {
                    const [dev, type, state] = line.split(":")
                    if (type === "wifi" && !wifi) wifi = dev
                    if (type === "ethernet") { eth = true; if (state === "connected") ethUp = true }
                }
                root.wifiDevice = wifi
                root.hasWifiDevice = wifi !== ""
                root.hasEthernet = eth
                root.ethernetConnected = ethUp
            }
        }
    }

    Process {
        id: activeConnProc
        command: ["nmcli", "-g", "NAME", "connection", "show", "--active"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.hotspotActive = text.split("\n").map(l => l.trim()).includes(root.hotspotName)
                if (root.hotspotActive && !root.hotspotPsk) pskProc.running = true
                if (!root.hotspotActive) root.hotspotPsk = ""
            }
        }
    }

    Process {
        id: pskProc
        command: ["nmcli", "-s", "-g", "802-11-wireless-security.psk", "connection", "show", root.hotspotName]
        stdout: StdioCollector {
            onStreamFinished: {
                root.hotspotPsk = text.trim()
                if (root._wantQr && root.hotspotPsk) { root._wantQr = false; root.hotspotReady() }
            }
        }
    }

    Process {
        id: hotspotProc
        stderr: StdioCollector {
            onStreamFinished: if (text.trim().length > 0) QsServices.Logger.warn("Network", `Hotspot: ${text.trim()}`)
        }
        onExited: {
            root.hotspotBusy = false
            root.hotspotPsk = ""
            root.refreshDevices()
            getNetworks.running = true
        }
    }

    component AccessPoint: QtObject {
        required property var lastIpcObject
        readonly property string ssid: lastIpcObject.ssid
        readonly property string bssid: lastIpcObject.bssid
        readonly property int strength: lastIpcObject.strength
        readonly property int frequency: lastIpcObject.frequency
        readonly property bool active: lastIpcObject.active
        readonly property string security: lastIpcObject.security
        readonly property bool isSecure: security.length > 0
    }

    Component {
        id: apComp

        AccessPoint {}
    }
}
