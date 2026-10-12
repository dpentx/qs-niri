#!/usr/bin/env python3
"""A fake MPRIS player, so the bar's media pill has something to show."""
import asyncio, sys
from dbus_next.aio import MessageBus
from dbus_next.service import ServiceInterface, method, dbus_property
from dbus_next import Variant, PropertyAccess

ART = sys.argv[1] if len(sys.argv) > 1 else ""
R = PropertyAccess.READ


class Root(ServiceInterface):
    def __init__(self): super().__init__("org.mpris.MediaPlayer2")
    @dbus_property(access=R)
    def CanQuit(self) -> "b": return False
    @dbus_property(access=R)
    def CanRaise(self) -> "b": return False
    @dbus_property(access=R)
    def HasTrackList(self) -> "b": return False
    @dbus_property(access=R)
    def Identity(self) -> "s": return "Fake Player"
    @dbus_property(access=R)
    def SupportedUriSchemes(self) -> "as": return []
    @dbus_property(access=R)
    def SupportedMimeTypes(self) -> "as": return []
    @method()
    def Quit(self): pass
    @method()
    def Raise(self): pass


class Player(ServiceInterface):
    def __init__(self): super().__init__("org.mpris.MediaPlayer2.Player")
    @dbus_property(access=R)
    def PlaybackStatus(self) -> "s": return "Playing"
    @dbus_property(access=R)
    def Metadata(self) -> "a{sv}":
        m = {
            "mpris:trackid": Variant("o", "/org/fake/1"),
            "mpris:length": Variant("x", 214_000_000),
            "xesam:title": Variant("s", "Midnight City Lights Over the Water"),
            "xesam:artist": Variant("as", ["Fake Artist"]),
            "xesam:album": Variant("s", "Fake Album"),
        }
        if ART: m["mpris:artUrl"] = Variant("s", "file://" + ART)
        return m
    @dbus_property(access=R)
    def Position(self) -> "x": return 83_000_000
    @dbus_property(access=R)
    def Volume(self) -> "d": return 1.0
    @dbus_property(access=R)
    def Rate(self) -> "d": return 1.0
    @dbus_property(access=R)
    def MinimumRate(self) -> "d": return 1.0
    @dbus_property(access=R)
    def MaximumRate(self) -> "d": return 1.0
    @dbus_property(access=R)
    def CanGoNext(self) -> "b": return True
    @dbus_property(access=R)
    def CanGoPrevious(self) -> "b": return True
    @dbus_property(access=R)
    def CanPlay(self) -> "b": return True
    @dbus_property(access=R)
    def CanPause(self) -> "b": return True
    @dbus_property(access=R)
    def CanSeek(self) -> "b": return True
    @dbus_property(access=R)
    def CanControl(self) -> "b": return True
    @method()
    def Next(self): pass
    @method()
    def Previous(self): pass
    @method()
    def PlayPause(self): pass
    @method()
    def Play(self): pass
    @method()
    def Pause(self): pass
    @method()
    def Stop(self): pass
    @method()
    def Seek(self, o: "x"): pass


async def main():
    bus = await MessageBus().connect()
    await bus.request_name("org.mpris.MediaPlayer2.fake")
    bus.export("/org/mpris/MediaPlayer2", Root())
    bus.export("/org/mpris/MediaPlayer2", Player())
    print("mpris ready", flush=True)
    await asyncio.get_event_loop().create_future()

asyncio.run(main())
