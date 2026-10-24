pragma Singleton

import Quickshell
import Quickshell.Bluetooth
import QtQuick

Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var connectedDevices: Bluetooth.devices.values.filter(device => device.connected)
    // false on machines without a Bluetooth controller: the UI hides every Bluetooth entry
    readonly property bool available: adapter !== null
    readonly property bool powered: adapter?.enabled ?? false
    readonly property bool connected: connectedDevices.length > 0
    readonly property string deviceName: connected ? (connectedDevices[0]?.name ?? connectedDevices[0]?.alias ?? "Device") : ""
    readonly property int connectedCount: connectedDevices.length

    // Icon file name for a device: BlueZ's icon class first, the name as a hint for what it cannot tell
    // apart (earbuds vs headphones, watches).
    function iconFor(device) {
        const icon = device?.icon ?? "", name = device?.name ?? ""
        if (/buds|pods|earbud|earphone/i.test(name)) return "ic_bt_untethered_earbuds"
        if (/watch|band|fit/i.test(name)) return "ic_hotspot_watch"
        if (icon.includes("headphone") || icon.includes("headset")) return "ic_headphone"
        if (icon.includes("audio")) return "ic_media_speaker_device"
        if (icon.includes("phone")) return "ic_hotspot_phone"
        if (icon.includes("tablet")) return "ic_hotspot_tablet"
        if (icon.includes("computer")) return "ic_hotspot_laptop"
        if (icon.includes("video") || /tv/i.test(name)) return "ic_device_tv_on"
        if (icon.includes("gaming")) return "sec_bluetooth_2d_game"
        if (icon.includes("mouse")) return "sec_bluetooth_2d_mouse"
        if (icon.includes("keyboard")) return "sec_bluetooth_2d_keyboard"
        return "sec_bluetooth_2d_bluetooth"
    }

    function togglePower() {
        if (adapter)
            adapter.enabled = !adapter.enabled
    }

    function setDiscovering(enabled: bool) {
        if (adapter)
            adapter.discovering = enabled
    }
}
