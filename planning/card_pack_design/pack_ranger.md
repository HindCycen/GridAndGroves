# 铁锈游侠 (Rust Ranger)

> *"废土拾荒者，用 AI 残骸和锈蚀零件组装自己的武器库。他不在乎什么魔法，只相信钢铁与火药。"*

**定位**: 高速节奏、网格腾挪、资源循环
**关键资源**: 网格空间（松动释放格子）、过载层数（攒-花循环）
**风格**: 每回合大量放置 Block，利用"松动"释放格子腾出空间继续放置。过载系统提供"先叠层再爆发"的节奏变化；废品回收机制让弃牌堆成为资源；锈蚀削弱敌人提供防守空间。三种资源（格子/过载/弃牌堆）互相转化。

---

## 核心设计思路

网格是 7×5 = 35 格。铁锈游侠的玩法是 **以空间换时间**——松动 Block 释放格子后可以继续放置，用数量弥补单格伤害的不足。但光靠数值不够，过载系统给了攒-花节奏，废品回收让弃牌堆成为二次资源。

**三种资源的转化循环**：
```
放置松动 Block → 释放格子 + 触发过载 → 
  → 格子用来放更多 Block 
  → 过载层数用来消费爆发
  → 松动 Block 进弃牌堆 → 废品回收触发
```

---

## 新机制

| 机制 | 说明 |
|------|------|
| **松动 (Loose)** | Block 被 Bot 触发后立即离开网格，释放占用的格子。通过 `LooseBlockBehavior` 实现。 |
| **过载 (Overload)** | 玩家 Stat，本回合每触发一个带过载标签的 Block 计数器 +1。`SpendOverloadBehavior` 消费层数换增益，消费后归零。回合结束时未消费的归零。 |
| **锈蚀 (Rust)** | 敌人 Stat，每层降低敌人伤害 1 点（上限 10 层），战斗结束清除。 |
| **废品回收 (Scrap Recovery)** | 当松动 Block 离开网格进入弃牌堆时触发额外效果——可能是抽 Block、加过载、或给敌人上锈蚀。通过 `OnLooseTriggered` 钩子或连锁 Behavior 实现。 |
| **链式释放 (Chain Release)** | 松动 Block 被触发时，相邻格上的松动 Block 也被立即释放（不触发效果，仅释放格子并进入弃牌堆）。快速腾挪大片区域。 |

## 新增 Stat

| StatDef | 触发时机 | 效果 |
|---------|----------|------|
| `OverloadStat` | `OnPostBlockExecute` 递增；消耗时归零；`OnTurnEnded` 清零 | 过载层数，可被消费换取增益 |
| `RustStat` | `OnBeforeDamageApply` | 每层减少敌人造成的伤害 1 点（上限 10）|
| `ScrapCounterStat` | `OnPostBlockExecute`（仅松动 Block）| 本回合松动触发计数，用于增幅效果 |

## 新增 Behavior

| Behavior | 作用 |
|----------|------|
| `LooseBlockBehavior` | Block 被触发后释放格子，Block 进入弃牌堆 |
| `SpendOverloadBehavior` | 消费当前过载层数，每层提供额外伤害/护盾 |
| `ApplyRustBehavior` | 给敌人施加 Rust Stat |
| `ChainReleaseBehavior` | 触发时释放相邻松动 Block（不触发效果，仅腾格子）|
| `ScrapPayoffBehavior` | 本回合每触发过 N 个松动 Block，获得额外加成 |
| `OverloadToRustBehavior` | 消费过载层数，每层施加 1 层锈蚀 |

---

## Block 完整列表

### 普通 (Common) × 18

