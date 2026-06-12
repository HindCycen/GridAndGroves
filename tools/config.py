"""
GridAndGroves 像素画生成器 — 配置
===================================
项目路径、调色板、尺寸常量。
由 generate.py 和 engine.py 共同引用。
"""

import os
from dataclasses import dataclass, field
from typing import ClassVar

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS_DIR = os.path.dirname(os.path.abspath(__file__))


# ── 像素缩放系数 ──────────────────────────────────────────────
# 游戏中所有像素画都遵循 "像素格 = 3×3 物理像素" 的规则
# 原始画布尺寸 → 放大 3× → 最终导入 Godot 的 PNG 尺寸
PIXEL_SCALE: int = 3


# ── 各类资源的像素尺寸 ─────────────────────────────────────────
@dataclass
class AssetSpec:
    """一种资产类型的规格"""
    native: int           # 原始像素画尺寸（像素格数）
    final: int            # PNG 输出尺寸 = native * PIXEL_SCALE
    label: str            # 显示名称

    def __post_init__(self):
        assert self.final == self.native * PIXEL_SCALE, \
            f"final({self.final}) != native({self.native}) * scale({PIXEL_SCALE})"


# 所有资产规格
SPECS: dict[str, AssetSpec] = {
    "block_part":   AssetSpec(32,   96,  "Block Part"),     # 32×32 → 96×96
    "stat_icon":    AssetSpec(15,   45,  "Stat Icon"),      # 15×15 → 45×45
    "enemy":        AssetSpec(64,   192, "Enemy"),          # 64×64 → 192×192
    "player_frame": AssetSpec(64,   192, "Player Frame"),   # 64×64 → 192×192
    "bot_frame":    AssetSpec(32,   96,  "Bot Frame"),      # 32×32 → 96×96
    "heart":        AssetSpec(15,   45,  "Heart Icon"),     # 15×15 → 45×45
    "button":       AssetSpec(32,   96,  "Button Icon"),    # 32×32 → 96×96
}


# ── 游戏调色板（从现有素材中提取）─────────────────────────────────
# 格式: { palette_name: [(R,G,B), ...] }
# 每个调色板的颜色按从深到浅排列

@dataclass
class Palette:
    """一个调色板，包含若干颜色 + 语义标签"""
    name: str
    colors: list[tuple[int, int, int]]
    tags: list[str] = field(default_factory=list)


