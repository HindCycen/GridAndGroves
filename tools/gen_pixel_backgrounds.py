#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
GridAndGroves 像素风战斗背景生成器（时间参数化 · v2 细节版）
============================================================
核心思想：**场景几何固定，天色由 --hour 单个参数驱动。**
同一区域（forest / ruins / core）在任意时刻共用同一套像素几何与细节，
只通过时间调色板（天空三段色 + 环境染色/压暗 + 灯光强度 + 日月位置/色温 +
光照方向）产生连续变暗效果。改一个数字即可产出下一个时间点。

像素规格：内部 480x270，整数坐标绘制（无抗锯齿），Bayer 4x4 抖动，
最终 4x NEAREST 放大到 1920x1080（项目默认纹理过滤为 nearest）。

用法：
    python tools/gen_pixel_backgrounds.py --themes forest --hours 16,17,18,19,20,21 --strip --preview
    python tools/gen_pixel_backgrounds.py --themes ruins --hours 19 --preview
"""

import argparse
import json
import math
import os

from PIL import Image, ImageDraw, ImageFont

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(BASE, "room", "battle_background")
PREVIEW_DIR = os.path.join(BASE, "demo_generated")

LW, LH = 480, 270
SCALE = 4
W, H = LW * SCALE, LH * SCALE

BAYER = [
    [0, 8, 2, 10],
    [12, 4, 14, 6],
    [3, 11, 1, 9],
    [15, 7, 13, 5],
]


# ─────────────────────────── 颜色与时间模型 ───────────────────────────

def hx(s):
    s = s.lstrip("#")
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16))


def mix(c0, c1, t):
    t = max(0.0, min(1.0, t))
    return tuple(int(round(c0[i] + (c1[i] - c0[i]) * t)) for i in range(3))


def scale(c, f):
    return tuple(max(0, min(255, int(round(v * f)))) for v in c)


def darken(c, f):
    return scale(c, 1.0 - f)


def lerp_value(v0, v1, f):
    if isinstance(v0, tuple):
        return tuple(lerp_value(a, b, f) for a, b in zip(v0, v1))
    v = v0 + (v1 - v0) * f
    if isinstance(v0, int) and isinstance(v1, int):
        return int(round(v))
    return v


def _interp_keys(keys, hour):
    h = hour % 24.0
    ks = list(keys)
    if h < ks[0][0]:
        ks.insert(0, (ks[-1][0] - 24.0, ks[-1][1]))
    for i in range(len(ks) - 1):
        h0, v0 = ks[i]
        h1, v1 = ks[i + 1]
        if h0 <= h <= h1:
            f = (h - h0) / max(1e-6, h1 - h0)
            return lerp_value(v0, v1, f)
    return ks[-1][1]


SKY_KEYS = [
    (5.0, (hx("#1c2440"), hx("#4a4468"), hx("#c07858"))),
    (7.0, (hx("#6a8fb0"), hx("#a8c4c0"), hx("#e8d8b0"))),
    (12.0, (hx("#5b9ec8"), hx("#9cc4d0"), hx("#e4e0bc"))),
    (16.0, (hx("#5a92b0"), hx("#a8c0a8"), hx("#e8d0a0"))),
    (18.0, (hx("#47508a"), hx("#b06a6a"), hx("#e89a5a"))),
    (19.5, (hx("#232a52"), hx("#4a3f6e"), hx("#a85f6a"))),
    (21.0, (hx("#0e1730"), hx("#1b2a4a"), hx("#2c4058"))),
    (23.0, (hx("#080f20"), hx("#101a32"), hx("#1a2840"))),
]

LIGHT_KEYS = [
    (5.0, (hx("#ffb07a"), 0.32, 0.22, 0.35)),
    (7.0, (hx("#ffe6c0"), 0.10, 0.02, 0.05)),
    (12.0, (hx("#ffffff"), 0.00, 0.00, 0.00)),
    (16.0, (hx("#ffdca0"), 0.12, 0.02, 0.00)),
    (18.0, (hx("#ff9a55"), 0.30, 0.10, 0.30)),
    (19.5, (hx("#6a5aa0"), 0.45, 0.34, 0.80)),
    (21.0, (hx("#2a3c6a"), 0.60, 0.55, 1.00)),
    (23.0, (hx("#161f3a"), 0.68, 0.64, 1.00)),
]


def light_params(hour):
    tint, amt, dark, lamps = _interp_keys(LIGHT_KEYS, hour)
    return {"tint": tint, "amt": amt, "dark": dark, "lamps": lamps}


def resolve(c_day, hour, lp=None):
    lp = lp or light_params(hour)
    return darken(mix(c_day, lp["tint"], lp["amt"]), lp["dark"])


def resolve_glow(c_day, hour, lp=None, floor=0.35):
    lp = lp or light_params(hour)
    f = floor + (1.0 - floor) * lp["lamps"]
    return scale(c_day, f)


def sky_colors(hour):
    return _interp_keys(SKY_KEYS, hour)


def sun_screen_pos(hour):
    h = hour % 24.0
    if 5.5 <= h <= 18.5:
        f = (h - 5.5) / 13.0
        return (60 + f * 380, 150 - math.sin(math.pi * f) * 120, False)
    nh = (h + 24.0) % 24.0
    f = (nh - 18.5) / 11.0 if nh >= 18.5 else (nh + 5.5) / 11.0
    return (420 - f * 360, 140 - math.sin(math.pi * f) * 110, True)


def sun_color(hour, is_moon):
    if is_moon:
        return hx("#dfe8f2"), hx("#8fa8c8")
    h = hour % 24.0
    if h < 7.5:
        return hx("#ffd9a0"), hx("#ff9a5a")
    if h > 16.5:
        return hx("#ffb85c"), hx("#ff7a3c")
    return hx("#fff2c0"), hx("#ffe9a3")


def light_dir(hour):
    """返回 (光照方向 -1 左 / +1 右, 日光强度 0..1)"""
    lp = light_params(hour)
    day = max(0.0, 1.0 - lp["lamps"] * 1.15)
    x, _, is_moon = sun_screen_pos(hour)
    if is_moon:
        return (1 if x > LW / 2 else -1), 0.0
    return (1 if x > LW / 2 else -1), day


# ─────────────────────────── 像素绘制辅助 ───────────────────────────

def r_rect(d, x0, y0, x1, y1, c, outline=None):
    d.rectangle([x0, y0, x1 - 1, y1 - 1], fill=c)
    if outline:
        d.rectangle([x0, y0, x1 - 1, y1 - 1], outline=outline)


def poly(d, pts, c, outline=None):
    if outline:
        d.line(list(pts) + [pts[0]], fill=outline)
    d.polygon(pts, fill=c)


def ell(d, cx, cy, rx, ry, c, outline=None):
    d.ellipse([int(cx - rx), int(cy - ry), int(cx + rx), int(cy + ry)], fill=c)
    if outline:
        d.ellipse([int(cx - rx), int(cy - ry), int(cx + rx), int(cy + ry)], outline=outline)


def dither_blob(d, cx, cy, rx, ry, base, hi, lo, sun_side, outline=None):
    """带抖动明暗的枝冠/灌木：光源侧高光、背光侧阴影（三色互相接近）"""
    hi = mix(hi, base, 0.38)
    lo = mix(lo, base, 0.30)
    ell(d, cx, cy, rx, ry, base, outline)
    for yy in range(int(cy - ry), int(cy + ry) + 1):
        for xx in range(int(cx - rx), int(cx + rx) + 1):
            dx = (xx - cx) / max(1.0, rx)
            dy = (yy - cy) / max(1.0, ry)
            if dx * dx + dy * dy > 1.0:
                continue
            w = 0.0
            if dx * sun_side > 0.05:
                w += 0.55 * (dx * sun_side - 0.05)
            if dy < -0.05:
                w += 0.30 * (-dy - 0.05)
            th = BAYER[yy % 4][xx % 4] / 16.0
            if w > th + 0.18:
                d.point((xx, yy), fill=hi)
            elif w < th - 0.42:
                d.point((xx, yy), fill=lo)


def build_ramp(stops, n=32):
    """stops: [(pos0..1, color), ...] -> 多级近似色带（相邻色差距小）"""
    ramp = []
    for i in range(n):
        t = i / (n - 1.0)
        col = stops[-1][1]
        for k in range(len(stops) - 1):
            p0, c0 = stops[k]
            p1, c1 = stops[k + 1]
            if p0 <= t <= p1:
                col = mix(c0, c1, (t - p0) / max(1e-6, p1 - p0))
                break
        ramp.append(col)
    return ramp


def at_ramp(ramp, t, x, y):
    """按 32 级色带取色：整数级之间用 Bayer 抖动，仅混合相邻近色"""
    n = len(ramp)
    pos = max(0.0, min(1.0, t)) * (n - 1)
    i = int(pos)
    frac = pos - i
    th = BAYER[y % 4][x % 4] / 16.0
    idx = i + 1 if (frac > th and i + 1 < n) else i
    return ramp[idx]


def draw_sky(img, hour):
    top, mid, low = sky_colors(hour)
    ramp = build_ramp([(0.0, top), (0.6, mid), (1.0, low)], 32)
    px = img.load()
    band2 = LH * 0.80
    for y in range(LH):
        t = min(1.0, y / band2)
        for x in range(LW):
            px[x, y] = at_ramp(ramp, t, x, y)


def hero_bg(img, x, y):
    return img.getpixel((max(0, min(LW - 1, int(x))), max(0, min(LH - 1, int(y)))))


def draw_sun_moon(img, hour):
    x, y, is_moon = sun_screen_pos(hour)
    body, glow = sun_color(hour, is_moon)
    d = ImageDraw.Draw(img)
    lp = light_params(hour)
    g = 0.45 + 0.55 * lp["lamps"] if is_moon else 1.0
    glow_d = scale(glow, g)
    for r, t in ((10, 0.62), (7, 0.36)):
        d.ellipse([int(x - r), int(y - r), int(x + r), int(y + r)], fill=mix(glow_d, hero_bg(img, x, y), t))
    d.ellipse([int(x - 4), int(y - 4), int(x + 4), int(y + 4)], fill=mix(body, (255, 255, 255), 0.15) if is_moon else body)


def draw_stars(img, hour):
    lp = light_params(hour)
    if lp["lamps"] < 0.45:
        return
    alpha = (lp["lamps"] - 0.45) / 0.55
    d = ImageDraw.Draw(img)
    seed = 1234567
    for i in range(80):
        seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
        sx = seed % LW
        seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
        sy = seed % int(LH * 0.60)
        if i % 3 == 0 and alpha < 0.8:
            continue
        d.point((sx, sy), fill=mix(hero_bg(img, sx, sy), (255, 255, 255), 0.35 + 0.5 * alpha))


CLOUD_KEYS = [
    (5.0, hx("#5a5470")),
    (7.0, hx("#e8e4dc")),
    (12.0, hx("#f4f4f0")),
    (16.0, hx("#f0e8d8")),
    (18.0, hx("#ffb98a")),
    (19.5, hx("#7a5a80")),
    (21.0, hx("#2a3450")),
    (23.0, hx("#1c2438")),
]


def draw_clouds(img, hour, lp):
    base = _interp_keys(CLOUD_KEYS, hour)
    shade = mix(base, hx("#1a1622"), 0.28)
    d = ImageDraw.Draw(img)
    clouds = [(66, 40, 20), (152, 26, 14), (298, 50, 24), (398, 32, 16), (232, 72, 12)]
    for (cx, cy, w) in clouds:
        for dx, dy, r in (
            (0, 0, w),
            (-w * 0.72, 3, w * 0.66),
            (w * 0.72, 3, w * 0.62),
            (-w * 0.32, -4, w * 0.56),
            (w * 0.34, -4, w * 0.5),
        ):
            d.ellipse([cx + dx - r, cy + dy - r * 0.55, cx + dx + r, cy + dy + r * 0.55], fill=base)
        for dx, dy, r in ((0, 4, w * 0.8), (-w * 0.46, 5, w * 0.5), (w * 0.46, 5, w * 0.45)):
            d.ellipse([cx + dx - r, cy + dy - r * 0.3, cx + dx + r, cy + dy + r * 0.3], fill=shade)


def draw_ground(img, hour, lp, c_far, c_near, c_patch):
    d = ImageDraw.Draw(img)
    far = resolve(c_far, hour, lp)
    near = resolve(c_near, hour, lp)
    patch = resolve(c_patch, hour, lp)
    y0 = 168
    ramp = build_ramp([(0.0, far), (1.0, near)], 24)
    px = img.load()
    for y in range(y0, LH):
        t = min(1.0, (y - y0) / float(LH - y0))
        for x in range(LW):
            px[x, y] = at_ramp(ramp, t, x, y)
    seed = 987654
    for i in range(150):
        seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
        gx = seed % LW
        seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
        gy = y0 + 4 + seed % (LH - y0 - 6)
        r = 1 + (i % 3)
        col = patch if i % 4 else mix(patch, (0, 0, 0), 0.2)
        d.ellipse([gx - r, gy - r // 2, gx + r, gy + r // 2], fill=col)
    return y0


def darken_platform(img, factor=0.34, feather=5):
    """网格区域背景压暗（提升地砖上 Block 的可读性），边缘羽化避免硬框感"""
    px = img.load()
    x0, y0, x1, y1 = 58, 118, 231, 243
    for y in range(y0, y1):
        for x in range(x0, x1):
            d = min(x - x0, x1 - 1 - x, y - y0, y1 - 1 - y)
            f = factor * min(1.0, max(0.0, d / float(feather)))
            if f <= 0.0:
                continue
            r, g, b = px[x, y]
            px[x, y] = (int(r * (1 - f)), int(g * (1 - f)), int(b * (1 - f)))


def draw_platform_frame(d, hour, lp):
    x0, y0, x1, y1 = 60, 120, 228, 240
    dark = resolve(hx("#15121a"), hour, lp)
    edge = resolve(hx("#2e2a33"), hour, lp)
    d.rectangle([x0 - 3, y0 - 3, x1 + 3, y1 + 3], outline=dark)
    d.rectangle([x0 - 2, y0 - 2, x1 + 2, y1 + 2], outline=edge)


def draw_grass(d, x, y, c_hi, c_lo, h=4, spread=3):
    d.line([(x, y), (x, y - h)], fill=c_hi)
    d.line([(x - spread, y), (x - spread + 1, y - h + 2)], fill=c_lo)
    d.line([(x + spread, y), (x + spread - 1, y - h + 1)], fill=c_lo)


def draw_bush(d, cx, cy, w, h, leaf, hi, lo, sun_side, out):
    dither_blob(d, cx, cy, w, h, leaf, hi, lo, sun_side, outline=out)
    for k in range(6):
        bx = cx - w + k * (w * 2 / 5.0)
        by = cy - h * 0.72 - (2 if k % 2 else 0)
        d.point((int(bx), int(by)), fill=hi)
        d.point((int(bx), int(by) - 1), fill=hi)


def draw_mushroom(d, x, y, cap, stem, glow):
    d.line([(x, y), (x, y - 3)], fill=stem)
    ell(d, x, y - 4, 3, 2, cap)
    d.point((x - 1, y - 5), fill=glow)
    d.point((x + 1, y - 5), fill=glow)


# ─────────────────────────── 场景：林地 ───────────────────────────

def scene_forest(img, d, hour, lp):
    sun_side, day = light_dir(hour)
    sun_body, _ = sun_color(hour, False)
    out = resolve(hx("#1a161e"), hour, lp)
    far3 = resolve(hx("#7f9f88"), hour, lp)
    far2 = resolve(hx("#66886f"), hour, lp)
    far1 = resolve(hx("#527560"), hour, lp)
    leaf = resolve(hx("#3f6350"), hour, lp)
    leaf_hi = mix(resolve(hx("#587f65"), hour, lp), sun_body, 0.25 * day)
    leaf_lo = resolve(hx("#2f4d3c"), hour, lp)
    trunk = resolve(hx("#4a3b31"), hour, lp)
    trunk_dk = resolve(hx("#372b24"), hour, lp)
    grass_hi = resolve(hx("#7fa063"), hour, lp)
    grass_lo = resolve(hx("#5b7847"), hour, lp)
    rock = resolve(hx("#6d6a62"), hour, lp)
    shadow = mix(resolve(hx("#1a161e"), hour, lp), resolve(hx("#54704c"), hour, lp), 0.35)
    glow = resolve_glow(hx("#ffe9a3"), hour, lp)

    # 远山（两层）
    d.polygon([(0, 166), (50, 158), (110, 164), (170, 156), (240, 165), (320, 157), (400, 164), (480, 158), (480, 176), (0, 176)], fill=far3)
    d.polygon([(0, 172), (60, 165), (130, 171), (200, 164), (280, 172), (360, 165), (440, 171), (480, 167), (480, 180), (0, 180)], fill=far2)

    # 远树线（高低错落两层）
    for i in range(30):
        tx = i * 17 - 4
        th = 8 + ((i * 7) % 9)
        d.polygon([(tx, 178), (tx + 8, 178 - th), (tx + 16, 178)], fill=far2)
    for i in range(24):
        tx = i * 21 + 3
        th = 6 + ((i * 5) % 7)
        d.polygon([(tx, 182), (tx + 9, 182 - th), (tx + 18, 182)], fill=far1)

    def tree(cx, base, h, r):
        r_rect(d, cx - 1, base - h, cx + 2, base, trunk, out)
        d.line([(cx + 1, base - h + 2), (cx + 1, base - 1)], fill=trunk_dk)
        d.line([(cx, base - h + 5), (cx - 4 * sun_side, base - h - 2)], fill=trunk)
        d.line([(cx, base - h + 11), (cx + 5 * sun_side, base - h + 3)], fill=trunk)
        dither_blob(d, cx, base - h - r * 0.72, r, r * 0.78, leaf, leaf_hi, leaf_lo, sun_side, out)
        dither_blob(d, cx - r * 0.58, base - h - r * 0.42, r * 0.60, r * 0.52, leaf, leaf_hi, leaf_lo, sun_side, out)
        dither_blob(d, cx + r * 0.52, base - h - r * 0.48, r * 0.56, r * 0.48, leaf, leaf_hi, leaf_lo, sun_side, out)
        ell(d, cx + sun_side * 2, base + 1, r * 0.75, 3, shadow)

    tree(26, 180, 64, 25)
    tree(2, 176, 40, 16)
    tree(462, 180, 70, 26)
    tree(478, 174, 44, 17)

    # 平台两侧灌木与蕨类
    draw_bush(d, 40, 238, 26, 10, leaf, leaf_hi, leaf_lo, sun_side, out)
    draw_bush(d, 452, 244, 24, 9, leaf, leaf_hi, leaf_lo, sun_side, out)
    # 地面草丛（成簇）
    for i in range(26):
        gx = (i * 41 + 7) % LW
        gy = 190 + (i * 23) % 72
        if 56 < gx < 236 and 186 < gy < 248:
            continue
        draw_grass(d, gx, gy, grass_hi, grass_lo)
    # 石块
    for i, (rx, ry, r) in enumerate(((34, 212, 3), (58, 248, 4), (300, 252, 3), (430, 226, 3), (474, 258, 4))):
        ell(d, rx, ry, r, r - 1, rock, out)
    # 蘑菇
    draw_mushroom(d, 24, 246, resolve(hx("#c96a5a"), hour, lp), resolve(hx("#e8d8c0"), hour, lp), glow)
    draw_mushroom(d, 440, 252, resolve(hx("#c96a5a"), hour, lp), resolve(hx("#e8d8c0"), hour, lp), glow)
    draw_mushroom(d, 452, 248, resolve(hx("#d98a5a"), hour, lp), resolve(hx("#e8d8c0"), hour, lp), glow)
    # 夜萤
    if lp["lamps"] > 0.15:
        cnt = int(4 + 12 * lp["lamps"])
        for i in range(cnt):
            fx = (i * 79 + 30) % LW
            fy = 58 + (i * 43) % 100
            d.point((fx, fy), fill=glow)
            d.point((fx + 1, fy), fill=mix(glow, (0, 0, 0), 0.3))


# ─────────────────────────── 场景：锈蚀废墟 ───────────────────────────

def scene_ruins(img, d, hour, lp):
    sun_side, day = light_dir(hour)
    sun_body, _ = sun_color(hour, False)
    out = resolve(hx("#1a161e"), hour, lp)
    far = resolve(hx("#5d4a48"), hour, lp)
    brick = resolve(hx("#4a3436"), hour, lp)
    mid = resolve(hx("#3a2c2e"), hour, lp)
    wall_hi = mix(resolve(hx("#5a4446"), hour, lp), sun_body, 0.22 * day)
    wall_lo = resolve(hx("#2a2022"), hour, lp)
    pipe = resolve(hx("#55403a"), hour, lp)
    pipe_hi = mix(resolve(hx("#6d5248"), hour, lp), sun_body, 0.2 * day)
    rust = resolve(hx("#8b4a2f"), hour, lp)
    smoke = resolve(hx("#7a6a68"), hour, lp)
    lamp = resolve_glow(hx("#ffcf7a"), hour, lp, 0.0)
    win_dark = resolve(hx("#241d20"), hour, lp)
    rock = resolve(hx("#57504a"), hour, lp)

    # 远景厂房天际线
    x = -10
    i = 0
    while x < LW + 20:
        bw = 26 + (i * 17) % 36
        bh = 22 + (i * 23) % 42
        base = 170
        r_rect(d, x, base - bh, x + bw, base, far)
        if i % 2 == 0:
            cx = x + 6 + (i * 7) % max(4, bw - 12)
            r_rect(d, cx, base - bh - 14, cx + 4, base - bh, far)
            for p in range(3):
                d.ellipse([cx - 5 + p * 5, base - bh - 24 - p * 3, cx + 7 + p * 5, base - bh - 16 - p * 3], fill=smoke)
        for wy in range(base - bh + 4, base - 4, 6):
            for wx in range(x + 4, x + bw - 4, 6):
                lit = ((wx * 7 + wy * 13 + i) % 5 == 0)
                col = lamp if (lit and lp["lamps"] > 0.3) else win_dark
                d.point((wx, wy), fill=col)
                d.point((wx + 1, wy), fill=col)
        x += bw + 6
        i += 1

    # 中景断墙（带砖缝与受光边）
    def wall(x0, y0, x1, y1):
        r_rect(d, x0, y0, x1, y1, mid, out)
        for yy in range(y0 + 3, y1, 4):
            d.line([(x0 + 1, yy), (x1 - 2, yy)], fill=wall_lo)
        d.line([(x0 + 1, y0 + 1), (x0 + 1, y1 - 2)], fill=wall_hi if sun_side < 0 else wall_lo)
        d.line([(x1 - 2, y0 + 1), (x1 - 2, y1 - 2)], fill=wall_hi if sun_side > 0 else wall_lo)

    wall(4, 118, 30, 178)
    wall(26, 136, 46, 178)
    wall(448, 114, 476, 178)

    # 管道与阀门
    d.line([(30, 150), (90, 150)], fill=pipe, width=3)
    d.line([(90, 150), (90, 130)], fill=pipe, width=3)
    d.line([(31, 149), (89, 149)], fill=pipe_hi)
    d.line([(392, 146), (448, 146)], fill=pipe, width=3)
    d.line([(448, 146), (448, 126)], fill=pipe, width=3)
    d.line([(393, 145), (447, 145)], fill=pipe_hi)
    ell(d, 90, 128, 3, 3, resolve(hx("#6d5248"), hour, lp), out)
    ell(d, 448, 124, 3, 3, resolve(hx("#6d5248"), hour, lp), out)
    # 电线杆 + 电缆
    for px_ in (60, 420):
        d.line([(px_, 178), (px_, 118)], fill=mid, width=2)
        d.line([(px_ - 6, 124), (px_ + 6, 124)], fill=mid)
        d.line([(px_ - 4, 132), (px_ + 4, 132)], fill=mid)
    for x0, x1, yc, sag in ((64, 416, 124, 10), (60, 240, 134, 8)):
        pts = []
        for t in range(0, 25):
            f = t / 24.0
            pts.append((int(x0 + (x1 - x0) * f), int(yc + sag * math.sin(math.pi * f))))
        d.line(pts, fill=out)

    # 地面：碎石、锈痕、反光水洼
    for k in range(90):
        gx = (k * 61 + 13) % LW
        gy = 186 + (k * 37) % 72
        if 56 < gx < 236 and 186 < gy < 248:
            continue
        r = 1 + (k % 3)
        col = rust if k % 4 == 0 else rock
        d.ellipse([gx - r, gy - r, gx + r, gy + r], fill=col)
    for k, (px_, py) in enumerate(((36, 232), (300, 258), (452, 238))):
        ell(d, px_, py, 7, 2, resolve(hx("#3d4a52"), hour, lp))
        d.point((px_ - 2, py - 1), fill=mix(resolve(hx("#9db8c8"), hour, lp), lamp, 0.2))


# ─────────────────────────── 场景：母树核心 ───────────────────────────

def scene_core(img, d, hour, lp):
    sun_side, day = light_dir(hour)
    sun_body, _ = sun_color(hour, False)
    out = resolve(hx("#0a1218"), hour, lp)
    mid = resolve(hx("#12242c"), hour, lp)
    mid_hi = mix(resolve(hx("#1d3944"), hour, lp), sun_body, 0.15 * day)
    moss = resolve(hx("#2a4a42"), hour, lp)
    seam = resolve_glow(hx("#59e0c0"), hour, lp, 0.5)
    pod_a = resolve_glow(hx("#9df3d8"), hour, lp, 0.45)
    pod_b = resolve_glow(hx("#e79df0"), hour, lp, 0.45)
    vine = resolve(hx("#2a4a42"), hour, lp)
    glow = pod_a

    # 顶部巨树冠剪影
    d.polygon(
        [(0, 0), (LW, 0), (LW, 24), (452, 34), (420, 26), (388, 40), (352, 30), (318, 44),
         (280, 32), (246, 46), (208, 34), (172, 46), (136, 34), (100, 46), (62, 34), (28, 44), (0, 28)],
        fill=mid, outline=out,
    )
    d.line([(0, 26), (480, 22)], fill=mix(mid_hi, mid, 0.5))
    for i in range(6):
        cx = 36 + i * 82
        cy = 38 + (i * 9) % 10
        dither_blob(d, cx, cy, 19, 10, mid, mid_hi, out, sun_side, outline=out)
    # 垂藤
    for i in range(11):
        vx = 16 + i * 44
        vy = 34 + (i * 13) % 14
        d.line([(vx, vy), (vx + (2 if i % 2 else -2), vy + 16)], fill=vine)
        d.point((vx + (2 if i % 2 else -2), vy + 17), fill=pod_a if i % 2 else pod_b)
        if i % 3 == 0:
            d.point((vx + (2 if i % 2 else -2) + 1, vy + 10), fill=vine)

    def pillar(px_, base, h, w):
        pts = [(px_ - w, base), (px_ + w, base), (px_ + int(w * 0.7), base - h), (px_ - int(w * 0.7), base - h)]
        poly(d, pts, mid, out)
        # 受光边
        lit_side = sun_side
        lx = px_ + lit_side * (w - 1)
        d.line([(lx, base - 4), (px_ + lit_side * int(w * 0.7), base - h + 6)], fill=mid_hi)
        # 面板横缝
        for k in range(1, 5):
            yy = base - int(h * k / 5.2)
            d.line([(px_ - int(w * 0.72), yy), (px_ + int(w * 0.72), yy)], fill=out)
        # 发光缝隙
        d.line([(px_, base - 8), (px_ + sun_side * 2, base - h + 10)], fill=seam)
        # 孢子挂点
        for k in range(2):
            yy = base - int(h * (0.34 + 0.34 * k))
            side = 1 if k % 2 == 0 else -1
            xx = px_ + side * int(w * 0.85)
            d.line([(xx, yy), (xx + side * 6, yy - 4)], fill=out)
            d.ellipse([xx + side * 6 - 2, yy - 6, xx + side * 6 + 2, yy - 2], fill=pod_a if k % 2 == 0 else pod_b)
        d.ellipse([px_ - 3, base - h - 7, px_ + 3, base - h - 1], fill=pod_a)
        # 苔藓
        for k in range(6):
            mx = px_ - w + (k * 11) % (w * 2)
            d.point((mx, base - 4 - (k * 7) % 10), fill=moss)

    pillar(26, 178, 88, 15)
    pillar(454, 178, 100, 17)

    # 发光根须
    for x0, x1, yc in ((32, 104, 184), (448, 376, 184), (32, 74, 198), (448, 406, 198)):
        pts = []
        for t in range(0, 21):
            f = t / 20.0
            pts.append((int(x0 + (x1 - x0) * f), int(yc + 9 * math.sin(math.pi * f))))
        d.line(pts, fill=seam)

    # 地面苔斑/石块
    for k in range(40):
        gx = (k * 53 + 11) % LW
        gy = 188 + (k * 31) % 70
        if 56 < gx < 236 and 186 < gy < 248:
            continue
        r = 1 + (k % 3)
        d.ellipse([gx - r, gy - r, gx + r, gy + r], fill=moss if k % 3 else resolve(hx("#1c2f29"), hour, lp))

    # 孢子光点
    if lp["lamps"] > 0.2:
        cnt = int(8 + 26 * lp["lamps"])
        for i in range(cnt):
            sx = (i * 71 + 17) % LW
            sy = 36 + (i * 53) % 132
            d.point((sx, sy), fill=pod_a if i % 3 else pod_b)
            if i % 5 == 0:
                d.point((sx + 1, sy), fill=mix(glow, mid, 0.4))


SCENES = {
    "forest": ("ForestClearing", scene_forest),
    "ruins": ("RustedRuins", scene_ruins),
    "core": ("BloomCore", scene_core),
}

GROUND = {
    "forest": (hx("#6d8a5e"), hx("#54704c"), hx("#7fa063")),
    "ruins": (hx("#4a4440"), hx("#37322f"), hx("#7d4326")),
    "core": (hx("#20362f"), hx("#152720"), hx("#2e4f42")),
}


# ─────────────────────────── 渲染与输出 ───────────────────────────

PALETTE_JSON = os.path.join(BASE, "resources", "palette", "gg256.json")


def snap_to_palette(img):
    with open(PALETTE_JSON, encoding="utf-8") as f:
        hexes = json.load(f)
    flat = []
    for h in hexes[:256]:
        h = h.lstrip("#")
        flat += [int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)]
    flat += [0] * (768 - len(flat))
    pal = Image.new("P", (1, 1))
    pal.putpalette(flat)
    return img.quantize(palette=pal, dither=Image.Dither.NONE).convert("RGB")


def render_lowres(theme, hour):
    _, fn = SCENES[theme]
    lp = light_params(hour)
    img = Image.new("RGB", (LW, LH), sky_colors(hour)[2])
    d = ImageDraw.Draw(img)
    draw_sky(img, hour)
    draw_clouds(img, hour, lp)
    draw_stars(img, hour)
    draw_sun_moon(img, hour)
    c_far, c_near, c_patch = GROUND[theme]
    draw_ground(img, hour, lp, c_far, c_near, c_patch)
    fn(img, d, hour, lp)
    darken_platform(img)
    draw_platform_frame(d, hour, lp)
    return img


def hour_tag(hour):
    h = int(hour)
    m = int(round((hour - h) * 60))
    return "%02d%02d" % (h % 24, m)


def render(theme, hour, preview=False, use_palette=True):
    name, _ = SCENES[theme]
    low = render_lowres(theme, hour)
    if use_palette:
        low = snap_to_palette(low)
    big = low.resize((W, H), Image.NEAREST)
    os.makedirs(OUT_DIR, exist_ok=True)
    out_path = os.path.join(OUT_DIR, "%s_%s.png" % (name, hour_tag(hour)))
    big.save(out_path)
    print("saved:", os.path.relpath(out_path, BASE))
    if preview:
        build_preview(big, theme, hour)
    return out_path


def _load(rel):
    return Image.open(os.path.join(BASE, rel.replace("/", os.sep))).convert("RGBA")


def build_preview(bg, theme, hour):
    layer = bg.convert("RGBA").copy()
    layer.alpha_composite(_load("room/battle_background/UpperLayer.png"), (0, 0))
    layer.alpha_composite(_load("actors/player/Player-export.png").crop((0, 0, 192, 192)), (300 - 96, 200 - 96))
    layer.alpha_composite(_load("resources/enemy_images/Gonh.png").crop((0, 0, 192, 192)), (1300 - 96, 150 - 96))
    layer.alpha_composite(_load("resources/enemy_images/RustHound.png").crop((0, 0, 192, 192)), (1500 - 96, 350 - 96))
    layer.alpha_composite(_load("resources/blockpart_picture/green/strike.png"), (432, 672))
    layer.alpha_composite(_load("resources/blockpart_picture/purple/echo.png"), (528, 672))
    os.makedirs(PREVIEW_DIR, exist_ok=True)
    out = os.path.join(PREVIEW_DIR, "pixel_preview_%s_%s.png" % (theme, hour_tag(hour)))
    layer.save(out)
    print("preview:", os.path.relpath(out, BASE))


def build_strip(theme, hours):
    name, _ = SCENES[theme]
    font = ImageFont.load_default()
    cols = 3
    rows = (len(hours) + cols - 1) // cols
    strip = Image.new("RGB", (LW * cols, LH * rows), (10, 10, 14))
    for i, h in enumerate(hours):
        low = render_lowres(theme, h)
        strip.paste(low, ((i % cols) * LW, (i // cols) * LH))
        sd = ImageDraw.Draw(strip)
        label = "%02d:00" % int(h)
        ox = (i % cols) * LW + 6
        oy = (i // cols) * LH + 5
        sd.text((ox + 1, oy + 1), label, fill=(0, 0, 0), font=font)
        sd.text((ox, oy), label, fill=(255, 255, 255), font=font)
    os.makedirs(PREVIEW_DIR, exist_ok=True)
    out = os.path.join(PREVIEW_DIR, "pixel_timestrip_%s.png" % name)
    strip.save(out)
    print("strip:", os.path.relpath(out, BASE))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--themes", default="forest,ruins,core")
    ap.add_argument("--hours", default="19")
    ap.add_argument("--preview", action="store_true")
    ap.add_argument("--strip", action="store_true")
    ap.add_argument("--no-palette", action="store_true", help="不吸附到 gg256 调色板")
    args = ap.parse_args()
    themes = [t.strip() for t in args.themes.split(",") if t.strip()]
    hours = [float(h) for h in args.hours.split(",") if h.strip()]
    for t in themes:
        if args.strip:
            build_strip(t, hours)
        for h in hours:
            render(t, h, preview=args.preview, use_palette=not args.no_palette)


if __name__ == "__main__":
    main()
