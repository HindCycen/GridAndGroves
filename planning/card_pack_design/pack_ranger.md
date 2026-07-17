# 铁锈游侠 (Rust Ranger)

> *"废土拾荒者，用 AI 残骸和锈蚀零件组装自己的武器库。他不在乎什么魔法，只相信钢铁与火药。"*

**定位**: 高速节奏、网格腾挪、中等伤害
**关键资源**: 网格空间（松动 Block 快速释放格子）
**风格**: 每回合大量放置 Block，利用"松动"特性让它们被触发后立即离开网格腾出空间。多格形状（L 形、2×2）占位大但触发收益高，需要松动小 Block 配合腾挪。

---

## 核心设计思路

网格是 7×5 = 35 格，Bot 每回合会踩遍所有格子。铁锈游侠的玩法就是 **以空间换时间**——松动 Block 释放格子后可以继续放置，用数量弥补单格伤害的不足。

大尺寸 Block（2×2、L 形）虽然占用更多格子，但一次触发多部件能打出段数更高的总伤害，是卡组中的爆发核心。如何用松动 Block 在有限网格中穿插这些大 Block，是本包的核心策略。

---

## 新机制

| 机制 | 说明 |
|------|------|
| **松动 (Loose)** | Block 被 Bot 触发后立即离开网格，释放占用的格子。通过 `LooseBlockBehavior` 实现。 |
| **过载 (Overload)** | 玩家 Stat，本回合每触发一个带过载标签的 Block 计数器 +1。`SpendOverloadBehavior` 消费层数换增益，消费后归零。回合结束时未消费的归零。 |
| **锈蚀 (Rust)** | 敌人 Stat，每层降低敌人伤害 2 点（上限 10 层），战斗结束清除。 |

## 新增 Stat

| StatDef | 触发时机 | 效果 |
|---------|----------|------|
| `OverloadStat` | `OnPostBlockExecute` 递增；消耗时归零；`OnTurnEnded` 清零 | 过载层数，可被消费换取增益 |
| `RustStat` | `OnBeforeDamageApply` | 每层减少敌人造成的伤害 2 点 |

## 新增 Behavior

| Behavior | 作用 |
|----------|------|
| `LooseBlockBehavior` | Block 被触发后释放格子，Block 进入弃牌堆 |
| `SpendOverloadBehavior` | 消费当前过载层数，每层提供额外伤害/护盾 |
| `ApplyRustBehavior` | 给敌人施加 Rust Stat |

---

## Block 完整列表

### 普通 (Common) × 18

