---
description: "Grid and Groves 项目架构详细说明。Use when: 需要理解项目架构、系统间关系、代码组织方式、设计模式"
applyTo: "**/*.cs"
---

# Grid and Groves 架构说明

## 核心架构原则

1. **动作队列调度**: 所有效果通过 `AbstractGameAction` 入队到 `ActionManager` 异步执行，而非直接函数调用
2. **三段式 TicTac**: 每个 Bot tick 分为 PreBlockExecute → BlockExecute → PostBlockExecute 三个阶段
3. **信号驱动**: `BattleTime` 作为事件总线，发出信号触发 `StatBehavior` 的钩子方法
4. **Resource 链**: BlockDef → BlockPartDef → BlockPartBehavior 三级引用，通过 .tres 文件配置

## Autoload 单例

| Autoload | 文件 | 职责 |
|----------|------|------|
| Glob | `global/Glob.cs` + 分部类 | 全局状态、网格、随机数、方块注册 |
| BattleTime | `global/BattleTime.cs` | 战斗信号总线，StatBehavior 触发器 |
| SaveLoad | `global/SaveLoad.cs` | 存档读写 |

## 动作系统 (actions/)

`AbstractGameAction` 是基类，所有动作通过 `ActionManager` 调度：
- `ActionManager.Instance.AddToBottom(action)` — 追加到队尾
- `ActionManager.Instance.AddToTop(action)` — 插入到队首
- `action.Update(delta)` — 每帧调用，完成后置 `IsDone = true`

## Bot 巡逻管线 (room/Bot.cs)

每个 tick（1 秒）：
1. `SayPreBlockExecute()` — Phase A: 修饰器
2. `MoveToNextCell()` — 移动到下一格，遇到 Block 时 `EnqueueBlockActions()`
3. `SayPostBlockExecute()` — Phase C: 触发类效果
4. 到边界时 `EndTurn()` → 敌人行动

## StatBehavior 系统 (stats/)

- 继承 `StatBehavior`，用 `[StatusBehavior(Period = Glob.StatExecuteAt.OnXxx)]` 标记方法
- `BattleTime` 在发出信号时扫描所有 "stats" 组中的 Stat 节点
- `StatBehavior.ExecuteAt(period)` 通过反射调用匹配的方法

## 注册机制

- 方块注册器实现 `AbstractBlockRegisterer`，加 `[BlockRegisterer]` 特性
- `Glob.AutoRegisterBlocks()` 在 `_Ready()` 中自动扫描并调用所有注册器
- `OriginalBlockRegisterer` 注册了 6 个基础方块

## 常用模式

- **伤害流程**: `DamageAction.Update()` → TriggerBeforeDamageHooks → PlayDamageVFX → HealthComponent.TakeDamage() → TriggerAfterDamageHooks
- **护盾吸收**: `HealthComponent.TakeDamage()` 先调 `ShieldComponent.ReduceShield()`，剩余伤害再扣血
- **属性限制**: `Stat.AddValue/ReduceValue/SetValue` 都做范围检查（MaxValue、CanGoNegative）
