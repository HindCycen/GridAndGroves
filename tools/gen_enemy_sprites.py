#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
GridAndGroves 敌人立绘生成器
============================
为敌人批量生成 192×192 的 2 帧 idle 动画立绘（输出 384×192 spritesheet）。

风格约定（与 Player / 部件图统一）：
- 扁平色块 + 深色描边 + 简单五官（几何卡通风）
- 4× 超采样绘制后 LANCZOS 缩放，保证边缘干净
- 帧 0 = 基准姿态；帧 1 = 整体上移 3px 的呼吸 + 眨眼
- 透明背景；确定性输出（同一脚本始终产出同一图片）

用法：
    python tools/gen_enemy_sprites.py                 # 生成全部敌人
    python tools/gen_enemy_sprites.py --names Gonh    # 只生成指定敌人
    python tools/gen_enemy_sprites.py --preview       # 额外生成预览拼图（工具目录）
"""
import argparse
import math
import os
import sys

from PIL import Image, ImageDraw

SIZE = 192            # 单帧尺寸（像素）
SS = 4                # 超采样倍数
OUT_W = 5             # 描边宽度（192 空间）
OUTLINE = (26, 22, 30, 255)
OUT_DIR = os.path.join("resources", "enemy_images")


def _b(x0, y0, x1, y1):
    return [x0 * SS, y0 * SS, x1 * SS, y1 * SS]


def rr(d, box, radius, fill, outline=OUTLINE, width=OUT_W):
    d.rounded_rectangle(_b(*box), radius=radius * SS, fill=fill, outline=outline, width=width * SS)


def el(d, box, fill, outline=OUTLINE, width=OUT_W):
    d.ellipse(_b(*box), fill=fill, outline=outline, width=width * SS)


def pg(d, pts, fill, outline=OUTLINE, width=OUT_W):
    d.polygon([(x * SS, y * SS) for x, y in pts], fill=fill, outline=outline, width=width * SS)


def ln(d, pts, fill, width):
    d.line([(x * SS, y * SS) for x, y in pts], fill=fill, width=width * SS)


def dot(d, cx, cy, r, fill):
    d.ellipse(_b(cx - r, cy - r, cx + r, cy + r), fill=fill)


# ──────────────────────────── 敌人绘制 ────────────────────────────
# 每个函数签名 (d, dy, blink)：
#   d     ImageDraw（768×768 超采样画布）
#   dy    呼吸偏移（单位 192 空间，帧 1 为 -3）
#   blink 是否闭眼


def _eyes_open(d, cx, cy, r, fill=(255, 255, 255, 255), pupil=(30, 30, 40, 255)):
    dot(d, cx, cy, r, fill)
    dot(d, cx + r * 0.15, cy, r * 0.45, pupil)


def _eyes_closed(d, cx, cy, r, color=(30, 30, 40, 255)):
    ln(d, [(cx - r, cy), (cx + r, cy)], color, 3)


def draw_gonh(d, dy, blink):
    """球形侦察机：天线 + 大圆身 + 面罩。青蓝色。"""
    body = (90, 190, 240, 255)
    shade = (52, 122, 172, 255)
    accent = (255, 255, 255, 255)
    # 天线
    ln(d, [(96, 40 + dy), (96, 62 + dy)], OUTLINE, 6)
    dot(d, 96, 36 + dy, 9, shade)
    # 脚（固定在地面，不随呼吸动）
    rr(d, (56, 146, 84, 164), 8, body)
    rr(d, (108, 146, 136, 164), 8, body)
    # 身体
    el(d, (34, 48 + dy, 158, 160 + dy), body)
    # 面罩
    rr(d, (56, 88 + dy, 136, 122 + dy), 12, shade)
    # 眼睛
    if blink:
        _eyes_closed(d, 80, 105 + dy, 7)
        _eyes_closed(d, 112, 105 + dy, 7)
    else:
        _eyes_open(d, 80, 105 + dy, 10)
        _eyes_open(d, 112, 105 + dy, 10)
    # 胸口装饰灯
    dot(d, 96, 140 + dy, 7, accent)


def draw_rusthound(d, dy, blink):
    """四足锈蚀猎犬：朝左（面向玩家）。铜棕色。"""
    body = (176, 104, 62, 255)
    shade = (120, 64, 34, 255)
    rust = (88, 44, 22, 255)
    eye = (255, 210, 90, 255)
    # 尾巴（身后 = 右）
    pg(d, [(150, 96 + dy), (178, 66 + dy), (172, 62 + dy), (146, 86 + dy)], shade)
    # 后腿 / 前腿（固定地面）
    rr(d, (116, 126, 142, 158), 8, shade)
    rr(d, (44, 126, 70, 158), 8, shade)
    rr(d, (126, 138, 148, 166), 7, shade)
    rr(d, (56, 138, 78, 166), 7, shade)
    # 身体
    rr(d, (46, 78 + dy, 154, 138 + dy), 26, body)
    # 锈斑
    dot(d, 92, 108 + dy, 11, rust)
    dot(d, 122, 96 + dy, 8, rust)
    # 头（左前方）
    rr(d, (30, 52 + dy, 92, 106 + dy), 20, body)
    # 耳朵
    pg(d, [(40, 56 + dy), (50, 24 + dy), (64, 54 + dy)], shade)
    # 吻部
    rr(d, (18, 76 + dy, 48, 100 + dy), 10, shade)
    dot(d, 24, 88 + dy, 5, OUTLINE)
    # 眼睛
    if blink:
        _eyes_closed(d, 68, 78 + dy, 6, (60, 34, 16, 255))
    else:
        dot(d, 68, 78 + dy, 9, (255, 255, 255, 255))
        dot(d, 66, 78 + dy, 5, eye)
    # 项圈
    ln(d, [(56, 62 + dy), (58, 100 + dy)], rust, 6)


def draw_sporecrawler(d, dy, blink):
    """低矮孢子爬虫：椭圆身体 + 小短腿 + 背上孢子。苔绿色。"""
    body = (114, 152, 74, 255)
    shade = (72, 102, 44, 255)
    spore = (168, 118, 208, 255)
    # 腿（两侧各三组）
    for lx in (46, 82, 118, 148):
        ln(d, [(lx, 138), (lx - 6, 156)], shade, 7)
    # 身体
    el(d, (26, 92 + dy, 166, 156 + dy), body)
    # 头（左前）
    el(d, (16, 96 + dy, 70, 146 + dy), shade)
    # 眼睛
    if blink:
        _eyes_closed(d, 34, 116 + dy, 6, (30, 40, 20, 255))
    else:
        dot(d, 34, 116 + dy, 9, (255, 255, 255, 255))
        dot(d, 32, 116 + dy, 4, (30, 40, 20, 255))
    # 背上孢子
    dot(d, 78, 96 + dy, 12, spore)
    dot(d, 108, 90 + dy, 9, spore)
    dot(d, 134, 100 + dy, 11, spore)
    # 孢子茎
    ln(d, [(78, 96 + dy), (78, 86 + dy)], shade, 4)
    ln(d, [(108, 90 + dy), (108, 80 + dy)], shade, 4)
    ln(d, [(134, 100 + dy), (134, 90 + dy)], shade, 4)


def draw_rustcolossus(d, dy, blink):
    """锈蚀巨像（精英）：方形身体 + 双臂 + 裂纹。铁灰 + 锈斑。"""
    body = (128, 122, 118, 255)
    shade = (86, 80, 78, 255)
    rust = (166, 96, 54, 255)
    eye = (255, 120, 90, 255)
    # 腿
    rr(d, (50, 132, 82, 166), 10, shade)
    rr(d, (98, 132, 130, 166), 10, shade)
    # 手臂
    rr(d, (18, 78 + dy, 48, 130 + dy), 12, shade)
    rr(d, (144, 78 + dy, 174, 130 + dy), 12, shade)
    dot(d, 33, 134 + dy, 13, body)
    dot(d, 159, 134 + dy, 13, body)
    # 躯干
    rr(d, (40, 62 + dy, 152, 146 + dy), 22, body)
    # 锈斑与裂纹
    dot(d, 70, 120 + dy, 12, rust)
    dot(d, 122, 88 + dy, 10, rust)
    ln(d, [(96, 70 + dy), (88, 96 + dy), (102, 114 + dy)], shade, 5)
    # 头
    rr(d, (66, 20 + dy, 126, 68 + dy), 16, shade)
    # 单眼横条
    rr(d, (74, 36 + dy, 118, 50 + dy), 7, (40, 34, 34, 255))
    if blink:
        ln(d, [(82, 43 + dy), (110, 43 + dy)], eye, 4)
    else:
        dot(d, 88, 43 + dy, 6, eye)
        dot(d, 104, 43 + dy, 6, eye)


def draw_ironwarden(d, dy, blink):
    """铁卫（Boss）：高楼式机械体 + 肩甲 + 核心。钢蓝色。"""
    body = (96, 118, 158, 255)
    shade = (58, 74, 106, 255)
    core = (120, 224, 236, 255)
    trim = (206, 214, 224, 255)
    # 腿
    rr(d, (54, 128, 86, 166), 12, shade)
    rr(d, (92, 128, 124, 166), 12, shade)
    # 躯干
    rr(d, (58, 66 + dy, 134, 148 + dy), 18, body)
    # 肩甲
    el(d, (24, 58 + dy, 72, 110 + dy), body)
    el(d, (120, 58 + dy, 168, 110 + dy), body)
    # 核心
    dot(d, 96, 104 + dy, 16, (36, 44, 60, 255))
    dot(d, 96, 104 + dy, 10, core)
    # 头
    rr(d, (72, 18 + dy, 120, 62 + dy), 12, shade)
    rr(d, (78, 30 + dy, 114, 46 + dy), 6, (30, 36, 50, 255))
    if blink:
        ln(d, [(84, 38 + dy), (108, 38 + dy)], core, 4)
    else:
        dot(d, 88, 38 + dy, 5, core)
        dot(d, 104, 38 + dy, 5, core)
    # 天线
    ln(d, [(96, 18 + dy), (96, 4 + dy)], trim, 4)
    dot(d, 96, 3 + dy, 5, core)


def draw_bloommother(d, dy, blink):
    """绽放之母（Boss）：花冠 + 藤蔓身体。翠绿 + 粉瓣。"""
    body = (96, 148, 84, 255)
    shade = (62, 100, 54, 255)
    petal = (226, 132, 172, 255)
    petal_dark = (186, 92, 138, 255)
    # 花瓣（头后一圈）
    for i in range(8):
        a = math.radians(i * 45 + 22)
        px = 96 + math.cos(a) * 46
        py = 62 + math.sin(a) * 46 + dy
        el(d, (px - 20, py - 26, px + 20, py + 26), petal_dark if i % 2 else petal)
    # 藤蔓手臂
    for side, flip in ((-1, 1), (1, -1)):
        base_x = 96 + side * 34
        pg(d, [(base_x, 118 + dy), (base_x + side * 34, 96 + dy), (base_x + side * 44, 112 + dy),
               (base_x + side * 16, 136 + dy)], shade)
    # 身体（茎）
    rr(d, (76, 104 + dy, 116, 156 + dy), 16, body)
    # 头
    el(d, (58, 26 + dy, 134, 102 + dy), body)
    # 眼睛 / 嘴
    if blink:
        _eyes_closed(d, 80, 62 + dy, 6, (30, 46, 26, 255))
        _eyes_closed(d, 112, 62 + dy, 6, (30, 46, 26, 255))
    else:
        dot(d, 80, 62 + dy, 9, (255, 255, 255, 255))
        dot(d, 112, 62 + dy, 9, (255, 255, 255, 255))
        dot(d, 78, 62 + dy, 4, (30, 46, 26, 255))
        dot(d, 110, 62 + dy, 4, (30, 46, 26, 255))
    ln(d, [(86, 82 + dy), (96, 88 + dy), (106, 82 + dy)], (30, 46, 26, 255), 3)
    # 根部叶
    el(d, (46, 138 + dy, 88, 162 + dy), shade)
    el(d, (104, 138 + dy, 146, 162 + dy), shade)


ENEMIES = {
    "Gonh": draw_gonh,
    "RustHound": draw_rusthound,
    "SporeCrawler": draw_sporecrawler,
    "RustColossus": draw_rustcolossus,
    "IronWarden": draw_ironwarden,
    "BloomMother": draw_bloommother,
}


def render_frame(kind: str, frame: int) -> Image.Image:
    """渲染单帧（192×192，透明背景）。frame 0 = 基准，frame 1 = 呼吸 + 眨眼。"""
    big = Image.new("RGBA", (SIZE * SS, SIZE * SS), (0, 0, 0, 0))
    d = ImageDraw.Draw(big)
    dy = 0 if frame == 0 else -3
    blink = frame == 1
    ENEMIES[kind](d, dy, blink)
    return big.resize((SIZE, SIZE), Image.LANCZOS)


def render_sheet(kind: str) -> Image.Image:
    """渲染 2 帧 spritesheet（384×192）。"""
    sheet = Image.new("RGBA", (SIZE * 2, SIZE), (0, 0, 0, 0))
    sheet.paste(render_frame(kind, 0), (0, 0))
    sheet.paste(render_frame(kind, 1), (SIZE, 0))
    return sheet


def make_preview(names, out_path):
    """生成预览拼图：上排帧 0，下排帧 1，用于人工复核。"""
    cols = len(names)
    pad = 8
    cell = SIZE
    img = Image.new("RGBA", (cols * (cell + pad) + pad, 2 * (cell + pad) + pad), (40, 44, 52, 255))
    for i, name in enumerate(names):
        for f in range(2):
            frame = render_frame(name, f)
            img.alpha_composite(frame, (pad + i * (cell + pad), pad + f * (cell + pad)))
    img.save(out_path)
    return out_path


def main():
    ap = argparse.ArgumentParser(description="GridAndGroves 敌人立绘生成器")
    ap.add_argument("--names", nargs="*", default=sorted(ENEMIES.keys()),
                    help="指定敌人名（默认全部）")
    ap.add_argument("--out", default=OUT_DIR, help="输出目录")
    ap.add_argument("--preview", action="store_true", help="额外生成预览拼图")
    args = ap.parse_args()

    os.makedirs(args.out, exist_ok=True)
    made = []
    for name in args.names:
        if name not in ENEMIES:
            print(f"WARN: unknown enemy {name}")
            continue
        path = os.path.join(args.out, f"{name}.png")
        render_sheet(name).save(path)
        made.append(name)
        print("wrote", path)
    if args.preview and made:
        preview_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "enemy_preview.png")
        make_preview(made, preview_path)
        print("preview ->", preview_path)
    print(f"generated {len(made)} enemy sprite sheet(s) -> {args.out}")


if __name__ == "__main__":
    main()
