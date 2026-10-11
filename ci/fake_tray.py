#!/usr/bin/env python3
"""Registers two fake StatusNotifierItems on the session bus (what busctl
shows under org.kde.StatusNotifierWatcher) so the bar's tray can be seen."""
import asyncio, sys
from dbus_next.aio import MessageBus
from dbus_next.service import ServiceInterface, method, dbus_property, signal
from dbus_next import Variant


class Item(ServiceInterface):
    def __init__(self, ident, title, icon):
        super().__init__("org.kde.StatusNotifierItem")
        self.ident, self.title, self.icon = ident, title, icon

    @dbus_property(access=__import__("dbus_next").PropertyAccess.READ)
    def Category(self) -> "s": return "ApplicationStatus"
    @dbus_property(access=__import__("dbus_next").PropertyAccess.READ)
    def Id(self) -> "s": return self.ident
    @dbus_property(access=__import__("dbus_next").PropertyAccess.READ)
    def Title(self) -> "s": return self.title
    @dbus_property(access=__import__("dbus_next").PropertyAccess.READ)
    def Status(self) -> "s": return "Active"
    @dbus_property(access=__import__("dbus_next").PropertyAccess.READ)
    def IconName(self) -> "s": return self.icon
    @dbus_property(access=__import__("dbus_next").PropertyAccess.READ)
    def ItemIsMenu(self) -> "b": return False
    @method()
    def Activate(self, x: "i", y: "i"): print("activate", self.ident, flush=True)


async def main():
    buses = []
    for n, (ident, title, icon) in enumerate([("fake-files", "Files", "files"),
                                              ("fake-music", "Music", "music")]):
        bus = await MessageBus().connect()
        name = f"org.kde.StatusNotifierItem-{1000 + n}-1"
        await bus.request_name(name)
        bus.export("/StatusNotifierItem", Item(ident, title, icon))
        intro = await bus.introspect("org.kde.StatusNotifierWatcher", "/StatusNotifierWatcher")
        w = bus.get_proxy_object("org.kde.StatusNotifierWatcher", "/StatusNotifierWatcher", intro)
        await w.get_interface("org.kde.StatusNotifierWatcher").call_register_status_notifier_item(name)
        print("registered", name, flush=True)
        buses.append(bus)
    await asyncio.get_event_loop().create_future()

asyncio.run(main())
