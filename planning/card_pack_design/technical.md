# 技术实现建议

新增的 Behavior、Stat 和游戏循环修改汇总。

---

## 新增 BlockPartBehavior

| Behavior | 所属包 | 作用 |
|----------|--------|------|
| `LooseBlockBehavior` | 铁锈游侠（核心） | Block 被触发后立即离开网格，释放占用格子。实现：触发后调用类似 `ExhaustBlock()` 的逻辑，但 Block 进入弃牌堆而非销毁。 |
| `SpendOverloadBehavior` | 铁锈游侠 | 消耗当前过载层数，每层提供额外伤害/护盾。过载层数归零。 |
| `ApplyRustBehavior` | 铁锈游侠 | 给敌人施加 Rust Stat |
| `ScrapPayoffBehavior` | 铁锈游侠 | 本回合每触发过 N 个松动 Block，获得额外加成 |
| `ChainReleaseBehavior` | 铁锈游侠 | 触发时释放相邻松动 Block（不触发效果，仅腾格子并进入弃牌堆） |
| `OverloadToRustBehavior` | 铁锈游侠 | 消费过载层数，每层给敌人施加 1 层锈蚀 |
| `ResonanceTriggerBehavior` | 星语术士 | 标记 Block 为共鸣源，触发相邻共鸣（链式传播，最多 3 层） |
| `SpendEchoBehavior` | 星语术士 | 消费当前回响层数，每层提供额外伤害或护盾 |
| `GlyphRootBehavior` | 星语术士（法阵） | 法阵驻留（`PreventsClear = true`），回合结束不清除，最多 2 个 |
| `ApplyVineBehavior` | 翠绿哨兵 | 给敌人施加 Vine Stat |
| `RootBehavior` | 翠绿哨兵 | Block 驻留网格（PreventsClear = true），每回合提供效果 |
| `SymbiosisBoostBehavior` | 翠绿哨兵 | 场上每有 1 个己方 Block（含扎根），效果 +X |
| `SporeBurstBehavior` | 翠绿哨兵 | 藤蔓层数达到阈值时触发额外 AOE 或效果 |
| `JungleShelterBehavior` | 翠绿哨兵 | 扎根时给相邻己方 Block 提供额外护盾 |
| `NatureCycleBehavior` | 翠绿哨兵 | 此扎根 Block 被清除时触发回收效果 |
| `SelfDamageBehavior` | 暗网契约 | 对自己造成伤害 |
| `DirectionModifierBehavior` | 精密传动 | 修改 Bot 巡逻方向（已有类似，可能需要标准化） |
| `RandomDamageBehavior` | 星尘余烬 | 随机数值伤害 |
| `PlacementRestrictionBehavior` | 精密传动 | 限制 Block 放置位置（如"只能放中央"） |

---

## 新增 StatDef / StatBehavior

| StatDef | 触发时机 | 效果 |
|---------|----------|------|
| `OverloadStat` | `OnPostBlockExecute` 递增；被 SpendOverloadBehavior 消耗时归零；`OnTurnEnded` 清零 | 本回合触发次数计数（仅计入带过载标签的 Block） |
| `RustStat` | `OnBeforeDamageApply` | 每层减少敌人造成的伤害 1 点（上限 10）|
| `VineStat` | `OnTurnEnded` | 每层对敌人造成 1 伤害，层数 -1（上限 20）|
| `SymbiosisStat` | `OnPostBlockExecute` | 统计场上己方 Block 数，每有 1 个获得护盾 |
| `EchoStat` | `OnPostBlockExecute` 当共鸣传播时递增；消费时归零；`OnTurnEnded` 清零 | 本回合共鸣传播计数，可消费换取增益 |
| `ScrapCounterStat` | `OnPostBlockExecute`（仅松动 Block）| 本回合松动触发计数，用于增幅效果 |
| `RootCountStat` | 放置/移除扎根时更新 | 场上扎根 Block 数量，用于共生倍数计算 |
| `SporeThresholdStat` | `OnPostBlockExecute` 检查藤蔓层数 | 藤蔓达 5/10/15 层时触发孢子爆发 |

---

## 游戏循环修改

### 1. 松动 (Loose) Block 的实现

当前 Block 被触发后的处理在 `Bot.ProcessBlockPart()` 中：

```
当前流程:
  ProcessBlockPart:
    → 执行 Behavior，产生 Action
    → 如果有 Action 声明 ExhaustSourceBlock → 立即移出战斗（ExhaustBlock）
    → 否则 Block 留在网格上直到回合结束

修改后流程:
  ProcessBlockPart:
    → 执行 Behavior，产生 Action
    → 如果有 Action 声明 ExhaustSourceBlock → 立即移出战斗（ExhaustBlock）
    → 如果 Behavior 中有 LooseBlockBehavior → 立即释放网格（不销毁 Block，放入弃牌堆）
    → 否则 Block 留在网格上直到回合结束
```

新增的 `LooseBlockBehavior` 应：
- 释放 Block 占用的所有网格格子（调用类似 `LiftFromGrid()` 的逻辑）
- 将 Block 移入弃牌堆（`DiscardedPile.AddBlock(block)`）
- 不销毁 Block 节点（区别于 Exhaust）
- 不触发 Block 的清除动画（或使用快速消失动画）

