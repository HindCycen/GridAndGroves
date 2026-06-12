#!/usr/bin/env python3
"""
GridAndGroves 像素画生成器 — CLI 入口
=======================================
用法:
  # 生成 Block Part 贴图
  python generate.py block "Strike" --desc "a basic sword strike attack"

  # 生成 Stat 图标
  python generate.py stat "Strength" --desc "flexed arm muscle"

  # 生成敌人贴图
  python generate.py enemy "Goblin" --desc "small green goblin"

  # 生成动画精灵表
  python generate.py spritesheet "player" --desc "blue hero" --frames 8 --anim idle

  # 生成 Bot 巡逻精灵表
  python generate.py spritesheet "bot" --desc "patrol robot" --frames 16 --anim patrol

  # 批量处理 .gg 文件
  python generate.py batch --file ../path/to/blocks.gg

  # 查看支持的调色板
  python generate.py palettes

首次运行会自动下载模型（~6GB），请保持网络畅通。
模型会缓存到 tools/models/ 目录。
"""

import argparse
import logging
import os
import sys
import re
from pathlib import Path

# 确保 tools 在模块搜索路径中
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from config import (
    SPECS, PALETTES, OUTPUT_DIRS, PROJECT_ROOT, PIXEL_SCALE,
    MODEL_CACHE_DIR, SPRITESHEET_FRAME_SIZE,
)
from engine import PixelModel, generate_pixel_art, generate_spritesheet, save_image, ensure_output_dir
from prompts import (
    build_block_part_prompt, build_stat_icon_prompt,
    build_enemy_prompt, build_animation_frames,
    build_block_part_prompt,
    NEGATIVE_PROMPT as DEFAULT_NEGATIVE,
)

logging.basicConfig(
    level=logging.INFO,
    format="[%(name)s] %(levelname)s %(message)s",
    handlers=[logging.StreamHandler()],
)
logger = logging.getLogger("gg-cli")


# ═══════════════════════════════════════════════════════════════
# Model 全局单例（延迟加载）
# ═══════════════════════════════════════════════════════════════

_engine: PixelModel | None = None


def get_engine() -> PixelModel:
    global _engine
    if _engine is None:
        _engine = PixelModel()
        ok = _engine.load()
        if not ok:
            logger.error("模型加载失败！无法继续。")
            sys.exit(1)
    return _engine


# ═══════════════════════════════════════════════════════════════
# CLI 子命令
# ═══════════════════════════════════════════════════════════════

def cmd_block(args):
    """生成 Block Part 贴图（96×96）"""
    engine = get_engine()
    spec = SPECS["block_part"]
    block_name = args.name
    description = args.desc or block_name

    prompt, palette_name, tags = build_block_part_prompt(block_name, description)
    palette = PALETTES[palette_name]
    seed = args.seed

    logger.info(f"方块: {block_name}")
    logger.info(f"描述: {description}")
    logger.info(f"调色板: {palette_name} ({palette.name})")
    logger.info(f"Prompt: {prompt}")

    # 生成主图
    img = generate_pixel_art(
        engine=engine,
        prompt=prompt,
        palette_colors=palette.colors,
        native_size=spec.native,
        final_size=spec.final,
        negative_prompt=DEFAULT_NEGATIVE,
        num_inference_steps=args.steps,
        seed=seed,
    )

    # 确定输出路径
    color_dir = palette.tags[0] if palette.tags else "generated"
    out_dir = ensure_output_dir("block_part")
    if args.output:
        out_dir = args.output

    filename = f"{block_name}.png"
    filepath = os.path.join(out_dir, filename)
    save_image(img, filepath)

    logger.info(f"✅ Block Part 已生成: {filepath}")