```
1. 生锈扳手 (Rusty Wrench)              1×1 @ (0,0)
   "敲你一下，不贵。"
   伤害 6，方向向下。DamageEnemyBehavior。

2. 铁片 (Metal Shard)                    1×1 @ (0,0)
   "啪一下扔出去就没影了。"
   伤害 5，方向向下。DamageEnemyBehavior。松动。

3. 旧齿轮 (Old Gear)                     1×1 @ (0,0)
   "挡一下还行，反正也撑不久。"
   护盾 7，方向向下。GrantShieldBehavior。松动。

4. 过载线圈 (Overload Coil)              1×1 @ (0,0)
   "电流噼啪作响，然后线圈脱落。"
   伤害 4，方向向下。DamageEnemyBehavior。过载 +1。松动。

5. 快拆螺栓 (Quick Release)              1×1 @ (0,0)
   "设计出来就是一次性的。"
   伤害 5，方向向下。DamageEnemyBehavior。松动。

6. 废铁投掷 (Scrap Throw)                1×2 横 @ (0,0)(1,0)
   "一把撒出去，总能中点什么。"
   部件 A: 伤害 5，方向向下。DamageEnemyBehavior。松动。
   部件 B: 伤害 4，方向向右。DamageEnemyBehavior。松动。

7. 铁管 (Iron Pipe)                      2×1 竖 @ (0,0)(0,1)
   "简单粗暴，两段伤害。"
   部件 A: 伤害 4，方向向下。DamageEnemyBehavior。
   部件 B: 伤害 4，方向向下。DamageEnemyBehavior。

8. 砂纸 (Sandpaper)                      1×1 @ (0,0)
   "磨一磨，让它生锈。"
   伤害 3，方向向下。DamageEnemyBehavior。锈蚀 +1。松动。

9. 废电池 (Dead Battery)                 1×1 @ (0,0)
   "还有一点余电，用完就扔。"
   护盾 5，方向向下。GrantShieldBehavior。过载 +1。松动。

10. 铁丝网 (Barbed Wire)                 1×2 横 @ (0,0)(1,0)
    "扯开一片，挡住一面。"
    部件 A: 伤害 4，方向向下。DamageEnemyBehavior。松动。
    部件 B: 护盾 4，方向向下。GrantShieldBehavior。松动。

11. 弹簧 (Spring)                        1×1 @ (0,0)
    "弹出去的瞬间，顺便带了点什么回来。"
    护盾 4，方向向下。GrantShieldBehavior。松动。
    回收到弃牌堆时抽 1 Block。

12. 螺丝刀 (Screwdriver)                 1×1 @ (0,0)
    "戳一下就跑。"
    伤害 6，方向向下。DamageEnemyBehavior。松动。

13. 铁板 (Iron Plate)                    1×1 @ (0,0)
    "硬挡一下，反正一次够本。"
    护盾 8，方向向下。GrantShieldBehavior。一次性。

14. 废料弹 (Scrap Shot)                  1×1 @ (0,0)
    "里面装满了废铁屑和过载能量。"
    伤害 6，方向向下。DamageEnemyBehavior。过载 +1。
    本回合每触发 1 个松动 Block，伤害 +1。

15. 双头扳手 (Double Wrench)             1×2 横 @ (0,0)(1,0)
    "一头敲完另一头也跑不掉。"
    部件 A: 伤害 6，方向向下。DamageEnemyBehavior。松动。
    部件 B: 伤害 6，方向向右。DamageEnemyBehavior。松动。

16. 旧螺丝 (Old Screw)                   1×1 @ (0,0)
    "又锈又钝，但胜在多。"
    伤害 3，方向向下。DamageEnemyBehavior。锈蚀 +2。松动。

17. 铁链 (Iron Chain)                    2×1 竖 @ (0,0)(0,1)
    "连着的两段，一个打人一个挡刀。"
    部件 A: 伤害 4，方向向下。DamageEnemyBehavior。松动。
    部件 B: 护盾 4，方向向下。GrantShieldBehavior。松动。

18. 信号枪 (Flare Gun)                   1×1 @ (0,0)
    "了一声，又来了一个人。"
    伤害 7，方向向下。DamageEnemyBehavior。一次性。
    从弃牌堆回收 1 个松动 Block 到手牌。
```

### 稀有 (Uncommon) × 10