```
1. 生锈扳手 (Rusty Wrench)              1×1 @ (0,0)
   伤害 6，方向向下。DamageEnemyBehavior。

2. 铁片 (Metal Shard)                    1×1 @ (0,0)
   伤害 4，方向向下。DamageEnemyBehavior。松动。

3. 旧齿轮 (Old Gear)                     1×1 @ (0,0)
   护盾 6，方向向下。GrantShieldBehavior。松动。

4. 过载线圈 (Overload Coil)              1×1 @ (0,0)
   伤害 3，方向向下。DamageEnemyBehavior。过载 +1。松动。

5. 快拆螺栓 (Quick Release)              1×1 @ (0,0)
   伤害 4，方向向下。DamageEnemyBehavior。松动。

6. 废铁投掷 (Scrap Throw)                1×2 横 @ (0,0)(1,0)
   部件 A: 伤害 4，方向向下。DamageEnemyBehavior。松动。
   部件 B: 伤害 3，方向向右。DamageEnemyBehavior。松动。

7. 铁管 (Iron Pipe)                      2×1 竖 @ (0,0)(0,1)
   部件 A: 伤害 4，方向向下。DamageEnemyBehavior。
   部件 B: 伤害 4，方向向下。DamageEnemyBehavior。

8. 砂纸 (Sandpaper)                      1×1 @ (0,0)
   伤害 2，方向向下。DamageEnemyBehavior。锈蚀 +1。松动。

9. 废电池 (Dead Battery)                 1×1 @ (0,0)
   护盾 4，方向向下。GrantShieldBehavior。过载 +1。

10. 铁丝网 (Barbed Wire)                 1×2 横 @ (0,0)(1,0)
   部件 A: 伤害 3，方向向下。DamageEnemyBehavior。松动。
   部件 B: 伤害 3，方向向下。DamageEnemyBehavior。松动。

11. 弹簧 (Spring)                        1×1 @ (0,0)
   护盾 3，方向向下。GrantShieldBehavior。松动。抽 1 Block。

12. 螺丝刀 (Screwdriver)                 1×1 @ (0,0)
   伤害 5，方向向下。DamageEnemyBehavior。松动。

13. 铁板 (Iron Plate)                    1×1 @ (0,0)
   护盾 8，方向向下。GrantShieldBehavior。一次性。

14. 废料弹 (Scrap Shot)                  1×1 @ (0,0)
   伤害 5，方向向下。DamageEnemyBehavior。过载 +2。

15. 锤子 (Hammer)                        1×2 横 @ (0,0)(1,0)
   部件 A: 伤害 6，方向向下。DamageEnemyBehavior。一次性。
   部件 B: 伤害 4，方向向下。DamageEnemyBehavior。一次性。

16. 旧螺丝 (Old Screw)                   1×1 @ (0,0)
   伤害 2，方向向下。DamageEnemyBehavior。锈蚀 +2。松动。

17. 铁链 (Iron Chain)                    2×1 竖 @ (0,0)(0,1)
   部件 A: 伤害 3，方向向下。DamageEnemyBehavior。松动。
   部件 B: 护盾 3，方向向下。GrantShieldBehavior。松动。

18. 信号枪 (Flare Gun)                   1×1 @ (0,0)
   伤害 7，方向向下。DamageEnemyBehavior。一次性。抽 1 Block。
```

### 稀有 (Uncommon) × 10

```
19. 喷砂器 (Sandblaster)                 1×1 @ (0,0)
    伤害 4，方向向下。DamageEnemyBehavior。锈蚀 +2。松动。

20. 废料洪流 (Scrap Torrent)             1×2 横 @ (0,0)(1,0)
    部件 A: 伤害 8，方向向下。DamageEnemyBehavior。松动。
    部件 B: 伤害 4，方向向右。DamageEnemyBehavior。松动。

21. 过载电容 (Overload Capacitor)        1×1 @ (0,0)
    护盾 6，方向向下。GrantShieldBehavior。消费过载：每层 +2 护盾。

22. 焊枪 (Welding Torch)                 1×1 @ (0,0)
    伤害 5，方向向下。SpendOverloadBehavior（每层 +3 伤害）。一次性。

23. 大型扳手 (Big Wrench)                2×1 竖 @ (0,0)(0,1)
    部件 A: 伤害 6，方向向下。DamageEnemyBehavior。松动。
    部件 B: 伤害 6，方向向下。DamageEnemyBehavior。松动。

24. 铁砧 (Anvil)                         2×2 @ (0,0)(1,0)(0,1)(1,1)
    四个部件: 各伤害 3，方向向下。DamageEnemyBehavior。一次性（主部件）。
    四段共 12 伤害的大块头，占 4 格。

25. 锈蚀炸弹 (Rust Bomb)                 1×2 横 @ (0,0)(1,0)
    部件 A: 伤害 3，方向向下。DamageEnemyBehavior。锈蚀 +3。松动。
    部件 B: 伤害 3，方向向下。DamageEnemyBehavior。锈蚀 +3。松动。

26. 链条锯 (Chain Saw)                   1×1 @ (0,0)
    伤害 9，方向向下。DamageEnemyBehavior。过载 +3。一次性。

27. 旧引擎 (Old Engine)                  2×1 竖 @ (0,0)(0,1)
    部件 A: 伤害 5，方向向下。DamageEnemyBehavior。
    部件 B: —，方向向下。CallbackAction → 抽 1 Block。松动。

28. 电磁铁 (Electromagnet)               L 形 @ (0,0)(1,0)(0,1)
    部件 A: 伤害 4，方向向下。DamageEnemyBehavior。松动。
    部件 B: 伤害 4，方向向右。DamageEnemyBehavior。松动。
    部件 C: —，方向向下。效果：从弃牌堆将 1 张松动 Block 回手。
```

