> 卡包设计文档已拆分到 `card_pack_design/` 目录。
> 设计核心原则已整合到 `.github/instructions/card-pack-design.instructions.md`。
> 详细 Block 列表见：
> - `card_pack_design/pack_ranger.md` — 铁锈游侠
> - `card_pack_design/pack_weaver.md` — 星语术士
> - `card_pack_design/pack_sentinel.md` — 翠绿哨兵
> - `card_pack_design/minipacks.md` — 5 个小卡包
> - `card_pack_design/technical.md` — 技术细节

## 🔧 建议新增的 BlockPartBehavior

以下是为支持上述设计需要新建的 Behavior 类（每个一个 `.cs` 文件）：

| Behavior | 所属包 | 作用 |
|----------|--------|------|
| `RecallSelfBehavior` | 铁锈游侠 | Block 被触发后回到手牌 |
| `ApplyRustBehavior` | 铁锈游侠 | 给敌人施加 Rust Stat |
| `ResonanceTriggerBehavior` | 星语术士 | 标记 Block 为共鸣源，触发相邻共鸣 |
| `ApplyVineBehavior` | 翠绿哨兵 | 给敌人施加 Vine Stat |
| `RootBehavior` | 翠绿哨兵 | Block 驻留网格，每回合提供效果 |
| `SelfDamageBehavior` | 暗网契约 | 对自己造成伤害 |
| `DirectionModifierBehavior` | 精密传动 | 修改 Bot 巡逻方向（已有类似，可能需要标准化） |
| `RandomDamageBehavior` | 星尘余烬 | 随机数值伤害 |
| `PlacementRestrictionBehavior` | 精密传动 | 限制 Block 放置位置（如"只能放中央"） |

## 🔧 建议新增的 Stat / StatBehavior

| StatDef | 类型 | 效果 |
|---------|------|------|
| `Rust` | `OnBeforeDamageApply` | 每层减少敌人造成的伤害 1 点 |
| `OverloadCounter` | `OnPostBlockExecute` 计数，`OnTurnEnded` 归零 | 记录触发次数，特定值触发 |
| `Starburst` | `OnTurnEnded` | 按层数造成额外伤害 |
| `Vine` | `OnTurnEnded` | 每层对敌人造成 1 伤害，层数 -1 |
| `Symbiosis` | `OnPostBlockExecute` | 场上每有 1 个己方 Block 获得护盾 |

## 🔧 游戏循环修改建议

### 1. 共鸣连锁（星语术士核心机制）

在 `Bot.EnqueueBlockActions()` 中，触发一个 Block 后：

```
EnqueueBlockActions(block):
  for part in block.Parts:
    ActionManager.AddToBottom(part.CreateAction())
    if part has ResonanceTriggerBehavior:
      for neighbor in get_adjacent_cells(block):
        if neighbor has a block with ResonanceTriggerBehavior:
          EnqueueBlockActions(neighbor)  // 递归触发
          limit recursion depth to 3
```

这需要修改 `Bot.cs` 的触发流程，增加一个递归共鸣步。

### 2. 驻留 Block（扎根/法阵）

修改回合结束的清理逻辑：

```
当前: 回合结束 → 清除场上所有玩家 Block
修改: 回合结束 → 清除场上所有 !PreventsClear 的 Block
```

`PreventsClear` 已存在于 `BlockPartBehavior` 中，但需要确保：
- `Bot.cs` 在检查 PathStep 时能跳过已清理的格子
- 驻留 Block 被触发后依然留在场上
- 驻留 Block 占用网格位置（影响后续放置）

### 3. 过载系统（铁锈游侠）

在 `BattleTime` 中增加一个信号/计数器：

```
OnPostBlockExecute:
  OverloadCounter++
  if OverloadCounter == 3: emit "OverloadThresholdReached_3"
  if OverloadCounter == 5: emit "OverloadThresholdReached_5"
  if OverloadCounter == 7: emit "OverloadThresholdReached_7"

OnTurnEnded:
  OverloadCounter = 0
```

### 4. 放置限制（精密传动）

在 `Block.CheckPlacementConditions()` 中增加一个通用钩子：

```
if block has PlacementRestrictionBehavior:
  检查额外放置条件（如"必须在第 3 列"、"必须放在中央"）
  不满足则不能放置
```

这需要新增 `IPlacementValidator` 接口或直接在 `CheckPlacementConditions()` 中遍历 behaviors。

---

## 📊 总览表

| 包名 | 类型 | Block 数 | 稀有度分布 | 核心机制 | 复杂度 |
|------|------|----------|------------|----------|--------|
| 铁锈游侠 | 主卡包 | ~33 | 普通 18 / 稀有 10 / 史诗 4 / 传说 1 | 回收、锈蚀、过载 | ⭐⭐ |
| 星语术士 | 主卡包 | ~32 | 普通 16 / 稀有 10 / 史诗 5 / 传说 1 | 共鸣、星涌、法阵 | ⭐⭐⭐ |
| 翠绿哨兵 | 主卡包 | ~30 | 普通 15 / 稀有 11 / 史诗 4 / 传说 0 | 扎根、藤蔓、共生 | ⭐⭐ |
| 紧急补给 | 小卡包 | 10 | 普通 7 / 稀有 3 / 史诗 0 / 传说 0 | 治疗、防御 | ⭐ |
| 废品爆破 | 小卡包 | 10 | 普通 4 / 稀有 4 / 史诗 2 / 传说 0 | AOE、爆炸 | ⭐⭐ |
| 暗网契约 | 小卡包 | 10 | 普通 3 / 稀有 4 / 史诗 3 / 传说 0 | 高风险高回报 | ⭐⭐ |
| 精密传动 | 小卡包 | 10 | 普通 4 / 稀有 4 / 史诗 1 / 传说 1 | 方向控制、精准 | ⭐⭐⭐ |
| 星尘余烬 | 小卡包 | 10 | 普通 4 / 稀有 3 / 史诗 2 / 传说 1 | 随机、Stat 交互 | ⭐⭐ |
