#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
GridAndGroves 程序化部件图生成器
================================
复刻现有 7 张部件图的风格（满幅圆角方块 + 深色描边 + 内部亮色图标），
为 147 个 Block 批量生成 96×96 部件图，摆脱手绘。

用法：
    python3 tools/gen_block_parts.py                # 生成全部图标 × 全部配色到 blockpart_picture/
    python3 tools/gen_block_parts.py --icons bolt   # 只生成指定图标

输出目录约定（与项目现有结构一致）：
    resources/blockpart_picture/<palette>/<icon>.png
"""

import argparse
import math
import os
import sys

from PIL import Image, ImageDraw

SIZE = 96
OUT_ROOT = os.path.join("resources", "blockpart_picture")

# ── 配色（底色 / 描边 / 高光 / 图标色）──
# 数值参考现有图片实测：green(64,96,32) 描边(32,80,16)；grey(128,112,128) 描边黑；blue 青
PALETTES = {
    "green":  {"bg": (64, 96, 32),  "edge": (32, 80, 16),  "hl": (48, 96, 16),  "icon": (240, 240, 240)},   # 玩家通用
    "blue":   {"bg": (32, 192, 208), "edge": (0, 80, 144), "hl": (0, 128, 208), "icon": (255, 255, 255)},   # 护盾/防御
    "grey":   {"bg": (128, 112, 128), "edge": (0, 0, 0),    "hl": (96, 96, 96), "icon": (240, 240, 240)},   # 敌人
    "red":    {"bg": (148, 44, 36),  "edge": (72, 16, 8),   "hl": (180, 64, 48), "icon": (255, 235, 225)},  # 爆炸/自伤
    "purple": {"bg": (92, 62, 140),  "edge": (38, 22, 76),  "hl": (122, 84, 176), "icon": (240, 230, 255)}, # 星语/法阵
    "brown":  {"bg": (106, 82, 50),  "edge": (52, 38, 18),  "hl": (136, 106, 66), "icon": (245, 235, 210)}, # 自然/扎根
    "yellow": {"bg": (160, 126, 34), "edge": (84, 60, 10),  "hl": (192, 152, 52), "icon": (255, 250, 220)}, # 机械/废品
    "dark":   {"bg": (64, 58, 78),   "edge": (20, 16, 28),  "hl": (92, 84, 108),  "icon": (230, 220, 240)}, # 暗网/神秘
}

# ── 图标绘制函数：fn(draw, cx, cy, s, color)，s 为图标半边长 ──
ICONS = {}


def icon(name):
    def deco(fn):
        ICONS[name] = fn
        return fn
    return deco


def _poly(d, pts, color):
    d.polygon(pts, fill=color)


@icon("blank")
def _blank(d, cx, cy, s, color):
    pass


@icon("arrow_down")
def _arrow_down(d, cx, cy, s, color):
    w = s * 0.9
    _poly(d, [(cx - w / 2, cy - s), (cx + w / 2, cy - s), (cx + w / 2, cy - s * 0.2),
              (cx + s * 1.1, cy - s * 0.2), (cx, cy + s), (cx - s * 1.1, cy - s * 0.2),
              (cx - w / 2, cy - s * 0.2)], color)


@icon("arrow_right")
def _arrow_right(d, cx, cy, s, color):
    w = s * 0.9
    _poly(d, [(cx - s, cy - w / 2), (cx - s, cy + w / 2), (cx - s * 0.2, cy + w / 2),
              (cx - s * 0.2, cy + s * 1.1), (cx + s, cy), (cx - s * 0.2, cy - s * 1.1),
              (cx - s * 0.2, cy - w / 2)], color)


@icon("arrow_up")
def _arrow_up(d, cx, cy, s, color):
    w = s * 0.9
    _poly(d, [(cx - w / 2, cy + s), (cx + w / 2, cy + s), (cx + w / 2, cy + s * 0.2),
              (cx + s * 1.1, cy + s * 0.2), (cx, cy - s), (cx - s * 1.1, cy + s * 0.2),
              (cx - w / 2, cy + s * 0.2)], color)


@icon("arrow_left")
def _arrow_left(d, cx, cy, s, color):
    w = s * 0.9
    _poly(d, [(cx + s, cy - w / 2), (cx + s, cy + w / 2), (cx + s * 0.2, cy + w / 2),
              (cx + s * 0.2, cy + s * 1.1), (cx - s, cy), (cx + s * 0.2, cy - s * 1.1),
              (cx + s * 0.2, cy - w / 2)], color)


@icon("sword")
def _sword(d, cx, cy, s, color):
    # 斜剑：刃 + 护手 + 柄
    _poly(d, [(cx - s * 0.5, cy - s * 1.1), (cx + s * 0.55, cy + s * 0.95),
              (cx + s * 0.25, cy + s * 1.2), (cx - s * 0.8, cy - s * 0.7)], color)
    _poly(d, [(cx - s * 1.0, cy + s * 0.35), (cx - s * 0.25, cy + s * 1.0),
              (cx - s * 0.45, cy + s * 1.15), (cx - s * 1.15, cy + s * 0.55)], color)


@icon("shield")
def _shield(d, cx, cy, s, color):
    d.rounded_rectangle([cx - s * 0.85, cy - s * 1.1, cx + s * 0.85, cy + s * 0.6],
                        radius=int(s * 0.3), fill=color)
    _poly(d, [(cx - s * 0.85, cy - s * 0.2), (cx + s * 0.85, cy - s * 0.2),
              (cx, cy + s * 1.1)], color)


@icon("cross")
def _cross(d, cx, cy, s, color):
    d.rounded_rectangle([cx - s * 0.35, cy - s * 1.15, cx + s * 0.35, cy + s * 1.15],
                        radius=int(s * 0.15), fill=color)
    d.rounded_rectangle([cx - s * 1.15, cy - s * 0.35, cx + s * 1.15, cy + s * 0.35],
                        radius=int(s * 0.15), fill=color)


@icon("bolt")
def _bolt(d, cx, cy, s, color):
    _poly(d, [(cx + s * 0.15, cy - s * 1.15), (cx - s * 0.7, cy + s * 0.25),
              (cx - s * 0.05, cy + s * 0.25), (cx - s * 0.15, cy + s * 1.15),
              (cx + s * 0.7, cy - s * 0.25), (cx + s * 0.05, cy - s * 0.25)], color)


@icon("rust")
def _rust(d, cx, cy, s, color):
    # 锈斑：几块重叠的不规则多边形
    for dx, dy, r, rot in [(-0.35, -0.2, 0.55, 0), (0.3, -0.15, 0.5, 1), (0.0, 0.35, 0.6, 2),
                           (-0.15, 0.0, 0.35, 3)]:
        pts = []
        n = 7
        for i in range(n):
            a = rot * 1.7 + i * 2 * math.pi / n
            rr = r * (0.75 + 0.35 * math.sin(i * 2.3 + dx * 7))
            pts.append((cx + dx * s * 1.4 + math.cos(a) * rr * s,
                        cy + dy * s * 1.4 + math.sin(a) * rr * s))
        _poly(d, pts, color)


@icon("vine")
def _vine(d, cx, cy, s, color):
    # 藤蔓：S 形曲线 + 叶片
    pts = []
    for i in range(24):
        t = i / 23
        x = cx + (t - 0.5) * s * 1.6
        y = cy + (t - 0.5) * s * 2.2
        x += math.sin(t * 6) * s * 0.25
        pts.append((x, y))
    d.line(pts, fill=color, width=max(3, int(s * 0.16)))
    for lx, ly, flip in [(-0.45, -0.4, 1), (0.45, 0.1, -1), (-0.3, 0.5, 1)]:
        _poly(d, [(cx + lx * s, cy + ly * s),
                  (cx + (lx + 0.25 * flip) * s, cy + (ly - 0.15) * s),
                  (cx + (lx + 0.1 * flip) * s, cy + (ly + 0.2) * s)], color)


@icon("glyph")
def _glyph(d, cx, cy, s, color):
    d.ellipse([cx - s, cy - s, cx + s, cy + s], outline=color, width=max(2, int(s * 0.13)))
    d.ellipse([cx - s * 0.55, cy - s * 0.55, cx + s * 0.55, cy + s * 0.55],
              outline=color, width=max(2, int(s * 0.11)))
    d.ellipse([cx - s * 0.13, cy - s * 0.13, cx + s * 0.13, cy + s * 0.13], fill=color)


@icon("root")
def _root(d, cx, cy, s, color):
    d.line([(cx, cy - s * 1.1), (cx, cy + s * 0.2)], fill=color, width=max(3, int(s * 0.16)))
    for i, (dx, ln) in enumerate([(-0.55, 0.55), (0.6, 0.5), (-0.2, 0.75), (0.35, 0.7)]):
        x0 = cx + dx * s * 0.3
        y0 = cy + s * 0.25
        x1 = cx + dx * s
        y1 = cy + s * 0.25 + ln * s
        d.line([(x0, y0), (x1, y1)], fill=color, width=max(3, int(s * 0.13)))
        d.line([(x1, y1), (x1 + 0.18 * s * (1 if dx >= 0 else -1), y1 - 0.12 * s)],
               fill=color, width=max(2, int(s * 0.1)))


@icon("echo")
def _echo(d, cx, cy, s, color):
    for i, r in enumerate([0.3, 0.55, 0.8, 1.05]):
        d.arc([cx - r * s, cy - r * s, cx + r * s, cy + r * s],
              start=210 + i * 40, end=330 + i * 40, fill=color, width=max(2, int(s * 0.12)))


@icon("card")
def _card(d, cx, cy, s, color):
    d.rounded_rectangle([cx - s * 0.75, cy - s * 1.0, cx + s * 0.75, cy + s * 1.0],
                        radius=int(s * 0.12), fill=color)
    d.rounded_rectangle([cx - s * 0.45, cy - s * 0.6, cx + s * 0.45, cy - s * 0.25],
                        radius=int(s * 0.06), fill=(0, 0, 0, 120))
    d.rounded_rectangle([cx - s * 0.45, cy + 0.0 * s, cx + s * 0.45, cy + s * 0.35],
                        radius=int(s * 0.06), fill=(0, 0, 0, 120))
    d.rounded_rectangle([cx - s * 0.45, cy + 0.55 * s, cx + s * 0.45, cy + s * 0.85],
                        radius=int(s * 0.06), fill=(0, 0, 0, 120))


@icon("bomb")
def _bomb(d, cx, cy, s, color):
    d.ellipse([cx - s * 0.85, cy - s * 0.7, cx + s * 0.85, cy + s * 1.0], fill=color)
    d.line([(cx, cy - s * 0.75), (cx + s * 0.35, cy - s * 1.15)], fill=color,
           width=max(3, int(s * 0.16)))
    d.ellipse([cx + s * 0.25, cy - s * 1.3, cx + s * 0.55, cy - s * 1.0], fill=color)


@icon("dice")
def _dice(d, cx, cy, s, color):
    d.rounded_rectangle([cx - s, cy - s, cx + s, cy + s], radius=int(s * 0.2), fill=color)
    r = s * 0.12
    for dx, dy in [(-0.4, -0.4), (0.4, -0.4), (0, 0), (-0.4, 0.4), (0.4, 0.4)]:
        d.ellipse([cx + dx * s - r, cy + dy * s - r, cx + dx * s + r, cy + dy * s + r],
                  fill=(0, 0, 0, 140))


@icon("star4")
def _star4(d, cx, cy, s, color):
    _poly(d, [(cx, cy - s), (cx + s * 0.22, cy - s * 0.22), (cx + s, cy),
              (cx + s * 0.22, cy + s * 0.22), (cx, cy + s), (cx - s * 0.22, cy + s * 0.22),
              (cx - s, cy), (cx - s * 0.22, cy - s * 0.22)], color)


@icon("starburst")
def _starburst(d, cx, cy, s, color):
    pts = []
    for i in range(16):
        a = i * math.pi / 8
        rr = s * (1.0 if i % 2 == 0 else 0.45)
        pts.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr))
    _poly(d, pts, color)


@icon("ring")
def _ring(d, cx, cy, s, color):
    for r in [0.95, 0.6]:
        d.ellipse([cx - r * s, cy - r * s, cx + r * s, cy + r * s],
                  outline=color, width=max(3, int(s * 0.14)))
    d.ellipse([cx - s * 0.15, cy - s * 0.15, cx + s * 0.15, cy + s * 0.15], fill=color)


@icon("emw")
def _emw(d, cx, cy, s, color):
    for i, r in enumerate([0.3, 0.6, 0.95]):
        d.arc([cx - r * s, cy - r * s, cx + r * s, cy + r * s], 200, 340,
              fill=color, width=max(2, int(s * 0.12)))
    d.line([(cx - s, cy), (cx + s, cy)], fill=color, width=max(2, int(s * 0.1)))


@icon("chain")
def _chain(d, cx, cy, s, color):
    for dx, dy, r in [(-0.45, -0.35, 0.32), (0.45, 0.35, 0.32), (0.0, -0.35, 0.32), (0.0, 0.35, 0.32)]:
        d.ellipse([cx + (dx - r) * s * 1.6, cy + (dy - r) * s * 1.6,
                   cx + (dx + r) * s * 1.6, cy + (dy + r) * s * 1.6],
                  outline=color, width=max(3, int(s * 0.15)))


@icon("recycle")
def _recycle(d, cx, cy, s, color):
    # 三角循环箭头
    for rot, a0 in [(0, -90), (120, 30), (240, 150)]:
        pts = []
        for i in range(10):
            a = math.radians(a0 + i * 9)
            pts.append((cx + math.cos(a) * s * 0.95, cy + math.sin(a) * s * 0.95))
        d.line(pts, fill=color, width=max(3, int(s * 0.14)))
    _poly(d, [(cx, cy - s * 0.95), (cx - s * 0.28, cy - s * 0.5), (cx + s * 0.28, cy - s * 0.5)], color)


@icon("sacrifice")
def _sacrifice(d, cx, cy, s, color):
    pts1 = [(cx + math.cos(math.radians(90 + i * 60)) * s, cy + math.sin(math.radians(90 + i * 60)) * s)
            for i in range(3)]
    pts2 = [(cx + math.cos(math.radians(-30 + i * 60)) * s, cy + math.sin(math.radians(-30 + i * 60)) * s)
            for i in range(3)]
    _poly(d, pts1, color)
    _poly(d, pts2, color)


@icon("sprout")
def _sprout(d, cx, cy, s, color):
    d.line([(cx, cy + s), (cx, cy - s * 0.3)], fill=color, width=max(3, int(s * 0.16)))
    for lx, flip in [(-0.55, 1), (0.55, -1)]:
        _poly(d, [(cx + lx * s * 0.1, cy - s * 0.3),
                  (cx + (lx + 0.5 * flip) * s, cy - s * 0.75),
                  (cx + (lx + 0.15 * flip) * s, cy - s * 0.1)], color)


@icon("detonator")
def _detonator(d, cx, cy, s, color):
    d.rounded_rectangle([cx - s * 0.55, cy + s * 0.15, cx + s * 0.55, cy + s],
                        radius=int(s * 0.2), fill=color)
    d.ellipse([cx - s * 0.3, cy - s * 0.5, cx + s * 0.3, cy + s * 0.15], fill=color)
    for dx, dy in [(-0.4, -0.7), (0.0, -1.0), (0.4, -0.65)]:
        for rr in [0.07, 0.11]:
            d.ellipse([cx + dx * s - rr * s, cy + dy * s - rr * s,
                       cx + dx * s + rr * s, cy + dy * s + rr * s], fill=color)


@icon("hack")
def _hack(d, cx, cy, s, color):
    _shield(d, cx, cy, s, color)
    d.line([(cx - s * 0.5, cy - s * 0.2), (cx + s * 0.5, cy + s * 0.5)], fill=(0, 0, 0, 150),
           width=max(3, int(s * 0.14)))
    d.line([(cx + s * 0.5, cy - s * 0.2), (cx - s * 0.5, cy + s * 0.5)], fill=(0, 0, 0, 150),
           width=max(3, int(s * 0.14)))


@icon("move")
def _move(d, cx, cy, s, color):
    d.arc([cx - s, cy - s, cx + s, cy + s], 20, 250, fill=color, width=max(3, int(s * 0.15)))
    _poly(d, [(cx + s * 0.95, cy - s * 0.35), (cx + s * 0.35, cy - s * 0.9),
              (cx + s * 1.25, cy - s * 0.9)], color)


@icon("spike")
def _spike(d, cx, cy, s, color):
    for dx in [-0.6, 0.0, 0.6]:
        _poly(d, [(cx + dx * s - s * 0.18, cy + s * 0.9), (cx + dx * s, cy - s * 0.9),
                  (cx + dx * s + s * 0.18, cy + s * 0.9)], color)


@icon("drop")
def _drop(d, cx, cy, s, color):
    pts = []
    for i in range(20):
        a = -math.pi / 2 + (i / 19) * 2 * math.pi
        r = s * (0.55 if a < -math.pi / 2 or a > math.pi / 2 else 0.9)
        pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r * 0.9 + s * 0.3))
    _poly(d, pts, color)


@icon("coin")
def _coin(d, cx, cy, s, color):
    d.ellipse([cx - s, cy - s, cx + s, cy + s], outline=color, width=max(3, int(s * 0.14)))
    d.ellipse([cx - s * 0.6, cy - s * 0.6, cx + s * 0.6, cy + s * 0.6],
              outline=color, width=max(2, int(s * 0.1)))


@icon("gear")
def _gear(d, cx, cy, s, color):
    pts = []
    n = 12
    for i in range(n * 2):
        a = i * math.pi / n
        rr = s * (1.0 if i % 2 == 0 else 0.75)
        pts.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr))
    _poly(d, pts, color)
    d.ellipse([cx - s * 0.35, cy - s * 0.35, cx + s * 0.35, cy + s * 0.35], fill=(0, 0, 0, 130))


# ── 生成 ──

def draw_part(icon_name, palette_name, out_path, radius=10, edge_w=4):
    pal = PALETTES[palette_name]
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # 描边层
    d.rounded_rectangle([0, 0, SIZE - 1, SIZE - 1], radius=radius, fill=pal["edge"])
    # 底色层
    d.rounded_rectangle([edge_w, edge_w, SIZE - 1 - edge_w, SIZE - 1 - edge_w],
                        radius=max(radius - edge_w, 2), fill=pal["bg"])
    # 高光：左上斜光（半透明白）
    hl = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    hd = ImageDraw.Draw(hl)
    hd.polygon([(edge_w + 2, edge_w + 2), (SIZE * 0.55, edge_w + 2), (edge_w + 2, SIZE * 0.45)],
               fill=(255, 255, 255, 26))
    img = Image.alpha_composite(img, hl)
    d = ImageDraw.Draw(img)
    # 图标
    if icon_name in ICONS:
        ICONS[icon_name](d, SIZE / 2, SIZE / 2, 30, pal["icon"])
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    img.save(out_path)
    return out_path


def main():
    ap = argparse.ArgumentParser(description="GridAndGroves 程序化部件图生成器")
    ap.add_argument("--icons", nargs="*", default=sorted(ICONS.keys()),
                    help="指定图标（默认全部）")
    ap.add_argument("--palettes", nargs="*", default=sorted(PALETTES.keys()),
                    help="指定配色（默认全部）")
    ap.add_argument("--out", default=OUT_ROOT, help="输出根目录")
    args = ap.parse_args()

    count = 0
    for pal in args.palettes:
        for ic in args.icons:
            if ic not in ICONS:
                print(f"WARN: unknown icon {ic}")
                continue
            path = os.path.join(args.out, pal, f"{ic}.png")
            draw_part(ic, pal, path)
            count += 1
    print(f"generated {count} part images -> {args.out}")


if __name__ == "__main__":
    main()
