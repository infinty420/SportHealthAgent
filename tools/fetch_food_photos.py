# AI 生成 —— 食物真实图片下载脚本（Wikimedia Commons 公开授权图片，离线下载后内置到 App）
# 运行时 App 不联网；仅开发阶段下载一次并打包进 media 资源。
import json
from pathlib import Path

import requests

MEDIA = Path(__file__).resolve().parent.parent / "entry/src/main/resources/base/media"

# (资源名, Commons 搜索词)
FOODS = [
    ("food_chicken", "chicken breast meat cooked"),
    ("food_egg", "boiled eggs"),
    ("food_yogurt", "greek yogurt bowl"),
    ("food_tofu", "tofu blocks"),
    ("food_oats", "oatmeal bowl"),
    ("food_rice", "steamed rice bowl"),
    ("food_sweetpotato", "baked sweet potato"),
    ("food_bread", "whole grain bread loaf"),
    ("food_avocado", "avocado fruit half seed"),
    ("food_nuts", "mixed nuts bowl"),
    ("food_oliveoil", "olive oil bottle"),
]

API = "https://commons.wikimedia.org/w/api.php"
HEADERS = {"User-Agent": "SportHealthAgent-asset-fetch/1.0 (competition project)"}


def find_thumb(query: str) -> str | None:
    """在 Wikimedia Commons 搜索图片，返回 256px 缩略图 URL。"""
    params = {
        "action": "query", "format": "json",
        "generator": "search", "gsrnamespace": 6, "gsrlimit": 5,
        "gsrsearch": f"filetype:bitmap {query}",
        "prop": "imageinfo", "iiprop": "url|mime", "iiurlwidth": 320,
    }
    resp = requests.get(API, params=params, headers=HEADERS, timeout=30)
    resp.raise_for_status()
    pages = resp.json().get("query", {}).get("pages", {})
    for page in pages.values():
        info = (page.get("imageinfo") or [{}])[0]
        mime = info.get("mime", "")
        thumb = info.get("thumburl")
        if thumb and mime in ("image/jpeg", "image/png"):
            return thumb
    return None


def main() -> None:
    results = {}
    for name, query in FOODS:
        if (MEDIA / f"{name}.jpg").exists():
            results[name] = "SKIP_EXISTS"
            print(f"[SKIP] {name}.jpg 已存在")
            continue
        try:
            url = find_thumb(query)
            if url is None:
                results[name] = "NOT_FOUND"
                print(f"[FAIL] {name}: no result")
                continue
            img = requests.get(url, headers=HEADERS, timeout=30)
            img.raise_for_status()
            if len(img.content) < 4096:
                results[name] = "TOO_SMALL"
                print(f"[FAIL] {name}: suspicious size {len(img.content)}")
                continue
            out = MEDIA / f"{name}.jpg"
            out.write_bytes(img.content)
            results[name] = "OK"
            print(f"[OK] {name}.jpg <- {url}")
        except Exception as e:
            results[name] = f"ERROR: {e}"
            print(f"[FAIL] {name}: {e}")
    print(json.dumps(results, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
