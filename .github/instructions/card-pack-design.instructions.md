---
description: "Grid and Groves 卡包设计核心原则。Use when: 设计新 Block、创建 BlockPack/MiniPack、理解包间差异、实现新机制（松动/过载/共鸣/藤蔓等）"
applyTo: "**/*.gd"
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
| **锈蚀 (Rust)** | `RustStat`：`OnBeforeDamageApply` 每层减伤 1，上限 10 层，战斗结束清除 |

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
| **藤蔓 (Vine)** | `VineStat`：`OnTurnEnded` 层数 ×1 伤害，层数 -1 |
| **共生 (Symbiosis)** | `SymbiosisStat`：`OnPostBlockExecute` 按场上己方 Block 数提供护盾 |

## Block 特性标签速查

| 标签 | 代码入口 | 行为 |
|------|---------|------|
| 一次性 (Exhaust) | `action.exhaust_source_block = true` | 触发后 Block 移出战斗并销毁 |
| 松动 (Loose) | `LooseBlockBehavior` | 触发后释放网格格子，Block 进入弃牌堆 |
| 驻留 (Root/Glyph) | `BlockPartBehavior.PreventsClear = true` | 回合结束不清除，留在网格上 |
| 共鸣 (Resonance) | `ResonanceTriggerBehavior` | 触发时传播到相邻 Block |

## Block 形状设计原则

Block 的形状由其所有部件的 `PartialPosition` 坐标决定，是游戏最具特色的策略维度。

### 可用形状一览

| 形状 | 部件数 | 坐标 | 策略特征 |
|------|--------|------|---------|
| 1×1 单格 | 1 | (0,0) | 灵活易放，每回合只能触发 1 次 |
| 1×2 横条 | 2 | (0,0)(1,0) | 横向占 2 格，Bot 蛇形路径容易覆盖 |
| 2×1 竖条 | 2 | (0,0)(0,1) | 纵向占 2 格，放置时有垂直限制 |
| L 形 | 3 | (0,0)(1,0)(0,1) | 占 3 格，三部件触发总收益高 |
| 2×2 方块 | 4 | (0,0)(1,0)(0,1)(1,1) | 占 4 格的大块头，爆发核心 |

### 设计比例建议

一个 30~33 Block 的卡包中，形状分布建议为：
- 1×1: 40~50%（基石，不能太少）
- 1×2 横: 15~25%
- 2×1 竖: 10~15%
- L 形: 8~12%
- 2×2: 3~8%

> 单格 Block 是必要的——它们是卡组的基石，提供稳定的基础输出和功能。多格 Block 是卡组的"爆发点"和"策略支点"，让玩家在"占大格打高收益"和"放小格保灵活"之间做取舍。

### 形状与机制的关系

| 机制 | 推荐形状 | 原因 |
|------|---------|------|
| 松动 | 1×1、1×2 | 释放格子快，适合高频腾挪 |
| 过载/锈蚀积累 | 1×1 | 单部件快速叠加层数 |
| 过载消费 | 1×1、L 形 | 大消费需要高收益支撑 |
| 共鸣传播 | 1×2、L 形、2×2 | 多部件可在多方向传播共鸣 |
| 法阵/扎根 | 1×1 | 长期占格，小格可减少战略负担 |
| 共生 | L 形、2×2 | 大块头每回合触发多部件，最大化共生收益 |
| 一次性爆发 | L 形、2×2 | 大尺寸 = 高总伤害，值得一次性消耗 |

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

## 两条 Scaling 路径

Block 设计必须意识到玩家有两种方式应对后期高强度战斗：

| 路径 | 机制 | 平衡含义 |
|------|------|---------|
| **跨战斗 Stat 积累** | Stat 跨战斗保留，叠层后提升攻防 | Stat-granting Block = "遗物"，必须稀有、一次性、永久从牌组移除。不可泛滥。 |
| **Bot 路径操控** | 改变 Bot 方向，复用/循环触发格子 | 可能达成无限的 Block，白板数值降至 ×0.4~0.5。路径操控是高手向，不应是唯一通关路径。 |

## 数值平衡速查

创建新 Block 时，用以下基准验算数值是否合理：

| 条件 | 每部件基准 | 说明 |
|------|-----------|------|
| 普通伤害 | 4~6 | ×1.0 |
| 稀有伤害 | 6~9 | ×1.4 |
| 史诗伤害 | 8~12 | ×2.0 |
| 普通护盾 | 5~7 | ×1.0 |
| 稀有护盾 | 8~12 | ×1.4 |
| 一次性 | 基准 ×1.3~1.5 | 单次使用补偿 |
| 松动 | 基准 ×0.8~0.9 | 释放格子 |
| 驻留 | 基准 ×0.7~0.8 | 每回合触发 |
| 可能无限 | 基准 ×0.4~0.5 | 防止循环失控 |
| 自伤 1 HP | 从总价值 -1 | 代价抵扣 |
| 过载消费 | 每层 +1 伤害 | 需先积累 |
| 添加跨战斗 Stat | 无直接价值 | 当作遗物设计 |

## 游戏经济速查

| 项目 | 值 |
|------|----|
| 初始金币 | 10 |
| 战斗奖励 | 3~5 ±1 |
| 普通 Block 价 | 8~10 |
| 稀有 Block 价 | 15~20 |
| 史诗 Block 价 | 25~35 |
| 传说 Block 价 | 40~60 |
| 打击/防御售价 | 1 |
| 其他售价 | 买入价 × 1/2 |
| 商店重掷 | 3 起递增 | |

详细数值推导见 `planning/card_pack_design/balance.md`。

## 详细参考

完整 Block 设计示例见 `planning/card_pack_design/`：
- `balance.md` — 数值平衡框架（含 StS 对照、形状效率、价值公式）
- `pack_ranger.md` — 铁锈游侠示例 Block 列表
- `pack_weaver.md` — 星语术士示例 Block 列表
- `pack_sentinel.md` — 翠绿哨兵示例 Block 列表
- `minipacks.md` — 5 个小卡包 Block 列表
- `technical.md` — Behavior / Stat / 游戏循环修改技术细节
