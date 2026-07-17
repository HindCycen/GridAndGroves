# 翠绿哨兵 (Verdant Sentinel)

> *"在 AI 封锁区生活的丛林之子，懂得如何与变异植物共生。他用藤蔓和孢子作为武器，耐心等待猎物自己倒下。"*

**定位**: 防守反击、持续伤害、控制战场
**关键资源**: 扎根 Block 的占格位置、藤蔓层数
**风格**: 用扎根 Block 长期占据网格，每回合提供稳定收益；藤蔓和共生效果随回合数增长滚雪球。大尺寸扎根 Block（L 形、2×2）占格多、每回合触发部件多，适合作为共生核心。

---

## 新机制

| 机制 | 说明 |
|------|------|
| **扎根 (Root)** | Block 驻留网格（`PreventsClear = true`），每回合被 Bot 触发时提供效果。最多 3 个。与"松动"形成鲜明对比。 |
| **藤蔓 (Vine)** | 敌人 Stat，`OnTurnEnded` 层数 ×1 伤害，层数 -1（类似 StS 中毒）。 |
| **共生 (Symbiosis)** | 场上每有 1 个己方 Block（含扎根），获得额外加成。与松动卡组配合收益低，与扎根配合收益高。 |

---

## Block 完整列表

### 普通 (Common) × 15

```
1. 荆棘射击 (Thorn Shot)                 1×1 @ (0,0)
   伤害 6，方向向下。DamageEnemyBehavior。

2. 缠绕藤蔓 (Entangling Vine)            1×1 @ (0,0)
   —，方向向下。ApplyVineBehavior（3 层）。

3. 木盾 (Wood Shield)                    1×1 @ (0,0)
   护盾 7，方向向下。GrantShieldBehavior。

4. 荆棘丛 (Bush)                         1×2 横 @ (0,0)(1,0)
   部件 A: 伤害 3，方向向下。DamageEnemyBehavior。
   部件 B: 伤害 3，方向向下。DamageEnemyBehavior。

5. 治愈孢子 (Healing Spore)              1×1 @ (0,0)
   治疗 4，方向向下。HealBehavior。松动。

6. 毒藤 (Poison Ivy)                     1×1 @ (0,0)
   伤害 2，方向向下。DamageEnemyBehavior。藤蔓 +2。松动。

7. 树皮 (Bark)                           1×1 @ (0,0)
   护盾 5，方向向下。GrantShieldBehavior。扎根。

8. 弹射种子 (Seed Shot)                  1×1 @ (0,0)
   伤害 5，方向向下。DamageEnemyBehavior。松动。

9. 藤鞭 (Vine Whip)                      2×1 竖 @ (0,0)(0,1)
   部件 A: 伤害 4，方向向下。DamageEnemyBehavior。
   部件 B: 伤害 4，方向向下。DamageEnemyBehavior。

10. 蘑菇云 (Mushroom Cloud)              1×1 @ (0,0)
    伤害 3，方向向下。DamageEnemyBehavior。藤蔓 +1。松动。

11. 尖刺陷阱 (Spike Trap)                1×1 @ (0,0)
    伤害 8，方向向下。DamageEnemyBehavior。一次性。

12. 树根缠绕 (Root Bind)                 1×1 @ (0,0)
    护盾 4，方向向下。GrantShieldBehavior。扎根。松动（释放格子，
    但扎根效果持续到回合结束？不——扎根意味着不消失，与松动矛盾。
    此处应为普通驻留）。

    修正：护盾 4，方向向下。GrantShieldBehavior。扎根。

13. 绿叶 (Green Leaf)                    1×2 横 @ (0,0)(1,0)
    部件 A: 治疗 3，方向向下。HealBehavior。
    部件 B: 护盾 3，方向向下。GrantShieldBehavior。

14. 蜂刺 (Bee Sting)                     1×1 @ (0,0)
    伤害 4，方向向下。DamageEnemyBehavior。藤蔓 +2。一次性。

15. 苔藓 (Moss)                          1×1 @ (0,0)
    护盾 3，方向向下。GrantShieldBehavior。扎根。
    共生：场上每有 1 个己方 Block，护盾 +1。
```

### 稀有 (Uncommon) × 11

