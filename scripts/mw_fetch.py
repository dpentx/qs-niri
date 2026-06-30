import json
import sys
from playwright.sync_api import sync_playwright
from bs4 import BeautifulSoup


def fetch_moewalls(url: str):
    with sync_playwright() as p:
        browser = p.chromium.launch(
            headless=True,
            args=["--disable-blink-features=AutomationControlled"],
        )
        context = browser.new_context(
            user_agent=(
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
                "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
            ),
            viewport={"width": 1366, "height": 900},
        )
        page = context.new_page()

        page.goto(url, wait_until="domcontentloaded", timeout=30000)

        try:
            page.wait_for_selector("article", timeout=15000)
        except Exception:
            pass

        try:
            page.wait_for_load_state("networkidle", timeout=10000)
        except Exception:
            pass

        soup = BeautifulSoup(page.content(), "html.parser")
        results = []

        for art in soup.find_all("article")[:9]:
            media_link = art.select_one(".entry-featured-media a[href]")
            img = art.find("img")
            title_el = art.select_one(".entry-title a") or art.select_one(".entry-title")

            if not media_link or not img:
                continue

            results.append({
                "url": media_link["href"],
                "thumb": img.get("data-src") or img.get("src") or "",
                "title": title_el.get_text(strip=True) if title_el else "",
            })

        browser.close()
        return results


if __name__ == "__main__":
    target_url = sys.argv[1] if len(sys.argv) > 1 else "https://moewalls.com/"
    try:
        data = fetch_moewalls(target_url)
        print(json.dumps(data, ensure_ascii=False))
    except Exception as e:
        print(json.dumps([]))
        print(f"HATA: {e}", file=sys.stderr)
