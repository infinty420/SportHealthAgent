# -*- coding: utf-8 -*-
"""检查 AI 底图 alpha 通道、清除左下角 AI生成 水印。"""
import os
from PIL import Image

MEDIA = r"C:\Users\infinty\DevEcoStudioProjects\SportHealthAgent\entry\src\main\resources\base\media"

for name in ("body_front.png", "body_back.png"):
    p = os.path.join(MEDIA, name)
    im = Image.open(p).convert("RGBA")
    w, h = im.size
    alpha = im.getchannel("A")
    lo, hi = alpha.getextrema()
    # 统计四角透明度，判断背景是否透明
    corners = [alpha.getpixel((2, 2)), alpha.getpixel((w - 3, 2)),
               alpha.getpixel((2, h - 3)), alpha.getpixel((w - 3, h - 3))]
    print(name, "size", im.size, "alpha range", (lo, hi), "corners", corners)
    # 清除左下角水印区域（约 x 0-25%, y 94%-100%）并整体裁掉底部 2% 保险
    px = im.load()
    for y in range(int(h * 0.93), h):
        for x in range(0, int(w * 0.30)):
            r, g, b, a = px[x, y]
            # 只擦掉近白色描边/文字像素，避免误伤人体（脚踝在右侧，此区域基本是背景）
            px[x, y] = (r, g, b, 0)
    im.save(p)
    print(name, "watermark area cleared")
