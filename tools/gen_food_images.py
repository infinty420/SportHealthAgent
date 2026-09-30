# AI 生成 —— 批量生成 39 张缺失食物图（写实白底方形），输出到 resources/base/media
# 用法：python tools/gen_food_images.py
# 依赖：image_generation 插件的 image_generation_tool.py（agent-gw SDK）
import concurrent.futures
import os
import subprocess
import sys

from PIL import Image

TOOL = "C:/Users/infinty/AppData/Roaming/kimi-desktop/daimon-share/daimon/runtime/kimi-code/home/plugins/managed/image_generation/scripts/image_generation_tool.py"
MEDIA_DIR = "C:/Users/infinty/DevEcoStudioProjects/SportHealthAgent/entry/src/main/resources/base/media"
RAW_DIR = "C:/Users/infinty/DevEcoStudioProjects/SportHealthAgent/tools/food_raw"

# (文件键, 中文名, 英文描述)
FOODS = [
    ("salmon", "三文鱼", "fresh raw salmon fillet slices"),
    ("shrimp", "虾", "cooked peeled shrimp on a small plate"),
    ("leanbeef", "瘦牛肉", "raw lean beef steak slices"),
    ("milk", "牛奶", "a glass of fresh milk"),
    ("proteinpowder", "蛋白粉", "whey protein powder scoop with a shaker bottle"),
    ("tuna", "金枪鱼", "canned tuna chunks in a white bowl"),
    ("chickenleg", "鸡腿肉", "raw skinless chicken drumsticks"),
    ("soymilk", "豆浆", "a glass of soy milk with soybeans beside"),
    ("quinoa", "藜麦", "cooked quinoa in a white bowl"),
    ("yam", "山药", "fresh Chinese yam root segments"),
    ("pasta", "意面", "dry spaghetti pasta bundle"),
    ("potato", "土豆", "fresh whole potatoes"),
    ("soba", "荞麦面", "buckwheat soba noodles"),
    ("pumpkin", "南瓜", "a slice of orange pumpkin"),
    ("peanutbutter", "花生酱", "peanut butter in a glass jar with a spoon"),
    ("chia", "奇亚籽", "chia seeds in a small white bowl"),
    ("cheese", "芝士", "a wedge of cheese"),
    ("darkchoc", "黑巧克力", "dark chocolate bar pieces"),
    ("coconutoil", "椰子油", "coconut oil in a glass jar with half a coconut"),
    ("broccoli", "西兰花", "fresh broccoli florets"),
    ("spinach", "菠菜", "fresh spinach leaves"),
    ("tomato", "番茄", "fresh red tomatoes"),
    ("cucumber", "黄瓜", "fresh cucumber, one whole and one sliced"),
    ("carrot", "胡萝卜", "fresh carrots"),
    ("lettuce", "生菜", "fresh green lettuce leaves"),
    ("bellpepper", "彩椒", "red and yellow bell peppers"),
    ("asparagus", "芦笋", "fresh green asparagus spears"),
    ("banana", "香蕉", "a bunch of ripe bananas"),
    ("blueberry", "蓝莓", "fresh blueberries in a small white bowl"),
    ("apple", "苹果", "a fresh red apple"),
    ("orange", "橙子", "a fresh orange, one whole and one half"),
    ("strawberry", "草莓", "fresh strawberries"),
    ("kiwi", "猕猴桃", "kiwi fruit, one whole and one half"),
    ("steamedrice", "米饭", "a bowl of steamed white rice"),
    ("noodles", "面条", "dry wheat noodles"),
    ("steamedbun", "馒头", "Chinese steamed buns mantou"),
    ("corn", "玉米", "a fresh corn cob"),
    ("multigrainrice", "杂粮饭", "a bowl of multigrain mixed rice"),
    ("baozi", "包子", "Chinese steamed stuffed buns baozi"),
]

PROMPT = ("Photorealistic studio food photography of {en} ({cn}), "
          "centered on a clean pure white background, soft even lighting, "
          "appetizing, high detail, square composition, no text, no watermark")


def gen_one(item):
    key, cn, en = item
    raw = os.path.join(RAW_DIR, f"food_{key}.jpg")
    final = os.path.join(MEDIA_DIR, f"food_{key}.jpg")
    if os.path.exists(final):
        return key, "skip-exists"
    cmd = [sys.executable, TOOL, "generate",
           "--description", PROMPT.format(en=en, cn=cn),
           "--size", "1024x1024", "--background", "opaque",
           "--output", raw]
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
    if not os.path.exists(raw):
        return key, f"FAIL: {r.stdout[-200:]} {r.stderr[-200:]}"
    im = Image.open(raw).convert("RGB").resize((512, 512), Image.LANCZOS)
    im.save(final, "JPEG", quality=82)
    return key, "ok"


def main():
    os.makedirs(RAW_DIR, exist_ok=True)
    done, failed = [], []
    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
        for key, status in pool.map(gen_one, FOODS):
            print(f"[{len(done)+len(failed)+1}/39] {key}: {status}", flush=True)
            (failed if status.startswith("FAIL") else done).append(key)
    print(f"DONE ok={len(done)} failed={len(failed)}: {failed}", flush=True)


if __name__ == "__main__":
    main()