PALETTES: dict[str, Palette] = {
    # ── 绿色（玩家方块）─ 3~5 色 ──
    "player_green": Palette("Player Green", [
        (45, 80, 22),    # 最深绿 #2d5016
        (60, 100, 30),   # 深绿   #3c641e
        (65, 110, 33),   # 中绿   #416e21
        (96, 158, 52),   # 亮绿   #609e34
        (255, 255, 255), # 白
    ], tags=["player", "green", "friendly", "attack"]),

    # ── 灰色（敌人方块）─ 3~5 色 ──
    "enemy_grey": Palette("Enemy Grey", [
        (0, 0, 0),          # 黑   #000000
        (105, 106, 106),    # 深灰 #696a6a
        (132, 126, 135),    # 中灰 #847e87
        (180, 180, 180),    # 亮灰 #b4b4b4
        (255, 255, 255),    # 白
    ], tags=["enemy", "grey", "hostile", "attack"]),

    # ── 蓝色（护盾）─ 11 色 ──
    "shield_blue": Palette("Shield Blue", [
        (1, 87, 155),       # 深蓝 #01579b
        (2, 136, 209),      # 钴蓝 #0288d1
        (38, 198, 218),     # 青蓝 #26c6da
        (224, 224, 224),    # 浅灰 #e0e0e0
        (239, 239, 239),    # 亮灰 #efefef
        (240, 240, 240),    # 白灰 #f0f0f0
        (242, 242, 242),    # 白灰 #f2f2f2
        (247, 247, 247),    # 亮白 #f7f7f7
        (248, 248, 248),    # 亮白 #f8f8f8
        (249, 249, 249),    # 亮白 #f9f9f9
        (255, 255, 255),    # 纯白 #ffffff
    ], tags=["shield", "blue", "defense", "protect"]),

    # ── 红色（伤害/心/易伤）─ 2 色 ──
    "damage_red": Palette("Damage Red", [
        (208, 23, 22),    # 深红 #d01716
        (229, 28, 35),    # 亮红 #e51c23
    ], tags=["red", "damage", "heart", "vulnerable", "fire"]),

    # ── 青色（玩家角色）─ 3 色 ──
    "player_cyan": Palette("Player Cyan", [
        (0, 0, 0),          # 黑
        (77, 208, 225),     # 青 #4dd0e1
        (255, 255, 255),    # 白
    ], tags=["player", "cyan", "character", "friendly"]),

    # ── 绿色（Bot 巡逻机器人）─ 3 色 ──
    "bot_green": Palette("Bot Green", [
        (0, 0, 0),          # 黑
        (69, 123, 31),      # 深草绿 #457b1f
        (106, 190, 48),     # 亮草绿 #6abe30
    ], tags=["bot", "green", "machine", "patrol"]),

    # ── 蓝色（敌人血条/通用敌人）─ 1 色 ──
    "enemy_blue": Palette("Enemy Blue", [
        (79, 195, 247),     # 亮蓝 #4fc3f7
    ], tags=["enemy", "blue", "simple"]),

    # ── 按色系整理的完整渐变调色板（含黑白）─────────────────────────
    # 每个色系都包含从黑 → 该色系各深浅 → 白的完整渐变
    # NOTE: 索引 0 保留为透明色 (rgba=0,0,0,0)，在所有调色板中统一约定

    # ── 红色系（血条 + 心 + 伤害数字）─ 6 色 ──
    "red_system": Palette("Red System", [
        (0, 0, 0),          # 黑     #000000
        (196, 20, 17),      # 最深红 #c41411  HealthBarMid
        (208, 23, 22),      # 深红   #d01716  Heart / Vulnerable / HealthBar
        (221, 25, 29),      # 中红   #dd191d  HealthBarMid
        (229, 28, 35),      # 亮红   #e51c23  HealthBarMid / Heart
        (255, 255, 255),    # 白     #ffffff
    ], tags=["red", "damage", "heart", "health", "hp", "fire", "blood"]),

    # ── 绿色系（玩家方块 + Bot + 增益 stat）─ 10 色 ──
    "green_system": Palette("Green System", [
        (0, 0, 0),          # 黑         #000000
        (45, 80, 22),       # 最深绿     #2d5016  玩家方块
        (60, 100, 30),      # 深绿       #3c641e  玩家方块
        (65, 110, 33),      # 中绿       #416e21  玩家方块
        (69, 123, 31),      # 草绿       #457b1f  Bot 深色
        (96, 158, 52),      # 亮绿       #609e34  玩家方块
        (106, 190, 48),     # 鲜草绿     #6abe30  Bot 亮色
        (66, 189, 65),      # stat 绿    #42bd41  Growing stat
        (114, 213, 114),    # stat 浅绿  #72d572  Growing stat
        (255, 255, 255),    # 白         #ffffff
    ], tags=["green", "player", "friendly", "nature", "grow", "bot", "buff"]),

    # ── 蓝色系（护盾 + 盾条 + 房间按钮 + 返回 + 敌人）─ 16 色 ──
    "blue_system": Palette("Blue System", [
        (0, 0, 0),          # 黑           #000000
        (26, 35, 126),      # 最深深蓝     #1a237e  ShieldBarMid
        (40, 53, 147),      # 深藏青       #283593  ShieldBarMid
        (42, 54, 177),      # 深蓝         #2a36b1  BattleRoom 暗
        (48, 63, 159),      # 中藏青       #303f9f  ShieldBarMid
        (57, 73, 171),      # 靛蓝         #3949ab  ShieldBarMid
        (59, 80, 206),      # 中蓝         #3b50ce  BattleRoom 主色
        (69, 94, 222),      # 亮藏青       #455ede  BattleRoom / EventRoom
        (1, 87, 155),       # 深天蓝       #01579b  护盾方块
        (86, 119, 252),     # 亮蓝         #5677fc  BattleRoom
        (2, 136, 209),      # 钴蓝         #0288d1  护盾方块
        (3, 155, 229),      # 天蓝         #039be5  BackToStage
        (3, 169, 244),      # 亮天蓝       #03a9f4  BackToStage
        (38, 198, 218),     # 青蓝         #26c6da  护盾方块
        (79, 195, 247),     # 亮青         #4fc3f7  敌人蓝色
        (255, 255, 255),    # 白           #ffffff
    ], tags=["blue", "shield", "defense", "navy", "cyan", "water", "magic"]),

    # ── 灰色系（敌人方块 + TopBar 蓝灰）─ 12 色 ──
    "grey_system": Palette("Grey System", [
        (0, 0, 0),          # 黑           #000000
        (38, 50, 56),       # 蓝灰最暗     #263238  TopBar
        (55, 71, 79),       # 蓝灰暗       #37474f  TopBar
        (69, 90, 100),      # 蓝灰         #455a64  TopBar
        (84, 110, 122),     # 蓝灰中       #546e7a  TopBar
        (96, 125, 139),     # 蓝灰         #607d8b  TopBar / HealthBarOver
        (105, 106, 106),    # 暖灰         #696a6a  敌人方块
        (120, 144, 156),    # 蓝灰亮       #78909c  TopBar / HealthBarOver
        (132, 126, 135),    # 暖灰亮       #847e87  敌人方块
        (144, 164, 174),    # 蓝灰最亮     #90a4ae  TopBar
        (180, 180, 180),    # 浅灰         #b4b4b4  敌人方块
        (255, 255, 255),    # 白           #ffffff
    ], tags=["grey", "enemy", "hostile", "dark", "stone", "metal", "ui"]),

    # ── 紫色系（房间按钮点缀）─ 3 色 ──
    "purple_system": Palette("Purple System", [
        (0, 0, 0),          # 黑     #000000
        (186, 104, 200),    # 紫     #ba68c8  BattleRoom 点缀
        (255, 255, 255),    # 白     #ffffff
    ], tags=["purple", "magic", "rare", "special", "room"]),

    # ── 白色/近白色系（高光渐变）─ 9 色 ──
    "white_system": Palette("White / Near-White", [
        (224, 224, 224),    # 浅灰   #e0e0e0
        (238, 238, 238),    # 灰色   #eeeeee  Shooting stat / EventRoom
        (239, 239, 239),    # 灰白   #efefef
        (240, 240, 240),    # 灰白   #f0f0f0
        (242, 242, 242),    # 灰白   #f2f2f2
        (247, 247, 247),    # 亮白   #f7f7f7
        (248, 248, 248),    # 亮白   #f8f8f8
        (249, 249, 249),    # 亮白   #f9f9f9
        (255, 255, 255),    # 纯白   #ffffff
    ], tags=["white", "light", "highlight", "shine", "pure"]),
}

