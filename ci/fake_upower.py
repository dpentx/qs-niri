#!/usr/bin/env python3
"""Minimal org.freedesktop.UPower mock: one battery whose "<percent> <state>"
is read from /tmp/qs-battery (state 1 = charging, 2 = discharging)."""
import asyncio, os
from dbus_next.aio import MessageBus
from dbus_next.service import ServiceInterface, method, dbus_property
from dbus_next import PropertyAccess, BusType

STATE_FILE = "/tmp/qs-battery"
DEV = "/org/freedesktop/UPower/devices/DisplayDevice"


class Device(ServiceInterface):
    def __init__(self):
        super().__init__("org.freedesktop.UPower.Device")
        self.pct, self.state = 62.0, 2

    def _r(access=PropertyAccess.READ): return access
    @dbus_property(access=PropertyAccess.READ)
    def Type(self) -> "u": return 2
    @dbus_property(access=PropertyAccess.READ)
    def State(self) -> "u": return self.state
    @dbus_property(access=PropertyAccess.READ)
    def Percentage(self) -> "d": return self.pct
    @dbus_property(access=PropertyAccess.READ)
    def IsPresent(self) -> "b": return True
    @dbus_property(access=PropertyAccess.READ)
    def IsRechargeable(self) -> "b": return True
    @dbus_property(access=PropertyAccess.READ)
    def Energy(self) -> "d": return 30.0
    @dbus_property(access=PropertyAccess.READ)
    def EnergyFull(self) -> "d": return 50.0
    @dbus_property(access=PropertyAccess.READ)
    def EnergyRate(self) -> "d": return 8.0
    @dbus_property(access=PropertyAccess.READ)
    def TimeToEmpty(self) -> "x": return 7200
    @dbus_property(access=PropertyAccess.READ)
    def TimeToFull(self) -> "x": return 0
    @dbus_property(access=PropertyAccess.READ)
    def IconName(self) -> "s": return "battery-good-symbolic"

    def update(self, pct, state):
        self.pct, self.state = pct, state
        self.emit_properties_changed({"Percentage": pct, "State": state})


class UPower(ServiceInterface):
    def __init__(self):
        super().__init__("org.freedesktop.UPower")
    @method()
    def EnumerateDevices(self) -> "ao": return [DEV]
    @method()
    def GetDisplayDevice(self) -> "o": return DEV
    @dbus_property(access=PropertyAccess.READ)
    def OnBattery(self) -> "b": return True
    @dbus_property(access=PropertyAccess.READ)
    def DaemonVersion(self) -> "s": return "1.0"


async def main():
    bus = await MessageBus(bus_type=BusType.SESSION).connect()
    dev = Device()
    bus.export("/org/freedesktop/UPower", UPower())
    bus.export(DEV, dev)
    await bus.request_name("org.freedesktop.UPower")
    print("upower mock up", flush=True)
    last = None
    while True:
        try:
            cur = open(STATE_FILE).read().split()
            if cur != last and len(cur) == 2:
                dev.update(float(cur[0]), int(cur[1])); last = cur
                print("state", cur, flush=True)
        except FileNotFoundError:
            pass
        await asyncio.sleep(0.5)

asyncio.run(main())
