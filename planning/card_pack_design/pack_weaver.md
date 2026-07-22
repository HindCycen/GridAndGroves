# 星语术士 (Astral Weaver)

> *"新世界的法术天才，能用星能编织出常人无法理解的力量网络。对她来说，每一颗 Block 都是一个咒语音节。"*

**定位**: 高 combo 潜力、布局策略、共鸣爆发
**关键资源**: 共鸣链长度与分支数、法阵驻留位置
**风格**: 需要精心布局 Block 在网格上的位置，让它们彼此相邻形成共鸣链。链越长、分支越多，末端 Block 的爆发越强。法阵提供回合间的持续收益，星能回响记录本回合的共鸣历史用于消费。大尺寸 Block（L 形、2×2）可以同时在多方向上成为分支节点。

---

## 新机制

| 机制 | 说明 |
|------|------|
| **共鸣 (Resonance)** | Block 的部件带有共鸣属性——Bot 触发时额外触发**相邻格上的共鸣 Block**，链式传播最多 3 层。传播方向由部件 `movingDirection` 决定。 |
| **星涌 (Starburst)** | 共鸣链中每个 Block 按链位置获得伤害加成：链位置 0（链首）无加成，链位置 1 加 1 倍，链位置 2 加 2 倍。通过运行时传参实现。 |
| **法阵 (Glyph)** | 驻留 Block（`PreventsClear = true`），每回合持续提供效果，永久占格，最多 2 个。法阵自身不传播共鸣。 |
| **星能回响 (Astral Echo)** | 共鸣链每成功传播 1 个 Block，全局计数器 +1。回响层数可被消费用于增幅效果。回合结束清零。与铁锈游侠的"过载"对应——过载是触发次数，回响是共鸣传播次数。 |
| **星辰聚焦 (Stellar Focus)** | 场上共鸣 Block 之间的相邻关系构成"共鸣网络"。网络中的分支点（连接 ≥2 个共鸣 Block 的格子）提供额外收益。 |

## 共鸣链传播逻辑

```
EnqueueBlockActions(block, depth):
  for part in block.Parts:
    action = part.CreateAction()
    if depth > 0: action.SetChainBonus(depth)
    ActionManager.AddToBottom(action)
    if part has ResonanceTriggerBehavior and depth < 3:
      for neighbor in adjacent_cells(block):
        if neighbor has ResonanceTriggerBehavior:
          EchoCounter += 1  // 星能回响计数
          EnqueueBlockActions(neighbor, depth + 1)
```

## 新增 Stat

| StatDef | 触发时机 | 效果 |
|---------|----------|------|
| `EchoStat` | `OnPostBlockExecute` 当共鸣传播时递增；消费时归零；`OnTurnEnded` 清零 | 本回合共鸣传播计数，可消费换取增益 |
| `GlyphCountStat` | 放置/移除法阵时更新 | 场上法阵数量，用于条件判断 |

## 新增 Behavior

| Behavior | 作用 |
|----------|------|
| `ResonanceTriggerBehavior` | 标记此部件为共鸣传播源，Bot 触发时递归触发相邻共鸣 Block |
| `SpendEchoBehavior` | 消费当前回响层数，每层提供额外伤害或护盾 |
| `GlyphRootBehavior` | 法阵驻留（`PreventsClear = true`），回合结束不清除，最多 2 个 |

---

## Block 完整列表

### 普通 (Common) × 16