# ── 语义 → 调色板映射 ─────────────────────────────────────────
# AI 根据描述的关键词自动选择调色板
SEMANTIC_PALETTE_MAP: list[tuple[list[str], str]] = [
    (["shield", "block", "defense", "protect", "guard", "armor", "barrier"], "shield_blue"),
    (["attack", "strike", "sword", "damage", "fire", "burn", "explode"], "player_green"),
    (["player", "character", "hero", "friendly", "cyan", "blue"], "player_cyan"),
    (["bot", "robot", "machine", "patrol", "drone", "mech"], "bot_green"),
    (["enemy", "hostile", "monster", "grey", "dark", "evil"], "enemy_grey"),
    (["heart", "hp", "health", "life", "red"], "damage_red"),
    (["vulnerable", "weak", "status", "debuff"], "damage_red"),
    (["grow", "growing", "buff", "green", "nature"], "player_green"),
    (["shoot", "shooting", "ranged", "magic"], "shield_blue"),
    (["red", "blood", "fire", "burn", "lava", "heart", "vulnerable"], "red_system"),
    (["green", "nature", "grow", "heal", "bot", "plant", "buff"], "green_system"),
    (["blue", "navy", "cyan", "water", "ice", "magic", "shield", "defense"], "blue_system"),
    (["grey", "gray", "stone", "metal", "dark", "shadow", "enemy", "hostile"], "grey_system"),
    (["purple", "magic", "rare", "arcane", "special"], "purple_system"),
    (["white", "light", "highlight", "shine", "holy", "pure"], "white_system"),
]


