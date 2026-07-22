# 技术实现建议

新增的 Behavior、Stat 和游戏循环修改汇总。

---

## 新增 BlockPartBehavior

| Behavior | 所属包 | 作用 |
|----------|--------|------|
| `LooseBlockBehavior` | 铁锈游侠（核心） | Block 被触发后立即离开网格，释放占用格子。实现：触发后调用类似 `ExhaustBlock()` 的逻辑，但 Block 进入弃牌堆而非销毁。 |
| `SpendOverloadBehavior` | 铁锈游侠 | 消耗当前过载层数，每层提供额外伤害/护盾。过载层数归零。 |
| `ApplyRustBehavior` | 铁锈游侠 | 给敌人施加 Rust Stat |
| `ResonanceTriggerBehavior` | 星语术士 | 标记 Block 为共鸣源，触发相邻共鸣（链式传播，最多 3 层） |
| `ApplyVineBehavior` | 翠绿哨兵 | 给敌人施加 Vine Stat |
| `RootBehavior` | 翠绿哨兵 | Block 驻留网格（PreventsClear = true），每回合提供效果 |
| `SelfDamageBehavior` | 暗网契约 | 对自己造成伤害 |
| `DirectionModifierBehavior` | 精密传动 | 修改 Bot 巡逻方向（已有类似，可能需要标准化） |
| `RandomDamageBehavior` | 星尘余烬 | 随机数值伤害 |
| `PlacementRestrictionBehavior` | 精密传动 | 限制 Block 放置位置（如"只能放中央"） |

---

## 新增 StatDef / StatBehavior

| StatDef | 触发时机 | 效果 |
|---------|----------|------|
| `OverloadStat` | `OnPostBlockExecute` 递增；被 SpendOverloadBehavior 消耗时归零；`OnTurnEnded` 清零 | 本回合触发次数计数（仅计入带过载标签的 Block） |
| `RustStat` | `OnBeforeDamageApply` | 每层减少敌人造成的伤害 1 点 |
| `VineStat` | `OnTurnEnded` | 每层对敌人造成 1 伤害，层数 -1 |
| `SymbiosisStat` | `OnPostBlockExecute` | 统计场上己方 Block 数，每有 1 个获得护盾 |

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
