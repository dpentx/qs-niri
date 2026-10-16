#!/usr/bin/env python3
"""
vector-to-svg.py — converts Android <vector> drawable XMLs to standalone SVG.

Android's vector drawable format is almost identical to SVG path syntax
(pathData == SVG's "d" attribute), so there is no need to compile a font
— we produce real SVG files directly and use them in QML with Image + tint (MultiEffect
colorization).

Usage:
    python3 vector-to-svg.py <source_folder_or_file> <dest_folder>

Example:
    python3 vector-to-svg.py ~/rom/decoded/SystemUI_decoded/res/drawable ~/qs-niri-icons

What it does:
- collects all <path>s inside <vector>
- converts viewportWidth/Height to the SVG viewBox
- REPLACES fillColor with "#ffffff" (white) — because on the QML side
  we will do dynamic coloring (tint) with MultiEffect/ColorOverlay;
  the original color is meaningless anyway (usually a placeholder "#000")
- merges icons with multiple <path>s into a single <svg>
- supports only simple <path> elements (advanced vector-drawable features
  like gradient/clip-path are skipped, a warning is printed)
"""
import sys
import os
import re
import xml.etree.ElementTree as ET

NS = {"android": "http://schemas.android.com/apk/res/android"}
ANDROID = "{http://schemas.android.com/apk/res/android}"


def convert_one(src_path, dest_path):
    try:
        tree = ET.parse(src_path)
    except ET.ParseError as e:
        print(f"  SKIPPED (parse error): {src_path} -> {e}")
        return False

    root = tree.getroot()
    if not root.tag.endswith("vector"):
        return False  # selector, shape, etc. -- not a vector

    vw = root.get(ANDROID + "viewportWidth")
    vh = root.get(ANDROID + "viewportHeight")
    if not vw or not vh:
        print(f"  SKIPPED (no viewport): {src_path}")
        return False

    paths = []
    # collect those directly under <path> and <group><path> (simple support)
    for path_el in root.iter():
        if path_el.tag.endswith("path"):
            d = path_el.get(ANDROID + "pathData")
            if d:
                paths.append(d)

    if not paths:
        print(f"  SKIPPED (no path, probably an advanced vector-drawable): {src_path}")
        return False

    path_tags = "\n".join(f'  <path d="{d}" fill="#ffffff" />' for d in paths)
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {vw} {vh}">
{path_tags}
</svg>
'''
    with open(dest_path, "w") as f:
        f.write(svg)
    return True


def main():
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <source_folder_or_file> <dest_folder>")
        sys.exit(1)

    src = sys.argv[1]
    dest_dir = sys.argv[2]
    os.makedirs(dest_dir, exist_ok=True)

    if os.path.isfile(src):
        files = [src]
    else:
        files = []
        for dirpath, _, filenames in os.walk(src):
            for fn in filenames:
                if fn.endswith(".xml"):
                    files.append(os.path.join(dirpath, fn))

    print(f"==> Scanning {len(files)} XML files...")
    converted = 0
    for f in files:
        name = os.path.splitext(os.path.basename(f))[0]
        dest = os.path.join(dest_dir, name + ".svg")
        if convert_one(f, dest):
            converted += 1

    print(f"==> Done. {converted}/{len(files)} files converted to SVG -> {dest_dir}")


if __name__ == "__main__":
    main()
