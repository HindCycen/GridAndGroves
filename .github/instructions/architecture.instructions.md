---
description: "Grid and Groves 项目架构详细说明。Use when: 需要理解项目架构、系统间关系、代码组织方式、设计模式"
applyTo: "**/*.gd"
---

# Grid and Groves 架构说明

## 核心架构原则

1. **动作队列调度**: 所有效果通过 `AbstractGameAction` 入队到 `ActionManager` 异步执行，而非直接函数调用
2. **三段式 TicTac**: 每个 Bot tick 分为 PreBlockExecute → BlockExecute → PostBlockExecute 三个阶段
3. **信号驱动**: `BattleTime` 作为事件总线，发出信号触发 `StatBehavior` 的钩子方法
4. **Resource 链**: BlockDef → BlockPartDef → BlockPartBehavior 三级引用
5. **JSON 扫描注册**: BlockDef 数据集中在 `block_defs.json`，由 `JsonBlockScanner` 运行时扫描注册

## Autoload 单例

| Autoload | 文件 | 职责 |
|----------|------|------|
| BlockRegistry | `global/BlockRegistry.gd` | 方块注册与创建 |
| PackManager | `global/PackManager.gd` | 卡包注册与卡池构建 |
| BattleTime | `global/BattleTime.gd` | 战斗信号总线，StatBehavior 触发器 |
| SaveLoad | `global/SaveLoad.gd` | 存档读写 |
| GridState | `global/GridState.gd` | 网格状态管理 |
| RngManager | `global/RngManager.gd` | 随机数管理 |

## 动作系统 (actions/)

`AbstractGameAction` 是基类，所有动作通过 `ActionManager` 调度：
- `ActionManager.add_to_bottom(action)` — 追加到队尾
- `ActionManager.add_to_top(action)` — 插入到队首
- `action._update(delta)` — 每帧调用，完成后置 `is_done = true`

## Bot 巡逻管线 (room/Bot.gd)

每个 tick（1 秒）：
1. `say_pre_block_execute()` — Phase A: 修饰器
2. `move_to_next_cell()` — 移动到下一格，遇到 Block 时 `enqueue_block_actions()`
3. `say_post_block_execute()` — Phase C: 触发类效果
4. 到边界时 `end_turn()` → 敌人行动

## StatBehavior 系统 (stats/)

- 继承 `StatBehavior`，在方法上加 `## @period OnTurnEnded` 标记触发时机
- `BattleTime` 在发出信号时扫描所有 "stats" 组中的 Stat 节点
- `StatBehavior.execute_at(period)` 通过方法名匹配调用

## 注册机制

- BlockDef 通过 `JsonBlockScanner.scan_and_register()` 从 `resources/block_defs.json` 注册
- 卡包通过 `PackManager.subscribe_block_pack()` / `subscribe_mini_pack()` 注册
- `BlockRegistry._ready()` 自动调用 `auto_register_blocks()` → 触发 JSON 扫描
- `OriginalBlockRegisterer.register()` 也被 JSON 扫描器替代

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
