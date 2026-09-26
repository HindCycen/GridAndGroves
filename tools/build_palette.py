#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
GridAndGroves 全局 256 色调色板构建器
=====================================
从项目现有美术（方块部件 / 敌人 / 玩家 / 状态与意图图标 / UI / 像素背景）
中确定性提取 256 色调色板，供：
  - pixelize_assets.py 量化素材
  - gen_pixel_backgrounds.py 吸附背景颜色
  - img2img 精修结果的最终量化

输出：
  resources/palette/gg256.png   16x16 色板图（Godot 可直接引用）
  resources/palette/gg256.json  颜色列表（#rrggbb，按提取顺序）
  resources/palette/gg256.gpl   GIMP 调色板（外部编辑器/Aseprite 可用）

用法：python tools/build_palette.py
"""

import glob
import json
import os

from PIL import Image, ImageDraw

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(BASE, "resources", "palette")
MAX_SIDE = 96  # 每张素材采样时缩到的最长边


def collect_sources():
    pats = [
        "resources/blockpart_picture/**/*.png",
        "resources/enemy_images/*.png",
        "actors/player/*.png",
        "resources/stat_images/*.png",
        "resources/enemy_intents/icons/*.png",
        "room/room_pictures/*.png",
        "room/battle_background/*.png",
        "components/healthbar/*.png",
        "room/bot_frames/*.png",
    ]
    files = []
    for p in pats:
        files.extend(glob.glob(os.path.join(BASE, p.replace("/", os.sep)), recursive=True))
    # 去掉 .import 同行重复与预览图
    files = [f for f in files if not f.endswith(".import")]
    return sorted(set(files))


def build_mosaic(files):
    thumbs = []
    for f in files:
        try:
            im = Image.open(f).convert("RGBA")
        except Exception:
            continue
        w, h = im.size
        if max(w, h) > MAX_SIDE:
            k = MAX_SIDE / float(max(w, h))
            im = im.resize((max(1, int(w * k)), max(1, int(h * k))), Image.BOX)
        # 丢弃全透明/近透明像素
        bg = Image.new("RGBA", im.size, (0, 0, 0, 0))
        px = im.load()
        for y in range(im.height):
            for x in range(im.width):
                r, g, b, a = px[x, y]
                if a < 200:
                    px[x, y] = (0, 0, 0, 0)
        thumbs.append(im)
    cols = 24
    cell = MAX_SIDE
    rows = (len(thumbs) + cols - 1) // cols
    mosaic = Image.new("RGBA", (cols * cell, rows * cell), (0, 0, 0, 0))
    for i, t in enumerate(thumbs):
        mosaic.paste(t, ((i % cols) * cell, (i // cols) * cell), t)
    return mosaic


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    files = collect_sources()
    mosaic = build_mosaic(files)
    print("sources:", len(files), "mosaic:", mosaic.size)

    # 以白底合成后再量化，避免透明区域拉低色彩统计
    flat = Image.new("RGB", mosaic.size, (255, 255, 255))
    flat.paste(mosaic, (0, 0), mosaic)
    # 面积下采样，让量化更快更均衡
    flat = flat.resize((max(1, flat.width // 2), max(1, flat.height // 2)), Image.BOX)
    pal_img = flat.quantize(colors=256, method=Image.MEDIANCUT, dither=Image.Dither.NONE)
    palette = pal_img.getpalette()[: 256 * 3]
    colors = [(palette[i * 3], palette[i * 3 + 1], palette[i * 3 + 2]) for i in range(256)]

    # 去重并补齐到 256（不足时用线性混合补齐，保持确定性）
    seen = set()
    uniq = []
    for c in colors:
        if c not in seen:
            seen.add(c)
            uniq.append(c)
    i = 0
    while len(uniq) < 256:
        a = uniq[i % len(uniq)]
        b = uniq[(i * 7 + 3) % len(uniq)]
        uniq.append(tuple((a[k] + b[k]) // 2 for k in range(3)))
        i += 1
    colors = uniq[:256]
    # 固定前几格为像素画基准色（黑/白/暗描边）
    colors[0] = (0, 0, 0)
    colors[1] = (255, 255, 255)
    colors[2] = (26, 22, 30)

    swatch = Image.new("RGB", (16 * 16, 16 * 16))
    d = ImageDraw.Draw(swatch)
    for idx, c in enumerate(colors):
        x = (idx % 16) * 16
        y = (idx // 16) * 16
        d.rectangle([x, y, x + 15, y + 15], fill=c)
    swatch.save(os.path.join(OUT_DIR, "gg256.png"))

    with open(os.path.join(OUT_DIR, "gg256.json"), "w", encoding="utf-8") as f:
        json.dump(["#%02x%02x%02x" % c for c in colors], f, indent=0)

    with open(os.path.join(OUT_DIR, "gg256.gpl"), "w", encoding="utf-8") as f:
        f.write("GIMP Palette\nName: GridAndGroves 256\nColumns: 16\n#\n")
        for c in colors:
            f.write("%3d %3d %3d\t#%02x%02x%02x\n" % (c[0], c[1], c[2], c[0], c[1], c[2]))

    print("palette saved:", os.path.relpath(os.path.join(OUT_DIR, "gg256.png"), BASE))


if __name__ == "__main__":
    main()
