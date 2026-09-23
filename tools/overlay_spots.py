# -*- coding: utf-8 -*-
"""把 BodyPathData 的色斑坐标画到底图上，人工检查对齐情况。"""
import os
from PIL import Image, ImageDraw

MEDIA = r"C:\Users\infinty\DevEcoStudioProjects\SportHealthAgent\entry\src\main\resources\base\media"
OUT = r"C:\Users\infinty\DevEcoStudioProjects\SportHealthAgent\tools"

FRONT = {
    "肩左": (25, 19, 12), "肩右": (75, 19, 12), "胸": (50, 21, 15),
    "腹": (50, 33, 12), "臀": (50, 46, 13), "手臂左": (17, 37, 10),
    "手臂右": (83, 37, 10), "腿左": (40, 60, 13), "腿右": (60, 60, 13),
}
BACK = {
    "肩左": (26, 18, 12), "肩右": (74, 18, 12), "背": (50, 31, 17),
    "臀": (50, 47, 14), "手臂左": (17, 36, 10), "手臂右": (83, 36, 10),
    "腿左": (42, 60, 13), "腿右": (58, 60, 13),
}

def overlay(img_name, spots, out_name):
    im = Image.open(os.path.join(MEDIA, img_name)).convert("RGBA")
    w, h = im.size
    bg = Image.new("RGBA", im.size, (24, 24, 28, 255))
    bg.alpha_composite(im)
    d = ImageDraw.Draw(bg)
    for name, (x, y, r) in spots.items():
        cx, cy, rr = x / 100 * w, y / 100 * h, r / 100 * w * 1.15
        d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], outline=(255, 60, 60, 255), width=3)
        d.text((cx - 12, cy - 6), name, fill=(255, 255, 0, 255))
    bg.convert("RGB").save(os.path.join(OUT, out_name))
    print("saved", out_name)

overlay("body_front.png", FRONT, "overlay_front.png")
overlay("body_back.png", BACK, "overlay_back.png")
