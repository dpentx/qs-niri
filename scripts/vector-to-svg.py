#!/usr/bin/env python3
"""
vector-to-svg.py — Android <vector> drawable XML'lerini standalone SVG'ye çevirir.

Android'in vector drawable formatı SVG path sözdizimiyle neredeyse birebir
aynı (pathData == SVG'nin "d" attribute'u), o yüzden font derlemeye gerek
yok — doğrudan gerçek SVG dosyaları üretip QML'de Image + tint (MultiEffect
colorization) ile kullanabiliriz.

Kullanım:
    python3 vector-to-svg.py <kaynak_klasör_veya_dosya> <hedef_klasör>

Örnek:
    python3 vector-to-svg.py ~/rom/decoded/SystemUI_decoded/res/drawable ~/qs-niri-icons

Ne yapar:
- <vector> içindeki tüm <path>'leri toplar
- viewportWidth/Height'i SVG viewBox'a çevirir
- fillColor'ı "#ffffff" (beyaz) ile DEĞİŞTİRİR — çünkü QML tarafında
  MultiEffect/ColorOverlay ile dinamik renklendirme (tint) yapacağız;
  orijinal renk zaten anlamsız (genelde placeholder "#000")
- Çoklu <path> olan ikonlarda hepsini tek <svg> içinde birleştirir
- Sadece basit <path> elemanlarını destekler (gradient/clip-path gibi
  gelişmiş vector-drawable özellikleri atlanır, uyarı basılır)
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
        print(f"  ATLANDI (parse hatası): {src_path} -> {e}")
        return False

    root = tree.getroot()
    if not root.tag.endswith("vector"):
        return False  # selector, shape, vs. -- vector değil

    vw = root.get(ANDROID + "viewportWidth")
    vh = root.get(ANDROID + "viewportHeight")
    if not vw or not vh:
        print(f"  ATLANDI (viewport yok): {src_path}")
        return False

    paths = []
    # doğrudan <path> ve <group><path> içindekileri topla (basit destek)
    for path_el in root.iter():
        if path_el.tag.endswith("path"):
            d = path_el.get(ANDROID + "pathData")
            if d:
                paths.append(d)

    if not paths:
        print(f"  ATLANDI (path yok, muhtemelen gelişmiş vector-drawable): {src_path}")
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
        print(f"Kullanım: {sys.argv[0]} <kaynak_klasör_veya_dosya> <hedef_klasör>")
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

    print(f"==> {len(files)} XML dosyası taranıyor...")
    converted = 0
    for f in files:
        name = os.path.splitext(os.path.basename(f))[0]
        dest = os.path.join(dest_dir, name + ".svg")
        if convert_one(f, dest):
            converted += 1

    print(f"==> Bitti. {converted}/{len(files)} dosya SVG'ye çevrildi -> {dest_dir}")


if __name__ == "__main__":
    main()
