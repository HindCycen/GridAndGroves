#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
GridAndGroves 敌人意图图标生成器
================================
45×45 图标（复用 gen_block_parts 的图标库）：圆角底 + 白色符号。
意图名含攻击关键词 → 红剑；防御 → 蓝盾；治疗 → 绿十字；削弱 → 紫滴；
其余 → 灰星（默认）。

用法：
    python3 tools/gen_intent_icons.py                 # 用现有意图名生成全部图标
    python3 tools/gen_intent_icons.py --names a b     # 指定意图名
"""
import argparse
import json
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_block_parts import ICONS

SIZE = 45
OUT = os.path.join("resources", "enemy_intents", "icons")

# 关键词 → (图标, 底色, 描边)
KEYWORDS = [
    (("attack", "lash", "hit", "strike", "smash", "slam", "crush", "grip", "pounce",
      "bite", "volley", "barrage", "whip", "punch", "claw", "fang", "burst"), ("sword", (148, 44, 36), (72, 16, 8))),  # 红：攻击
    (("guard", "defend", "shield", "block", "protect"), ("shield", (32, 128, 128), (0, 64, 96))),  # 蓝：防御
    (("heal", "recover", "restore", "buff", "empower", "bloom", "seed", "grow"), ("cross", (64, 128, 48), (24, 72, 20))),   # 绿：治疗/增益
    (("debuff", "weaken", "poison", "rust", "vine", "curse"), ("drop", (92, 62, 140), (38, 22, 76))),  # 紫：削弱
]
DEFAULT = ("star4", (128, 112, 128), (0, 0, 0))  # 灰星：未知意图


def pick_style(intent_name):
    low = intent_name.lower()
    for kws, style in KEYWORDS:
        if any(k in low for k in kws):
            return style
    return DEFAULT


def make_intent_icon(icon, bg, edge, out_path):
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, SIZE - 1, SIZE - 1], radius=9, fill=edge)
    d.rounded_rectangle([2, 2, SIZE - 3, SIZE - 3], radius=7, fill=bg)
    if icon in ICONS:
        ICONS[icon](d, SIZE / 2, SIZE / 2, 13, (245, 245, 245))
    img.save(out_path)
    return out_path


def collect_intent_names():
    """从 enemy_defs.json 收集全部 intentName"""
    names = []
    data = json.load(open("resources/enemy_defs.json", encoding="utf-8"))
    for enemy in data.get("enemies", []):
        for intent in enemy.get("intentCycle", []):
            n = intent.get("intentName", "")
            if n and n not in names:
                names.append(n)
    return names


def main():
    ap = argparse.ArgumentParser(description="敌人意图图标生成器")
    ap.add_argument("--names", nargs="*", default=None,
                    help="指定意图名（默认扫描 enemy_defs.json）")
    args = ap.parse_args()

    names = args.names if args.names is not None else collect_intent_names()
    os.makedirs(OUT, exist_ok=True)
    for name in names:
        icon, bg, edge = pick_style(name)
        path = os.path.join(OUT, f"{name}.png")
        make_intent_icon(icon, bg, edge, path)
        print("wrote", path)
    print(f"generated {len(names)} intent icons -> {OUT}")


if __name__ == "__main__":
    main()