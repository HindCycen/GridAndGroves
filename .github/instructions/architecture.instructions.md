---
description: "Grid and Groves 项目架构详细说明。Use when: 需要理解项目架构、系统间关系、代码组织方式、设计模式"
applyTo: "**/*.gd"
---

# Grid and Groves 架构说明

## 核心架构原则

1. **动作队列调度**: 所有效果通过 `AbstractGameAction` 入队到 `ActionManager` 异步执行，而非直接函数调用
2. **三段式 TicTac**: 每个 Bot tick 分为 PreBlockExecute → BlockExecute → PostBlockExecute 三个阶段
3. **信号驱动**: `BattleTime` 作为事件总线，发出信号触发 `StatBehavior` 的钩子方法
4. **JSON 扫描注册**: BlockDef 数据集中在 `block_defs.json`，敌人数据集中在 `enemy_defs.json`，由 JSON 扫描器运行时扫描注册

## Autoload 单例

| Autoload | 文件 | 职责 |
|----------|------|------|
| GameLog | `global/GameLog.gd` | 日志输出 |
| GridState | `global/GridState.gd` | 网格状态管理 |
| RngManager | `global/RngManager.gd` | 多流随机数管理 |
| BlockRegistry | `global/BlockRegistry.gd` | 方块/敌人注册与创建 |
| PackManager | `global/PackManager.gd` | 卡包注册与卡池构建（`_ready` 自动扫描目录；已接入主流程） |
| BattleTime | `global/BattleTime.gd` | 战斗信号总线，StatBehavior 触发器 |
| SaveLoad | `global/SaveLoad.gd` | 存档读写与玩家状态恢复（含金币/卡池/层数/击杀） |

> ⚠️ `ActionManager` 不是 Autoload，而是由 BattleRoom 在战斗场景中创建的运行时节点。

## 动作系统 (actions/)

`AbstractGameAction` 是基类，所有动作通过 `ActionManager` 调度。
`ActionManager` 是战斗场景中的运行时节点（非 Autoload），通过静态变量 `Instance` 访问：
- `ActionManager.Instance.add_to_bottom(action)` — 追加到队尾
- `ActionManager.Instance.add_to_top(action)` — 插入到队首
- `action.update(delta)` — 每帧调用，完成后置 `is_done = true`

## Bot 巡逻管线 (room/Bot.gd)

每个 tick（1 秒）：
1. `say_pre_block_execute()` — Phase A: 修饰器
2. `move_to_next_cell()` — 移动到下一格，遇到 Block 时 `enqueue_block_actions()`
3. `say_post_block_execute()` — Phase C: 触发类效果
4. 到边界时 `end_turn()` → 敌人行动

## StatBehavior 系统 (stats/)

- 继承 `StatBehavior`，覆写 `get_execute_periods()` 声明时期，覆写 `execute_at(period)` 实现效果（内部 `match` 分发）
- `Stat._ready()` 自动加入 "stats" 组；`BattleTime` 发出信号时遍历该组，调用 `Definition.Behavior.execute_at(period)`
- `## @period OnXxx` 注释只是文档约定，不参与分发
- 已接线时期: `OnBattleStarted`, `OnTurnStarted`, `OnPreBlockExecute`, `OnBlockExecute`, `OnPostBlockExecute`, `OnTurnEnded`, `OnBattleEnded`, `OnBeforeDamageApply`, `OnAfterDamageApply`

## 注册机制

- BlockDef 通过 `JsonBlockScanner.scan_and_register()` 从 `resources/block_defs.json` 注册
- 敌人与楼层图表通过 `JsonEnemyScanner.scan_and_register()` 从 `resources/enemy_defs.json` 注册
- `BlockRegistry._ready()` 自动调用 `auto_register_blocks()` / `auto_register_enemies()`
- `registerers/` 下 `AbstractBlockRegisterer` / `OriginalBlockRegisterer` 为历史遗留，`register()` 已无调用方
- 卡包（`PackManager.subscribe_block_pack()` / `subscribe_mini_pack()` / `build_card_pool()`）已接入游戏流程：主菜单选择 → 构建卡池 → 商店/初始牌组消费 → 游戏结束清理

## BlockDef JSON 注册格式

```json
{
  "blocks": [
    {
      "name": "BlockName",
      "description": "",
      "parts": [
        {
          "partId": "PartId",
          "baseDamage": 10,
          "baseShield": 0,
          "description": "Deal %D% damage.",
          "movingDirection": [0, 1],
          "spriteTexture": "res://path/to/texture.png",
          "behaviors": [
            { "script": "res://path/to/Behavior.gd" },
            { "script": "res://path/to/ParamBehavior.gd",
              "params": { "TargetStatDef": "res://path/to/StatDef.tres", "InitialValue": 1 } }
          ]
        }
      ]
    }
  ]
}
```

## 常用模式

- **伤害流程**: `DamageAction._update()` → 触发 BeforeDamage 钩子 → 播放 VFX → `HealthComponent.take_damage()` → 触发 AfterDamage 钩子
- **护盾吸收**: `HealthComponent.take_damage()` 先调 `ShieldComponent.reduce_shield()`，剩余伤害再扣血
- **属性限制**: `Stat.add_value/reduce_value/set_value` 都做范围检查（MaxValue、CanGoNegative）
- **新增 Block**: 只需修改 `block_defs.json` + 新建 Behavior .gd 文件，无需创建任何 .tres