```
19. 喷砂器 (Sandblaster)                 1×1 @ (0,0)
    "锈蚀加速器，附带物理伤害。"
    伤害 5，方向向下。DamageEnemyBehavior。锈蚀 +2。松动。

20. 废料洪流 (Scrap Torrent)             1×2 横 @ (0,0)(1,0)
    "倾泻而下的废铁海啸。"
    部件 A: 伤害 8，方向向下。DamageEnemyBehavior。松动。
    部件 B: 伤害 6，方向向右。DamageEnemyBehavior。松动。
    如果本回合已触发 ≥3 个松动 Block，部件 B 伤害翻倍。

21. 过载电容 (Overload Capacitor)        1×1 @ (0,0)
    "充电完毕，准备释放。"
    护盾 6，方向向下。GrantShieldBehavior。
    消费过载层数：每消费 1 层 +2 护盾。

22. 焊枪 (Welding Torch)                 1×1 @ (0,0)
    "用积累的能量换一记狠的。"
    伤害 5，方向向下。DamageEnemyBehavior。一次性。
    SpendOverloadBehavior（每消费 1 层过载 +3 伤害）。

23. 大型扳手 (Big Wrench)                2×1 竖 @ (0,0)(0,1)
    "大就是好，两根大铁棒。"
    部件 A: 伤害 7，方向向下。DamageEnemyBehavior。松动。
    部件 B: 伤害 7，方向向下。DamageEnemyBehavior。松动。

24. 铁砧 (Anvil)                         2×2 @ (0,0)(1,0)(0,1)(1,1)
    "轰然砸落，占一大片，砸一大片。"
    四个部件: 各伤害 4，方向向下。DamageEnemyBehavior。一次性。
    四段共 16 伤害。如果此 Block 触发时过载 ≥5，伤害总额外 +6。

25. 锈蚀炸弹 (Rust Bomb)                 1×2 横 @ (0,0)(1,0)
    "爆炸溅射，锈蚀蔓延。"
    部件 A: 伤害 4，方向向下。DamageEnemyBehavior。锈蚀 +3。松动。
    部件 B: —，方向向下。CallbackAction：场上每有 1 个松动 Block 刚进入弃牌堆，锈蚀 +1。松动。

26. 链条锯 (Chain Saw)                   1×1 @ (0,0)
    "锯齿轰鸣，过载飙升。"
    伤害 9，方向向下。DamageEnemyBehavior。过载 +3。一次性。

27. 旧引擎 (Old Engine)                  2×1 竖 @ (0,0)(0,1)
    "老东西发动起来还能跑——把另一个也带回来。"
    部件 A: 伤害 6，方向向下。DamageEnemyBehavior。
    部件 B: —，方向向下。从弃牌堆回收 1 个松动 Block 到手牌。松动。

28. 链式反应 (Chain Reaction)            L 形 @ (0,0)(1,0)(0,1)
    "一个松动，周遭全部散架。"
    部件 A: 伤害 7，方向向下。DamageEnemyBehavior。松动。
    部件 B: 伤害 5，方向向右。DamageEnemyBehavior。松动。
    部件 C: —，方向向下。ChainReleaseBehavior：触发时释放相邻松动 Block
            （不造成伤害，仅释放格子并进弃牌堆）。
```

### 史诗 (Epic) × 4

```
29. 锈蚀风暴 (Rust Storm)                1×2 横 @ (0,0)(1,0)
    "让伤口生锈的最好方式——让风吹一吹。"
    部件 A: 伤害 4，方向向下。DamageEnemyBehavior。松动。
    部件 B: —，方向向下。OverloadToRustBehavior：消费全部过载层数，
            每层给敌人施加 1 层锈蚀。松动。

30. 超载运转 (Overload Rush)             L 形 @ (0,0)(1,0)(0,1)
    "过载到极限后，把一切都砸出去。"
    部件 A: 伤害 10，方向向下。SpendOverloadBehavior（每层 +5 伤害）。一次性。
    部件 B: —，方向向下。过载层数清零后重新产生 2 层过载。
    部件 C: 伤害 4，方向向右。DamageEnemyBehavior。一次性。

31. 蒸汽锤 (Steam Hammer)                1×2 横 @ (0,0)(1,0)
    "压力越大，砸得越狠。"
    部件 A: 伤害 6，方向向下。DamageEnemyBehavior。一次性。
    部件 B: —，方向向下。消费过载层数：每层 +2 伤害给部件 A。
           如果消费 ≥5 层，额外施加 1 层锈蚀。

32. 废品巨像 (Scrap Golem)               2×2 @ (0,0)(1,0)(0,1)(1,1)
    "东拼西凑的巨无霸，打完整架散架。"
    四个部件: 各伤害 6，方向向下。DamageEnemyBehavior。松动。
    四段共 24 伤害，全部松动释放 4 格。
    如果四个部件全部触发，从弃牌堆回收 1 个 Block 到手牌。
```

### 传说 (Legendary) × 1

```
33. 磁力收束 (Magnetic Pinch)            2×2 @ (0,0)(1,0)(0,1)(1,1)
    "磁极反转，碎铁横飞——然后全部吸回来。"
    部件 A: 伤害 12，方向向下。DamageEnemyBehavior。松动。
    部件 B: 伤害 12，方向向下。DamageEnemyBehavior。松动。
    部件 C: —，方向向下。消费过载层数：每层 +2 伤害给 A 和 B。松动。
    部件 D: 护盾 6，方向向下。GrantShieldBehavior。
    所有松动部件进弃牌堆后，从弃牌堆回收 1 个松动 Block 到手牌。
```

---

---

## 初始卡组

铁锈游侠的初始卡组 = 4 打击 + 4 防御 + 1 角色固有 + 1 角色能力。

### 角色固有：锈蚀核心 (Rust Core)

```
锈蚀核心 (Rust Core)                    1×1 @ (0,0)  [— 初始固有]
  伤害 5，方向向下。DamageEnemyBehavior。
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
| 松动 | 20 |
| 过载 | 9 |
| 锈蚀 | 6 |
| 一次性 | 7 |
| 链式释放 | 1 |
| 废品回收 | 3 |
