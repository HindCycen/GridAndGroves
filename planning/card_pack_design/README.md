# 卡包设计 — 总览

> 基于世界观设定，规划 3 个主卡包（BlockPack）和 5 个小卡包（MiniPack）的内容框架。
> 每个卡包独立文件，本文档仅描述跨包共用的核心概念。

---

## 目录

| 文件 | 内容 |
|------|------|
| `pack_ranger.md` | 铁锈游侠（Rust Ranger）— 松动、过载、锈蚀、废品回收、链式释放 |
| `pack_weaver.md` | 星语术士（Astral Weaver）— 共鸣、星涌、法阵、星能回响、星辰聚焦 |
| `pack_sentinel.md` | 翠绿哨兵（Verdant Sentinel）— 扎根、藤蔓、共生、孢子蔓延、丛林庇护、自然循环 |
| `minipacks.md` | 5 个小卡包 |
| `technical.md` | Behavior / Stat / 游戏循环修改建议 |

---

## 🧱 跨包共用概念

### 部件位置 (PartialPosition)

`BlockPartDef.PartialPosition` 是一个 `Vector2`，表示部件在 Block 局部空间中的坐标。

| 属性 | 值 |
|------|----|
| 类型 | `Vector2`（float，支持小数） |
| 单位 | 1.0 = 96 像素（对应一个网格格子的尺寸） |
| 原点 `(0, 0)` | Block 的左上角局部原点 |
| 轴方向 | X 正方向向右，Y 正方向向下 |

**实际效果**：在 `BlockPart._Ready()` 中执行 `Position = PartDefinition.PartialPosition * 96`，将部件定位到 Block 内的对应像素位置。

**典型取值**（基于已有 `.tres` 数据）：

| 坐标 | 说明 |
|------|------|
| `(0, 0)` | 左上位置（默认，单部件 Block 常用） |
| `(1, 0)` | 右上位置 |
| `(0, 1)` | 左下位置 |
| `(1, 1)` | 右下位置 |

> `PartialPosition` 是**像素偏移坐标**而非网格索引。它定义了部件在 Block 内的渲染位置，而非"占据哪个格子"。部件之间可以重叠（同一个坐标），也可以使用小数坐标实现非对齐布局。

**放置时的网格占位**：当 Block 被放置到战斗网格上时，每个部件通过 `GridState.find_nearest_grid_point(part.global_position)` 找到最近的网格点并标记为 Occupied。因此，部件的 `PartialPosition` 间接决定了 Block 在网格上占据哪些格子。

---

### Block 特性标签 (Traits)

以下特性标签可在 Block 设计中使用，通过 `BlockPartBehavior` 的字段或新的 Behavior 实现：

| 特性 | 说明 |
|------|------|
| **一次性 (Exhaust)** | Block 被 Bot 触发后立即移出战斗（不进入弃牌堆）。已有 `ExhaustSourceBlock` 机制支持。 |
| **松动 (Loose)** | Block 被 Bot 触发后，**不等回合结束**立即离开网格，释放占用的格子。适用于快节奏、高频率放置的打法。 |
| **驻留 (Root/Glyph)** | Block 在回合结束后继续留在网格上（`PreventsClear = true`），每回合持续提供效果。占用网格位置，需要战略布局。 |

---

### Block 稀有度 (Rarity)

每个 `BlockDef` 拥有一个稀有度等级。

| 等级 | 名称 | 颜色 | 权重 | 说明 |
|------|------|------|------|------|
| 0 | 普通 (Common) | `#FFFFFF` | 10 | 基础 Block，数值较低，机制简单 |
| 1 | 稀有 (Uncommon) | `#4ADE80` | 4 | 带有 1 个核心机制 |
| 2 | 史诗 (Epic) | `#60A5FA` | 1.5 | 复合机制或高数值，通常有条件 |
| 3 | 传说 (Legendary) | `#FBBF24` | 0.5 | 改变游戏规则的独特效果 |

**权重含义**：随机生成奖励时作为概率权重。例如普通 Block 出现概率是稀有的 2.5 倍。

**稀有度影响**：

| 方面 | 效果 |
|------|------|
| 战利品奖励 | 高稀有度出现概率 = 基础权重 |
| 商店价格 | 普通 50 → 稀有 100 → 史诗 175 → 传说 300 |
| 事件获取 | 传说 Block 通常只能通过特定事件 / Boss 战获得 |
| 初始卡组 | 只包含普通和少量稀有 Block |
| 部件数量 | 稀有度越高，平均部件数越多（传说通常 3~4 个部件） |

---

### Block 尺寸

Block 在网格上占据的格子数由其所有部件的 `PartialPosition` 推导：

- 1 个部件 → 通常占 1 格（单格 Block）
- 2 个部件在不同坐标 → 占 2 格（横条或竖条）
- 3~4 个部件在不同坐标 → 占 3~4 格（L 形或 2×2 方块）

> 占格数越多，Bot 触发概率越高，但放置限制也越大。
