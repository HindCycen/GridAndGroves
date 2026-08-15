#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
GridAndGroves Stat 图标生成器
=============================
45×45 图标：圆角底 + 白色符号（复用 gen_block_parts 的图标库）
用法：python3 tools/gen_stat_icons.py
"""
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_block_parts import ICONS

SIZE = 45
OUT = os.path.join("resources", "stat_images")

# Stat 名 → (图标, 底色, 描边)
STATS = {
    "Echo":        ("echo",     (92, 62, 140), (38, 22, 76)),    # 紫：回响
    "Overload":    ("bolt",     (160, 126, 34), (84, 60, 10)),   # 黄：过载
    "Rust":        ("rust",     (148, 80, 36), (72, 32, 10)),    # 锈橙
    "ScrapCounter":("gear",     (110, 84, 52), (52, 38, 18)),    # 棕：废品
    "Symbiosis":   ("star4",    (64, 96, 32), (32, 80, 16)),     # 绿：共生
    "Vine":        ("vine",     (64, 128, 48), (24, 72, 20)),    # 深绿：藤蔓
    "Growing":     ("sprout",   (64, 128, 48), (24, 72, 20)),
    "Shooting":    ("arrow_up", (64, 96, 32), (32, 80, 16)),
}


def make_stat_icon(icon, bg, edge, out_path):
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, SIZE - 1, SIZE - 1], radius=9, fill=edge)
    d.rounded_rectangle([2, 2, SIZE - 3, SIZE - 3], radius=7, fill=bg)
    if icon in ICONS:
        ICONS[icon](d, SIZE / 2, SIZE / 2, 13, (245, 245, 245))
    img.save(out_path)
    return out_path


def main():
    os.makedirs(OUT, exist_ok=True)
    for stat, (icon, bg, edge) in STATS.items():
        path = os.path.join(OUT, f"{stat}.png")
        make_stat_icon(icon, bg, edge, path)
        print("wrote", path)
    print(f"generated {len(STATS)} stat icons")


if __name__ == "__main__":
    main()
