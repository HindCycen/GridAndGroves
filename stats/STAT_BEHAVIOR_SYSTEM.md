# StatBehavior 自动执行系统

## 概述

本系统实现战斗事件 → StatBehavior 的自动触发机制。当战斗中的特定事件发生（回合开始、回合结束、Block 触发等），所有注册到 "stats" 组的 Stat 节点对应的 Behavior 会自动执行对应时期的方法。

**技术栈**：纯 GDScript（Godot 4.7），无反射、无特性（Attribute）。

## 核心组件

### 1. StatBehavior 基类

**位置**: `stats/StatBehavior.gd`

```gdscript
class_name StatBehavior extends Resource

var belonging_stat: Stat  # 绑定的 Stat 实例（由 Stat._ready 赋值）

func execute_at(_period: int) -> void:
    pass

func get_execute_periods() -> Array[int]:
    return []
```

子类需要：
1. 覆写 `get_execute_periods()` 声明关注的时期（用于文档/自检）
2. 覆写 `execute_at(period)`，用 `match period` 分发处理

**示例**（`resources/stat_behaviors/OverloadStatBehavior.gd`）：

```gdscript
class_name OverloadStatBehavior extends StatBehavior

## 过载计数：OnTurnEnded 清零
func get_execute_periods() -> Array[int]:
	return [Enums.StatExecuteAt.OnPostBlockExecute, Enums.StatExecuteAt.OnTurnEnded]

func execute_at(period: int) -> void:
	match period:
		Enums.StatExecuteAt.OnTurnEnded:
			if belonging_stat != null and belonging_stat.CurrentValue > 0:
				belonging_stat.set_value(0)
```

### 2. Stat 节点注册

**位置**: `stats/Stat.gd`

```gdscript
func _ready() -> void:
	CurrentValue = 0
	if Definition != null and Definition.Behavior != null:
		Definition.Behavior.belonging_stat = self
	add_to_group("stats")  # ← 注册到 "stats" 组
```

所有 Stat 节点进入场景树时自动加入 "stats" 组，供 BattleTime 全局查找。

### 3. BattleTime 事件触发器

**位置**: `global/BattleTime.gd`

BattleTime 是 Autoload 信号总线，`_ready()` 时把自身信号连接到内部处理方法：

```gdscript
func _execute_stat_behaviors(period: Enums.StatExecuteAt) -> void:
	var stats := get_tree().get_nodes_in_group("stats")
	for node in stats:
		if node is Stat and node.Definition != null and node.Definition.Behavior != null:
			node.Definition.Behavior.execute_at(period)
```

对外只暴露 `say_xxx()` 触发方法，业务代码不直接调用 `execute_at`：

| 信号 | 触发方法 | 对应时期 |
|------|----------|----------|
| `battle_started` | `say_battle_started()` | `OnBattleStarted` |
| `turn_started` | `say_turn_started()` | `OnTurnStarted` |
| `pre_block_execute` | `say_pre_block_execute()` | `OnPreBlockExecute` |
| `block_execute` | `say_block_execute()` | `OnBlockExecute` |
| `post_block_execute` | `say_post_block_execute()` | `OnPostBlockExecute` |
| `turn_ended` | `say_turn_ended()` | `OnTurnEnded` |
| `battle_ended` | `say_battle_ended()` | `OnBattleEnded` |

### 4. DamageAction 伤害钩子

**位置**: `actions/DamageAction.gd`

伤害相关时期不由 BattleTime 触发，而是在 `DamageAction.update()` 中直接调用：

- `_trigger_before_damage_hooks()` → `OnBeforeDamageApply`（扣血前）
- `_trigger_after_damage_hooks()` → `OnAfterDamageApply`（扣血后）

实现为遍历 "stats_components" 组中所有 StatsComponent 的 Stat，调用其 Behavior 对应时期。

## 已接线的执行时期

