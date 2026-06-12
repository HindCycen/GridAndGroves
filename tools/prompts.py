"""
GridAndGroves 像素画生成器 — Prompt 模板
===========================================
根据资产类型和用户描述，自动构建高质量的 AI 生成 Prompt。
包含语义理解：从描述中提取关键词来确定主题、色调和图形。
"""

import re
from typing import Optional

from config import suggest_palette, PALETTES


# ── 风格锁定 ───────────────────────────────────────────────────
# 这些后缀保证输出风格统一为游戏的像素画风
PIXEL_STYLE = (
    "pixel art, hard edges, flat colors, clear silhouette, "
    "retro game asset, center framed"
)

NEGATIVE_PROMPT = (
    "photo, realistic, smooth, gradient, blur, anti-alias, "
    "complex, high detail, 3d, round edges, bevel, drop shadow, "
    "oil painting, watercolor, sketch, line art"
)

# ── 语义关键词 → 图形主题映射 ──────────────────────────────────
# 用于自动丰富描述
VISUAL_THEMES: dict[str, list[str]] = {
    "sword": ["cross", "blade", "sharp", "vertical"],
    "attack": ["cross", "slash", "burst", "angled lines"],
    "strike": ["cross", "star", "impact", "spark"],
    "fire": ["flame", "pointed top", "warm"],
    "shield": ["rounded rectangle", "dome", "solid"],
    "defense": ["square", "wall", "thick border"],
    "protect": ["circle", "ring", "surround"],
    "arrow": ["triangle", "pointing right", "directional"],
    "right": ["arrow", "triangle east", "directional"],
    "move": ["arrow", "chevron", "directional"],
    "grow": ["upward", "chevron up", "plant", "sprout"],
    "heal": ["heart", "cross", "plus"],
    "heart": ["heart shape", "rounded top"],
    "magic": ["star", "sparkle", "diamond"],
    "buff": ["upward arrow", "chevron", "plus"],
    "debuff": ["downward arrow", "broken", "negative"],
    "poison": ["drop", "drip", "skull small"],
    "weak": ["downward", "sagging", "broken line"],
    "enemy": ["menacing", "angular", "dark"],
    "boss": ["large", "crown", "imposing"],
    "nature": ["leaf", "vine", "round organic"],
    "lightning": ["zigzag", "bolt", "sharp angled"],
    "ice": ["crystal", "diamond", "sharp points", "snowflake"],
    "dark": ["skull", "evil eye", "spiked"],
    "robot": ["mechanical", "square", "antenna", "gear"],
    "drone": ["flying", "small wings", "mechanical eye"],
}

# 敌人类型 → 视觉描述映射
ENEMY_THEMES: dict[str, dict] = {
    "goblin": {
        "body": "small humanoid goblin, large ears, hunched",
        "colors": "green skin, dark grey clothes",
        "shape": "short and lean",
    },
    "skeleton": {
        "body": "human skeleton, bony, hollow eyes",
        "colors": "bone white, dark black empty eyes",
        "shape": "tall and thin",
    },
    "slime": {
        "body": "blob slime creature, wobbly",
        "colors": "semi-transparent blue or green",
        "shape": "round blob with two eyes",
    },
    "bat": {
        "body": "flying bat creature, wings spread",
        "colors": "dark purple or brown",
        "shape": "small with wide wings",
    },
    "wolf": {
        "body": "ferocious wolf, four legs, snarling",
        "colors": "grey fur, red eyes",
        "shape": "low to ground, muscular body",
    },
    "orc": {
        "body": "large orc warrior, muscular, tusks",
        "colors": "green-grey skin, dark armor",
        "shape": "bulky and tall, broad shoulders",
    },
    "mage": {
        "body": "cloaked figure, hood, staff",
        "colors": "dark blue or purple robe",
        "shape": "tall, flowing robe, staff in hand",
    },
    "knight": {
        "body": "armored knight, helmet with visor, sword and shield",
        "colors": "silver armor, red or blue accents",
        "shape": "broad, tall, imposing",
    },
    "dragon": {
        "body": "small dragon, wings folded, scales, tail",
        "colors": "red or green scales",
        "shape": "four legs, tail, horns",
    },
    "eye": {
        "body": "floating eyeball monster, iris, veins",
        "colors": "pale white, red veins, dark pupil",
        "shape": "round floating sphere",
    },
    "demon": {
        "body": "horned demon, tail, wings, claws",
        "colors": "dark red or purple",
        "shape": "humanoid with horns and tail",
    },
    "golem": {
        "body": "stone golem, blocky, rocky texture",
        "colors": "grey stone, glowing crystal center",
        "shape": "tall, wide, blocky humanoid",
    },
}


