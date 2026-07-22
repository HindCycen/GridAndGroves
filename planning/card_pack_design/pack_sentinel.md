# 翠绿哨兵 (Verdant Sentinel)

> *"在 AI 封锁区生活的丛林之子，懂得如何与变异植物共生。他用藤蔓和孢子作为武器，耐心等待猎物自己倒下。"*

**定位**: 防守反击、持续伤害、控制战场
**关键资源**: 扎根 Block 的占格位置、藤蔓层数、场上 Block 密度
**风格**: 用扎根 Block 长期占据网格，每回合提供稳定收益；藤蔓和共生效果随回合数增长滚雪球。大尺寸扎根 Block（L 形、2×2）占格多、每回合触发部件多，适合作为共生核心。
**新增机制**: 孢子蔓延（藤蔓达到阈值时触发爆发）、丛林庇护（扎根保护相邻 Block）、自然循环（扎根被清除时回馈资源）。

---

## 新机制

| 机制 | 说明 |
|------|------|
| **扎根 (Root)** | Block 驻留网格（`PreventsClear = true`），每回合被 Bot 触发时提供效果。最多 3 个。 |
| **藤蔓 (Vine)** | 敌人 Stat，`OnTurnEnded` 层数 ×1 伤害，层数 -1（类似 StS 中毒）。 |
| **共生 (Symbiosis)** | 场上每有 1 个己方 Block（含扎根），获得额外加成。与松动卡组配合收益低，与扎根配合收益高。 |
| **孢子蔓延 (Spore Spread)** | 藤蔓层数累积到一定阈值（如 5/10/15 层）时触发额外效果——可以是额外伤害、施加 debuff、或生成临时 Block。 |
| **丛林庇护 (Jungle Shelter)** | 扎根 Block 给相邻格上的己方 Block 提供额外护盾或效果增强。扎根越多，庇护网越大。 |
| **自然循环 (Nature's Cycle)** | 扎根 Block 被清除（被献祭/被销毁/被覆盖）时触发一次效果——回血、抽 Block、或对敌人造成伤害。让"失去扎根"不完全是坏事。 |

## 新增 Stat

| StatDef | 触发时机 | 效果 |
|---------|----------|------|
| `VineStat` | `OnTurnEnded` | 每层 1 伤害给敌人，层数 -1。上限 20 层。 |
| `RootCountStat` | 放置/移除扎根时更新 | 场上扎根 Block 数量，用于共生倍数计算 |
| `SporeThresholdStat` | `OnPostBlockExecute` 检查藤蔓层数 | 藤蔓达 5/10/15 层时触发孢子爆发 |

## 新增 Behavior

| Behavior | 作用 |
|---------|------|
| `RootBehavior` | 驻留网格（`PreventsClear = true`），每回合稳定触发，最多 3 个 |
| `ApplyVineBehavior` | 给敌人施加 N 层藤蔓 |
| `SymbiosisBoostBehavior` | 场上每有 1 个己方 Block（含扎根），效果 +X |
| `SporeBurstBehavior` | 藤蔓层数达到阈值时触发额外 AOE 或效果 |
| `JungleShelterBehavior` | 扎根时给相邻己方 Block 提供额外护盾 |
| `NatureCycleBehavior` | 此扎根 Block 被清除时触发回收效果 |

---

## Block 完整列表

### 普通 (Common) × 16

```
1. 荆棘射击 (Thorn Shot)                 1×1 @ (0,0)
   "从丛林中射出的第一根刺。"
   伤害 6，方向向下。DamageEnemyBehavior。

2. 缠绕藤蔓 (Entangling Vine)            1×1 @ (0,0)
   "让敌人步履维艰的藤蔓。"
   —，方向向下。ApplyVineBehavior（3 层藤蔓）。

3. 木盾 (Wood Shield)                    1×1 @ (0,0)
   "坚实的木质护盾。"
   护盾 7，方向向下。GrantShieldBehavior。

4. 荆棘丛 (Bush)                         1×2 横 @ (0,0)(1,0)
   "一片密集的荆棘。"
   部件 A: 伤害 3，方向向下。DamageEnemyBehavior。
   部件 B: 伤害 3，方向向下。DamageEnemyBehavior。

5. 治愈孢子 (Healing Spore)              1×1 @ (0,0)
   "孢子在伤口上迅速生长，愈合组织。"
   治疗 5，方向向下。HealBehavior。松动。
   自然循环：如果此 Block 被清除，额外治疗 2。

6. 毒藤 (Poison Ivy)                     1×1 @ (0,0)
   "见血封喉的毒藤——刺完就跑。"
   伤害 3，方向向下。DamageEnemyBehavior。藤蔓 +2。松动。

7. 树皮 (Bark)                           1×1 @ (0,0)
   "一层树皮，扎根于网格。"
   护盾 7，方向向下。GrantShieldBehavior。扎根。

8. 弹射种子 (Seed Shot)                  1×1 @ (0,0)
   "被挤出去的种子，寻找新的生长点。"
   伤害 6，方向向下。DamageEnemyBehavior。松动。

9. 藤鞭 (Vine Whip)                      2×1 竖 @ (0,0)(0,1)
   "上抽下打。"
   部件 A: 伤害 4，方向向下。DamageEnemyBehavior。
   部件 B: 伤害 4，方向向下。DamageEnemyBehavior。

10. 蘑菇云 (Mushroom Cloud)              1×1 @ (0,0)
    "孢子云蕴含微毒，迅速扩散。"
    伤害 4，方向向下。DamageEnemyBehavior。藤蔓 +1。松动。

11. 尖刺陷阱 (Spike Trap)                1×1 @ (0,0)
    "一次性的尖刺爆发。"
    伤害 8，方向向下。DamageEnemyBehavior。一次性。

12. 树根盘绕 (Root Bind)                 1×1 @ (0,0)
    "树根牢牢抓住地面，每回合都在生长。"
    护盾 6，方向向下。GrantShieldBehavior。扎根。
    共生：场上每有 2 个己方 Block，此扎根额外提供 1 护盾。

13. 绿叶 (Green Leaf)                    1×2 横 @ (0,0)(1,0)
    "一片治愈的绿叶，一片守护的绿叶。"
    部件 A: 治疗 3，方向向下。HealBehavior。
    部件 B: 护盾 3，方向向下。GrantShieldBehavior。

14. 蜂刺 (Bee Sting)                     1×1 @ (0,0)
    "一刺注入毒液，然后蜂死刺亡。"
    伤害 4，方向向下。DamageEnemyBehavior。藤蔓 +2。一次性。

15. 苔藓 (Moss)                          1×1 @ (0,0)
    "满覆苔藓的石块，有生命的盾牌。"
    护盾 5，方向向下。GrantShieldBehavior。扎根。
    共生：场上每有 1 个己方 Block，护盾 +1。

16. 孢子喷射 (Spore Burst)               1×1 @ (0,0)
    "细小的孢子渗入敌人伤口。"
    伤害 3，方向向下。DamageEnemyBehavior。藤蔓 +1。
    如果敌人已有 ≥3 层藤蔓，额外 +1 层。
```

### 稀有 (Uncommon) × 11

```
17. 深根 (Deep Root)                     1×1 @ (0,0)
    "根扎得越深，守护越久。"
    护盾 6，方向向下。GrantShieldBehavior。
    扎根（PreventsClear = true），每回合提供 6 护盾。

18. 孢子云 (Spore Cloud)                 1×1 @ (0,0)
    "大范围的孢子喷雾。"
    伤害 3，方向向下。DamageEnemyBehavior。
    对所有敌人施加 2 层藤蔓。松动。

19. 光合作用 (Photosynthesis)            1×1 @ (0,0)
    "阳光转化为生命力——扎根越多，治愈越强。"
    治疗 6，方向向下。HealBehavior。
    共生：场上有 ≥2 个扎根 Block 时触发。每多 1 个扎根 +2 治疗。松动。

20. 荆棘反甲 (Thorned Armor)             1×1 @ (0,0)
    "用荆棘编织的甲胄，挨打就扎回去。"
    护盾 10，方向向下。GrantShieldBehavior。
    获得护盾时对敌人造成 3 伤害。

21. 丛林之怒 (Jungle's Wrath)            L 形 @ (0,0)(1,0)(0,1)
    "丛林的怒火随着生物密度而高涨。"
    部件 A: 伤害 5，方向向下。DamageEnemyBehavior。
    部件 B: 伤害 4，方向向右。DamageEnemyBehavior。
    部件 C: 伤害 3，方向向左。DamageEnemyBehavior。
    共生：每部件获得"场上每有 1 个己方 Block，伤害 +1"。

22. 共生护盾 (Symbiotic Shield)          1×2 横 @ (0,0)(1,0)
    "共生关系越紧密，护盾越坚固。"
    部件 A: 护盾 6，方向向下。GrantShieldBehavior。
    部件 B: 护盾 4，方向向下。GrantShieldBehavior。
    共生：场上每有 1 个己方 Block，两部件护盾各 +1。

23. 藤蔓陷阱 (Vine Trap)                 1×2 横 @ (0,0)(1,0)
    "精心布置的陷阱——一旦触发，藤蔓翻倍蔓延。"
    部件 A: 伤害 3，方向向下。DamageEnemyBehavior。藤蔓 +3。
    部件 B: —，方向向下。CallbackAction → 敌人当前藤蔓层数翻倍。一次性。

24. 森林之盾 (Forest Shield)             2×1 竖 @ (0,0)(0,1)
    "两层盾，两次扎根，双重守护。"
    部件 A: 护盾 9，方向向下。GrantShieldBehavior。扎根。
    部件 B: 护盾 7，方向向下。GrantShieldBehavior。扎根。

25. 吸血藤 (Vampire Vine)                1×1 @ (0,0)
    "每一击都在汲取生命。"
    伤害 4，方向向下。DamageEnemyBehavior。
    治疗伤害值 50%。共生：每有 1 个己方 Block 额外 +1 治疗。

26. 荆棘之墙 (Thorn Wall)                2×1 竖 @ (0,0)(0,1)
    "一道带刺的墙——挡住伤害，反刺敌人。"
    部件 A: 护盾 10，方向向下。GrantShieldBehavior。一次性。
    部件 B: 护盾 8，方向向下。GrantShieldBehavior。一次性。
    每部件被触发时对敌人造成 3 伤害。

27. 剧毒新星 (Toxic Nova)                1×1 @ (0,0)
    "毒性大爆发，所有敌人都被波及。"
    伤害 4，方向向下。DamageEnemyBehavior。
    对所有敌人施加 3 层藤蔓。松动。一次性。
```

### 史诗 (Epic) × 4

```
28. 剧毒开花 (Toxic Bloom)               1×1 @ (0,0)
    "藤蔓积累到极致时，毒性之花盛放。"
    伤害 4，方向向下。DamageEnemyBehavior。
    消耗场上所有藤蔓层数，每层造成 1 额外伤害。一次性。
    如果消耗 ≥10 层，额外对所有敌人施加 3 层藤蔓。

29. 种子地雷 (Seed Mine)                 1×1 @ (0,0)
    "埋入地下的种子——被触发后爆炸，然后生根发芽。"
    伤害 12，方向向下。DamageEnemyBehavior。
    驻留（不消失直到被触发）。触发爆炸后消失。
    自然循环：消失时在随机空格生成 1 个"小树苗"（1×1，护盾 3，扎根）。

30. 千年古树 (Ancient Tree)              2×2 @ (0,0)(1,0)(0,1)(1,1)
    "参天古树，四个部件都深深扎根于网格。每回合都释放生命能量。"
    四个部件都是扎根。
    部件 A: 护盾 7，方向向下。GrantShieldBehavior。扎根。
    部件 B: 护盾 5，方向向下。GrantShieldBehavior。扎根。
    部件 C: 治疗 4，方向向下。HealBehavior。扎根。
    部件 D: —，方向向下。共生爆发：场上每有 1 个己方扎根 Block，
            对敌人造成 5 伤害。扎根。
    占 4 格的巨型扎根，每回合稳定触发 4 次。

31. 荆棘领域 (Thorn Field)               L 形 @ (0,0)(1,0)(0,1)
    "荆棘编织的领域——攻击的同时播撒尖刺。"
    部件 A: 伤害 6，方向向下。DamageEnemyBehavior。一次性。
    部件 B: —，方向向下。在随机空格生成 1 个"荆棘陷阱"
            （1×1，伤害 4，松动，不可手动放置）。
    部件 C: 护盾 5，方向向右。GrantShieldBehavior。
```

### 传说 (Legendary) × 1

```
32. 世界树 (Yggdrasil)                   2×2 @ (0,0)(1,0)(0,1)(1,1)
    "传说中连接九界的巨树——每一根枝条都是庇护，每一片落叶都是毒药。"
    四个部件都是扎根。
    部件 A: 护盾 10，方向向下。GrantShieldBehavior。扎根。
    部件 B: 护盾 10，方向向下。GrantShieldBehavior。扎根。
    部件 C: —，方向向下。回合结束时对敌人施加场上扎根数 ×2 层藤蔓。扎根。
    部件 D: —，方向向下。丛林庇护：相邻己方 Block 获得伤害减免 2。扎根。
    自然循环：如果此 Block 被清除，从弃牌堆回收 2 个扎根 Block 到手牌。
```

---

---

## 初始卡组

翠绿哨兵的初始卡组 = 4 打击 + 4 防御 + 1 角色固有 + 1 角色能力。

### 角色固有：共生核心 (Symbiosis Core)

```
共生核心 (Symbiosis Core)               1×1 @ (0,0)  [— 初始固有]
  护盾 6，方向向下。GrantShieldBehavior。
  共生：场上每有 1 个己方 Block，护盾 +1。
  扎根。
```

### 角色能力：光合纲领 (Photosynthesis Doctrine)

```
光合纲领 (Photosynthesis Doctrine)      1×1 @ (0,0)  [— 初始能力]
  —，方向向下。GrantPlayerStatBehavior:
  StatDef: "每回合开始获得 2 护盾；扎根上限从 3 增加到 4"
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
| 普通 | 16 |
| 稀有 | 11 |
| 史诗 | 4 |
| 传说 | 1 |
| **总计** | **32** |

| 机制标签 | 数量 |
|---------|------|
| 藤蔓 | 10 |
| 扎根（驻留） | 8 |
| 共生 | 6 |
| 孢子蔓延（阈值触发）| 3 |
| 自然循环（回收） | 3 |
| 松动 | 4 |
| 一次性 | 6 |
