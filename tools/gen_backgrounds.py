# 文件标注：AI 生成 —— 背景图批量产出脚本（开发期一次性工具）
#
# 视觉系统 · 背景图生成
# 产出 6 张本地背景图到 resources/base/media/：
#   bg_page_light/bg_page_dark  1080x2340 页面底（顶部极淡光晕，中下纯净）
#   bg_hero_light/bg_hero_dark  1080x600  Hero 横幅底（同色系渐变 + 白色低透明跑道弧线）
#   bg_empty_light/bg_empty_dark 720x720  空态插图（透明底哑铃线稿）
# 全部 PIL 本地绘制：无网络、无文字、无人物、低对比，运行后校验尺寸与体积。
# 用法：python tools/gen_backgrounds.py
import os
import math
import numpy as np
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'entry', 'src', 'main', 'resources', 'base', 'media')

LIMIT_BG = 150 * 1024
LIMIT_EMPTY = 80 * 1024


def hex_rgb(h):
    return (int(h[1:3], 16), int(h[3:5], 16), int(h[5:7], 16))


def lerp(a, b, t):
    return a + (b - a) * t


def gradient_vertical(w, h, c1, c2):
    """纵向渐变底图（c1 顶 → c2 底），返回 numpy RGB 数组"""
    top = hex_rgb(c1)
    bot = hex_rgb(c2)
    t = np.broadcast_to(np.linspace(0.0, 1.0, h, dtype=np.float32).reshape(h, 1, 1), (h, w, 1))[:, :, 0]
    arr = np.zeros((h, w, 3), dtype=np.float32)
    for i in range(3):
        arr[:, :, i] = lerp(top[i], bot[i], t)
    return arr


def add_radial_glow(arr, cx_ratio, cy_ratio, radius_px, glow_rgb, max_alpha):
    """叠加径向光晕：中心 max_alpha（0~1）线性衰减到 radius 处为 0"""
    h, w, _ = arr.shape
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    cx, cy = w * cx_ratio, h * cy_ratio
    dist = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2)
    alpha = np.clip(1.0 - dist / radius_px, 0.0, 1.0) * max_alpha
    glow = np.array(hex_rgb(glow_rgb), dtype=np.float32)
    for i in range(3):
        arr[:, :, i] = arr[:, :, i] * (1.0 - alpha) + glow[i] * alpha
    return arr


def draw_track_arcs(img, alpha=20, color=(255, 255, 255)):
    """白色低透明跑道弧线（同心弧，圆心在右下外侧）——装饰图案层"""
    overlay = Image.new('RGBA', img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    w, h = img.size
    cx, cy = int(w * 0.92), int(h * 1.05)
    for i, r in enumerate(range(140, 620, 80)):
        d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(color[0], color[1], color[2], alpha), width=3)
    # 左上角两条更淡的反向弧
    cx2, cy2 = int(w * 0.02), int(h * -0.1)
    for r in range(120, 300, 80):
        d.ellipse([cx2 - r, cy2 - r, cx2 + r, cy2 + r], outline=(color[0], color[1], color[2], max(alpha - 6, 6)), width=2)
    img.alpha_composite(overlay)


def draw_dumbbell(size, line_rgb, alpha):
    """极简哑铃线稿（透明底）：杠 + 四片铃片轮廓"""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = (line_rgb[0], line_rgb[1], line_rgb[2], alpha)
    lw = max(size // 60, 6)
    mid = size // 2
    bar_half = int(size * 0.26)
    # 杠
    d.line([mid - bar_half, mid, mid + bar_half, mid], fill=c, width=lw)
    # 铃片（左右各两片，圆角矩形轮廓）
    plate_w = int(size * 0.045)
    for side in (-1, 1):
        for k, (off, ph) in enumerate(((int(size * 0.20), int(size * 0.30)), (int(size * 0.28), int(size * 0.20)))):
            x = mid + side * off
            d.rounded_rectangle([x - plate_w, mid - ph // 2, x + plate_w, mid + ph // 2],
                                radius=plate_w, outline=c, width=lw)
    return img


def save(img, name, limit):
    path = os.path.join(OUT, name)
    img.save(path, 'PNG', optimize=True)
    size = os.path.getsize(path)
    status = 'OK' if size <= limit else 'OVER(%d>%d)' % (size, limit)
    print('%-22s %dx%d %6.1fKB %s' % (name, img.size[0], img.size[1], size / 1024.0, status))
    return size <= limit


def main():
    ok = True

    # ---- bg_page_light：#F5F7FA 底 + 顶部 1/4 极淡蓝径向光晕（≤3% 观感） ----
    arr = gradient_vertical(1080, 2340, '#F5F7FA', '#F5F7FA')
    arr = add_radial_glow(arr, 0.5, 0.0, 900, '#3D6BFF', 0.05)
    ok &= save(Image.fromarray(arr.astype(np.uint8), 'RGB'), 'bg_page_light.png', LIMIT_BG)

    # ---- bg_page_dark：#101214 底 + 顶部微弱冷色光晕（亮度 ≤8%） ----
    arr = gradient_vertical(1080, 2340, '#101214', '#101214')
    arr = add_radial_glow(arr, 0.5, 0.0, 800, '#2E4E8F', 0.08)
    ok &= save(Image.fromarray(arr.astype(np.uint8), 'RGB'), 'bg_page_dark.png', LIMIT_BG)

    # ---- bg_hero_light：#2F6BFF→#7BA6FF 同系渐变 + 白色 8% 跑道弧线 ----
    arr = gradient_vertical(1080, 600, '#2F6BFF', '#7BA6FF')
    img = Image.fromarray(arr.astype(np.uint8), 'RGB').convert('RGBA')
    draw_track_arcs(img, alpha=20)
    ok &= save(img.convert('RGB'), 'bg_hero_light.png', LIMIT_BG)

    # ---- bg_hero_dark：#1F3A6E→#2E4E8F 同系渐变 + 同风格弧线 ----
    arr = gradient_vertical(1080, 600, '#1F3A6E', '#2E4E8F')
    img = Image.fromarray(arr.astype(np.uint8), 'RGB').convert('RGBA')
    draw_track_arcs(img, alpha=16)
    ok &= save(img.convert('RGB'), 'bg_hero_dark.png', LIMIT_BG)

    # ---- bg_empty_light / bg_empty_dark：透明底哑铃线稿 ----
    ok &= save(draw_dumbbell(720, hex_rgb('#6B7280'), 26), 'bg_empty_light.png', LIMIT_EMPTY)
    ok &= save(draw_dumbbell(720, hex_rgb('#9AA1A9'), 34), 'bg_empty_dark.png', LIMIT_EMPTY)

    print('ALL WITHIN LIMITS' if ok else 'SOME FILES OVER LIMIT')


if __name__ == '__main__':
    main()