| 时期 | 触发来源 | 状态 |
|------|----------|------|
| `OnBattleStarted` | BattleTime（Bot._ready → say_battle_started） | ✅ |
| `OnTurnStarted` | BattleTime（BattleRoom._start_player_turn） | ✅ |
| `OnPreBlockExecute` | BattleTime（Bot 每 tick Phase A） | ✅ |
| `OnBlockExecute` | BattleTime（Bot/ResonanceBot 触发部件时） | ✅ |
| `OnPostBlockExecute` | BattleTime（Bot 每 tick Phase C） | ✅ |
| `OnTurnEnded` | BattleTime（Bot.end_turn） | ✅ |
| `OnBattleEnded` | BattleTime（BattleRoom 胜利/失败） | ✅ |
| `OnBeforeDamageApply` | DamageAction | ✅ |
| `OnAfterDamageApply` | DamageAction | ✅ |
| `OnBeforeBlockApply` / `OnAfterBlockApply` / `OnStatusApplied` | 枚举已定义 | ⚠️ 尚未接线 |

> `Enums.StatExecuteAt` 中的 `OnBeforeBlockApply`、`OnAfterBlockApply`、`OnStatusApplied`
> 目前只是枚举值，尚无触发点。新增接线时在对应逻辑处调用 `Behavior.execute_at(period)` 即可。

## 使用示例：创建自定义 StatBehavior

1. 在 `resources/stat_behaviors/` 下新建 `.gd`，继承 `StatBehavior`：

```gdscript
class_name MyStatBehavior extends StatBehavior

func get_execute_periods() -> Array[int]:
	return [Enums.StatExecuteAt.OnTurnEnded]

func execute_at(period: int) -> void:
	if period != Enums.StatExecuteAt.OnTurnEnded:
		return
	if belonging_stat == null or belonging_stat.CurrentValue <= 0:
		return
	# 在 belonging_stat 上实现效果
	GameLog.debug("MyStatBehavior executed, value = " + str(belonging_stat.CurrentValue))
```

2. 创建/修改 `resources/stat_defs/` 下的 `.tres`（StatDef），`Behavior` 字段指向该脚本。

3. 通过 `StatsComponent.add_status(stat)` 施加状态（自动加入场景树与 "stats" 组）。

## 数据流

```
战斗事件发生（如 Bot.end_turn）
        │
        ▼
BattleTime.say_turn_ended()
        │
        ▼
BattleTime._execute_stat_behaviors(OnTurnEnded)
        │  遍历 "stats" 组
        ▼
每个 Stat.Definition.Behavior.execute_at(OnTurnEnded)
        │
        ▼
子类实现按时期执行效果（match 分发）
```

## 注意事项

1. **Behavior 是共享 Resource**：同一个 `.tres`/JSON 引用的 Behavior 实例可能被多个 Stat 共享
   （`belonging_stat` 会指向最后绑定的 Stat）。多实例场景下避免在 Behavior 中保存实例状态，
   状态应放在 `Stat.CurrentValue` 上。
2. **`belonging_stat` 由 `Stat._ready` 赋值**，Behavior 内使用前判空。
3. **不要在 `execute_at` 中直接修改场景树结构**（如 `queue_free` 遍历中的节点）；
   需要移除 Stat 时通过 `StatsComponent.remove_status()`。
4. 标注 `## @period OnTurnEnded` 只是注释约定（文档用途），实际分发由 `execute_at()` 决定。

## 相关文件清单

| 文件 | 作用 |
|------|------|
| `stats/StatBehavior.gd` | 行为基类 |
| `stats/Stat.gd` | 状态节点（注册到 "stats" 组） |
| `global/BattleTime.gd` | 战斗信号总线 |
| `global/Enums.gd` | `StatExecuteAt` 枚举 |
| `actions/DamageAction.gd` | 伤害钩子（OnBefore/AfterDamageApply） |
| `resources/stat_behaviors/*.gd` | 具体行为实现 |
| `resources/stat_defs/*.tres` | StatDef 数据 |
