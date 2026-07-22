# Grid & Groves — Block / Stat 内容制作指南

本文档介绍在 ActionManager + 三段式 TicTac 管线体系下，如何创建完整的游戏内容：方块（Block）、方块部件（BlockPart）、属性（Stat）以及自定义动作（Action）。

---

## 目录

1. [系统概览](#1-系统概览)
2. [制作一个方块](#2-制作一个方块)
3. [制作一个方块部件行为](#3-制作一个方块部件行为)
4. [制作一个属性（Stat）](#4-制作一个属性stat)
5. [制作一个自定义动作](#5-制作一个自定义动作)
6. [制作一个自定义 VFX](#6-制作一个自定义-vfx)
7. [深入：管线时序与钩子](#7-深入管线时序与钩子)
8. [目录参考](#8-目录参考)

---

## 1. 系统概览

### 核心管线

```
回合开始 (TurnStarted)
  ↓
玩家放置方块 (UI)
  ↓
点击 End Turn → Bot.StartPatrol()
  ┌─────────────────────────────────────┐
  │ 每个 Bot tick（1 秒一次）：          │
  │  ① SayPreBlockExecute() ← Phase A   │
  │  ② MoveToNextCell()                 │
  │     └→ 遇到 Block → EnqueueBlockActions() ← Phase B │
  │  ③ SayPostBlockExecute() ← Phase C  │
  │  （检查 _endingTurn，是则跳过③和④） │
  │  ④ ScheduleNextStep()               │
  └─────────────────────────────────────┘
  ↓ Bot 到达网格边界 → EndTurn() → 停止巡逻
  ↓ SayTurnEnded() → 触发 OnTurnEnded 钩子
  ↓ 敌人攻击玩家
  ↓ 检查胜负 → 继续下一回合或结束战斗
```

### 三段式 TicTac 含义

| Phase | 信号 | 对标 StS | 用途 |
|-------|------|----------|------|
| A | `PreBlockExecute` | 打牌前（onPlayCard） | 修饰伤害、扣费、atDamageGive |
| B | `BlockExecute` | 打牌中（card.use） | BlockPart 自身的效果 |
| C | `PostBlockExecute` | 打牌后（onUseCard/onAfterUseCard） | 荆棘反伤、勒脖等效、触发类效果 |

### 三个关键概念

| 概念 | 数据来源 | 作用 |
|------|----------|------|
| **BlockDef** | `resources/block_defs.json` 中的 block 条目 | 方块的元数据（名称、包含哪些 Part） |
| **BlockPartDef** | `resources/block_defs.json` 中的 parts 数组 | 部件定义（伤害值、方向、绑定哪些行为） |
| **BlockPartBehavior** | `resources/blockpart_behaviors/*.gd` | 部件被触发时的实际效果（GDScript） |

### ActionManager — 中央调度器

所有效果不再同步执行，而是转为 `AbstractGameAction` 入队，由 `ActionManager` 每帧推进。

| 入队方式 | 方法 | 效果 |
|----------|------|------|
| 追加到队尾 | `ActionManager.add_to_bottom(action)` | 大多数效果使用 |
| 插入到队首 | `ActionManager.add_to_top(action)` | 紧急效果（如触发类反击） |

> `BlockPartBehavior` 通过 `create_action(block, part)` 方法返回具体 Action 类型，
> 支持动画时长和 VFX。返回 null 表示无需 Action 入队（如纯方向修改行为）。

---

## 2. 制作一个方块

一个方块 = **BlockDef JSON 条目** → 引用若干个 **BlockPartDef 数组条目** → 每个 Part 引用若干个 **BlockPartBehavior (.gd)**。

### 流程概览

```
1. 编写 BlockPartBehavior 代码          → resources/blockpart_behaviors/XXXBehavior.gd
2. 在 block_defs.json 中添加 Block 条目 → resources/block_defs.json
   └→ 在 parts 数组中配置 PartDef 数据
3. 无需创建任何 .tres 文件
4. 重启游戏即可自动注册               → BlockRegistry._ready() → JsonBlockScanner
```

### 2.1 步骤一：编写行为代码（如有需要）

参见[第 3 章](#3-制作一个方块部件行为)。

### 2.2 步骤二：在 JSON 中定义 BlockPartDef

在 `resources/block_defs.json` 的 block 条目的 `parts` 数组中定义部件。每个部件支持以下字段：

| 字段 | 类型 | 用途 |
|------|------|------|
| `partId` | string | 唯一标识（如 `"DamagePart"`） |
| `partId` | string | 唯一标识（如 `"DamagePart"`） |
| `description` | string | 悬停描述，支持 `%D%`(伤害) `%S%`(护盾) `%M%`(魔数) 占位符 |
| `baseDamage` | int | 基础伤害值 |
| `baseShield` | int | 基础护盾值 |
| `baseMagicNum` | int | 基础魔法值 |
| `movingDirection` | int[] | **Bot 触碰到此部件后的巡逻方向**，如 `[0, 1]` |
| `partialPosition` | float[] | 在方块内的相对位置，如 `[0, 1]`（以 96px 为单位） |
| `spriteTexture` | string | 部件贴图的 res:// 路径 |
| `behaviors` | object[] | 绑定到此部件的行为列表 |

#### 关于 movingDirection

| 值 | 含义 |
|----|------|
| `[0, 1]` (默认) | 恢复向下蛇行巡逻 |
| `[1, 0]` | Bot 改为向右移动 |
| `[0, -1]` | Bot 改为向上移动 |
| `[-1, 0]` | Bot 改为向左移动 |

> 不附加转向要求的部件应保留 `movingDirection = [0, 1]`（默认 Down）。

#### 关于 behaviors

`behaviors` 是一个数组，按顺序执行。每个 Behavior 的 `create_action()` 返回的 Action 按数组顺序入队到 `ActionManager`。

```json
"behaviors": [
  { "script": "res://resources/blockpart_behaviors/MoveRightBehavior.gd" },
  { "script": "res://resources/blockpart_behaviors/DamageEnemyBehavior.gd" }
]
```
入队顺序: null (方向修改无 Action), DamageAction(伤害)

### 2.3 步骤三：在 JSON 中定义 BlockDef

在 `resources/block_defs.json` 中添加 block 条目：

```json
{
  "name": "MyBlock",
  "description": "",
  "parts": [
    { "partId": "MyPart", "baseDamage": 6, ... }
  ]
}
```

| JSON 字段 | 类型 | 用途 |
|-----------|------|------|
| `name` | string | 方块名称（唯一标识） |
| `description` | string | 描述文字 |
| `parts` | object[] | 组成此方块的所有部件定义 |

> **注意**：同一个方块可以有多个 Part，每个 Part 的 `partialPosition` 决定了它在方块内的位置。
> 例如 `[0, 0]` 是左上，`[1, 0]` 是右上。

### 2.4 步骤四：自动注册

**无需手动注册**。`BlockRegistry._ready()` 自动调用 `JsonBlockScanner.scan_and_register()`，从 `resources/block_defs.json` 读取所有 BlockDef。

注册后可通过 `BlockRegistry.create_block_by_name("MyBlock")` 在代码中生成实例。

> 如需在 JSON 中引用有参数的 Behavior（如 `GrantPlayerStatBehavior`），使用 `"params"` 字典：
> ```json
> { "script": "res://path/to/GrantPlayerStatBehavior.gd",
>   "params": { "TargetStatDef": "res://path/to/StatDef.tres", "InitialValue": 1 } }
> ```

---

## 3. 制作一个方块部件行为

### 3.1 基本行为（用 `create_action`）

在 `resources/blockpart_behaviors/` 下新建 `.gd` 文件：

```gdscript
class_name MyBehavior extends BlockPartBehavior

func create_action(block, part):
    # 返回一个具体的 Action，用来在队列中异步执行
    return DamageAction.new(block, target_node, part.Damage, 0.4)
```

### 3.2 内置 Action 类型

| Action 类型 | 构造参数 | 效果 |
|-------------|----------|------|
| `DamageAction` | `(Block source, Node target, int amount, float duration)` | 造成伤害，duration 期间播放 VFX |
| `HealAction` | `(Node target, int amount, float duration)` | 治疗，duration 期间播放 VFX |
| `ApplyStatusAction` | `(Node target, StatDef statDef, int initialValue, float duration)` | 给目标施加/增减状态 |
| `CallbackAction` | `(Callable callback, int type = Callback, bool exhaustSourceBlock = false)` | 包装一个同步回调 |
| `WaitAction` | `(float duration)` | 等待一段时间（停顿动作） |
| `VFXAction` | `(Node2D vfxNode, float duration, Node parent = null)` | 播放一个视觉效果后销毁 |

### 3.3 示例：简洁的伤害行为

```gdscript
class_name DamagePlayerBehavior extends BlockPartBehavior

func create_action(block, part):
    var tree: SceneTree = block.get_tree()
    if tree == null:
        return null
    var players: Array[Node] = tree.get_nodes_in_group("Players")
    var target: Node2D = players[0] as Node2D if players.size() > 0 else null
    if target != null and part.Damage > 0:
        return DamageAction.new(block, target, part.Damage, 0.4)
    return null
```

### 3.4 示例：复合效果（用 CallbackAction 包装复杂逻辑）

如果效果无法用单个内置 Action 表达，可以用多个 Action 组合：

```gdscript
func create_action(block, part):
    # 先用一个 WaitAction 等待 0.3s
    ActionManager.add_to_bottom(WaitAction.new(0.3))
    # 再用 CallbackAction 执行复杂逻辑
    return CallbackAction.new(func():
        # 你的复杂逻辑...
    )
```

或直接返回 `CallbackAction` 完成全部操作（无动画延时）：

```gdscript
func create_action(block, part):
    return CallbackAction.new(func():
        # 复杂逻辑直接在这里写
    )
```

---

## 4. 制作一个属性（Stat）

属性 = 状态栏中持久显示的图标，有数值和触发行为。跨战斗保留。

### 4.1 结构

```
StatDef (resources/stat_defs/) ──→ StatBehavior (resources/stat_behaviors/)
  .tres 文件                      .gd 代码
  ├─ StatName                     └─ ## @period OnTurnEnded 标记的方法
  ├─ MaxValue
  ├─ Icon
  └─ Behavior ───→ StatBehavior
```

### 4.2 步骤一：编写 StatBehavior

在 `resources/stat_behaviors/` 下新建 `.gd`：

```gdscript
class_name MyStatBehavior extends StatBehavior

## @period OnTurnEnded
func on_turn_end() -> void:
    var stat = belonging_stat
    if stat == null or stat.CurrentValue <= 0:
        return
    var players: Array[Node] = stat.get_tree().get_nodes_in_group("Players")
    if players.size() > 0:
        var health: HealthComponent = players[0].get_node("RenderingComponent/HealthComponent")
        if health != null:
            health.take_damage(stat.CurrentValue)
```

### 4.3 支持的触发时机

| 时期 | 触发时机 | 对标 StS |
|------|----------|----------|
| `OnBattleStarted` | 战斗开始 | atBattleStart |
| `OnBattleEnded` | 战斗结束 | — |
| `OnTurnStarted` | 回合开始 | atTurnStart |
| `OnTurnEnded` | 回合结束 | atTurnEnd |
| `OnPreBlockExecute` | Phase A：每个 Bot tick 开始时 | onPlayCard |
| `OnBlockExecute` | Phase B：BlockPart 触发时 | card.use |
| `OnPostBlockExecute` | Phase C：BlockPart 触发后 | onUseCard |
| `OnBeforeDamageApply` | DamageAction 扣血前 | atDamageGive |
| `OnAfterDamageApply` | DamageAction 扣血后 | onAttack |
| `OnBeforeBlockApply` | 获得格挡前 | — |
| `OnAfterBlockApply` | 获得格挡后 | — |
| `OnStatusApplied` | 状态被施加时 | onApplyPower |

> **注意**：`OnTurnEnded` 由 Bot.end_turn() 触发，发生在敌人攻击之前。
> `OnBattleEnded` 由 BattleRoom._on_defeat() 或 _on_victory() 触发。

### 4.4 步骤二：创建 StatDef (.tres)

在 Godot 编辑器中右键 `resources/stat_defs/` → **New Resource...** → 选择 `StatDef`。

| 字段 | 类型 | 用途 |
|------|------|------|
| `StatName` | string | 属性名称 |
| `Description` | string | 描述（支持 `%N%` 占位符，运行时替换为数值） |
| `MaxValue` | int | 最大值 |
| `CanGoNegative` | bool | 是否为可负 |
| `Icon` | Texture2D | 状态栏图标 |
| `Behavior` | StatBehavior | 绑定到此属性的行为 |

在 Inspector 中：
1. 设置 `StatName`、`MaxValue`
2. `Behavior` → 下拉选择 **New ShootingStatBehavior**（或从文件加载）
3. 设置 `Icon` 贴图

### 4.5 在代码中施加状态

```gdscript
var stat_def = load("res://resources/stat_defs/MyStat.tres") as StatDef
if stat_def != null:
    var stat := Stat.new()
    stat.Definition = stat_def
    stats_component.add_status(stat)
    stat.add_value(amount) # 设置数值
```

> `StatsComponent.add_status(stat)` 会自动将 `Stat` 节点加入场景树、添加到 "stats" 组，
> 并绑定 `StatBehavior.belonging_stat = stat`。

---

## 5. 制作一个自定义动作

如果内置 Action 无法满足需求，可以继承 `AbstractGameAction`。

### 5.1 基类 API

```gdscript
class_name AbstractGameAction extends RefCounted

var duration: float           # 总时长（秒）
var start_duration: float     # 起始时长
var is_done: bool             # 是否已完成
var amount: int               # 数值
var source: Node              # 动作发出者
var target: Node              # 动作目标
var action_type: int          # 动作类型
var exhaust_source_block: bool # 是否耗尽来源方块

func _update(delta: float) -> void:  # 每帧推进，子类重写
    pass

func tick_duration(delta: float) -> void:  # 推进 duration
    pass
```

### 5.2 示例：自定义动作

```gdscript
class_name MyCustomAction extends AbstractGameAction

var _target: Node
var _has_executed: bool

func _init(target: Node, amount: int, duration: float):
    self.target = target
    self.amount = amount
    self.duration = duration
    start_duration = duration
    action_type = Enums.ActionType.Special

func _update(delta: float) -> void:
    if is_done:
        return
    tick_duration(delta)
    if not is_done:
        return
    if not _has_executed and is_instance_valid(target):
        # 在这里做实际效果
        _has_executed = true
```

### 5.3 入队方式

```gdscript
# 在 Behavior.create_action 或任何代码中：
var action = MyCustomAction.new(target, amount, 0.5)
ActionManager.add_to_bottom(action) # 追加到队尾
# 或
ActionManager.add_to_top(action)    # 插入到队首
```

---

## 7. 深入：管线时序与钩子

### 7.1 一个完整的 Bot Tick

```
OnPatrolTimerTimeout()
  │
  ├─ Phase A: SayPreBlockExecute()
  │     → 触发 OnPreBlockExecute 钩子
  │     → Stat 在此阶段可产生 Action 入队（如加伤修饰）
  │
  ├─ MoveToNextCell()
  │     └─ 遇到方块 → EnqueueBlockActionsAt()
  │         ├─ 同步修改 _currentDirection ← Phase B 方向
  │         ├─ SayBlockExecute()
  │         │    → 触发 OnBlockExecute 钩子
  │         └─ 每个 Behavior.CreateAction() 入队
  │             → DamageAction(0.4s)
  │             → ApplyStatusAction(0.3s)
  │             → 等
  │
  ├─ (如果 _endingTurn，此处 return)
  │
  ├─ Phase C: SayPostBlockExecute()
  │     → 触发 OnPostBlockExecute 钩子
  │     → Stat 在此阶段可产生 Action（如荆棘）
  │
  └─ ScheduleNextStep()
```

**动作时序示例**：连续 10 个 Action 在同一 tick 触发

```
Phase A: Stat X 产生 2 个 Action → addToBottom → 第 1,2 位执行
Phase B: Block 的 3 个 Behavior → addToBottom → 第 3,4,5 位执行
         Action Z 需要优先 → addToTop → 插到第 3 位之前
Phase C: Stat Y 产生 2 个 Action → addToBottom → 第 6,7 位...
```

> `addToTop` 插入到当前队列头部，用于"插队"。
> 但注意：如果当前正在执行的 Action 已经开始，`addToTop` 不会打断它，
> 而是从下一个开始插到前面。

### 7.2 回合边界

```
Bot 到达网格最右列 → EndTurn()
  → SayTurnEnded()          → 触发 OnTurnEnded 钩子（ShootingStat 在此触发）
  → OnBotTurnEnded()        → 敌人攻击（MakeEnemiesAttackPlayer）
  → StartPlayerTurn()       → 下一回合
```

### 7.3 死亡处理

```
玩家 HP ≤ 0
  → HealthComponent 触发 Died 信号
  → BattleRoom.OnPlayerDied()
  → OnDefeat()
    ├─ bot.StopPatrol()       → 停止 Bot 巡逻
    ├─ endTurnButton.Disable  → 禁用操作
    └─ SayBattleEnded()       → 触发 OnBattleEnded 钩子
                              → 状态最后结算（如 GrowingStat 回血）
```

---

## 8. 目录参考

```
resources/
├── block_defs.json          # ★ 所有 BlockDef 的 JSON 描述（注册入口）
├── blockdefs/               # BlockDef .tres（仅保留 EnemyAttackBlock）
├── blockparts/              # BlockPartDef .tres（仅保留 EnemyAttackPart00）
├── blockpart_behaviors/     # BlockPartBehavior .gd
│   ├── DamageEnemyBehavior.gd
│   ├── DamagePlayerBehavior.gd
│   ├── GrantShieldBehavior.gd
│   ├── GrantPlayerStatBehavior.gd   # 带参数的行为
│   ├── GiveGrowingStatBehavior.gd
│   ├── MoveRightBehavior.gd
│   ├── DoNothing.gd
│   └── ExamplePartBehavior.gd
├── blockpart_picture/       # 方块贴图
├── stat_defs/               # StatDef .tres
│   ├── Growing.tres
│   ├── Shooting.tres
│   └── ...
├── stat_behaviors/          # StatBehavior .gd
│   ├── GrowingStatBehavior.gd
│   ├── ShootingStatBehavior.gd
│   └── ...
├── stat_images/             # 属性图标
├── enemy_defs/              # EnemyDefinition .tres
├── enemy_intents/           # IntentDefinition .tres
├── enemy_images/            # 敌人贴图
└── ...
```

### 系统代码目录

```
actions/                     # Action 系统
├── AbstractGameAction.gd    # 动作基类
├── ActionManager.gd         # 中央调度器
├── DamageAction.gd          # 伤害动作（含 VFX）
├── HealAction.gd            # 治疗动作
├── ApplyStatusAction.gd     # 施加状态动作
├── CallbackAction.gd        # 回调包装动作
├── WaitAction.gd            # 等待动作
└── ...

vfx/                         # 视觉效果
├── VFXAction.cs             # VFX 包装动作
├── DamageNumberVFX.cs       # 浮动伤害数字
├── BlockNumberVFX.cs        # 浮动格挡数字
└── ...

room/
├── Bot.cs                   # 巡逻机器人（三段式执行）
├── BattleRoom.cs            # 战斗房间管理
├── EventRoom.cs             # 事件房间
├── StageRoom.cs             # 楼层地图
├── BlockPilesHere.cs        # 方块堆管理
└── ...

global/
├── BattleTime.cs            # 信号中枢（三段式 TicTac）
├── GlobConstants.cs         # 枚举定义（StatExecuteAt / TicTacPhase）
├── Glob.cs                  # Autoload 入口
├── GlobBlockInitializer.cs  # 方块工厂
├── GlobGridControlling.cs   # 网格控制
├── GlobRandSetter.cs        # 随机数管理
├── GlobRegistererExecuter.cs# 自动注册
└── SaveLoad.cs              # 存档系统

blocks/
├── Block.cs                 # 方块实例
├── BlockPart.cs             # 方块部件实例
├── BlockDef.cs              # 方块定义（Resource）
├── BlockPartDef.cs          # 部件定义（Resource）
├── BlockPartBehavior.cs     # 部件行为基类
└── ...

stats/
├── Stat.cs                  # 属性实例
├── StatBehavior.cs          # 属性行为基类
├── StatDef.cs               # 属性定义（Resource）
└── ...
```

---

> **补充阅读**：
> - `docs/如何编写Resource文件.md` — `.tres` 文件格式详解
> - `docs/StageRoom.md` — 楼层内循环系统
> - `stats/STAT_BEHAVIOR_SYSTEM.md` — StatBehavior 系统设计
