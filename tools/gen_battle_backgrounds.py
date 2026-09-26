#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
GridAndGroves 战斗背景程序化生成器
==================================
确定性生成 1920x1080 战斗场景背景（3 个主题），并可选合成战斗布局预览图。

风格：扁平几何 + 深色描边（描边色 26,22,30），2x 超采样后 LANCZOS 缩小，
与 tools/gen_enemy_sprites.py / gen_block_parts.py 保持同一套视觉语言。

场景布局（世界坐标，勿在生成物中改动）：
- 网格地面: x 240..912, y 480..960（地砖为半透明黑，背景会透出并被压暗）
- 玩家区  : x ~204..396, y ~104..296（保持简洁）
- 敌人区  : x ~1200..1800, y ~50..450（保持低对比度，避免抢角色）
- 顶栏    : y 0..60

用法：
    python tools/gen_battle_backgrounds.py            # 生成全部主题
    python tools/gen_battle_backgrounds.py --only forest
    python tools/gen_battle_backgrounds.py --preview  # 额外输出战斗布局预览到 demo_generated/
"""

import argparse
import math
import os
import random

from PIL import Image, ImageDraw, ImageFilter

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(BASE, "room", "battle_background")
PREVIEW_DIR = os.path.join(BASE, "demo_generated")

W, H = 1920, 1080
SS = 2  # 超采样倍率
SW, SH = W * SS, H * SS

OUTLINE = (26, 22, 30, 255)
GRID_RECT = (240, 480, 912, 960)


def rgba(hex_str, alpha=255):
    h = hex_str.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), alpha)


def lerp(a, b, t):
    return a + (b - a) * t


def lerp_color(c0, c1, t):
    return tuple(int(round(lerp(c0[k], c1[k], t))) for k in range(4))


def vgrad(stops):
    """竖直渐变，stops: [(pos0..1, color), ...]，返回全屏图"""
    strip = Image.new("RGBA", (1, SH))
    px = strip.load()
    for y in range(SH):
        t = y / max(1, SH - 1)
        col = stops[-1][1]
        for i in range(len(stops) - 1):
            p0, c0 = stops[i]
            p1, c1 = stops[i + 1]
            if p0 <= t <= p1:
                col = lerp_color(c0, c1, (t - p0) / max(1e-6, p1 - p0))
                break
        px[0, y] = col
    return strip.resize((SW, SH), Image.BILINEAR)


def blob_pts(cx, cy, r, rng, wobble=0.2, n=14, squash_y=1.0, phase=0.0):
    pts = []
    for i in range(n):
        a = 2 * math.pi * i / n + phase
        rr = r * (1.0 + rng.uniform(-wobble, wobble))
        pts.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr * squash_y))
    return pts


def poly(d, pts, fill, outline=None, ow=6):
    if outline:
        loop = list(pts) + [pts[0]]
        d.line(loop, fill=outline, width=ow, joint="curve")
    d.polygon(pts, fill=fill)


def draw_sun(img, d, cx, cy, r, color, glow_color, glow_scale=3.0):
    glow = Image.new("RGBA", (SW, SH), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([cx - r * glow_scale, cy - r * glow_scale, cx + r * glow_scale, cy + r * glow_scale], fill=glow_color)
    glow = glow.filter(ImageFilter.GaussianBlur(r * glow_scale * 0.4))
    img.alpha_composite(glow)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=color)


def draw_rays(img, d, ox, oy, color, rng, count=4):
    layer = Image.new("RGBA", (SW, SH), (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    for i in range(count):
        a0 = math.radians(38 + i * 16 + rng.uniform(-4, 4))
        a1 = a0 + math.radians(rng.uniform(4, 8))
        far = 3000 * SS
        p = [
            (ox, oy),
            (ox + math.cos(a0) * far, oy + math.sin(a0) * far),
            (ox + math.cos(a1) * far, oy + math.sin(a1) * far),
        ]
        ld.polygon(p, fill=color)
    layer = layer.filter(ImageFilter.GaussianBlur(10 * SS))
    img.alpha_composite(layer)


def draw_glow_dots(img, dots, color, r, blur=6):
    glow = Image.new("RGBA", (SW, SH), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    for (x, y) in dots:
        gd.ellipse([x - r, y - r, x + r, y + r], fill=color)
    glow = glow.filter(ImageFilter.GaussianBlur(blur * SS))
    img.alpha_composite(glow)
    d = ImageDraw.Draw(img)
    for (x, y) in dots:
        d.ellipse([x - r * 0.35, y - r * 0.35, x + r * 0.35, y + r * 0.35], fill=color)


def draw_ground(img, d, y0, col_top, col_bottom, patch_colors, rng, wave=8):
    top_pts = []
    for x in range(-20, SW + 40, 48):
        yy = y0 + math.sin(x / (180 * SS)) * wave * SS + rng.uniform(-4, 4) * SS
        top_pts.append((x, yy))
    poly(d, top_pts + [(SW, SH), (0, SH)], col_bottom, OUTLINE, 6 * SS)
    # 顶部受光带
    band = [(x, y) for (x, y) in top_pts]
    poly(d, band + [(SW, y0 + 26 * SS), (0, y0 + 26 * SS)], col_top)
    # 地面斑块
    for _ in range(46):
        cx = rng.randint(0, SW)
        cy = rng.randint(int(y0 + 70 * SS), SH - 30 * SS)
        r = rng.randint(24, 96) * SS
        pts = blob_pts(cx, cy, r, rng, 0.4, 10, 0.35)
        d.polygon(pts, fill=rng.choice(patch_colors))


def draw_clearing(img, d, alpha=70):
    """网格地面下方的暗色平台，给地砖一个视觉底座"""
    x0, y0, x1, y1 = [v * SS for v in GRID_RECT]
    pad = 26 * SS
    d.rounded_rectangle(
        [x0 - pad, y0 - pad, x1 + pad, y1 + pad],
        radius=26 * SS,
        fill=(0, 0, 0, alpha),
        outline=(0, 0, 0, alpha + 70),
        width=5 * SS,
    )


def draw_haze(img, y, color, height=140):
    layer = Image.new("RGBA", (SW, SH), (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    ld.rectangle([0, y - height * SS / 2, SW, y + height * SS / 2], fill=color)
    layer = layer.filter(ImageFilter.GaussianBlur(40 * SS))
    img.alpha_composite(layer)


def draw_vignette(img, strength=150):
    layer = Image.new("RGBA", (SW, SH), (0, 0, 0, strength))
    ld = ImageDraw.Draw(layer)
    ld.ellipse(
        [-SW * 0.22, -SH * 0.28, SW * 1.22, SH * 1.28], fill=(0, 0, 0, 0)
    )
    layer = layer.filter(ImageFilter.GaussianBlur(180 * SS))
    img.alpha_composite(layer)


def draw_tree(d, x, base_y, h, crown_r, trunk_col, leaf_col, rng, leaf_dark=None):
    tw = max(8 * SS, int(h * 0.10))
    trunk = [
        (x - tw / 2, base_y),
        (x + tw / 2, base_y),
        (x + tw / 3, base_y - h * 0.62),
        (x - tw / 3, base_y - h * 0.62),
    ]
    poly(d, trunk, trunk_col, OUTLINE, 5 * SS)
    if leaf_dark is not None:
        back = blob_pts(x - crown_r * 0.35, base_y - h * 0.55, crown_r * 0.78, rng, 0.2, 14, 0.9)
        poly(d, back, leaf_dark, OUTLINE, 5 * SS)
    pts = blob_pts(x, base_y - h * 0.86, crown_r, rng, 0.22, 15, 0.92)
    poly(d, pts, leaf_col, OUTLINE, 5 * SS)


# ─────────────────────────── 主题绘制 ───────────────────────────

def theme_forest(img, d):
    """林地空地：Stage 1，清晨林间 """
    rng = random.Random(101)
    sky = vgrad([
        (0.00, rgba("#6ea391")),
        (0.38, rgba("#a9cbb0")),
        (0.62, rgba("#e6dcb4")),
        (1.00, rgba("#d9c9a0")),
    ])
    img.alpha_composite(sky)
    draw_sun(img, d, 1500 * SS, 190 * SS, 52 * SS, rgba("#fff2c0"), rgba("#ffe9a3", 46))
    draw_rays(img, d, 1500 * SS, 190 * SS, rgba("#fff4c8", 16), rng, 4)

    # 远山/远树线（低对比，无描边）
    far = Image.new("RGBA", (SW, SH), (0, 0, 0, 0))
    fd = ImageDraw.Draw(far)
    pts = [(0, 640 * SS)]
    for x in range(0, SW + 80, 80):
        pts.append((x, (600 - 70 * math.sin(x / (700 * SS))) * SS))
    pts += [(SW, 700 * SS), (0, 700 * SS)]
    fd.polygon(pts, fill=rgba("#7d9b85", 235))
    img.alpha_composite(far)
    draw_haze(img, 600 * SS, rgba("#f2ead0", 60))

    # 中景树木（左右两侧，避开网格与敌人）
    draw_tree(d, 60 * SS, 720 * SS, 430 * SS, 135 * SS, rgba("#4a3b31"), rgba("#3f6350"), rng, rgba("#33523f"))
    draw_tree(d, 190 * SS, 772 * SS, 250 * SS, 92 * SS, rgba("#4a3b31"), rgba("#47705a"), rng)
    draw_tree(d, 1878 * SS, 720 * SS, 460 * SS, 150 * SS, rgba("#4a3b31"), rgba("#3a5c4a"), rng, rgba("#2f4d3c"))
    draw_tree(d, 1748 * SS, 776 * SS, 250 * SS, 92 * SS, rgba("#4a3b31"), rgba("#47705a"), rng)

    # 地面
    draw_ground(
        img, d, 660 * SS,
        rgba("#6d8a5e"), rgba("#54704c"),
        [rgba("#5c7a52"), rgba("#68865a"), rgba("#486244")],
        rng,
    )

    # 网格底座 + 苔藓点缀
    draw_clearing(img, d, 60)
    moss = random.Random(7)
    for _ in range(46):
        cx = moss.randint(250, 910) * SS
        cy = moss.randint(470, 1000) * SS
        if 200 * SS < cx < 950 * SS and 440 * SS < cy < 1000 * SS:
            continue
        r = moss.randint(10, 26) * SS
        d.ellipse([cx - r, cy - r * 0.6, cx + r, cy + r * 0.6], fill=rgba("#7fa063", 150))

    # 萤火虫
    fire = [(rng.randint(90, 920), rng.randint(210, 430)) for _ in range(16)]
    draw_glow_dots(img, [(x * SS, y * SS) for (x, y) in fire], rgba("#ffe9a3"), 4 * SS, 6)
    draw_vignette(img, 130)


def theme_ruins(img, d):
    """锈蚀废墟：Stage 2，黄昏工厂 """
    rng = random.Random(202)
    sky = vgrad([
        (0.00, rgba("#2c2430")),
        (0.34, rgba("#5d3839")),
        (0.60, rgba("#a85f45")),
        (0.78, rgba("#e09a5e")),
        (1.00, rgba("#c98a5c")),
    ])
    img.alpha_composite(sky)
    draw_sun(img, d, 320 * SS, 560 * SS, 46 * SS, rgba("#ffd08a"), rgba("#ffb46b", 52))
    draw_rays(img, d, 320 * SS, 560 * SS, rgba("#ffcf96", 14), rng, 3)

    # 远景工厂天际线（低对比剪影）
    far = Image.new("RGBA", (SW, SH), (0, 0, 0, 0))
    fd = ImageDraw.Draw(far)
    x = -40 * SS
    while x < SW + 80 * SS:
        bw = rng.randint(90, 240) * SS
        bh = rng.randint(90, 300) * SS
        base = 660 * SS
        fd.rectangle([x, base - bh, x + bw, base], fill=rgba("#4a3436", 210))
        if rng.random() < 0.5:
            ch = rng.randint(40, 120) * SS
            cw = rng.randint(18, 34) * SS
            cx = x + rng.randint(10 * SS, max(11 * SS, int(bw) - 40 * SS))
            fd.rectangle([cx, base - bh - ch, cx + cw, base - bh], fill=rgba("#4a3436", 210))
            fd.ellipse([cx - 26 * SS, base - bh - ch - 30 * SS, cx + cw + 26 * SS, base - bh - ch + 18 * SS], fill=rgba("#6d5856", 120))
        x += bw + rng.randint(14, 60) * SS
    img.alpha_composite(far)
    draw_haze(img, 640 * SS, rgba("#e8b070", 60))

    # 中景：断塔、管道、枯树
    def pylon(px, base, hh, tilt=0.0):
        w = 34 * SS
        pts = [
            (px - w, base), (px + w, base),
            (px + w * 0.6 + tilt, base - hh), (px - w * 0.6 + tilt, base - hh),
        ]
        poly(d, pts, rgba("#3a2c2e"), OUTLINE, 5 * SS)
        for k in range(1, 4):
            yy = base - hh * k / 3.4
            d.line([(px - w * 0.8 + tilt * k / 3.4, yy), (px + w * 0.8 + tilt * k / 3.4, yy)], fill=rgba("#6b4a3a"), width=5 * SS)
        d.line([(px + w * 0.5 + tilt, base - hh), (px + w * 0.5 + tilt, base - hh - 60 * SS)], fill=rgba("#3a2c2e"), width=6 * SS)
        d.line([(px + w * 0.5 + tilt, base - hh - 56 * SS), (px + w * 0.5 + tilt + 90 * SS, base - hh - 90 * SS)], fill=rgba("#3a2c2e"), width=4 * SS)

    pylon(150 * SS, 700 * SS, 460 * SS, 10 * SS)
    pylon(1810 * SS, 700 * SS, 520 * SS, -12 * SS)

    # 悬挂电缆
    for (x0, x1, y0, sag, col) in [(40, 420, 360, 46, 4), (1520, 1900, 350, 40, 4)]:
        pts = []
        for t in range(0, 21):
            f = t / 20.0
            x = lerp(x0, x1, f) * SS
            y = (y0 + sag * math.sin(math.pi * f)) * SS
            pts.append((x, y))
        d.line(pts, fill=rgba("#241f22", 200), width=col * SS, joint="curve")

    # 地面
    draw_ground(
        img, d, 670 * SS,
        rgba("#4a4440"), rgba("#37322f"),
        [rgba("#423c38"), rgba("#4f4842"), rgba("#7d4326", 160)],
        rng,
    )
    draw_clearing(img, d, 74)

    # 锈迹与碎金属
    rust = random.Random(11)
    for _ in range(26):
        cx = rust.randint(0, W) * SS
        cy = rust.randint(720, 1070) * SS
        if 200 * SS < cx < 950 * SS:
            continue
        r = rust.randint(10, 30) * SS
        pts = blob_pts(cx, cy, r, rust, 0.5, 9, 0.35)
        d.polygon(pts, fill=rgba("#7d4326", 80))

    draw_vignette(img, 140)


def theme_core(img, d):
    """母树核心：Stage 3，夜色机械母树"""
    rng = random.Random(303)
    sky = vgrad([
        (0.00, rgba("#0c1722")),
        (0.40, rgba("#14303a")),
        (0.72, rgba("#1e4a48")),
        (1.00, rgba("#28584e")),
    ])
    img.alpha_composite(sky)

    # 月/光晕
    draw_sun(img, d, 1560 * SS, 180 * SS, 46 * SS, rgba("#d8f3e6"), rgba("#9df3d8", 26), 1.8)
    draw_rays(img, d, 1560 * SS, 180 * SS, rgba("#bff3e2", 12), rng, 3)

    # 远景巨树/机械拱门
    far = Image.new("RGBA", (SW, SH), (0, 0, 0, 0))
    fd = ImageDraw.Draw(far)
    fd.polygon([(0, 660 * SS), (200 * SS, 300 * SS), (420 * SS, 660 * SS)], fill=rgba("#0a141c", 235))
    fd.polygon([(1500 * SS, 660 * SS), (1750 * SS, 210 * SS), (2000 * SS, 660 * SS)], fill=rgba("#0a141c", 235))
    img.alpha_composite(far)
    draw_haze(img, 620 * SS, rgba("#5ad0b8", 26))

    # 中景：巨树主干 + 拱形机械结构（左右两侧）
    def pillar(px, base, hh, w):
        body = [
            (px - w, base), (px + w, base),
            (px + w * 0.68, base - hh), (px - w * 0.68, base - hh),
        ]
        poly(d, body, rgba("#12242c"), OUTLINE, 6 * SS)
        for side in (-1, 1):
            root = [
                (px + side * w * 1.35, base),
                (px + side * w * 0.15, base - 26 * SS),
                (px + side * w * 0.2, base),
            ]
            d.polygon(root, fill=rgba("#0e1d24"))
        # 纵向发光缝隙
        d.line([(px, base - 40 * SS), (px + 6 * SS, base - hh + 30 * SS)], fill=rgba("#59e0c0", 90), width=3 * SS)
        # 两侧孢子
        for k in range(2):
            yy = base - hh * (0.34 + 0.30 * k)
            side = 1 if k % 2 == 0 else -1
            xx = px + side * w * 0.75
            off = side * 22 * SS
            d.line([(xx, yy), (xx + off, yy - 16 * SS)], fill=rgba("#0e1d24"), width=4 * SS)
            col = rgba("#9df3d8") if k % 2 == 0 else rgba("#e79df0")
            r = 9 * SS
            d.ellipse([xx + off - r, yy - 16 * SS - r, xx + off + r, yy - 16 * SS + r], fill=col)
        # 顶部核心
        r2 = 12 * SS
        d.ellipse([px - r2, base - hh - r2, px + r2, base - hh + r2], fill=rgba("#9df3d8"))

    pillar(120 * SS, 720 * SS, 470 * SS, 100 * SS)
    pillar(1848 * SS, 720 * SS, 540 * SS, 112 * SS)

    # 地面
    draw_ground(
        img, d, 660 * SS,
        rgba("#20362f"), rgba("#152720"),
        [rgba("#1c2f29"), rgba("#264039"), rgba("#2e4f42")],
        rng,
    )

    # 发光根系
    def tendril(p0, p1, p2, col, w=4):
        pts = []
        for i in range(19):
            t = i / 18.0
            x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0]
            y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1]
            pts.append((x, y))
        d.line(pts, fill=col, width=w, joint="curve")

    tendril((150 * SS, 726 * SS), (280 * SS, 800 * SS), (430 * SS, 780 * SS), rgba("#59e0c0", 70), 3 * SS)
    tendril((150 * SS, 726 * SS), (215 * SS, 850 * SS), (300 * SS, 950 * SS), rgba("#59e0c0", 50), 2 * SS)
    tendril((1818 * SS, 726 * SS), (1700 * SS, 800 * SS), (1560 * SS, 780 * SS), rgba("#59e0c0", 70), 3 * SS)
    tendril((1818 * SS, 726 * SS), (1755 * SS, 860 * SS), (1680 * SS, 950 * SS), rgba("#59e0c0", 50), 2 * SS)
    draw_clearing(img, d, 80)

    # 孢子/萤光
    spores = [(rng.randint(60, 900), rng.randint(220, 720)) for _ in range(30)]
    draw_glow_dots(img, [(x * SS, y * SS) for (x, y) in spores], rgba("#9df3d8"), 5 * SS, 9)
    magenta = [(rng.randint(950, 1880), rng.randint(200, 640)) for _ in range(14)]
    draw_glow_dots(img, [(x * SS, y * SS) for (x, y) in magenta], rgba("#e79df0"), 4 * SS, 8)

    draw_vignette(img, 150)


THEMES = {
    "forest": ("ForestClearing", theme_forest),
    "ruins": ("RustedRuins", theme_ruins),
    "core": ("BloomCore", theme_core),
}


def generate(theme_key, preview=False):
    name, fn = THEMES[theme_key]
    img = Image.new("RGBA", (SW, SH), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    fn(img, d)
    out = img.resize((W, H), Image.LANCZOS)
    os.makedirs(OUT_DIR, exist_ok=True)
    out_path = os.path.join(OUT_DIR, name + ".png")
    out.save(out_path)
    print("saved:", os.path.relpath(out_path, BASE))
    if preview:
        build_preview(out, theme_key)
    return out_path


def _load(rel):
    return Image.open(os.path.join(BASE, rel.replace("/", os.sep))).convert("RGBA")


def build_preview(bg_img, theme_key):
    """把背景与真实战斗元素合成，模拟游戏内观感"""
    bg = bg_img.copy()
    upper = _load("room/battle_background/UpperLayer.png")
    bg.alpha_composite(upper, (0, 0))
    player = _load("actors/player/Player-export.png").crop((0, 0, 192, 192))
    bg.alpha_composite(player, (300 - 96, 200 - 96))
    enemy = _load("resources/enemy_images/Gonh.png").crop((0, 0, 192, 192))
    bg.alpha_composite(enemy, (1300 - 96, 150 - 96))
    enemy2 = _load("resources/enemy_images/RustHound.png").crop((0, 0, 192, 192))
    bg.alpha_composite(enemy2, (1500 - 96, 350 - 96))
    block = _load("resources/blockpart_picture/green/strike.png")
    bg.alpha_composite(block, (432, 672))
    block2 = _load("resources/blockpart_picture/purple/echo.png")
    bg.alpha_composite(block2, (528, 672))
    os.makedirs(PREVIEW_DIR, exist_ok=True)
    out = os.path.join(PREVIEW_DIR, "bg_preview_" + theme_key + ".png")
    bg.save(out)
    print("preview:", os.path.relpath(out, BASE))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", choices=sorted(THEMES.keys()), default=None)
    ap.add_argument("--preview", action="store_true")
    args = ap.parse_args()
    keys = [args.only] if args.only else sorted(THEMES.keys())
    for k in keys:
        generate(k, preview=args.preview)


if __name__ == "__main__":
    main()
