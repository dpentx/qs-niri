"""
Bir moewalls.com wallpaper detay sayfasından gerçek video dosyasının
(.webm / .mp4) tam URL'sini çıkarır. Playwright'a ihtiyaç yok çünkü
video path'i sayfanın statik HTML'inde gömülü geliyor (JS render gerekmiyor).

Kullanım:
    python3 mw_resolve.py "https://moewalls.com/anime/serina-blue-archive-live-wallpaper/"

Çıktı (stdout): tek satır, video dosyasının tam URL'si. Bulunamazsa boş satır.
"""
import re
import sys
import urllib.request

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"

VIDEO_RE = re.compile(r'(/wp-content/uploads/preview/[^\s"\'<>]+?\.(?:webm|mp4))')


def resolve(detail_url: str) -> str:
    req = urllib.request.Request(detail_url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=15) as resp:
        html = resp.read().decode("utf-8", errors="ignore")

    m = VIDEO_RE.search(html)
    if not m:
        return ""

    path = m.group(1)
    if path.startswith("http"):
        return path
    return "https://moewalls.com" + path


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("")
        sys.exit(1)
    try:
        print(resolve(sys.argv[1]))
    except Exception as e:
        print("", file=sys.stdout)
        print(f"HATA: {e}", file=sys.stderr)
