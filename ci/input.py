#!/usr/bin/env python3
"""Long-lived virtual pointer for the CI (headless Sway has no input devices, so the nested niri would
never get a wl_pointer). Reads lines from a FIFO: "click X Y [left|right|middle]" or "move X Y".
usage: PYTHONPATH=<generated protocol dir> WAYLAND_DISPLAY=<sway> input.py <fifo> <width> <height>"""
import os, sys, time
from pywayland.client import Display
from pywayland.protocol.wayland import WlSeat
from wlr_virtual_pointer_unstable_v1 import ZwlrVirtualPointerManagerV1

fifo, W, H = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
BTN = {"left": 0x110, "right": 0x111, "middle": 0x112}
found = {}

display = Display()
display.connect()
registry = display.get_registry()

def on_global(reg, name, iface, version):
    if iface == "wl_seat" and "seat" not in found:
        found["seat"] = reg.bind(name, WlSeat, min(version, 5))
    elif iface == "zwlr_virtual_pointer_manager_v1":
        found["mgr"] = reg.bind(name, ZwlrVirtualPointerManagerV1, 1)

registry.dispatcher["global"] = on_global
display.roundtrip()
ptr = found["mgr"].create_virtual_pointer(found["seat"])
display.roundtrip()
t0 = time.monotonic()
now = lambda: int((time.monotonic() - t0) * 1000)

def move(x, y):
    ptr.motion_absolute(now(), x, y, W, H)
    ptr.frame()
    display.flush()

def button(b, down):
    ptr.button(now(), BTN[b], 1 if down else 0)
    ptr.frame()
    display.flush()

print("virtual pointer ready", flush=True)
with os.fdopen(os.open(fifo, os.O_RDWR), "r") as f:   # read-write open: the FIFO never reports EOF between writers
    for line in f:
        p = line.split()
        try:
            if p[0] == "move":
                move(int(p[1]), int(p[2]))
            elif p[0] == "click":
                b = p[3] if len(p) > 3 else "left"
                move(int(p[1]), int(p[2])); time.sleep(0.3)
                button(b, True); time.sleep(0.1); button(b, False)
        except Exception as e:           # a bad line must not kill the holder
            print("input.py:", line.strip(), e, flush=True)
