# AI 生成 —— 应用图标生成脚本（PIL 绘制：品牌底色 + 心率脉冲线）
from PIL import Image, ImageDraw
import shutil
from pathlib import Path

SIZE = 1024
ROOT = Path(__file__).resolve().parent.parent

img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
d = ImageDraw.Draw(img)

# 圆角矩形底色（品牌强调色 #2F6BFF）
d.rounded_rectangle([0, 0, SIZE, SIZE], radius=220, fill=(47, 107, 255, 255))

# 心率脉冲折线（白色）
pts = [
    (140, 560), (320, 560), (400, 420), (500, 700),
    (580, 360), (660, 560), (884, 560),
]
d.line(pts, fill=(255, 255, 255, 255), width=56, joint="curve")
# 端点圆头
for p in (pts[0], pts[-1]):
    d.ellipse([p[0] - 28, p[1] - 28, p[0] + 28, p[1] + 28], fill=(255, 255, 255, 255))

targets = [
    ROOT / "AppScope/resources/base/media/app_icon.png",
    ROOT / "entry/src/main/resources/base/media/app_icon.png",
]
for t in targets:
    t.parent.mkdir(parents=True, exist_ok=True)
    img.save(t)
    print("saved:", t)
