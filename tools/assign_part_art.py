#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
GridAndGroves 部件图自动分配脚本（包配色版）
================================================
按部件语义（行为类型 → 图标）与「所属卡包（→ 角色/包配色）」为 block_defs.json
中所有部件自动分配 96×96 程序化部件图。

配色规则（v2，需求：同一角色的所有牌颜色统一）：
- 3 个主卡包 = 角色色：铁锈游侠→brown / 星语术士→purple / 翠绿哨兵→green，
  包内所有部件（无论伤害/护盾/机制）统一使用该角色色调
- 5 个小卡包各固定一色：紧急补给→yellow / 废品爆破→red / 暗网契约→dark /
  精密传动→blue / 星尘余烬→purple
- 敌人块（faction=1）→ grey
- 基础卡 Strike/Defend → 使用手绘原型图（green/strike.png、blue/defend.png），不动
- 其他无包块 → 按语义兜底色（伤害绿 / 护盾蓝 / 治疗绿 / 转向蓝 / 空白绿）

用法：
    python3 tools/assign_part_art.py            # 更新 block_defs.json 的 spriteTexture
    python3 tools/assign_part_art.py --dry-run  # 只打印统计不写入
"""

import argparse
import json
import os
import re

BASE = "res://resources/blockpart_picture"

# 特殊行为 → 图标（dict 顺序即优先级，先匹配先得；v2 只决定图标，不再决定配色）
BEHAVIOR_ICONS = [
    ("DamagePlayerBehavior", "drop"),
    ("HealBehavior", "cross"),
    ("AddOverloadBehavior", "bolt"),
    ("SpendOverloadBehavior", "bolt"),
    ("SpendOverloadBoostBehavior", "bolt"),
    ("OverloadThresholdBehavior", "bolt"),
    ("OverloadToRustBehavior", "rust"),
    ("ApplyRustBehavior", "rust"),
    ("ScrapToRustBehavior", "rust"),
    ("ApplyVineBehavior", "vine"),
    ("ApplyVineAllBehavior", "vine"),
    ("DoubleVineBehavior", "vine"),
    ("RootCountVineBehavior", "vine"),
    ("ConsumeVineDamageBehavior", "vine"),
    ("GlyphRootBehavior", "glyph"),
    ("RootBehavior", "root"),
    ("AddEchoBehavior", "echo"),
    ("SpendEchoBehavior", "echo"),
    ("EchoBonusDamageBehavior", "echo"),
    ("EchoThresholdBehavior", "echo"),
    ("EchoBurstBehavior", "echo"),
    ("ResonanceTriggerBehavior", "echo"),
    ("ChainBonusDamageBehavior", "starburst"),
    ("ChainBonusShieldBehavior", "starburst"),
    ("DrawBlockBehavior", "card"),
    ("RecallFromDiscardBehavior", "recycle"),
    ("ReturnPlacedToHandBehavior", "recycle"),
    ("RemoveFromDiscardBehavior", "recycle"),
    ("NatureCycleBehavior", "recycle"),
    ("SummonBlockBehavior", "sprout"),
    ("SporeBurstBehavior", "starburst"),
    ("ChainReleaseBehavior", "chain"),
    ("ChainTriggerBehavior", "chain"),
    ("DetonatorBehavior", "detonator"),
    ("RemoveEnemyBuffBehavior", "hack"),
    ("RandomDamageBehavior", "dice"),
    ("RandomDebuffBehavior", "dice"),
    ("ColumnConditionDamageBehavior", "move"),
    ("PlacementRestrictionBehavior", "move"),
    ("SacrificeGlyphBehavior", "sacrifice"),
    ("ShieldReflectBehavior", "shield"),
    ("JungleShelterBehavior", "shield"),
    ("SymbiosisBoostBehavior", "star4"),
    ("ScrapPayoffBehavior", "gear"),
    ("ScrapBonusDamageBehavior", "gear"),
    ("ScrapThresholdBehavior", "gear"),
]

DIR_ICONS = {
    (0, 1): "arrow_down",
    (1, 0): "arrow_right",
    (0, -1): "arrow_up",
    (-1, 0): "arrow_left",
}

# ── 包 → 配色（v2：同一角色所有牌颜色统一） ──
# .tres 文件名 → (卡包中文名, palette)
PACK_PALETTES = {
    "PackRanger.tres": ("铁锈游侠", "brown"),
    "PackWeaver.tres": ("星语术士", "purple"),
    "PackSentinel.tres": ("翠绿哨兵", "green"),
    "MiniEmergencySupplies.tres": ("紧急补给", "yellow"),
    "MiniJunkExplosion.tres": ("废品爆破", "red"),
    "MiniDarkWebPact.tres": ("暗网契约", "dark"),
    "MiniPrecisionDrive.tres": ("精密传动", "blue"),
    "MiniStardustEmber.tres": ("星尘余烬", "purple"),
}

# 无包块的语义兜底色（v1 逻辑）
SEMANTIC_FALLBACK = "green"

# 使用手绘原型、不参与自动分配的基础卡
HANDMADE_CARDS = {"Strike", "Defend"}


def behavior_name(bh):
    return os.path.basename(bh.get("script", "")).replace(".gd", "")


def icon_for_part(part):
    """返回图标名（与配色解耦）"""
    bhv_names = [behavior_name(b) for b in part.get("behaviors", [])]
    for script_name, icon in BEHAVIOR_ICONS:
        if script_name in bhv_names:
            return icon
    dmg = part.get("baseDamage", 0)
    shd = part.get("baseShield", 0)
    heal = part.get("baseHeal", 0)
    if dmg > 0:
        md = tuple(part.get("movingDirection", [0, 1]))
        return DIR_ICONS.get(md, "arrow_down")
    if shd > 0:
        return "shield"
    if heal > 0:
        return "cross"
    md = tuple(part.get("movingDirection", [0, 1]))
    if md != (0, 1):
        return "move"
    return "blank"


# ── .tres 解析：BlockNames → 所属包 ──

def parse_tres_block_names(path):
    """从卡包 .tres 文本解析 PackName 与 BlockNames"""
    try:
        text = open(path, encoding="utf-8").read()
    except OSError:
        return None, []
    m = re.search(r'PackName\s*=\s*"([^"]*)"', text)
    pack_name = m.group(1) if m else ""
    names = []
    m2 = re.search(r'BlockNames\s*=\s*Array\[String\]\((\[[^\]]*\])\)', text)
    if m2:
        names = re.findall(r'"([^"]*)"', m2.group(1))
    return pack_name, names


def build_block_palette_map():
    """返回 {block_name: palette}，块名全局唯一（命名契约）"""
    mapping = {}
    for dir_name in ("resources/block_packs", "resources/mini_packs"):
        if not os.path.isdir(dir_name):
            continue
        for fname in sorted(os.listdir(dir_name)):
            if not fname.endswith(".tres"):
                continue
            display, pal = PACK_PALETTES.get(fname, (None, None))
            if pal is None:
                continue
            _, names = parse_tres_block_names(os.path.join(dir_name, fname))
            for n in names:
                if n in mapping:
                    print(f"WARN: block '{n}' in multiple packs ({mapping[n]} vs {pal})")
                mapping[n] = pal
    return mapping


def main():
    ap = argparse.ArgumentParser(description="部件图自动分配（包配色）")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    block_palette = build_block_palette_map()
    print(f"loaded {len(block_palette)} blocks into pack color mapping")

    path = "resources/block_defs.json"
    data = json.load(open(path, encoding="utf-8"))
    assigned = {}
    skipped_handmade = 0
    missing = 0
    for block in data["blocks"]:
        name = block.get("name", "")
        faction = block.get("faction", 0)
        if name in HANDMADE_CARDS:
            skipped_handmade += 1
            continue
        for part in block.get("parts", []):
            icon = icon_for_part(part)
            if faction == 1:
                pal = "grey"
            elif name in block_palette:
                pal = block_palette[name]
            else:
                pal = SEMANTIC_FALLBACK
            tex = f"{BASE}/{pal}/{icon}.png"
            if not os.path.exists(tex.replace("res://", "", 1)):
                print(f"WARN: missing {tex} for {name}/{part['partId']}")
                missing += 1
                continue
            part["spriteTexture"] = tex
            assigned.setdefault((icon, pal), 0)
            assigned[(icon, pal)] += 1

    if not args.dry_run:
        with open(path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
            f.write("\n")
    print(f"assigned {sum(assigned.values())} parts (handmade kept: {skipped_handmade}, missing: {missing}):")
    for (icon, pal), cnt in sorted(assigned.items(), key=lambda kv: -kv[1]):
        print(f"  {pal}/{icon}: {cnt}")


if __name__ == "__main__":
    main()