# -*- coding: utf-8 -*-
"""批量去除动作库/食物图片左下角「AI生成」水印。

原理：水印位于左下角（x 0-13%, y 92.5%-100%），该区域是纯色/渐变摄影背景。
用同一行右侧 14% 处的真实背景像素平移覆盖水印，接缝处羽化过渡，肉眼无痕。
支持 --sample 只处理样本并输出前后对比裁剪图。
"""
import os
import sys
from PIL import Image, ImageFilter

MEDIA = r"C:\Users\infinty\DevEcoStudioProjects\SportHealthAgent\entry\src\main\resources\base\media"
OUT = r"C:\Users\infinty\DevEcoStudioProjects\SportHealthAgent\tools"

# 水印矩形（相对坐标，紧贴文字区域）
WM_X0, WM_X1 = 0.0, 0.13
WM_Y0, WM_Y1 = 0.938, 1.0


def clean(im):
    """用正上方同列像素向下平移覆盖水印：竖直结构（架杆、器械腿）自然延续，
    纯背景同样无痕；顶部接缝羽化 + 轻模糊。"""
    im = im.convert("RGB")
    w, h = im.size
    x0, x1 = int(w * WM_X0), int(w * WM_X1)
    y0, y1 = int(h * WM_Y0), int(h * WM_Y1)
    bh = y1 - y0
    strip = im.crop((x0, y0 - bh, x1, y0))
    # 亮度对齐：逐通道把补丁整体平移，使其底行与接缝上方一行均值一致，消除色阶断层
    px_pre = im.load()
    bands = strip.split()
    new_bands = []
    for c in range(3):
        above = sum(px_pre[x, y0 - 1][c] for x in range(x0, x1)) / (x1 - x0)
        below = sum(px_pre[x, y0 - bh - 1][c] for x in range(x0, x1)) / (x1 - x0)
        delta = int(round(above - below))
        new_bands.append(bands[c].point(lambda v, d=delta: max(0, min(255, v + d))))
    strip = Image.merge("RGB", new_bands)
    im.paste(strip, (x0, y0))
    # 顶部接缝羽化：接缝上下 3px 做交叉混合
    px = im.load()
    feather = 3
    for d in range(feather):
        t = (d + 1) / (feather + 1)  # 越靠接缝下方，越多用新像素
        y_seam = y0 + d
        y_above = y0 - 1 - d
        if y_above < 0 or y_seam >= h:
            continue
        for x in range(x0, x1):
            a = px[x, y_above]
            b = px[x, y_seam]
            px[x, y_seam] = tuple(int(a[c] * (1 - t) + b[c] * t) for c in range(3))
    # 轻模糊消除纹理差异
    patch = im.crop((x0, y0 - feather, x1, y1)).filter(ImageFilter.GaussianBlur(1.0))
    im.paste(patch, (x0, y0 - feather))
    return im


def targets(prefixes):
    return [f for f in sorted(os.listdir(MEDIA))
            if any(f.startswith(p) for p in prefixes) and f.lower().endswith((".jpg", ".jpeg", ".png"))]


def main():
    sample_mode = "--sample" in sys.argv
    files = targets(("ex2_",))
    if sample_mode:
        samples = ["ex2_bb_squat.jpg", "ex2_bd_curl.png", "ex2_bb_bench.jpg", "ex2_bd_facepull.png"]
        for name in samples:
            path = os.path.join(MEDIA, name)
            if not os.path.exists(path):
                continue
            im = Image.open(path)
            w, h = im.size
            before = im.convert("RGB").crop((0, int(h * 0.88), int(w * 0.35), h))
            after = clean(im).crop((0, int(h * 0.88), int(w * 0.35), h))
            combo = Image.new("RGB", (before.width, before.height * 2 + 4), (255, 0, 0))
            combo.paste(before, (0, 0))
            combo.paste(after, (0, before.height + 4))
            combo.save(os.path.join(OUT, "wm_check_" + name.rsplit(".", 1)[0] + ".png"))
            print("sample saved:", name)
        return
    done = 0
    for name in files:
        path = os.path.join(MEDIA, name)
        im = Image.open(path)
        result = clean(im)
        if name.lower().endswith((".jpg", ".jpeg")):
            result.save(path, quality=95)
        else:
            result.save(path)
        done += 1
    print("cleaned", done, "images")


if __name__ == "__main__":
    main()
