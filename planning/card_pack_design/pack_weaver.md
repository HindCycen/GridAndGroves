# 星语术士 (Astral Weaver)

> *"新世界的法术天才，能用星能编织出常人无法理解的力量网络。对她来说，每一颗 Block 都是一个咒语音节。"*

**定位**: 高 combo 潜力、大数字爆发、布局策略
**关键资源**: 共鸣链长度、Block 相邻排列
**风格**: 需要精心布局 Block 在网格上的位置，让它们彼此相邻形成共鸣链。链越长，最终爆发越强。

---

## 新机制

| 机制 | 说明 |
|------|------|
| **共鸣 (Resonance)** | Block 的某个部件带有"共鸣"属性——Bot 触发该部件时，额外触发**相邻格**上所有也带"共鸣"的 Block（连锁触发）。链式传播，最多 3 层。 |
| **星涌 (Starburst)** | 基于**共鸣链长度**的动态加成。Bot 触发一条共鸣链时，链上每个 Block 除了自身效果外，额外按其在链中的位置获得递增加成。链越长，末端 Block 的加成越大。 |
| **法阵 (Glyph)** | 特殊 Block，放置后不会在回合结束消失（`PreventsClear = true`）。每回合持续提供效果，但永久占用网格位置。最多同时存在 2 个。 |

## 新增 Stat

| StatDef | 触发时机 | 效果 |
|---------|----------|------|
| `GlyphSustainStat` | `OnTurnStarted` | 管理场上法阵 Block 的存在和每回合效果 |

> 星涌不需要 Stat 计数器——它通过 `ResonanceTriggerBehavior` 在运行时传递链长参数，直接在 DamageAction 中计算加成。

## 游戏循环修改

在 Bot 的 `EnqueueBlockActions()` 中增加共鸣传播逻辑：

```
EnqueueBlockActions(block):
  chainLength = 1
  for part in block.Parts:
    action = part.CreateAction()
    action.SetChainBonus(0)            // 链首无加成
    ActionManager.AddToBottom(action)
    if part has ResonanceTriggerBehavior:
      PropagateResonance(block, ref chainLength)

PropagateResonance(currentBlock, ref chainLength):
  if chainLength >= 3: return          // 最多 3 层
  for each neighbor cell (up/down/left/right):
    if neighbor has a block with ResonanceTriggerBehavior:
      chainLength++
      for part in neighbor.Parts:
        action = part.CreateAction()
        action.SetChainBonus(chainLength - 1)  // 第 2 个 +1，第 3 个 +2
        ActionManager.AddToBottom(action)
      PropagateResonance(neighbor, ref chainLength)
```

## 示例 Block

```
Block: "星尘箭" (Stardust Arrow)          [普通]
  部件1 @ (0, 0): 伤害 7，方向向下
    行为: DamageEnemyBehavior

Block: "共鸣水晶" (Resonance Crystal)     [普通]
  部件1 @ (0, 0): 伤害 4，方向向下
    行为: DamageEnemyBehavior
  标签: 共鸣（可作为链中节点传播）

Block: "星涌节点" (Starburst Node)        [稀有]
  部件1 @ (0, 0): 伤害 2，方向向下
    行为: DamageEnemyBehavior
  标签: 共鸣
  额外: 在共鸣链中时，每层链位置 +3 伤害

Block: "守护法阵" (Guardian Glyph)        [史诗]
  部件1 @ (0, 0): 护盾 5，方向向下
    行为: GrantShieldBehavior
  特性: 驻留（PreventsClear = true），每回合被 Bot 触发时提供护盾
  限制: 最多 2 个

Block: "能量引流" (Energy Conduit)        [普通]
  部件1 @ (0, 0): —，方向向下
    行为: CallbackAction → 抽 1 张 Block
  标签: 共鸣（主要用作共鸣链连接器）

Block: "群星齐鸣" (Stellar Chorus)        [史诗]
  部件1 @ (0, 0): 伤害 5，方向向下
    行为: DamageEnemyBehavior
  标签: 共鸣
  额外: 如果它是共鸣链的末端（链位置 ≥ 2），伤害翻倍

Block: "虚空裂隙" (Void Rift)             [史诗]
  部件1 @ (0, 0): 伤害 15，方向向下
    行为: DamageEnemyBehavior
  条件: 必须紧邻一个己方法阵 Block 才能放置
  代价: 触发后，相邻的法阵 Block 消失（牺牲法阵换取爆发）

Block: "编织" (Weave)                     [稀有]
  部件1 @ (0, 0): 护盾 6，方向向下
    行为: GrantShieldBehavior
  部件2 @ (1, 0): —，方向向下
    行为: CallbackAction → 抽 1 张 Block
  标签: 共鸣（两个部件都可以传播共鸣）

Block: "新星" (Nova)                      [传说]
  部件1 @ (0, 0): 伤害 3，方向向下
    行为: DamageEnemyBehavior
  部件2 @ (1, 0): 伤害 3，方向向右
    行为: DamageEnemyBehavior
  部件3 @ (0, 1): 伤害 3，方向向左
    行为: DamageEnemyBehavior
  标签: 三个部件都是共鸣
  效果: 作为共鸣链末端时，三个部件各获得链位置 ×2 的额外伤害
  尺寸: L 形，占 3 格
```

## 卡包构成

| 类别 | 数量 |
|------|------|
| 共鸣类 | ~8 |
| 星涌加成类 | ~4 |
| 法阵类 | ~3 |
| 基础填充 | ~17 |
| **总计** | **~32** |

| 稀有度 | 数量 |
|--------|------|
| 普通 | ~16 |
| 稀有 | ~10 |
| 史诗 | ~5 |
| 传说 | ~1 |
