# 星语术士 (Astral Weaver)

> *"新世界的法术天才，能用星能编织出常人无法理解的力量网络。对她来说，每一颗 Block 都是一个咒语音节。"*

**定位**: 高 combo 潜力、大数字爆发、布局策略
**关键资源**: 共鸣链长度、Block 相邻排列
**风格**: 需要精心布局 Block 在网格上的位置，让它们彼此相邻形成共鸣链。链越长，末端 Block 的爆发越强。大尺寸 Block（L 形、2×2）可以同时在多方向上成为共鸣链的分支节点。

---

## 新机制

| 机制 | 说明 |
|------|------|
| **共鸣 (Resonance)** | Block 的部件带有共鸣属性——Bot 触发时额外触发相邻格上的共鸣 Block，链式传播最多 3 层 |
| **星涌 (Starburst)** | 共鸣链中每个 Block 按链位置获得伤害加成。链位置 0（链首）无加成，链位置 1 加 1 倍，链位置 2 加 2 倍。通过运行时传参实现，无需 Stat 计数器。 |
| **法阵 (Glyph)** | 驻留 Block（`PreventsClear = true`），每回合持续提供效果，永久占格，最多 2 个。 |

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
          EnqueueBlockActions(neighbor, depth + 1)
```

---

## Block 完整列表

### 普通 (Common) × 16

```
1. 星尘箭 (Stardust Arrow)               1×1 @ (0,0)
   伤害 7，方向向下。DamageEnemyBehavior。

2. 星能碎片 (Star Shard)                 1×1 @ (0,0)
   伤害 4，方向向下。DamageEnemyBehavior。共鸣。

3. 星光护盾 (Starlight Shield)            1×1 @ (0,0)
   护盾 6，方向向下。GrantShieldBehavior。

4. 能量引流 (Energy Conduit)             1×1 @ (0,0)
   —，方向向下。CallbackAction → 抽 1 Block。共鸣。

5. 流星 (Meteor)                         1×1 @ (0,0)
   伤害 8，方向向下。DamageEnemyBehavior。一次性。

6. 星轨 (Star Trail)                     1×2 横 @ (0,0)(1,0)
   部件 A: 伤害 3，方向向下。DamageEnemyBehavior。共鸣。
   部件 B: 伤害 3，方向向右。DamageEnemyBehavior。共鸣。

7. 灵气 (Aura)                           1×1 @ (0,0)
   护盾 4，方向向下。GrantShieldBehavior。共鸣。

8. 星座连线 (Constellation)              2×1 竖 @ (0,0)(0,1)
   部件 A: 伤害 4，方向向下。DamageEnemyBehavior。共鸣。
   部件 B: 护盾 4，方向向下。GrantShieldBehavior。

9. 闪烁 (Twinkle)                        1×1 @ (0,0)
   伤害 2，方向向下。DamageEnemyBehavior。共鸣。抽 1 Block。

10. 星辰之盾 (Astral Shield)             1×1 @ (0,0)
    护盾 8，方向向下。GrantShieldBehavior。一次性。

11. 射线 (Ray)                           1×2 横 @ (0,0)(1,0)
    部件 A: 伤害 5，方向向下。DamageEnemyBehavior。
    部件 B: 伤害 5，方向向右。DamageEnemyBehavior。
    共鸣（仅部件 B 触发共鸣传播）。

12. 引力波 (Gravity Ripple)              1×1 @ (0,0)
    伤害 5，方向向下。DamageEnemyBehavior。额外：Bot 方向改为向上。

13. 星尘 (Stardust)                      1×1 @ (0,0)
    伤害 3，方向向下。DamageEnemyBehavior。共鸣。松动。

14. 月弧 (Moon Arc)                      2×1 竖 @ (0,0)(0,1)
    部件 A: 护盾 5，方向向下。GrantShieldBehavior。
    部件 B: 护盾 5，方向向下。GrantShieldBehavior。

15. 光柱 (Light Pillar)                  1×2 横 @ (0,0)(1,0)
    部件 A: 伤害 6，方向向下。DamageEnemyBehavior。一次性。
    部件 B: 伤害 4，方向向下。DamageEnemyBehavior。一次性。

16. 星火 (Sparkle)                       1×1 @ (0,0)
    伤害 2，方向向下。DamageEnemyBehavior。共鸣。过载 +1。
```

### 稀有 (Uncommon) × 10

```
17. 共鸣水晶 (Resonance Crystal)         1×2 横 @ (0,0)(1,0)
    部件 A: 伤害 4，方向向下。DamageEnemyBehavior。共鸣。
    部件 B: —，方向—。ResonanceTriggerBehavior（标记为传播源）。共鸣。

18. 星涌节点 (Starburst Node)            1×1 @ (0,0)
    伤害 2，方向向下。DamageEnemyBehavior。共鸣。
    链位置每 +1，伤害 +1。