def build_block_part_prompt(block_name: str, description: str) -> tuple[str, str, list[str]]:
    """
    根据方块名称和描述，构建 Prompt 并推荐调色板。
    返回: (prompt, palette_name, tags_for_reference)
    """
    desc_lower = (block_name + " " + description).lower()

    # 提取视觉主题
    visual_elements = []
    for keyword, themes in VISUAL_THEMES.items():
        if keyword in desc_lower:
            visual_elements.extend(themes)

    # 自动选择调色板
    palette_name = suggest_palette(block_name + " " + description)
    palette = PALETTES[palette_name]

    # 构建图形描述
    if visual_elements:
        shape_desc = ", ".join(dict.fromkeys(visual_elements))  # 去重保序
    else:
        shape_desc = "simple geometric symbol"

    prompt = (
        f"pixel art 32x32 game icon, {shape_desc}, "
        f"representing {description or block_name}, "
        f"colors: {', '.join(palette.tags)}, "
        f"{PIXEL_STYLE}"
    )

    return prompt, palette_name, visual_elements


def build_stat_icon_prompt(stat_name: str, description: str) -> tuple[str, str]:
    """构建 Stat 图标 Prompt"""
    desc_lower = (stat_name + " " + description).lower()

    # 从 VISUAL_THEMES 找匹配
    visual_elements = []
    for keyword, themes in VISUAL_THEMES.items():
        if keyword in desc_lower:
            visual_elements.extend(themes)

    palette_name = suggest_palette(stat_name + " " + description, fallback="damage_red")
    palette = PALETTES[palette_name]

    shape_desc = ", ".join(dict.fromkeys(visual_elements)) if visual_elements else "simple icon symbol"

    prompt = (
        f"pixel art status icon 15x15, {shape_desc}, "
        f"representing {description or stat_name}, "
        f"colors: {', '.join(palette.tags)}, "
        f"{PIXEL_STYLE}"
    )
    return prompt, palette_name


def build_enemy_prompt(enemy_name: str, description: str) -> tuple[str, str]:
    """
    构建敌人贴图 Prompt。
    自动识别敌人类型，匹配视觉主题。
    """
    desc_lower = (enemy_name + " " + description).lower()

    # 匹配敌人主题
    matched_theme = None
    for kind, theme in ENEMY_THEMES.items():
        if kind in desc_lower:
            matched_theme = theme
            break

    if matched_theme:
        body_desc = matched_theme["body"]
        color_desc = matched_theme["colors"]
        shape_desc = matched_theme["shape"]
        custom_desc = f"{body_desc}, {shape_desc}, {color_desc}"
    else:
        custom_desc = description or enemy_name

    palette_name = suggest_palette(desc_lower, fallback="enemy_grey")
    palette = PALETTES[palette_name]

    prompt = (
        f"pixel art 64x64 enemy creature, {custom_desc}, "
        f"facing forward, game character sprite, "
        f"colors: {', '.join(palette.tags)}, "
        f"{PIXEL_STYLE}"
    )
    return prompt, palette_name


def build_animation_frames(
    base_description: str,
    num_frames: int,
    anim_type: str = "idle",
) -> list[str]:
    """
    为动画生成多帧描述的 prompt 列表。
    anim_type: idle | walk | attack | patrol
    """
    frame_prompts = []

    if anim_type == "idle":
        # 待机动画：轻微呼吸浮动
        for i in range(num_frames):
            phase = i / num_frames
            offset = int(phase * 2)  # 1-2 像素上下浮动
            bob = "slight bob up" if offset == 0 else "slight bob down"
            frame_prompts.append(
                f"{base_description}, {bob}, frame {i + 1}/{num_frames}"
            )

    elif anim_type == "walk" or anim_type == "patrol":
        # 行走/巡逻：腿部分开-闭合
        leg_phases = ["legs together", "left leg forward", "legs together", "right leg forward"]
        for i in range(num_frames):
            leg = leg_phases[i % len(leg_phases)]
            arm = "arms swinging" if "leg" in leg else "arms at side"
            frame_prompts.append(
                f"{base_description}, walking animation, "
                f"{leg}, {arm}, frame {i + 1}/{num_frames}"
            )

    elif anim_type == "attack":
        # 攻击动画：蓄力-挥出-收招
        phases_count = num_frames
        for i in range(phases_count):
            t = i / max(phases_count - 1, 1)
            if t < 0.3:
                desc = "wind up, weapon pulled back"
            elif t < 0.6:
                desc = "strike forward, weapon extended, impact"
            else:
                desc = "recover, returning to neutral"
            frame_prompts.append(
                f"{base_description}, attack animation, {desc}, "
                f"frame {i + 1}/{num_frames}"
            )

    else:
        # 通用：逐帧小变化
        for i in range(num_frames):
            frame_prompts.append(
                f"{base_description}, animation variation {i + 1}/{num_frames}"
            )

    return frame_prompts
