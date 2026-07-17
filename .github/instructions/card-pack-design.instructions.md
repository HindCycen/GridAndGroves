---
description: "Grid and Groves 卡包设计核心原则。Use when: 设计新 Block、创建 BlockPack/MiniPack、理解包间差异、实现新机制（松动/过载/共鸣/藤蔓等）"
applyTo: "**/*.cs"
---

# 卡包设计核心原则

## 设计总纲

三个主卡包（BlockPack）各对应一种玩法风格，通过 Block 特性标签实现差异化：

| 特性标签 | 生命周期 | 适用包 |
|---------|---------|--------|
| 默认（无标签） | 被触发后留在网格，回合结束清理 | 星语术士、通用 |
| **松动 (Loose)** | 被触发后**立即离开网格**，释放格子 | 铁锈游侠 |
| **驻留 (Root/Glyph)** | 回合结束**不消失**（`PreventsClear = true`），长期占格 | 翠绿哨兵、星语术士 |

### 网格基本盘

- 网格 = 7×5 = 35 格
- Bot 每回合蛇形巡逻全部 35 格，每 tick 1 秒
- 玩家每回合可放置的 Block 数受限于：**手牌数** 和 **网格空闲格数**
- 敌人也会占用网格格子
- **网格空间是核心资源**——松动释放格子，驻留占据格子

## 铁锈游侠 — 高速腾挪

**核心循环**：放置松动 Block → Bot 触发 → 释放格子 → 放置更多 Block

| 机制 | 实现方式 |
|------|---------|
| **松动 (Loose)** | `LooseBlockBehavior`：触发后释放网格格位，Block 进入弃牌堆，不销毁 |
| **过载 (Overload)** | `OverloadStat`：每触发一个带过载标签的 Block +1，`SpendOverloadBehavior` 消费层数换增益，层数归零。`OnTurnEnded` 未消费层数清零。**非固定阈值触发**，而是攒-花循环 |
| **锈蚀 (Rust)** | `RustStat`：`OnBeforeDamageApply` 每层减伤 2，上限 10 层，战斗结束清除 |

**避免的设计**：
- ❌ 固定阈值过载奖励（Bot 跑满 35 格必然达成）
- ❌ "回到手牌"类效果（抽牌机制已足够强，网格才是真正限制）

## 星语术士 — 共鸣连锁

**核心循环**：在网格上构建相邻的共鸣 Block 链 → Bot 触发链首 → 链式传播，末端伤害递增

| 机制 | 实现方式 |
|------|---------|
| **共鸣 (Resonance)** | `ResonanceTriggerBehavior`：Bot 触发时扫描上下左右邻格，递归触发带共鸣的 Block，最多 3 层 |
| **星涌 (Starburst)** | 运行时按链位置传参，在 `DamageAction` 中直接计算加成，无需 Stat 计数器 |
| **法阵 (Glyph)** | 使用 `PreventsClear = true` 驻留网格，最多 2 个 |

**共鸣链传播伪代码**：
```
EnqueueBlockActions(block, depth):
  for part in block.Parts:
    action = part.CreateAction()
    if depth > 0: action.AddChainBonus(depth)
    ActionManager.AddToBottom(action)
    if part has ResonanceTriggerBehavior and depth < 3:
      for neighbor in adjacent_cells(block):
        if neighbor has ResonanceTriggerBehavior:
          EnqueueBlockActions(neighbor, depth + 1)
```

## 翠绿哨兵 — 防守滚雪球

**核心循环**：扎根 Block 长期占格 → 每回合稳定收益 → 共生效果随场上 Block 数增长

| 机制 | 实现方式 |
|------|---------|
| **扎根 (Root)** | `RootBehavior` + `PreventsClear = true`，最多 3 个 |
| **藤蔓 (Vine)** | `VineStat`：`OnTurnEnded` 层数 ×3 伤害，层数 -1 |
| **共生 (Symbiosis)** | `SymbiosisStat`：`OnPostBlockExecute` 按场上己方 Block 数提供护盾 |

## Block 特性标签速查

| 标签 | 代码入口 | 行为 |
|------|---------|------|
| 一次性 (Exhaust) | `AbstractGameAction.ExhaustSourceBlock = true` | 触发后 Block 移出战斗并销毁 |
| 松动 (Loose) | `LooseBlockBehavior` | 触发后释放网格格子，Block 进入弃牌堆 |
| 驻留 (Root/Glyph) | `BlockPartBehavior.PreventsClear = true` | 回合结束不清除，留在网格上 |
| 共鸣 (Resonance) | `ResonanceTriggerBehavior` | 触发时传播到相邻 Block |

## PartialPosition 说明

`BlockPartDef.PartialPosition` 是 `Vector2(float)`，用作**像素偏移坐标**：

- 代码：`Position = PartDefinition.PartialPosition * 96`
- 1 单位 = 96 像素
- `(0, 0)` = 左上，(1, 0) = 右移 96px，(0, 1) = 下移 96px
- 支持小数实现非对齐布局
- 放置时每部件通过 `FindNearestGridPoint` 确定占格

## Block 稀有度

| 等级 | 名称 | 权重 | 说明 |
|------|------|------|------|
| 0 | 普通 | 10 | 基础，机制简单 |
| 1 | 稀有 | 4 | 带 1 个核心机制 |
| 2 | 史诗 | 1.5 | 复合机制或条件 |
| 3 | 传说 | 0.5 | 独特效果，特定来源 |

权重影响战利品概率、商店价格、初始卡组构成。

## 详细参考

完整 Block 设计示例见 `planning/card_pack_design/`：
- `pack_ranger.md` — 铁锈游侠示例 Block 列表
- `pack_weaver.md` — 星语术士示例 Block 列表
- `pack_sentinel.md` — 翠绿哨兵示例 Block 列表
- `minipacks.md` — 5 个小卡包 Block 列表
- `technical.md` — Behavior / Stat / 游戏循环修改技术细节