# ── 透明 / 半透明颜色参考 ──────────────────────────────────────
# 游戏中使用了以下半透明颜色（alpha < 255）用于 UI 叠加层和阴影：
#   rgba(  0,   0,   0, 110)  — 黑色半透明覆盖层 (UpperLayer.png)
#   rgba( 33,  33,  33, 121)  — 深色半透明背景 (HealthBarBG.png)
#   rgba(  0,   0,   0, 118)  — 黑色半透明阴影 (BotFrames.png)
#   rgba(  0,   0,   0, 181)  — 黑色半透明轮廓 (BotFrames.png)
# 在调色板中，索引 0 统一约定为全透明色 (rgba=0,0,0,0)，
# 不在 RGB 列表中显式写出，由生成脚本自行处理。


# ── 全面调色板（包含项目所有颜色）─────────────────────────────────
# 合并所有色系的颜色，去重后按亮度排序。
# 用于 AI 生成需要精确匹配任何现有素材内容的场景。
# 包含黑、白以及所有中间色。
ALL_COLORS = sorted(set(
    c for pal in PALETTES.values() for c in pal.colors
), key=lambda c: c[0] * 0.299 + c[1] * 0.587 + c[2] * 0.114)

COMPREHENSIVE_PALETTE = Palette("Comprehensive (All Colors)", ALL_COLORS,
    tags=["all", "comprehensive", "master", "universal"])


def suggest_palette(description: str, fallback: str = "player_green") -> str:
    """根据描述文字自动推荐最匹配的调色板"""
    desc_lower = description.lower()
    # 按优先级从高到低匹配
    for tags, pal_name in SEMANTIC_PALETTE_MAP:
        for tag in tags:
            if tag in desc_lower:
                return pal_name
    # 没有命中则检查各调色板的标签组
    best_score = 0
    best_name = fallback
    for pal_name, pal in PALETTES.items():
        score = sum(1 for t in pal.tags if t in desc_lower)
        if score > best_score:
            best_score = score
            best_name = pal_name
    return best_name


# ── 项目目录映射 ──────────────────────────────────────────────
# 生成后的文件应放到哪里
OUTPUT_DIRS: dict[str, str] = {
    "block_part":   "resources/blockpart_picture",
    "stat_icon":    "resources/stat_images",
    "enemy":        "resources/enemy_images",
    "player_frame": "actors/player",
    "bot_frame":    "room/bot_frames",
    "heart":        "room/room_pictures",
    "button":       "room/room_pictures",
}

# ── 精灵表（SpriteSheet）布局 ──────────────────────────────────
SPRITESHEET_FRAME_SIZE: dict[str, int] = {
    "player": 192,   # 每帧 192×192
    "bot":    96,    # 每帧 96×96
}

# ── AI 模型配置 ────────────────────────────────────────────────
MODEL_CACHE_DIR = os.path.join(TOOLS_DIR, "models")

# 默认使用的像素画模型（HuggingFace 模型 ID）
# para-lost/PixelArtRedo-XL 是目前质量最好的像素画模型
# 如果显存不足(8GB VRAM)，会自动降级到 wavymulder/pixel-art-diffusion
PIXEL_MODEL_ID: str = "Onodofthenorth/SD_PixelArt_SpriteSheet_Generator"
PIXEL_MODEL_FALLBACK: str = "Onodofthenorth/SD_PixelArt_SpriteSheet_Generator"
