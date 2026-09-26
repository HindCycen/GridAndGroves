#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
GridAndGroves 素材像素化工具（矢量底稿 -> 像素画）
==================================================
把现有矢量素材（角色/敌人/方块部件/状态图标/地砖叠图）按统一的像素网格重绘：
    1) 面积平均下采样到 N 像素网格（BOX）
    2) 中位切分调色板量化（去抗锯齿杂色）
    3) alpha 阈值化（像素画硬边）
    4) 4x NEAREST 放大回原显示尺寸（与 480x270 -> 1920x1080 的背景同一像素密度）

输出用于人工评估的对照拼图 demo_generated/pixel_asset_preview.png
以及一张全像素战斗合成 demo_generated/pixel_scene_mock.png

用法：python tools/pixelize_assets.py
"""

import json
import os

from PIL import Image, ImageDraw, ImageFont

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PREVIEW_DIR = os.path.join(BASE, "demo_generated")
PALETTE_JSON = os.path.join(BASE, "resources", "palette", "gg256.json")
SCALE = 4

# (相对路径, 每帧目标像素宽, 是否横向 spritesheet, 调色板颜色数)
ASSETS = [
    ("actors/player/Player-export.png", 48, True, 8),
    ("resources/enemy_images/Gonh.png", 48, True, 10),
    ("resources/enemy_images/RustHound.png", 48, True, 10),
    ("resources/enemy_images/SporeCrawler.png", 48, True, 10),
    ("resources/enemy_images/RustColossus.png", 48, True, 10),
    ("resources/enemy_images/IronWarden.png", 48, True, 10),
    ("resources/enemy_images/BloomMother.png", 48, True, 10),
    ("resources/blockpart_picture/green/strike.png", 24, False, 6),
    ("resources/blockpart_picture/blue/defend.png", 24, False, 6),
    ("resources/blockpart_picture/purple/echo.png", 24, False, 6),
    ("resources/blockpart_picture/brown/bolt.png", 24, False, 6),
    ("resources/blockpart_picture/red/detonator.png", 24, False, 6),
    ("resources/stat_images/Overload.png", 12, False, 8),
    ("resources/stat_images/Rust.png", 12, False, 8),
]


def load(rel):
    return Image.open(os.path.join(BASE, rel.replace("/", os.sep))).convert("RGBA")


def load_palette_image():
    with open(PALETTE_JSON, encoding="utf-8") as f:
        hexes = json.load(f)
    flat = []
    for h in hexes[:256]:
        h = h.lstrip("#")
        flat += [int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)]
    flat += [0] * (768 - len(flat))
    pal = Image.new("P", (1, 1))
    pal.putpalette(flat)
    return pal


_PAL = None


def quantize_to_palette(img_rgb):
    global _PAL
    if _PAL is None:
        _PAL = load_palette_image()
    return img_rgb.quantize(palette=_PAL, dither=Image.Dither.NONE).convert("RGB")


def pixelize_frame(img, target_w, colors):
    """单帧像素化：面积下采样 -> 调色板量化 -> alpha 硬边"""
    w, h = img.size
    target_h = max(1, round(h * target_w / float(w)))
    small = img.resize((target_w, target_h), Image.BOX)
    rgb = small.convert("RGB")
    q = quantize_to_palette(rgb)
    alpha = small.getchannel("A").point(lambda a: 255 if a >= 96 else 0)
    out = q.convert("RGBA")
    out.putalpha(alpha)
    # 透明像素不留脏色
    px = out.load()
    for y in range(target_h):
        for x in range(target_w):
            if px[x, y][3] == 0:
                px[x, y] = (0, 0, 0, 0)
    return out


def pixelize(rel, target_w, is_sheet, colors=None):
    src = load(rel)
    w, h = src.size
    if is_sheet and w == h * 2:
        frames = [src.crop((i * h, 0, (i + 1) * h, h)) for i in range(2)]
        outs = [pixelize_frame(f, target_w, colors) for f in frames]
        sheet = Image.new("RGBA", (outs[0].width * 2, outs[0].height), (0, 0, 0, 0))
        for i, o in enumerate(outs):
            sheet.paste(o, (i * outs[0].width, 0))
        small = sheet
    else:
        small = pixelize_frame(src, target_w, colors)
    big = small.resize((small.width * SCALE, small.height * SCALE), Image.NEAREST)
    return small, big


def build_contact_sheet(results):
    font = ImageFont.load_default()
    cell = 140
    pad = 8
    cols = 3
    rows = (len(results) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * (cell * 2 + pad * 3), rows * (cell + pad * 2)), (24, 22, 28))
    sd = ImageDraw.Draw(sheet)
    for i, (rel, small, big) in enumerate(results):
        cx = (i % cols) * (cell * 2 + pad * 3) + pad
        cy = (i // cols) * (cell + pad * 2) + pad
        sd.text((cx, cy), os.path.basename(rel) + "  " + str(small.size[0]) + "px-grid",
                fill=(220, 220, 220), font=font)
        src = load(rel)
        src_thumb = fit(src, cell, cell)
        big_thumb = fit(big, cell, cell)
        sheet.paste(src_thumb, (cx, cy + 12), src_thumb)
        sheet.paste(big_thumb, (cx + cell + pad, cy + 12), big_thumb)
        sd.text((cx, cy + 12 + cell + 2), "original", fill=(150, 200, 150), font=font)
        sd.text((cx + cell + pad, cy + 12 + cell + 2), "pixelized 4x", fill=(200, 170, 240), font=font)
    return sheet


def fit(img, w, h):
    im = img.copy()
    im.thumbnail((w, h), Image.NEAREST)
    canvas = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    canvas.paste(im, ((w - im.width) // 2, (h - im.height) // 2), im)
    return canvas


def build_grid_overlay():
    """地砖按同一像素网格程序化重画（半透明底稿不适合直接量化）"""
    lw, lh = 480, 270
    img = Image.new("RGBA", (lw, lh), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    x0, y0 = 60, 120
    for cx in range(7):
        for cy in range(5):
            ax = x0 + cx * 24
            ay = y0 + cy * 24
            d.rectangle([ax, ay, ax + 23, ay + 23], fill=(13, 12, 16, 210), outline=(206, 206, 212, 235))
    return img.resize((lw * SCALE, lh * SCALE), Image.NEAREST)


def build_scene_mock(pixel_assets):
    bg = load("room/battle_background/ForestClearing_2000.png").convert("RGBA")
    def get(rel):
        for r, small, big in pixel_assets:
            if r == rel:
                return big
        return load(rel)
    bg.alpha_composite(build_grid_overlay(), (0, 0))
    player = get("actors/player/Player-export.png")
    bg.alpha_composite(player.crop((0, 0, player.width // 2, player.height)), (300 - 96, 200 - 96))
    gonh = get("resources/enemy_images/Gonh.png")
    bg.alpha_composite(gonh.crop((0, 0, gonh.width // 2, gonh.height)), (1300 - 96, 150 - 96))
    hound = get("resources/enemy_images/RustHound.png")
    bg.alpha_composite(hound.crop((0, 0, hound.width // 2, hound.height)), (1500 - 96, 350 - 96))
    strike = get("resources/blockpart_picture/green/strike.png")
    bg.alpha_composite(strike, (432, 672))
    echo = get("resources/blockpart_picture/purple/echo.png")
    bg.alpha_composite(echo, (528, 672))
    out = os.path.join(PREVIEW_DIR, "pixel_scene_mock.png")
    bg.convert("RGB").save(out)
    print("mock:", os.path.relpath(out, BASE))


def main():
    os.makedirs(PREVIEW_DIR, exist_ok=True)
    results = []
    for rel, tw, sheet, colors in ASSETS:
        small, big = pixelize(rel, tw, sheet, colors)
        results.append((rel, small, big))
    sheet = build_contact_sheet(results)
    out = os.path.join(PREVIEW_DIR, "pixel_asset_preview.png")
    sheet.save(out)
    print("contact sheet:", os.path.relpath(out, BASE))
    build_scene_mock(results)


if __name__ == "__main__":
    main()