### 2. 共鸣连锁（星语术士核心机制）

在 `Bot.EnqueueBlockActions()` 中，触发一个 Block 后增加递归共鸣步：

```
EnqueueBlockActions(block, chainDepth = 0):
  for part in block.Parts:
    action = part.CreateAction()
    if chainDepth > 0:
      action.SetChainBonus(chainDepth)   // 链位置加成
    ActionManager.AddToBottom(action)
    if part has ResonanceTriggerBehavior and chainDepth < 3:
      for neighbor in get_adjacent_cells(block):
        if neighbor has block with ResonanceTriggerBehavior:
          EnqueueBlockActions(neighbor, chainDepth + 1)
```

### 3. 驻留 Block（扎根 / 法阵）

修改回合结束的清理逻辑：

```
当前: 回合结束 → 清除场上所有玩家 Block
修改: 回合结束 → 清除场上所有 !PreventsClear 的 Block
```

需要确保：
- `Bot.gd` 在检查 PathStep 时能跳过已清理的格子
- 驻留 Block 被触发后依然留在场上
- 驻留 Block 占用网格位置（影响后续放置）
- 驻留 Block 有数量上限（建议 2~3 个）

### 4. 过载系统（铁锈游侠）

过载不是固定阈值触发，而是可消耗的资源：

```
OnPostBlockExecute:
  if triggered block has "过载" tag:
    OverloadStat.AddValue(1)

SpendOverloadBehavior.CreateAction():
  读取 OverloadStat.CurrentValue
  消耗全部层数 (OverloadStat.SetValue(0))
  返回 DamageAction(amount = base + spentLayers * bonusPerLayer)

OnTurnEnded:
  OverloadStat.SetValue(0)   // 未消耗的过载清零
```

### 5. 放置限制（精密传动）

在 `Block.CheckPlacementConditions()` 中增加通用钩子，遍历部件的 behaviors，若有 `PlacementRestrictionBehavior` 则检查额外条件。

### 6. 链式释放 ChainRelease （铁锈游侠）

在 `LooseBlockBehavior` 执行后加入邻格扫描：

```
LooseBlockBehavior 执行:
  → 释放本 Block 占用的所有格子
  → Block 进入弃牌堆
  → 如果 Block 有 ChainReleaseBehavior:
      for neighbor in adjacent_cells(block):
        if neighbor has a LooseBlock:
          释放 neighbor（不触发效果，直接腾格子、进弃牌堆）
```

注意：链式释放不递归（不触发 ChainReleaseBehavior 的邻居的邻居），防止一次性释放全网格。

### 7. 废品回收 Scrap Recovery （铁锈游侠）

在 `Bot._exhaust_block()` / `LooseBlockBehavior` 执行后加入：

```
OnLooseTriggered:
  → 检查松动的 Block 是否有 ScrapPayoffBehavior
  → 更新 ScrapCounterStat
  → 触发"松动 Block 进入弃牌堆"信号
  → StatBehavior 在 OnPostBlockExecute 中检查条件
```

实现方式：可在 `Bot._process_block_part()` 中增加一个统一的 `_on_block_loosed(block)` 钩子，Behavior 可注册监听。

### 8. 孢子蔓延 Spore Spread（翠绿哨兵）

在 `OnPostBlockExecute` 或 `OnTurnEnded` 中检查藤蔓层数阈值：

```
OnPostBlockExecute:
  → 获取敌人身上的 VineStat.CurrentValue
  → 如果 >= 5 且未触发过 Lv1: 触发孢子爆发 Lv1
  → 如果 >= 10 且未触发过 Lv2: 触发孢子爆发 Lv2
  → 如果 >= 15 且未触发过 Lv3: 触发孢子爆发 Lv3
```

孢子爆发效果建议：
- Lv1 (5 层): 对所有敌人造成 3 伤害
- Lv2 (10 层): 对所有敌人造成 5 伤害 + 施加 1 层藤蔓
- Lv3 (15 层): 对所有敌人造成 8 伤害 + 施加 2 层藤蔓 + 治疗玩家 3 HP

### 9. 丛林庇护 Jungle Shelter（翠绿哨兵）

扎根 Block 给相邻己方 Block 提供效果增强：

```
RootBehavior 执行时:
  → 检查场上所有己方 Block
  → 如果某 Block 相邻于 ≥1 个扎根 Block:
      该 Block 获得额外效果（如护盾 +2）
  → 多个扎根相邻时效果叠加
```

在 `SymbiosisBoostBehavior` 中可增加对"是否被庇护"的判断，被庇护的 Block 获得双倍共生加成。

### 10. 自然循环 Nature's Cycle（翠绿哨兵）

当扎根 Block 被清除时触发：

```
清除扎根 Block（被销毁/被献祭/被覆盖）时:
  → 检查 Block 是否有 NatureCycleBehavior
  → 执行回收效果（回血/抽 Block/生成临时 Block 等）
```

在 `Bot._exhaust_block()` 和任何清除 Block 的逻辑中加入 `_on_block_cleared(block)` 钩子。