```
1. 星尘箭 (Stardust Arrow)               1×1 @ (0,0)
   "最基础的星光编织——直来直往。"
   伤害 7，方向向下。DamageEnemyBehavior。

2. 星能碎片 (Star Shard)                 1×1 @ (0,0)
   "破碎的星光，碰撞后会传递能量。"
   伤害 4，方向向下。DamageEnemyBehavior。共鸣。

3. 星光护盾 (Starlight Shield)            1×1 @ (0,0)
   "用星光织一面盾。"
   护盾 6，方向向下。GrantShieldBehavior。

4. 能量引流 (Energy Conduit)             1×1 @ (0,0)
   "共鸣中的裂隙会牵来另一颗星。"
   —，方向向下。抽 1 Block。共鸣。

5. 流星 (Meteor)                         1×1 @ (0,0)
   "一闪而过的星体，击中即焚。"
   伤害 8，方向向下。DamageEnemyBehavior。一次性。

6. 星轨 (Star Trail)                     1×2 横 @ (0,0)(1,0)
   "一条星轨上窜动着两股能量。"
   部件 A: 伤害 3，方向向下。DamageEnemyBehavior。共鸣。
   部件 B: 伤害 3，方向向右。DamageEnemyBehavior。共鸣。

7. 灵气 (Aura)                           1×1 @ (0,0)
   "环绕周身的星光屏障。"
   护盾 4，方向向下。GrantShieldBehavior。共鸣。

8. 星座连线 (Constellation)              2×1 竖 @ (0,0)(0,1)
   "上下两颗星，连成一段线。"
   部件 A: 伤害 4，方向向下。DamageEnemyBehavior。共鸣。
   部件 B: 护盾 4，方向向下。GrantShieldBehavior。

9. 闪烁 (Twinkle)                        1×1 @ (0,0)
   "一闪一闪亮晶晶——又一颗被牵来了。"
   伤害 2，方向向下。DamageEnemyBehavior。共鸣。
   抽 1 Block。

10. 星辰之盾 (Astral Shield)             1×1 @ (0,0)
    "用尽全部星光，凝聚一瞬的守护。"
    护盾 8，方向向下。GrantShieldBehavior。一次性。

11. 聚光射线 (Focus Ray)                 1×2 横 @ (0,0)(1,0)
    "光线收束，单向传播。"
    部件 A: 伤害 5，方向向下。DamageEnemyBehavior。
    部件 B: 伤害 5，方向向右。DamageEnemyBehavior。共鸣。
    共鸣传播方向固定向右。

12. 引力涟漪 (Gravity Ripple)            1×1 @ (0,0)
    "扭曲空间的涟漪，让巡逻者折返。"
    伤害 5，方向向下。DamageEnemyBehavior。
    方向修改为向上（Bot 折返）。

13. 星尘 (Stardust)                      1×1 @ (0,0)
    "飘散的星尘，落地即散。"
    伤害 4，方向向下。DamageEnemyBehavior。共鸣。松动。

14. 月弧 (Moon Arc)                      2×1 竖 @ (0,0)(0,1)
    "两弧月光交叠成盾。"
    部件 A: 护盾 5，方向向下。GrantShieldBehavior。
    部件 B: 护盾 5，方向向下。GrantShieldBehavior。

15. 光柱 (Light Pillar)                  1×2 横 @ (0,0)(1,0)
    "两道强光，一闪即灭。"
    部件 A: 伤害 6，方向向下。DamageEnemyBehavior。一次性。
    部件 B: 伤害 4，方向向下。DamageEnemyBehavior。一次性。

16. 星火 (Sparkle)                       1×1 @ (0,0)
    "微弱的星火，但多一颗就多一次机会。"
    伤害 2，方向向下。DamageEnemyBehavior。共鸣。
    回响+1（本回合共鸣传播计数增加）。
```

### 稀有 (Uncommon) × 11

```
17. 共鸣水晶 (Resonance Crystal)         1×2 横 @ (0,0)(1,0)
    "纯化的共振源，只传播不伤敌。"
    部件 A: 伤害 4，方向向下。DamageEnemyBehavior。共鸣。
    部件 B: —，方向向下。ResonanceTriggerBehavior（纯传播源）。共鸣。
    两部件都可向后传播共鸣。

18. 星涌节点 (Starburst Node)            1×1 @ (0,0)
    "链越深，涌越烈。"
    伤害 2，方向向下。DamageEnemyBehavior。共鸣。
    链位置每 +1，伤害 +2（位置 1=4，位置 2=6）。

19. 编织 (Weave)                         L 形 @ (0,0)(1,0)(0,1)
    "星线编织成网——拉来一张牌，织出一层盾。"
    部件 A: 护盾 6，方向向下。GrantShieldBehavior。
    部件 B: —，方向向下。抽 1 Block。共鸣。
    部件 C: 护盾 4，方向向右。GrantShieldBehavior。共鸣。

20. 星能脉冲 (Star Pulse)                1×1 @ (0,0)
    "到链尾时爆发出最强能量。"
    伤害 6，方向向下。DamageEnemyBehavior。共鸣。
    如果链位置 ≥1，伤害翻倍为 12。

21. 双子星 (Binary Stars)                1×2 横 @ (0,0)(1,0)
    "双星系统，双向传播。"
    部件 A: 伤害 5，方向向下。DamageEnemyBehavior。共鸣。
    部件 B: 伤害 5，方向向右。DamageEnemyBehavior。共鸣。
    两个部件各自向不同方向传播共鸣。

22. 以太护盾 (Ether Shield)              2×1 竖 @ (0,0)(0,1)
    "两层以太，一层共鸣，一层守护。"
    部件 A: 护盾 8，方向向下。GrantShieldBehavior。共鸣。
    部件 B: 护盾 4，方向向下。GrantShieldBehavior。

23. 星盘 (Astrolabe)                     1×1 @ (0,0)
    "每一声共鸣都在星盘上刻下一道痕迹。"
    伤害 4，方向向下。DamageEnemyBehavior。
    本回合每触发过 1 个共鸣 Block，伤害 +1（包括自身）。

24. 银河分支 (Galaxy Branch)             L 形 @ (0,0)(1,0)(0,1)
    "三星汇聚，向三个方向同时绽放。"
    部件 A: 伤害 3，方向向下。DamageEnemyBehavior。共鸣。
    部件 B: 伤害 3，方向向右。DamageEnemyBehavior。共鸣。
    部件 C: 伤害 3，方向向上。DamageEnemyBehavior。共鸣。
    三向共鸣传播（上、右、下）。

25. 星门 (Star Gate)                     1×1 @ (0,0)
    "压缩的星门，保护现在，祝福未来。"
    护盾 10，方向向下。GrantShieldBehavior。一次性。
    放置时：指定场上 1 个共鸣 Block，本回合它视为链位置 +1。

26. 超新星前兆 (Supernova Omen)          2×2 @ (0,0)(1,0)(0,1)(1,1)
    "四颗星组成的共鸣矩阵，庞大而脆弱。"
    四个部件: 各伤害 3，方向向下。DamageEnemyBehavior。共鸣。
    四段共 12 伤害。四个部件都能传播共鸣。
    如果本 Block 四个部件全部被共鸣链触发，回响 +3。
```