```
16. 深根 (Deep Root)                     1×1 @ (0,0)
    护盾 4，方向向下。GrantShieldBehavior。
    扎根（PreventsClear = true），每回合提供 4 护盾。

17. 孢子云 (Spore Cloud)                 1×1 @ (0,0)
    伤害 2，方向向下。DamageEnemyBehavior。
    对所有敌人施加 2 层藤蔓。松动。

18. 光合作用 (Photosynthesis)            1×1 @ (0,0)
    治疗 5，方向向下。HealBehavior。
    条件：场上有 ≥ 2 个扎根 Block 时触发。松动。
    共生：扎根越多治疗越强。

19. 荆棘反甲 (Thorned Armor)             1×1 @ (0,0)
    护盾 10，方向向下。GrantShieldBehavior。
    获得护盾时对敌人造成 3 伤害。

20. 丛林之怒 (Jungle's Wrath)            L 形 @ (0,0)(1,0)(0,1)
    部件 A: 伤害 5，方向向下。DamageEnemyBehavior。
    部件 B: 伤害 4，方向向右。DamageEnemyBehavior。
    部件 C: 伤害 3，方向向左。DamageEnemyBehavior。
    共生：每个部件获得"场上每有 1 个己方 Block，伤害 +1"。

21. 共生护盾 (Symbiotic Shield)          1×2 横 @ (0,0)(1,0)
    部件 A: 护盾 6，方向向下。GrantShieldBehavior。
    部件 B: 护盾 4，方向向下。GrantShieldBehavior。
    共生：场上每有 1 个己方 Block，所有护盾值 +1。

22. 藤蔓陷阱 (Vine Trap)                 1×2 横 @ (0,0)(1,0)
    部件 A: 伤害 3，方向向下。DamageEnemyBehavior。藤蔓 +3。
    部件 B: —，方向向下。CallbackAction → 藤蔓层数翻倍。一次性。

23. 森林之盾 (Forest Shield)             2×1 竖 @ (0,0)(0,1)
    部件 A: 护盾 8，方向向下。GrantShieldBehavior。扎根。
    部件 B: 护盾 6，方向向下。GrantShieldBehavior。扎根。

24. 吸血藤 (Vampire Vine)                1×1 @ (0,0)
    伤害 4，方向向下。DamageEnemyBehavior。
    治疗：回复伤害值 50%。共生：每有 1 个己方 Block 额外 +1 治疗。

25. 荆棘之墙 (Thorn Wall)                2×1 竖 @ (0,0)(0,1)
    部件 A: 护盾 10，方向向下。GrantShieldBehavior。一次性。
    部件 B: 护盾 8，方向向下。GrantShieldBehavior。一次性。
    两个部件被触发时各对敌人造成 3 伤害。

26. 剧毒新星 (Toxic Nova)                1×1 @ (0,0)
    伤害 3，方向向下。DamageEnemyBehavior。
    对所有敌人施加 3 层藤蔓。松动。一次性。
```

### 史诗 (Epic) × 4

```
27. 剧毒爆发 (Toxic Bloom)               1×1 @ (0,0)
    伤害 4，方向向下。DamageEnemyBehavior。
    消耗所有藤蔓层数，每层造成 1 额外伤害。一次性。

28. 种子地雷 (Seed Mine)                 1×1 @ (0,0)
    伤害 12，方向向下。DamageEnemyBehavior。
    驻留（不消失直到被 Bot 触发，触发后爆炸消失）。

29. 千年古树 (Ancient Tree)              2×2 @ (0,0)(1,0)(0,1)(1,1)
    四个部件都是扎根。
    部件 A: 护盾 6，方向向下。GrantShieldBehavior。扎根。
    部件 B: 护盾 4，方向向下。GrantShieldBehavior。扎根。
    部件 C: 治疗 3，方向向下。HealBehavior。扎根。
    部件 D: —，方向向下。CallbackAction → 共生爆发：
            每有 1 个己方扎根 Block，对敌人造成 4 伤害。扎根。
    占 4 格的巨型扎根，每回合稳定触发 4 次。

30. 荆棘领域 (Thorn Field)               L 形 @ (0,0)(1,0)(0,1)
    部件 A: 伤害 6，方向向下。DamageEnemyBehavior。一次性。
    部件 B: —，方向向下。CallbackAction → 放置 1 个"荆棘"伪装 Block
            （1×1，伤害 4，松动，不能手动放置）到随机空格。
    部件 C: 护盾 5，方向向右。GrantShieldBehavior。
```

### 传说 (Legendary) × 0

```
（翠绿哨兵没有传说 Block——其强度通过扎根和共生的滚雪球效应体现。）
```

---

---

## 初始卡组

翠绿哨兵的初始卡组 = 4 打击 + 4 防御 + 1 角色固有 + 1 角色能力。

### 角色固有：共生核心 (Symbiosis Core)

```
共生核心 (Symbiosis Core)               1×1 @ (0,0)  [— 初始固有]
  护盾 5，方向向下。GrantShieldBehavior。
  共生：场上每有 1 个己方 Block，护盾 +1。
  扎根。
```

### 角色能力：光合纲领 (Photosynthesis Doctrine)

```
光合纲领 (Photosynthesis Doctrine)      1×1 @ (0,0)  [— 初始能力]
  —，方向向下。GrantPlayerStatBehavior:
  StatDef: "每回合开始获得 2 护盾"
  一次性。Exhaust。从本局卡组中永久移除。
```

---

## 卡包统计

| 形状 | 数量 | 占比 |
|------|------|------|
| 1×1 | 17 | 57% |
| 1×2 横 | 5 | 17% |
| 2×1 竖 | 4 | 13% |
| L 形 | 3 | 10% |
| 2×2 | 1 | 3% |

| 稀有度 | 数量 |
|--------|------|
| 普通 | 15 |
| 稀有 | 11 |
| 史诗 | 4 |
| 传说 | 0 |
| **总计** | **30** |

| 机制标签 | 数量 |
|---------|------|
| 藤蔓 | 9 |
| 扎根（驻留） | 7 |
| 共生 | 6 |
| 松动 | 5 |
| 一次性 | 6 |
