"""生成热力图人体轮廓占位底图（正面/背面）——AI 生图服务恢复后会被替换"""
from PIL import Image, ImageDraw, ImageFilter

W, H = 640, 1280
COLOR = (176, 183, 192, 255)  # 中性灰（占位图，正式版用 AI 真人轮廓）
SHADOW = (150, 157, 166, 255)


def ellipse(d, cx, cy, rx, ry, color=COLOR):
    d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=color)


def make_body(path):
    img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # 头 + 颈
    ellipse(d, 320, 92, 56, 66)
    d.rectangle([292, 140, 348, 185], fill=COLOR)
    # 斜方/肩
    d.polygon([(200, 175), (320, 150), (440, 175), (470, 220), (170, 220)], fill=COLOR)
    # 三角肌（圆肩）
    ellipse(d, 165, 215, 58, 62)
    ellipse(d, 475, 215, 58, 62)
    # 胸/躯干（上宽）
    ellipse(d, 320, 300, 128, 105)
    # 腰腹（收窄）
    ellipse(d, 320, 445, 92, 95)
    # 臀胯
    ellipse(d, 320, 555, 108, 85)
    # 上臂 / 前臂 / 手
    for sx in (-1, 1):
        cx = 320 + sx * 178
        ellipse(d, cx, 330, 36, 88)
        ellipse(d, cx + sx * 10, 465, 28, 78)
        ellipse(d, cx + sx * 12, 552, 24, 30)
    # 大腿
    ellipse(d, 268, 690, 56, 105)
    ellipse(d, 372, 690, 56, 105)
    # 小腿
    ellipse(d, 272, 870, 38, 92)
    ellipse(d, 368, 870, 38, 92)
    # 足
    ellipse(d, 272, 985, 30, 42)
    ellipse(d, 368, 985, 30, 42)
    # 平滑边缘
    img = img.filter(ImageFilter.GaussianBlur(4))
    img.save(path)


make_body(r"C:/Users/infinty/DevEcoStudioProjects/SportHealthAgent/entry/src/main/resources/base/media/body_front.png")
make_body(r"C:/Users/infinty/DevEcoStudioProjects/SportHealthAgent/entry/src/main/resources/base/media/body_back.png")
print("done")