19. 编织 (Weave)                         L 形 @ (0,0)(1,0)(0,1)
    部件 A: 护盾 6，方向向下。GrantShieldBehavior。
    部件 B: —，方向向下。CallbackAction → 抽 1 Block。共鸣。
    部件 C: 护盾 4，方向向右。GrantShieldBehavior。共鸣。

20. 星能脉冲 (Star Pulse)                1×1 @ (0,0)
    伤害 6，方向向下。DamageEnemyBehavior。共鸣。
    链位置 ≥ 1 时伤害翻倍。

21. 双子星 (Binary Stars)                1×2 横 @ (0,0)(1,0)
    部件 A: 伤害 5，方向向下。DamageEnemyBehavior。共鸣。
    部件 B: 伤害 5，方向向右。DamageEnemyBehavior。共鸣。
    两个部件都传播共鸣——可以同时向左右两侧分支。

22. 以太护盾 (Ether Shield)              2×1 竖 @ (0,0)(0,1)
    部件 A: 护盾 8，方向向下。GrantShieldBehavior。共鸣。
    部件 B: 护盾 4，方向向下。GrantShieldBehavior。

23. 星盘 (Astrolabe)                     1×1 @ (0,0)
    伤害 4，方向向下。DamageEnemyBehavior。
    额外：本回合每触发一个共鸣 Block，此伤害 +1。

24. 银河分支 (Galaxy Branch)             L 形 @ (0,0)(1,0)(0,1)
    部件 A: 伤害 3，方向向下。DamageEnemyBehavior。共鸣。
    部件 B: 伤害 3，方向向右。DamageEnemyBehavior。共鸣。
    部件 C: 伤害 3，方向向上。DamageEnemyBehavior。共鸣。
    三向共鸣——可以向上、右、下三个方向传播。

25. 星门 (Star Gate)                     1×1 @ (0,0)
    护盾 10，方向向下。GrantShieldBehavior。一次性。
    额外：放置时选择场上一个共鸣 Block，本回合它视为链位置 +1。

26. 超新星前兆 (Supernova Omen)          2×2 @ (0,0)(1,0)(0,1)(1,1)
    四个部件: 各伤害 2，方向向下。DamageEnemyBehavior。共鸣。
    四段共 8 伤害，四个部件都能传播共鸣——可作为大型共鸣中转站。
```

### 史诗 (Epic) × 5

```
27. 守护法阵 (Guardian Glyph)            1×1 @ (0,0)
    护盾 5，方向向下。GrantShieldBehavior。
    驻留（PreventsClear = true），每回合被 Bot 触发时提供护盾。
    最多 2 个。

28. 虚空裂隙 (Void Rift)                 1×1 @ (0,0)
    伤害 15，方向向下。DamageEnemyBehavior。一次性。
    条件：必须紧邻一个己方法阵 Block。
    代价：触发后该法阵 Block 消失。

29. 群星齐鸣 (Stellar Chorus)            1×2 横 @ (0,0)(1,0)
    部件 A: 伤害 5，方向向下。DamageEnemyBehavior。共鸣。
    部件 B: 伤害 5，方向向右。DamageEnemyBehavior。共鸣。
    如果此 Block 是共鸣链末端（链位置 ≥ 2），伤害翻倍。

30. 星语法阵 (Astral Glyph)              1×1 @ (0,0)
    —，方向向下。CallbackAction → 回合结束时星涌爆发，
    对本回合触发过的每个共鸣 Block 造成 5 点伤害。
    驻留。

31. 坍缩星 (Collapsar)                   L 形 @ (0,0)(1,0)(0,1)
    部件 A: 伤害 10，方向向下。DamageEnemyBehavior。一次性。
    部件 B: —，方向向下。CallbackAction → 销毁场上 1 个己方法阵，
           每销毁 1 个法阵本 Block 伤害 +8。
    部件 C: 护盾 4，方向向右。GrantShieldBehavior。
```

### 传说 (Legendary) × 1

```
32. 新星 (Nova)                          L 形 @ (0,0)(1,0)(0,1)
    三个部件都是共鸣。
    部件 A: 伤害 3，方向向下。DamageEnemyBehavior。共鸣。
    部件 B: 伤害 3，方向向右。DamageEnemyBehavior。共鸣。
    部件 C: 伤害 3，方向向左。DamageEnemyBehavior。共鸣。
    链末端加成：每个部件获得链位置 ×1 的额外伤害。
    如果三个部件都被共鸣链触发，额外执行一次 CallbackAction →
    对本回合共鸣链上的所有敌人造成 5 点伤害。
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
  StatDef: "共鸣链最大长度从 3 增加到 4"
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
| 稀有 | 10 |
| 史诗 | 5 |
| 传说 | 1 |
| **总计** | **32** |

| 机制标签 | 数量 |
|---------|------|
| 共鸣 | 18 |
| 法阵（驻留） | 2 |
| 一次性 | 5 |
| 松动 | 1 |
