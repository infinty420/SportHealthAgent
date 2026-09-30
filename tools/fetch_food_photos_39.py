# AI 生成 —— 39 种缺图食物真实图片下载（Wikimedia Commons 公开授权图片，离线下载后内置到 App）
# 运行时 App 不联网；仅开发阶段下载一次并打包进 media 资源。
# 与 fetch_food_photos.py 同源，新增：中心方形裁剪 + 缩放 512x512（食物卡片为正方形）。
import io
import json
import time
from pathlib import Path

import requests
from PIL import Image

MEDIA = Path(__file__).resolve().parent.parent / "entry/src/main/resources/base/media"

# (资源名, Commons 搜索词)
FOODS = [
    ("food_salmon", "salmon fillet raw"),
    ("food_shrimp", "cooked shrimp plate"),
    ("food_leanbeef", "lean beef steak raw"),
    ("food_milk", "glass of milk"),
    ("food_proteinpowder", "whey protein"),
    ("food_tuna", "canned tuna"),
    ("food_chickenleg", "chicken drumsticks raw"),
    ("food_soymilk", "soy milk glass"),
    ("food_quinoa", "quinoa bowl cooked"),
    ("food_yam", "chinese yam root"),
    ("food_pasta", "spaghetti pasta dry"),
    ("food_potato", "potatoes"),
    ("food_soba", "soba noodles"),
    ("food_pumpkin", "pumpkin slice"),
    ("food_peanutbutter", "peanut butter jar"),
    ("food_chia", "chia seeds bowl"),
    ("food_cheese", "cheese wedge"),
    ("food_darkchoc", "dark chocolate bar"),
    ("food_coconutoil", "coconut oil jar"),
    ("food_broccoli", "broccoli florets"),
    ("food_spinach", "spinach leaves"),
    ("food_tomato", "tomatoes"),
    ("food_cucumber", "cucumber"),
    ("food_carrot", "carrots"),
    ("food_lettuce", "lettuce"),
    ("food_bellpepper", "bell peppers"),
    ("food_asparagus", "asparagus"),
    ("food_banana", "bananas"),
    ("food_blueberry", "blueberries bowl"),
    ("food_apple", "red apple"),
    ("food_orange", "orange fruit"),
    ("food_strawberry", "strawberries"),
    ("food_kiwi", "kiwi fruit"),
    ("food_steamedrice", "bowl of steamed rice"),
    ("food_noodles", "wheat noodles dry"),
    ("food_steamedbun", "mantou steamed bun"),
    ("food_corn", "corn cob"),
    ("food_multigrainrice", "multigrain rice bowl"),
    ("food_baozi", "baozi steamed bun"),
]

API = "https://commons.wikimedia.org/w/api.php"
HEADERS = {"User-Agent": "SportHealthAgent-asset-fetch/1.0 (competition project)"}


def find_thumb(query: str) -> str | None:
    """在 Wikimedia Commons 搜索图片，返回 512px 缩略图 URL（429 自动退避重试）。"""
    params = {
        "action": "query", "format": "json",
        "generator": "search", "gsrnamespace": 6, "gsrlimit": 5,
        "gsrsearch": f"filetype:bitmap {query}",
        "prop": "imageinfo", "iiprop": "url|mime", "iiurlwidth": 512,
    }
    resp = None
    for attempt in range(4):
        resp = requests.get(API, params=params, headers=HEADERS, timeout=30)
        if resp.status_code != 429:
            break
        wait = 20 * (attempt + 1)
        print(f"  ...429, sleep {wait}s", flush=True)
        time.sleep(wait)
    resp.raise_for_status()
    pages = resp.json().get("query", {}).get("pages", {})
    for page in pages.values():
        info = (page.get("imageinfo") or [{}])[0]
        mime = info.get("mime", "")
        thumb = info.get("thumburl")
        if thumb and mime in ("image/jpeg", "image/png"):
            return thumb
    return None


def square512(content: bytes) -> bytes:
    """中心裁剪为方形并缩放到 512x512 JPEG。"""
    im = Image.open(io.BytesIO(content)).convert("RGB")
    w, h = im.size
    side = min(w, h)
    im = im.crop(((w - side) // 2, (h - side) // 2, (w + side) // 2, (h + side) // 2))
    im = im.resize((512, 512), Image.LANCZOS)
    buf = io.BytesIO()
    im.save(buf, "JPEG", quality=82)
    return buf.getvalue()


def main() -> None:
    results = {}
    for name, query in FOODS:
        if (MEDIA / f"{name}.jpg").exists():
            results[name] = "SKIP_EXISTS"
            print(f"[SKIP] {name}.jpg 已存在", flush=True)
            continue
        try:
            url = find_thumb(query)
            if url is None:
                results[name] = "NOT_FOUND"
                print(f"[FAIL] {name}: no result", flush=True)
                continue
            img = requests.get(url, headers=HEADERS, timeout=30)
            img.raise_for_status()
            if len(img.content) < 4096:
                results[name] = "TOO_SMALL"
                print(f"[FAIL] {name}: suspicious size {len(img.content)}", flush=True)
                continue
            (MEDIA / f"{name}.jpg").write_bytes(square512(img.content))
            results[name] = "OK"
            print(f"[OK] {name}.jpg <- {url}", flush=True)
        except Exception as e:
            results[name] = f"ERROR: {e}"
            print(f"[FAIL] {name}: {e}", flush=True)
        time.sleep(4)  # 限速，避免触发 Commons 429
    print(json.dumps(results, ensure_ascii=False, indent=2), flush=True)


if __name__ == "__main__":
    main()
