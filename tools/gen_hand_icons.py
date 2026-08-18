#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
GridAndGroves 手绘原型图标提取器
================================
从最初手绘的两张图中提取形状，生成 Strike/Defend 基础卡的部件图：

- Attack-G.png：绿色底板 + 白色剑形 → 提取“白色部分”作为攻击图标
- Shield-G.png：透明底青色盾形（无白色）→ 提取不透明部分（盾轮廓）作为防御图标

提取的形状按程序化部件图风格（圆角底 + 深描边 + 高光）合成新图：
    resources/blockpart_picture/green/strike.png  （攻击，玩家绿）
    resources/blockpart_picture/blue/defend.png   （防御，护盾蓝）

用法：
    python3 tools/gen_hand_icons.py          # 生成两张图
    python3 tools/gen_hand_icons.py --json   # 生成图并更新 block_defs.json 引用
"""

import json
import os
import sys

from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_block_parts import SIZE, PALETTES, draw_part

SRC_DIR = os.path.join("resources", "blockpart_picture", "green")
ATTACK_SRC = os.path.join(SRC_DIR, "Attack-G.png")
SHIELD_SRC = os.path.join(SRC_DIR, "Shield-G.png")
OUT = os.path.join("resources", "blockpart_picture")

ICON_HALF = 30  # 与 gen_block_parts.draw_part 的图标半边长一致

# 白色阈值：Attack-G 的图标是 (224,224,224) 亮白
WHITE_THRESHOLD = 200


def extract_white_mask(img):
    """提取白色像素 mask（保留白色 + alpha 有效区域）"""
    px = img.load()
    w, h = img.size
    mask = Image.new("L", (w, h), 0)
    mpx = mask.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a > 100 and r >= WHITE_THRESHOLD and g >= WHITE_THRESHOLD and b >= WHITE_THRESHOLD:
                mpx[x, y] = 255
    return mask


def extract_opaque_mask(img):
    """提取不透明像素 mask（Shield-G 为透明底盾形）"""
    px = img.load()
    w, h = img.size
    mask = Image.new("L", (w, h), 0)
    mpx = mask.load()
    for y in range(h):
        for x in range(w):
            if px[x, y][3] > 100:
                mpx[x, y] = 255
    return mask


def trim_and_fit(mask, target_half):
    """裁掉空白边界，等比缩放到以 target_half 为半径的方形区域内（保持纵横比）"""
    bbox = mask.getbbox()
    if bbox is None:
        return None
    crop = mask.crop(bbox)
    cw, ch = crop.size
    # 目标尺寸 = 图标区（2*target_half）内留一点余量
    target = int(target_half * 2 * 0.92)
    scale = min(target / cw, target / ch)
    nw = max(int(cw * scale), 1)
    nh = max(int(ch * scale), 1)
    crop = crop.resize((nw, nh), Image.LANCZOS)
    # 二值化（LANCZOS 会引入半透明边缘）
    crop = crop.point(lambda v: 255 if v > 120 else 0)
    return crop


def to_outline(mask, erosion=5, keep_core_ratio=0.28):
    """实心形状 → 轮廓描边（挖空内芯，保留中央小实心核心防太空）"""
    inner = mask.filter(ImageFilter.MinFilter(erosion))
    outline = mask.copy()
    px1 = outline.load()
    px2 = inner.load()
    w, h = mask.size
    for y in range(h):
        for x in range(w):
            if px1[x, y] > 0 and px2[x, y] > 0:
                px1[x, y] = 0
    # 中央小实心核心（保持整体重心）
    bbox = mask.getbbox()
    cw = bbox[2] - bbox[0]
    ch = bbox[3] - bbox[1]
    core_w = max(int(cw * keep_core_ratio), 3)
    core_h = max(int(ch * keep_core_ratio), 3)
    cx0 = (bbox[0] + bbox[2]) // 2 - core_w // 2
    cy0 = (bbox[1] + bbox[3]) // 2 - core_h // 2
    for y in range(cy0, cy0 + core_h):
        for x in range(cx0, cx0 + core_w):
            if 0 <= x < w and 0 <= y < h and mask.getpixel((x, y)) > 0:
                px1[x, y] = 255
    return outline


def compose(icon_mask, palette_name, icon_tint, out_path):
    """把提取的图标形状合成到程序化底板上（风格与 draw_part 一致）"""
    pal = PALETTES[palette_name]
    img = _base_tile(pal)
    # 图标：提取形状填充为亮色
    tint = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    tpx = tint.load()
    mpx = icon_mask.load()
    cx0 = (SIZE - icon_mask.size[0]) // 2
    cy0 = (SIZE - icon_mask.size[1]) // 2
    for y in range(icon_mask.size[1]):
        for x in range(icon_mask.size[0]):
            if mpx[x, y] > 0:
                tpx[cx0 + x, cy0 + y] = (*icon_tint, 255)
    img = Image.alpha_composite(img, tint)
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    img.save(out_path)
    print("wrote", out_path)


def compose_with_icon_image(icon_img, palette_name, out_path):
    """把已渲染的图标位图（保留原色彩，如手绘盾的渐变）贴到程序化底板上"""
    img = _base_tile(PALETTES[palette_name])
    cx0 = (SIZE - icon_img.size[0]) // 2
    cy0 = (SIZE - icon_img.size[1]) // 2
    img.alpha_composite(icon_img, (cx0, cy0))
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    img.save(out_path)
    print("wrote", out_path)


def _base_tile(pal):
    """程序化底板：描边 + 底色 + 高光"""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, SIZE - 1, SIZE - 1], radius=10, fill=pal["edge"])
    d.rounded_rectangle([4, 4, SIZE - 5, SIZE - 5], radius=6, fill=pal["bg"])
    hl = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    hd = ImageDraw.Draw(hl)
    hd.polygon([(6, 6), (SIZE * 0.55, 6), (6, SIZE * 0.45)], fill=(255, 255, 255, 26))
    return Image.alpha_composite(img, hl)


def update_block_defs_json():
    """把 Strike/Defend 部件的 spriteTexture 指向手绘原型图"""
    path = "resources/block_defs.json"
    data = json.load(open(path, encoding="utf-8"))
    updated = 0
    for block in data["blocks"]:
        name = block.get("name", "")
        if name not in ("Strike", "Defend"):
            continue
        target = "green/strike.png" if name == "Strike" else "blue/defend.png"
        for part in block.get("parts", []):
            part["spriteTexture"] = f"res://resources/blockpart_picture/{target}"
            updated += 1
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")
    print(f"updated {updated} part texture reference(s) in block_defs.json")


def main():
    do_json = "--json" in sys.argv

    attack = Image.open(ATTACK_SRC).convert("RGBA")
    shield = Image.open(SHIELD_SRC).convert("RGBA")

    # Strike：提取 Attack-G 的白色部分（剑形）
    sword_mask = trim_and_fit(extract_white_mask(attack), ICON_HALF)
    if sword_mask is None:
        print("ERROR: no white shape found in Attack-G.png")
    else:
        compose(sword_mask, "green", (240, 240, 240),
                os.path.join(OUT, "green", "strike.png"))

    # Defend：Shield-G 手绘盾（透明底青色渐变盾，无白色部分）
    # 直接提取盾剪影原图贴到程序化蓝色底板上，保留手绘渐变细节
    shield_mask = extract_opaque_mask(shield)
    bbox = shield_mask.getbbox()
    if bbox is None:
        print("ERROR: no opaque shape found in Shield-G.png")
    else:
        crop = shield.crop(bbox)
        target = int(ICON_HALF * 2 * 0.92)
        scale = min(target / crop.size[0], target / crop.size[1])
        crop = crop.resize((max(int(crop.size[0] * scale), 1), max(int(crop.size[1] * scale), 1)),
                           Image.LANCZOS)
        compose_with_icon_image(crop, "blue", os.path.join(OUT, "blue", "defend.png"))

    if do_json:
        update_block_defs_json()


if __name__ == "__main__":
    main()