def cmd_stat(args):
    """生成 Stat 图标（45×45）"""
    engine = get_engine()
    spec = SPECS["stat_icon"]
    stat_name = args.name
    description = args.desc or stat_name

    prompt, palette_name = build_stat_icon_prompt(stat_name, description)
    palette = PALETTES[palette_name]

    logger.info(f"Stat: {stat_name}")
    logger.info(f"调色板: {palette_name} ({palette.name})")

    img = generate_pixel_art(
        engine=engine,
        prompt=prompt,
        palette_colors=palette.colors,
        native_size=spec.native,
        final_size=spec.final,
        negative_prompt=DEFAULT_NEGATIVE,
        num_inference_steps=args.steps,
        seed=args.seed,
    )

    out_dir = ensure_output_dir("stat_icon")
    if args.output:
        out_dir = args.output

    filename = f"{stat_name}.png"
    filepath = os.path.join(out_dir, filename)
    save_image(img, filepath)
    logger.info(f"✅ Stat Icon 已生成: {filepath}")


def cmd_enemy(args):
    """生成敌人贴图（192×192）"""
    engine = get_engine()
    spec = SPECS["enemy"]
    enemy_name = args.name
    description = args.desc or enemy_name

    prompt, palette_name = build_enemy_prompt(enemy_name, description)
    palette = PALETTES[palette_name]

    logger.info(f"敌人: {enemy_name}")
    logger.info(f"调色板: {palette_name} ({palette.name})")
    logger.info(f"Prompt: {prompt}")

    img = generate_pixel_art(
        engine=engine,
        prompt=prompt,
        palette_colors=palette.colors,
        native_size=spec.native,
        final_size=spec.final,
        negative_prompt=DEFAULT_NEGATIVE,
        num_inference_steps=args.steps,
        seed=args.seed,
    )

    out_dir = ensure_output_dir("enemy")
    if args.output:
        out_dir = args.output

    filename = f"{enemy_name}.png"
    filepath = os.path.join(out_dir, filename)
    save_image(img, filepath)
    logger.info(f"✅ Enemy 已生成: {filepath}")