### 史诗 (Epic) × 5

```
27. 守护法阵 (Guardian Glyph)            1×1 @ (0,0)
    "铭刻在地上的守护星图——每回合重焕光芒。"
    护盾 7，方向向下。GrantShieldBehavior。
    法阵（PreventsClear = true），每回合被触发时提供 7 护盾。最多 2 个。

28. 虚空裂隙 (Void Rift)                 1×1 @ (0,0)
    "撕开一道虚空之口——代价是献祭一座法阵。"
    伤害 15，方向向下。DamageEnemyBehavior。一次性。
    条件：必须紧邻 1 个己方法阵。
    触发后该法阵消失。

29. 群星齐鸣 (Stellar Chorus)            1×2 横 @ (0,0)(1,0)
    "末端的星总是唱得最响亮。"
    部件 A: 伤害 5，方向向下。DamageEnemyBehavior。共鸣。
    部件 B: 伤害 5，方向向右。DamageEnemyBehavior。共鸣。
    如果此 Block 是共鸣链末端（链位置 ≥2），两部件伤害翻倍。
    如果回响 ≥5，额外造成 5 点伤害。

30. 星语法阵 (Astral Glyph)              1×1 @ (0,0)
    "铭刻的法阵在回合结束时引动群星——每一声共鸣都是一次轰炸。"
    —，方向向下。法阵。
    驻留。回合结束时对本回合触发过的每个共鸣 Block 的敌人造成 4 伤害。
    最多 2 个。

31. 坍缩星 (Collapsar)                   L 形 @ (0,0)(1,0)(0,1)
    "法阵坍缩的瞬间释放出全部能量。"
    部件 A: 伤害 10，方向向下。DamageEnemyBehavior。一次性。
    部件 B: —，方向向下。销毁场上 1 个己方法阵，部件 A 伤害 +8。
    部件 C: 护盾 4，方向向右。GrantShieldBehavior。
```

### 传说 (Legendary) × 1

```
32. 新星 (Nova)                          L 形 @ (0,0)(1,0)(0,1)
    "当三颗共鸣星在链尾汇聚——新星爆发。"
    三个部件都是共鸣。
    部件 A: 伤害 3，方向向下。DamageEnemyBehavior。共鸣。
    部件 B: 伤害 3，方向向右。DamageEnemyBehavior。共鸣。
    部件 C: 伤害 3，方向向左。DamageEnemyBehavior。共鸣。
    每个部件获得链位置 ×2 额外伤害。
    如果三个部件都被共鸣链触发，额外释放一次星涌爆发——
    对本回合共鸣链上的所有敌人造成 5 伤害。
```

---

---

## 初始卡组

星语术士的初始卡组 = 4 打击 + 4 防御 + 1 角色固有 + 1 角色能力。

### 角色固有：共鸣核心 (Resonance Core)

```
共鸣核心 (Resonance Core)               1×1 @ (0,0)  [— 初始固有]
  伤害 4，方向向下。DamageEnemyBehavior。
  共鸣。
  抽 1 Block。CallbackAction。
```

### 角色能力：星能回路 (Astral Circuit)

```
星能回路 (Astral Circuit)               1×1 @ (0,0)  [— 初始能力]
  —，方向向下。GrantPlayerStatBehavior:
  StatDef: "共鸣链最大长度从 3 增加到 4；每回合开始获得 1 层回响"
  一次性。Exhaust。从本局卡组中永久移除。
```

---

## 卡包统计

| 形状 | 数量 | 占比 |
|------|------|------|
| 1×1 | 16 | 50% |
| 1×2 横 | 7 | 22% |
| 2×1 竖 | 3 | 9% |
| L 形 | 4 | 13% |
| 2×2 | 1 | 3% |
| 共鸣传播 | 1×1 中 2 个仅标记传播 | — |

| 稀有度 | 数量 |
|--------|------|
| 普通 | 16 |
| 稀有 | 11 |
| 史诗 | 5 |
| 传说 | 1 |
| **总计** | **33** |

| 机制标签 | 数量 |
|---------|------|
| 共鸣 | 20 |
| 法阵（驻留） | 3 |
| 回响（星能回响） | 4 |
| 一次性 | 5 |
| 松动 | 1 |
| 方向修改 | 1 |