### 史诗 (Epic) × 4

```
29. 锈蚀风暴 (Rust Storm)                1×2 横 @ (0,0)(1,0)
    部件 A: 伤害 3，方向向下。DamageEnemyBehavior。松动。
    部件 B: —，方向向下。ApplyRustBehavior（层数 = 场上 Rust 层数）。松动。

30. 超载运转 (Overload Rush)             L 形 @ (0,0)(1,0)(0,1)
    部件 A: 伤害 8，方向向下。SpendOverloadBehavior（每层 +4 伤害）。一次性。
    部件 B: —，方向向下。CallbackAction → 消费后产生 2 层过载。
    部件 C: 伤害 4，方向向右。DamageEnemyBehavior。一次性。

31. 蒸汽锤 (Steam Hammer)                1×2 横 @ (0,0)(1,0)
    部件 A: 伤害 10，方向向下。DamageEnemyBehavior。一次性。
    部件 B: —，方向向下。CallbackAction → 释放时过载 +3。
    放置时：每有 3 层过载，伤害 +2。

32. 废品巨像 (Scrap Golem)               2×2 @ (0,0)(1,0)(0,1)(1,1)
    四个部件: 各伤害 5，方向向下。DamageEnemyBehavior。松动。
    四段共 20 伤害，全部触发后释放 4 格。
```

### 传说 (Legendary) × 1

```
33. 磁力收束 (Magnetic Pinch)            2×2 @ (0,0)(1,0)(0,1)(1,1)
    部件 A: 伤害 12，方向向下。DamageEnemyBehavior。松动。
    部件 B: 伤害 12，方向向下。DamageEnemyBehavior。松动。
    部件 C: —，方向向下。CallbackAction → 前两个部件触发后，
           从弃牌堆选 1 张松动 Block 回手。
    部件 D: 护盾 6，方向向下。GrantShieldBehavior。
```

---

---

## 初始卡组

铁锈游侠的初始卡组 = 4 打击 + 4 防御 + 1 角色固有 + 1 角色能力。

### 角色固有：锈蚀核心 (Rust Core)

```
锈蚀核心 (Rust Core)                    1×1 @ (0,0)  [— 初始固有]
  伤害 4，方向向下。DamageEnemyBehavior。
  锈蚀 +2。ApplyRustBehavior。
  松动。
```

### 角色能力：废品回收协议 (Scrap Recycling Protocol)

```
废品回收协议 (Scrap Recycling Protocol)  1×1 @ (0,0)  [— 初始能力]
  —，方向向下。GrantPlayerStatBehavior:
  StatDef: "每回合第 1 个松动 Block 被触发时抽 1 Block"
  一次性。Exhaust。从本局卡组中永久移除。
```

> 角色能力设计为"遗物类"Block——触发后永久移除，添加跨战斗 Stat。

---

## 卡包统计

| 形状 | 数量 | 占比 |
|------|------|------|
| 1×1 | 14 | 42% |
| 1×2 横 | 8 | 24% |
| 2×1 竖 | 5 | 15% |
| L 形 | 3 | 9% |
| 2×2 | 3 | 9% |

| 稀有度 | 数量 |
|--------|------|
| 普通 | 18 |
| 稀有 | 10 |
| 史诗 | 4 |
| 传说 | 1 |
| **总计** | **33** |

| 机制标签 | 数量 |
|---------|------|
| 松动 | 19 |
| 过载 | 7 |
| 锈蚀 | 5 |
| 一次性 | 6 |
