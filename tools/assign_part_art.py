#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
GridAndGroves 部件图自动分配脚本
================================
按部件语义（行为类型 → 图标，阵营/用途 → 配色）为 block_defs.json 中
所有部件自动分配 96×96 程序化部件图，替换原来的 7 张占位图。

用法：
    python3 tools/assign_part_art.py          # 更新 block_defs.json 的 spriteTexture
    python3 tools/assign_part_art.py --dry-run  # 只打印统计不写入
"""

import argparse
import json
import os

from PIL import Image

BASE = "res://resources/blockpart_picture"

# 特殊行为 → 图标（dict 顺序即优先级，先匹配先得）
BEHAVIOR_ICONS = [
    # 自伤（红色滴血最醒目，放最前）
    ("DamagePlayerBehavior", ("drop", "red")),
    # 治疗
    ("HealBehavior", ("cross", "green")),
    # 过载系（闪电）
    ("AddOverloadBehavior", ("bolt", "green")),
    ("SpendOverloadBehavior", ("bolt", "green")),
    ("SpendOverloadBoostBehavior", ("bolt", "green")),
    ("OverloadThresholdBehavior", ("bolt", "green")),
    ("OverloadToRustBehavior", ("rust", "green")),
    # 锈蚀系
    ("ApplyRustBehavior", ("rust", "green")),
    ("ScrapToRustBehavior", ("rust", "green")),
    # 藤蔓系
    ("ApplyVineBehavior", ("vine", "green")),
    ("ApplyVineAllBehavior", ("vine", "green")),
    ("DoubleVineBehavior", ("vine", "green")),
    ("RootCountVineBehavior", ("vine", "green")),
    ("ConsumeVineDamageBehavior", ("vine", "green")),
    # 法阵 / 扎根
    ("GlyphRootBehavior", ("glyph", "purple")),
    ("RootBehavior", ("root", "brown")),
    # 回响 / 共鸣系
    ("AddEchoBehavior", ("echo", "purple")),
    ("SpendEchoBehavior", ("echo", "purple")),
    ("EchoBonusDamageBehavior", ("echo", "purple")),
    ("EchoThresholdBehavior", ("echo", "purple")),
    ("EchoBurstBehavior", ("echo", "purple")),
    ("ResonanceTriggerBehavior", ("echo", "purple")),
    ("ChainBonusDamageBehavior", ("starburst", "purple")),
    ("ChainBonusShieldBehavior", ("starburst", "purple")),
    # 抽牌 / 回收
    ("DrawBlockBehavior", ("card", "green")),
    ("RecallFromDiscardBehavior", ("recycle", "green")),
    ("ReturnPlacedToHandBehavior", ("recycle", "green")),
    ("RemoveFromDiscardBehavior", ("recycle", "dark")),
    ("NatureCycleBehavior", ("recycle", "green")),
    # 生成 / 孢子
    ("SummonBlockBehavior", ("sprout", "brown")),
    ("SporeBurstBehavior", ("starburst", "brown")),
    # 链式
    ("ChainReleaseBehavior", ("chain", "green")),
    ("ChainTriggerBehavior", ("chain", "red")),
    # 引爆 / 爆炸
    ("DetonatorBehavior", ("detonator", "red")),
    # 破盾 / 移除
    ("RemoveEnemyBuffBehavior", ("hack", "dark")),
    # 随机
    ("RandomDamageBehavior", ("dice", "purple")),
    ("RandomDebuffBehavior", ("dice", "purple")),
    # 方向 / 位置条件
    ("ColumnConditionDamageBehavior", ("move", "blue")),
    ("PlacementRestrictionBehavior", ("move", "blue")),
    # 献祭
    ("SacrificeGlyphBehavior", ("sacrifice", "purple")),
    # 反伤 / 庇护
    ("ShieldReflectBehavior", ("shield", "blue")),
    ("JungleShelterBehavior", ("shield", "blue")),
    # 共生
    ("SymbiosisBoostBehavior", ("star4", "green")),
    # 废品回收
    ("ScrapPayoffBehavior", ("gear", "yellow")),
    ("ScrapBonusDamageBehavior", ("gear", "yellow")),
    ("ScrapThresholdBehavior", ("gear", "yellow")),
]

# 方向 → 图标
DIR_ICONS = {
    (0, 1): "arrow_down",
    (1, 0): "arrow_right",
    (0, -1): "arrow_up",
    (-1, 0): "arrow_left",
}

DIR_ORDER = ["arrow_down", "arrow_right", "arrow_up", "arrow_left"]


def behavior_name(bh):
    return os.path.basename(bh.get("script", "")).replace(".gd", "")


def icon_for_part(part):
    """返回 (icon_name, palette) 或 None（保持原图）"""
    bhv_names = [behavior_name(b) for b in part.get("behaviors", [])]
    # 1. 特殊行为优先
    for script_name, (icon, pal) in BEHAVIOR_ICONS:
        if script_name in bhv_names:
            return (icon, pal)
    # 2. 纯伤害 → 方向箭头（green）
    dmg = part.get("baseDamage", 0)
    shd = part.get("baseShield", 0)
    heal = part.get("baseHeal", 0)
    if dmg > 0:
        md = tuple(part.get("movingDirection", [0, 1]))
        icon = DIR_ICONS.get(md, "arrow_down")
        return (icon, "green")
    if shd > 0:
        return ("shield", "blue")
    if heal > 0:
        return ("cross", "green")
    # 3. 纯功能部件：有方向 → 转向图标；否则空白
    md = tuple(part.get("movingDirection", [0, 1]))
    if md != (0, 1):
        return ("move", "blue")
    return ("blank", "green")


def main():
    ap = argparse.ArgumentParser(description="部件图自动分配")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    path = "resources/block_defs.json"
    data = json.load(open(path))
    assigned = {}
    for block in data["blocks"]:
        faction = block.get("faction", 0)
        for part in block.get("parts", []):
            icon, pal = icon_for_part(part)
            if faction == 1:
                pal = "grey"
            tex = f"{BASE}/{pal}/{icon}.png"
            if not os.path.exists(tex.replace("res://", "", 1)):
                print(f"WARN: missing {tex} for {block['name']}/{part['partId']}")
                continue
            part["spriteTexture"] = tex
            assigned.setdefault((icon, pal), 0)
            assigned[(icon, pal)] += 1

    if not args.dry_run:
        with open(path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
            f.write("\n")
    print("assigned", sum(assigned.values()), "parts:")
    for (icon, pal), cnt in sorted(assigned.items(), key=lambda kv: -kv[1]):
        print(f"  {pal}/{icon}: {cnt}")


if __name__ == "__main__":
    main()
