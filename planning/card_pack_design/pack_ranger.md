# 铁锈游侠 (Rust Ranger)

> *"废土拾荒者，用 AI 残骸和锈蚀零件组装自己的武器库。他不在乎什么魔法，只相信钢铁与火药。"*

**定位**: 高速节奏、网格腾挪、中等伤害
**关键资源**: 网格空间（松动 Block 快速释放格子）
**风格**: 每回合大量放置小型 Block，利用"松动"特性让它们被触发后立即离开网格，腾出空间放下更多 Block。

---

## 核心设计思路

网格是 7×5 = 35 格，Bot 每回合会踩遍所有格子。每回合可放置的 Block 数量受限于：
1. 手牌数量
2. 网格上空闲的格子数（敌人也会占格）

铁锈游侠的核心玩法就是 **以空间换时间**——用"松动"Block 在被触发后立即让出格子，使同一回合内可以放置更多 Block。

---

## 新机制

| 机制 | 说明 |
|------|------|
| **松动 (Loose)** | Block 被 Bot 触发后，**不等回合结束**立即离开网格，释放占用的格子。通过新的 `LooseBlockBehavior` 实现，触发后调用类似 `ExhaustBlock()` 的逻辑但不销毁 Block（回到手牌或弃牌堆取决于具体实现）。 |
| **过载 (Overload)** | 玩家 Stat，本回合内每触发一个带"过载"标签的 Block，计数器 +1。**消耗**过载层数的 Block 会获得额外效果（如每层过载 +2 伤害），消耗后将层数归零。回合结束时未消耗的过载层数全部清零。这迫使玩家在"攒层数赌大的"和"即时变现"之间做选择。 |
| **锈蚀 (Rust)** | 新 Stat，施加于敌人。每层降低敌人造成的伤害 2 点（叠加上限 10 层）。战斗结束时清除。 |

> **过载阈值说明**：Bot 每回合巡逻 35 格，但玩家能放置的 Block 数通常为 5~12 个（受手牌和空闲格子限制）。过载层数的价值不在于"达到某个固定阈值"，而在于"你愿意攒多久才消费"。攒得越多单次收益越大，但可能错过中途的放置机会。

## 新增 Stat

| StatDef | 触发时机 | 效果 |
|---------|----------|------|
| `OverloadStat` | `OnPostBlockExecute` 递增；被其他 Behavior 消耗时归零；`OnTurnEnded` 清零 | 记录本回合触发次数，可被消耗换取增益 |
| `RustStat` | `OnBeforeDamageApply` | 每层减少敌人造成的伤害 2 点 |

## 新增 Behavior

| Behavior | 作用 |
|----------|------|
| `LooseBlockBehavior` | Block 被触发后立即离开网格（释放格子），Block 回到弃牌堆而非手牌 |
| `SpendOverloadBehavior` | 消耗当前过载层数，每层提供额外伤害 / 护盾 |
| `ApplyRustBehavior` | 给敌人施加 Rust Stat |

## 示例 Block

```
Block: "生锈扳手" (Rusty Wrench)        [普通]
  部件1 @ (0, 0): 伤害 6，方向向下
    行为: DamageEnemyBehavior
  特性: 松动（触发后离开网格）

Block: "快拆螺栓" (Quick Release)       [普通]
  部件1 @ (0, 0): 伤害 4，方向向下
    行为: DamageEnemyBehavior
  特性: 松动

Block: "过载线圈" (Overload Coil)        [普通]
  部件1 @ (0, 0): 伤害 3，方向向下
    行为: DamageEnemyBehavior
  额外: 过载 +1（标记此 Block 计入过载计数器）

Block: "喷砂器" (Sandblaster)           [稀有]
  部件1 @ (0, 0): 伤害 4，方向向下
    行为: ApplyRustBehavior（2 层）
  特性: 松动

Block: "过载电容" (Overload Capacitor)  [稀有]
  部件1 @ (0, 0): 护盾 6，方向向下
    行为: GrantShieldBehavior
  额外: 每有过载 1 层，额外 +2 护盾（消耗过载）

Block: "废料洪流" (Scrap Torrent)       [稀有]
  部件1 @ (0, 0): 伤害 8，方向向下
    行为: DamageEnemyBehavior
  特性: 松动
  部件2 @ (1, 0): 伤害 4，方向向右
    行为: DamageEnemyBehavior
  特性: 松动

Block: "焊枪" (Welding Torch)           [稀有]
  部件1 @ (0, 0): 伤害 5，方向向下
    行为: SpendOverloadBehavior（每层 +3 伤害）
  特性: 一次性（Exhaust）

Block: "锈蚀风暴" (Rust Storm)          [史诗]
  部件1 @ (0, 0): 伤害 3，方向向下
    行为: DamageEnemyBehavior
  部件2 @ (1, 0): —，方向向下
    行为: ApplyRustBehavior（层数 = 场上 Rust 层数 ÷ 2）
  特性: 松动（两个部件独立触发，各释放一次格子）

Block: "超载运转" (Overload Rush)       [史诗]
  部件1 @ (0, 0): 伤害 8，方向向下
    行为: SpendOverloadBehavior（每层 +4 伤害）
  特性: 一次性
  额外: 消费过载后额外产生 2 层过载（鼓励连续爆发）

Block: "磁力收束" (Magnetic Pinch)      [传说]
  部件1 @ (0, 0): 伤害 12，方向向下
    行为: DamageEnemyBehavior
  部件2 @ (1, 0): 伤害 12，方向向下
    行为: DamageEnemyBehavior
  特性: 两个部件都带"松动"
  额外: 两个部件都被触发后，将弃牌堆中 1 个松动 Block 回手
```

## 卡包构成

| 类别 | 数量 |
|------|------|
| 松动类（Loose） | ~10 |
| 过载类（Overload） | ~7 |
| 锈蚀类（Rust） | ~5 |
| 基础填充 | ~11 |
| **总计** | **~33** |

| 稀有度 | 数量 |
|--------|------|
| 普通 | ~18 |
| 稀有 | ~10 |
| 史诗 | ~4 |
| 传说 | ~1 |