def cmd_spritesheet(args):
    """
    生成动画精灵表。
    支持 player / bot / enemy 三种类型的多帧动画。
    """
    engine = get_engine()
    sheet_type = args.type
    description = args.desc or sheet_type
    num_frames = args.frames
    anim_type = args.anim

    # 确定每帧尺寸
    if sheet_type == "player":
        spec = SPECS["player_frame"]
        native = spec.native
        frame_size = spec.final
        cols = 8
    elif sheet_type == "bot":
        spec = SPECS["bot_frame"]
        native = spec.native
        frame_size = spec.final
        cols = 8
    else:
        # 自定义
        native = args.native or 64
        frame_size = native * PIXEL_SCALE
        cols = args.cols or 8

    # 确定调色板
    if sheet_type == "player":
        palette = PALETTES["player_cyan"]
    elif sheet_type == "bot":
        palette = PALETTES["bot_green"]
    else:
        palette_name = "enemy_grey"
        palette = PALETTES[palette_name]

    PIXEL_STYLE = (
        "pixel art, game sprite, hard pixel edges, no anti-aliasing, "
        "flat colors, clear silhouette, centered"
    )

    # 生成帧描述
    frame_prompts = build_animation_frames(
        base_description=description,
        num_frames=num_frames,
        anim_type=anim_type,
    )

    full_prompts = [
        f"pixel art {native}x{native} game character, {fp}, "
        f"colors: {', '.join(palette.tags)}, "
        f"{PIXEL_STYLE}"
        for fp in frame_prompts
    ]

    logger.info(f"精灵表: {sheet_type}, {num_frames}帧, {anim_type}动画")
    logger.info(f"帧尺寸: {frame_size}×{frame_size}, 每帧原始: {native}×{native}")

    sheet = generate_spritesheet(
        engine=engine,
        prompts=full_prompts,
        palette_colors=palette.colors,
        native_size=native,
        final_frame_size=frame_size,
        cols=cols,
        negative_prompt=DEFAULT_NEGATIVE,
        inference_steps=args.steps,
        seed=args.seed,
    )

    # 输出路径：SpriteSheet 放到对应目录
    out_dir = ensure_output_dir(sheet_type + "_frame")
    if args.output:
        out_dir = args.output

    total_width = min(num_frames, cols) * frame_size
    total_height = ((num_frames + cols - 1) // cols) * frame_size
    filename = f"{sheet_type.capitalize()}Spritesheet.png"
    filepath = os.path.join(out_dir, filename)
    save_image(sheet, filepath)
    logger.info(f"✅ SpriteSheet 已生成: {filepath}")
    logger.info(f"   布局: {min(num_frames, cols)} 列 × {((num_frames + cols - 1) // cols)} 行")
    logger.info(f"   尺寸: {total_width}×{total_height}")


def cmd_palettes(_args):
    """列出所有可用的调色板"""
    print(f"\n{'=' * 60}")
    print(f"GridAndGroves 像素画调色板 ({len(PALETTES)} 个)")
    print(f"{'=' * 60}")
    for name, pal in PALETTES.items():
        color_blocks = "".join(
            f"\033[48;2;{r};{g};{b}m  \033[0m"
            for r, g, b in pal.colors
        )
        print(f"\n{name} ({pal.name})")
        print(f"  标签: {', '.join(pal.tags)}")
        print(f"  颜色: {color_blocks}")
        for r, g, b in pal.colors:
            print(f"    rgb({r:3d}, {g:3d}, {b:3d})  #{r:02x}{g:02x}{b:02x}")
    print()


def cmd_batch(args):
    """
    批量处理 .gg 文件。
    解析 DSL 中的 block 定义，自动为每个 block 生成贴图。
    """
    gg_file = args.file
    if not os.path.exists(gg_file):
        logger.error(f"文件不存在: {gg_file}")
        sys.exit(1)

    engine = get_engine()

    with open(gg_file, "r", encoding="utf-8") as f:
        content = f.read()

    # 简单的 .gg 解析器：提取 block 定义
    blocks = parse_gg_blocks(content)

    if not blocks:
        logger.warning(f"未在 {gg_file} 中找到任何 block 定义")
        return

    logger.info(f"从 {gg_file} 中找到 {len(blocks)} 个 block 定义")

    for block_name, block_body in blocks:
        # 从 block body 中提取描述性内容
        desc = extract_description(block_name, block_body)
        logger.info(f"生成: {block_name} ({desc})")

        prompt, palette_name, tags = build_block_part_prompt(block_name, desc)
        palette = PALETTES[palette_name]
        spec = SPECS["block_part"]

        img = generate_pixel_art(
            engine=engine,
            prompt=prompt,
            palette_colors=palette.colors,
            native_size=spec.native,
            final_size=spec.final,
            negative_prompt=DEFAULT_NEGATIVE,
            num_inference_steps=args.steps,
            seed=args.seed,
        )

        out_dir = ensure_output_dir("block_part")
        if args.output:
            out_dir = args.output
        filename = f"{block_name}.png"
        filepath = os.path.join(out_dir, filename)
        save_image(img, filepath)

    logger.info(f"✅ 批量处理完成！{len(blocks)} 个 block 已生成")


def parse_gg_blocks(content: str) -> list[tuple[str, str]]:
    """解析 .gg 文件中的 block 定义，返回 [(名字, body), ...]"""
    blocks = []
    # 匹配 "block Name" 开头的段落
    lines = content.split("\n")
    current_name = None
    current_lines = []
    in_block = False

    for line in lines:
        stripped = line.strip()
        if stripped.startswith("block "):
            if in_block and current_name:
                blocks.append((current_name, "\n".join(current_lines)))
            current_name = stripped[6:].strip()
            current_lines = []
            in_block = True
        elif in_block:
            if stripped.startswith("block ") or stripped.startswith("stat ") or stripped.startswith("bag ") or stripped.startswith("bigbag "):
                if current_name:
                    blocks.append((current_name, "\n".join(current_lines)))
                current_name = None
                current_lines = []
                in_block = False
            else:
                current_lines.append(line)

    if in_block and current_name:
        blocks.append((current_name, "\n".join(current_lines)))

    return blocks


def extract_description(block_name: str, block_body: str) -> str:
    """
    从 block body 中提取描述性信息。
    比如如果有 "damage D -> all enemy" 则包含 "attack damage"，如果有图标路径则包含形状信息。
    """
    desc = block_name

    # 检查关键词
    if "damage" in block_body.lower():
        desc += " dealing damage attack"
    if "shield" in block_body.lower() or "BS" in block_body:
        desc += " shield defense"
    if "heal" in block_body.lower():
        desc += " healing"
    if "arrow" in block_body.lower() or "dir" in block_body.lower() or "right" in block_body.lower():
        desc += " directional arrow"
    if "grow" in block_body.lower() or "growing" in block_body.lower() or "stat" in block_body.lower():
        desc += " status effect buff"
    if "exhaust" in block_body.lower():
        desc += " consumable"
    if "delete" in block_body.lower():
        desc += " remove permanent"

    return desc


# ═══════════════════════════════════════════════════════════════
# 主入口
# ═══════════════════════════════════════════════════════════════

def main():
    parser = argparse.ArgumentParser(
        description="GridAndGroves 像素画 AI 生成器",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  python generate.py block "Strike" --desc "basic sword attack"
  python generate.py block "Shield" --desc "round shield defense"
  python generate.py stat "Strength" --desc "muscle arm"
  python generate.py enemy "Goblin" --desc "small green goblin"
  python generate.py enemy "Dragon" --desc "red fire breathing dragon"
  python generate.py spritesheet "player" --desc "blue haired hero" --frames 8 --anim idle
  python generate.py spritesheet "bot" --desc "patrol robot" --frames 16 --anim patrol
  python generate.py batch --file ../resources/blocks.gg
  python generate.py palettes
        """,
    )
    parser.add_argument("--seed", type=int, default=None, help="随机种子（可复现）")
    parser.add_argument("--steps", type=int, default=30, help="推理步数（默认 30，越大越精细）")
    parser.add_argument("--output", type=str, default=None, help="输出目录（默认自动放到项目对应目录）")

    sub = parser.add_subparsers(dest="command", required=True)

    # block
    p_block = sub.add_parser("block", help="生成 Block Part 贴图 (96×96)")
    p_block.add_argument("name", help="方块名称（如 Strike, Shield, Bash）")
    p_block.add_argument("--desc", "-d", default="", help="自然语言描述，例如 'a sword strike with fire'")
    p_block.set_defaults(func=cmd_block)

    # stat
    p_stat = sub.add_parser("stat", help="生成 Stat 图标 (45×45)")
    p_stat.add_argument("name", help="状态名称（如 Strength, Vulnerable, Growing）")
    p_stat.add_argument("--desc", "-d", default="", help="自然语言描述")
    p_stat.set_defaults(func=cmd_stat)

    # enemy
    p_enemy = sub.add_parser("enemy", help="生成敌人贴图 (192×192)")
    p_enemy.add_argument("name", help="敌人名称（如 Goblin, Dragon, Skeleton）")
    p_enemy.add_argument("--desc", "-d", default="", help="自然语言描述")
    p_enemy.set_defaults(func=cmd_enemy)

    # spritesheet
    p_sheet = sub.add_parser("spritesheet", help="生成动画精灵表")
    p_sheet.add_argument("type", choices=["player", "bot", "enemy"], help="精灵类型")
    p_sheet.add_argument("--desc", "-d", default="", help="角色描述")
    p_sheet.add_argument("--frames", "-f", type=int, default=8, help="帧数（默认 8）")
    p_sheet.add_argument("--anim", "-a", choices=["idle", "walk", "patrol", "attack"], default="idle", help="动画类型")
    p_sheet.add_argument("--cols", type=int, default=8, help="SpriteSheet 列数")
    p_sheet.add_argument("--native", type=int, default=None, help="自定义原始像素尺寸（enemy 用）")
    p_sheet.set_defaults(func=cmd_spritesheet)

    # batch
    p_batch = sub.add_parser("batch", help="批量处理 .gg 文件")
    p_batch.add_argument("--file", "-f", required=True, help=".gg 文件路径")
    p_batch.set_defaults(func=cmd_batch)

    # palettes
    p_pal = sub.add_parser("palettes", help="列出所有调色板")
    p_pal.set_defaults(func=cmd_palettes)

    # 解析
    parsed = parser.parse_args()
    parsed.func(parsed)


if __name__ == "__main__":
    main()
