# AI 生成 —— 食物/动作示意图标生成脚本（PIL：圆角色块 + 中文单/双字，统一视觉风格）
# 产物输出到 entry/src/main/resources/base/media/，全部为本地内置资源，App 运行时不联网。
from PIL import Image, ImageDraw, ImageFont
from pathlib import Path

SIZE = 256
MEDIA = Path(__file__).resolve().parent.parent / "entry/src/main/resources/base/media"

# 候选 CJK 字体（按优先级）
FONT_CANDIDATES = [
    "C:/Windows/Fonts/msyh.ttc",
    "C:/Windows/Fonts/msyh.ttf",
    "C:/Windows/Fonts/simhei.ttf",
    "C:/Windows/Fonts/simsun.ttc",
]


def load_font(size: int) -> ImageFont.FreeTypeFont:
    for p in FONT_CANDIDATES:
        if Path(p).exists():
            return ImageFont.truetype(p, size)
    raise RuntimeError("未找到可用的中文字体，请检查 FONT_CANDIDATES")


# (文件名, 文字, 底色 RGB)
ASSETS = [
    # ---- 食物（11 种，与 DietPlanner 食材参考一致）----
    ("food_chicken", "鸡胸", (222, 120, 90)),
    ("food_egg", "蛋", (240, 190, 90)),
    ("food_yogurt", "酸奶", (245, 245, 250)),   # 浅色底配深字（见下方 SPECIAL_DARK_TEXT）
    ("food_tofu", "豆腐", (250, 240, 220)),
    ("food_oats", "燕麦", (200, 165, 110)),
    ("food_rice", "糙米", (170, 130, 90)),
    ("food_sweetpotato", "红薯", (215, 110, 70)),
    ("food_bread", "全麦", (190, 150, 100)),
    ("food_avocado", "牛油", (120, 160, 90)),
    ("food_nuts", "坚果", (160, 115, 75)),
    ("food_oliveoil", "橄榄", (130, 150, 80)),
    # ---- 动作分类（8 类，与 ExerciseLibrary 一致）----
    ("ex_chest", "胸", (75, 120, 220)),
    ("ex_back", "背", (60, 150, 170)),
    ("ex_legs", "腿", (230, 130, 60)),
    ("ex_shoulder", "肩", (150, 100, 210)),
    ("ex_arms", "臂", (220, 90, 110)),
    ("ex_core", "核心", (45, 160, 120)),
    ("ex_cardio", "有氧", (235, 90, 80)),
    ("ex_stretch", "拉伸", (100, 140, 200)),
]

# 浅色底使用深色文字
DARK_TEXT_BG = {"food_yogurt", "food_tofu"}


def render(name: str, text: str, bg: tuple) -> None:
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, SIZE, SIZE], radius=56, fill=bg + (255,))
    dark = name in DARK_TEXT_BG
    fg = (60, 55, 50, 255) if dark else (255, 255, 255, 255)
    font_size = 150 if len(text) == 1 else 110
    font = load_font(font_size)
    bbox = d.textbbox((0, 0), text, font=font)
    w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
    d.text(((SIZE - w) / 2 - bbox[0], (SIZE - h) / 2 - bbox[1]), text, font=font, fill=fg)
    img.save(MEDIA / f"{name}.png")
    print("saved:", name)


def main() -> None:
    MEDIA.mkdir(parents=True, exist_ok=True)
    for name, text, bg in ASSETS:
        render(name, text, bg)
    print(f"done, {len(ASSETS)} icons -> {MEDIA}")


if __name__ == "__main__":
    main()
