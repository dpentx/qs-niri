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
    @dbus_property(access=__import__("dbus_next").PropertyAccess.READ)
    def Menu(self) -> "o": return "/Menu"
    @method()
    def Activate(self, x: "i", y: "i"): print("activate", self.ident, flush=True)


ENTRIES = [  # (id, label, type)
    (1, "Open", ""), (2, "Pause", ""), (3, "", "separator"),
    (4, "Preferences", ""), (5, "Quit", ""),
]


class Menu(ServiceInterface):
    """Minimal com.canonical.dbusmenu: a flat list of entries."""
    def __init__(self):
        super().__init__("com.canonical.dbusmenu")

    def _props(self, i, label, kind):
        d = {"label": Variant("s", label), "enabled": Variant("b", i != 4)}
        if kind: d["type"] = Variant("s", kind)
        return d

    @dbus_property(access=__import__("dbus_next").PropertyAccess.READ)
    def Version(self) -> "u": return 3
    @dbus_property(access=__import__("dbus_next").PropertyAccess.READ)
    def TextDirection(self) -> "s": return "ltr"
    @dbus_property(access=__import__("dbus_next").PropertyAccess.READ)
    def Status(self) -> "s": return "normal"

    @method()
    def GetLayout(self, parent: "i", depth: "i", names: "as") -> "u(ia{sv}av)":
        kids = [Variant("(ia{sv}av)", [i, self._props(i, l, k), []]) for i, l, k in ENTRIES]
        return [1, [0, {"children-display": Variant("s", "submenu")}, kids]]
    @method()
    def GetGroupProperties(self, ids: "ai", names: "as") -> "a(ia{sv})":
        return [[i, self._props(i, l, k)] for i, l, k in ENTRIES if i in ids]
    @method()
    def AboutToShow(self, i: "i") -> "b": return False
    @method()
    def Event(self, i: "i", e: "s", d: "v", t: "u"): print("menu event", i, e, flush=True)
    @method()
    def EventGroup(self, events: "a(isvu)") -> "ai": return []


async def main():
    buses = []
    for n, (ident, title, icon) in enumerate([("fake-files", "Files", "folder"),
                                              ("fake-music", "Music", "multimedia-audio-player")]):
        bus = await MessageBus().connect()
        name = f"org.kde.StatusNotifierItem-{1000 + n}-1"
        await bus.request_name(name)
        bus.export("/StatusNotifierItem", Item(ident, title, icon))
        bus.export("/Menu", Menu())
        intro = await bus.introspect("org.kde.StatusNotifierWatcher", "/StatusNotifierWatcher")
        w = bus.get_proxy_object("org.kde.StatusNotifierWatcher", "/StatusNotifierWatcher", intro)
        await w.get_interface("org.kde.StatusNotifierWatcher").call_register_status_notifier_item(name)
        print("registered", name, flush=True)
        buses.append(bus)
    await asyncio.get_event_loop().create_future()

asyncio.run(main())
