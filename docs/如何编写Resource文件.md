# Grid & Groves — Resource 文件编写指南

本文档介绍项目中所有继承自 Godot `Resource` 的类型以及对应的 `.tres` 数据文件如何编写。

---

## 目录

1. [什么是 Resource？](#1-什么是-resource)
2. [编写一个新的 Resource 类型](#2-编写一个新的-resource-类型)
3. [Resource 一览](#3-resource-一览)
4. [创建 .tres 实例文件](#4-创建-tres-实例文件)
5. [SubResource 与 ExtResource](#5-subresource-与-extresource)
6. [编写 Behavior（行为）子类](#6-编写-behavior行为子类)
7. [Enum 与 Resource 配合](#7-enum-与-resource-配合)
8. [BlockDef 注册：JSON 扫描](#8-blockdef-注册json-扫描)
9. [Behavior 参数支持](#9-behavior-参数支持)

---

## 1. 什么是 Resource？

Godot 的 `Resource` 是引擎内置的数据容器，支持序列化（存为 `.tres`/`.res`）、在编辑器中可视化编辑、复制时独立实例化。

在 GDScript 中定义一个 Resource 类：

```gdscript
class_name MyResource extends Resource

@export var my_field: String
```

- **必须加 `class_name`** 才能在编辑器「新建资源」对话框中看到。
- **字段用 `@export`** 暴露给编辑器。

---

## 2. 编写一个新的 Resource 类型

### 步骤

1. 在合适的目录下新建 `.gd` 文件（如 `resources/MyNewDef.gd`）。
2. 第一行 `class_name MyNewDef extends Resource`，字段加 `@export`。
3. 引用其他 Resource 时直接声明类型：

```gdscript
class_name MyNewDef extends Resource

@export var name: String
@export var value: int = 10            # 默认值
@export var linked_def: Resource       # 引用另一个 Resource
@export var def_list: Array[Resource]  # 数组
```

---

## 3. Resource 一览

### 3.1 数据持久化 — DataResource

**位置**: `resources/DataResource.gd`

| 字段 | 类型 GDScript | 用途 |
|---|---|---|
| `PlayerCurrentHealth` | `int` | 玩家当前血量 |
| `PlayerMaxHealth` | `int` | 玩家最大血量 |
| `PlayerDeckBlockNames` | `Array[String]` | 牌组中的 Block 名称列表 |
| `PlayerStatNames` | `Array[String]` | 玩家属性名称 |
| `PlayerStatValues` | `Array[int]` | 玩家属性值 |
| `StageCount` | `int` | 当前层数 |
| `RoomCount` | `int` | 当前房间数 |
| `GridClickable` / `GridLeft` / `GridIsBattleCell` | `Array[int]` | 地图格子状态 |
| `StageDefPath` | `String` | 当前层的 StageDef 路径 |
| `LastNonStageRoomType` | `int` | 上一个非地图房间类型（0=None, 1=Battle, 2=Event） |
| `LastNonStageRoomEnemyNames` / `LastNonStageRoomEventDefPath` | - | 返回上一房间所需信息 |
| `Seed` | `int` | 随机种子 |
| `各种 RandUsage` | `int` | 各随机流已使用次数 |

> 这是一个**存档用** Resource，由代码读写，一般不需要手动创建 `.tres`。

---

### 3.2 关卡定义 — StageDef

**位置**: `resources/StageDef.gd`

| 字段 | 类型 GDScript | 用途 |
|---|---|---|
| `StageEventRand` | `EventRand` | 本层随机事件池 |
| `StartingDeck` | `Array[String]` | 初始牌组 Block 名称列表 |

```
resources/
  EgStageDef.tres ───── StageDef 示例
```

> ⚠️ 敌人配置由 `resources/enemy_defs.json` 的 `stageCharts` 字段驱动
> （`StageRoom._build_enemy_chart_for_room` 按房间序号从 JSON 选图表）。

---

### 3.4 敌人图鉴 — EnemyChartDef

**位置**: `resources/EnemyChartDef.gd`

| 字段 | 类型 GDScript | 用途 |
|---|---|---|
| `EnemyDefs` | `Array` | 此 Chart 包含的敌人定义 |

> 运行时由 `EnemyChartDef.new()` 构建（如 `Room._navigate_to_previous_battle`），
> 或由 `StageRoom._build_enemy_chart_for_room` 从 JSON 图表生成。

---

### 3.5 敌人定义 — EnemyDefinition

**位置**: `resources/EnemyDefinition.gd`

| 字段 | 类型 GDScript | 用途 |
|---|---|---|
| `EnemyName` | `String` | 敌人名称 |
| `MaxHealth` | `int` | 最大血量（默认 50） |
| `AttackDamage` | `int` | 攻击力（默认 10） |
| `EnemyImage` | `Texture2D` | 敌人贴图（192×192 单帧，或 384×192 双帧 spritesheet） |
| `IntentCycle` | `Array` | 行动循环（每回合按顺序执行） |
| `InitialStats` | `Array` | 初始属性 |
| `InitialStatValues` | `Array[int]` | 与 `InitialStats` 平行的初始数值（JSON 字段 `initialStatValues`，缺省用 StatDef.MaxValue） |

> ⚠️ 敌人注册已改为 JSON 方案：`resources/enemy_defs.json` → `JsonEnemyScanner`。
> 旧的 `.tres`（`resources/enemy_defs/Gonh.tres`）不再被加载，仅作为格式参考保留。

**JSON 示例**（`resources/enemy_defs.json`，现行方案）：

```json
{
  "enemies": [
    {
      "enemyName": "RustHound",
      "maxHealth": 22,
      "attackDamage": 4,
      "enemyImage": "res://resources/enemy_images/RustHound.png",
      "initialStats": ["res://resources/stat_defs/Shooting.tres"],
      "initialStatValues": [5],
      "intentCycle": [
        {
          "intentName": "HoundPounce",
          "repeatCount": 2,
          "blockPlacements": [
            { "blockName": "EnemyAttackBlock", "gridPosition": [5, 1], "randomOffsetRange": 1 }
          ]
        }
      ]
    }
  ],
  "stageCharts": {
    "EgStageDef": {
      "weakCharts": [{ "enemies": ["Gonh"] }],
      "strongCharts": [{ "enemies": ["Gonh", "RustHound"] }],
      "eliteCharts": [{ "enemies": ["RustColossus"] }],
      "bossCharts": [{ "enemies": ["IronWarden"] }]
    }
  }
}
```

> 敌人立绘可用 `python tools/gen_enemy_sprites.py` 生成（详见 `docs/美术管线.md`）；
> 意图图标由 `python tools/gen_intent_icons.py` 按 `intentName` 关键词自动生成。

**示例 `.tres`**（`resources/enemy_defs/Gonh.tres`，旧方案格式参考）：

```
[gd_resource type="Resource" script_class="EnemyDefinition" format=3]

[ext_resource type="Script" path="res://resources/EnemyDefinition.gd" id="1_define"]
[ext_resource type="Resource" path="res://resources/enemy_intents/PlaceAttackAtCenter.tres" id="2_intent1"]
[ext_resource type="Resource" path="res://resources/enemy_intents/PlaceAttackRight.tres" id="3_intent2"]
[ext_resource type="Texture2D" path="res://resources/enemy_images/Gonh.png" id="4_image"]
[ext_resource type="Resource" path="res://resources/stat_defs/Shooting.tres" id="5_shooting"]

[resource]
script = ExtResource("1_define")
AttackDamage = 5
EnemyName = "Gonh"
EnemyImage = ExtResource("4_image")
IntentCycle = Array[Object]([ExtResource("2_intent1"), ExtResource("3_intent2")])
InitialStats = Array[Object]([ExtResource("5_shooting")])
MaxHealth = 30
```

---

### 3.6 行动意图 — IntentDefinition

**位置**: `resources/IntentDefinition.gd`

| 字段 | 类型 GDScript | 用途 |
|---|---|---|
| `IntentName` | `String` | 意图名称 |
| `RepeatCount` | `int` | 重复次数（默认 1） |
| `BlockPlacements` | `Array` | 要放置的方块组 |

**示例 `.tres`**（`resources/enemy_intents/PlaceAttackAtCenter.tres`）：

```
[gd_resource type="Resource" script_class="IntentDefinition" format=3]

[ext_resource type="Script" path="res://resources/IntentDefinition.gd" id="2_intent"]
[ext_resource type="Script" path="res://resources/BlockPlacementDef.gd" id="3_placement"]

[sub_resource type="Resource" id="Place_1"]
script = ExtResource("3_placement")
BlockName = "EnemyAttackBlock"
GridPosition = Vector2i(2, 2)
RandomOffsetRange = 1

[resource]
script = ExtResource("2_intent")
BlockPlacements = [SubResource("Place_1")]
IntentName = "PlaceAttackAtCenter"
RepeatCount = 2
```

---

### 3.7 方块放置点 — BlockPlacementDef

**位置**: `resources/BlockPlacementDef.gd`

| 字段 | 类型 GDScript | 用途 |
|---|---|---|
| `BlockName` | `String` | 要放置的方块**名称**（运行时由 BlockRegistry 按名查找） |
| `GridPosition` | `Vector2i` | 网格位置 |
| `RandomOffsetRange` | `int` | 随机偏移范围（默认 1） |

---

### 3.8 方块定义 / 部件定义 — BlockDef / BlockPartDef

> ⚠️ **不再是 Resource 类**。BlockDef 与 BlockPartDef 的数据集中写在
> `resources/block_defs.json` 中，由 `JsonBlockScanner` 运行时扫描构建。
> 具体格式见第 8 节与 `docs/如何制作BlockAndStat内容.md`。

---

### 3.9 方块部件行为 — BlockPartBehavior

**位置**: `blocks/BlockPartBehavior.gd`

```gdscript
class_name BlockPartBehavior extends Resource

func create_action(_block, _part):
    return null

func prevents_clear() -> bool:
    return false
```

**编写步骤：**

1. 在 `resources/blockpart_behaviors/` 下新建 `.gd` 文件。
2. 第一行 `class_name XxxBehavior extends BlockPartBehavior`。
3. 覆写 `create_action` 方法，返回一个 `AbstractGameAction` 子类（或 `null`）。
4. 如需驻留网格（回合结束不清理），覆写 `prevents_clear()` 返回 `true`（参考 `RootBehavior`）。

**示例**（`resources/blockpart_behaviors/DamageEnemyBehavior.gd`，简化自 `DamageBehavior`）：

```gdscript
class_name DamageEnemyBehavior extends DamageBehavior

func _init() -> void:
	TargetGroup = "Enemies"
```

实际通用实现 `DamageBehavior.create_action`（多目标时其余目标直接追加到队列尾部）：

```gdscript
func create_action(block, part):
	if block == null:
		return null
	var tree: SceneTree = block.get_tree()
	if tree == null:
		return null
	var targets: Array[Node2D] = []
	for node in tree.get_nodes_in_group(TargetGroup):
		if node is Node2D:
			var hc: HealthComponent = node.get_node_or_null("RenderingComponent/HealthComponent") as HealthComponent
			if hc != null and not hc.is_dead:
				targets.append(node)
	if targets.size() == 0:
		return null
	for i in range(1, targets.size()):
		if ActionManager.Instance != null:
			ActionManager.Instance.add_to_bottom(DamageAction.new(block, targets[i], part.Damage))
	return DamageAction.new(block, targets[0], part.Damage, 0.4)
```

> **注意**：`ActionManager` 是战斗场景中的运行时节点（非 Autoload），
> 必须通过 `ActionManager.Instance.add_to_bottom(...)` 访问。
> BlockPartBehavior **不需要**单独创建 `.tres` 文件，在 JSON 扫描器中通过 `"script"` 路径引用即可自动实例化。

---

### 3.10 事件 — EventDef

**位置**: `resources/EventDef.gd`

| 字段 | 类型 GDScript | 用途 |
|---|---|---|
| `EventDesc` | `String` | 事件描述（支持 BBCode） |
| `Choices` | `Array` | 可选选项 |

---

### 3.11 事件选项 — EventChoiceDef

**位置**: `resources/EventChoiceDef.gd`

| 字段 | 类型 GDScript | 用途 |
|---|---|---|
| `Name` | `String` | 选项名称 |
| `Description` | `String` | 选项描述 |
| `ResultDescription` | `String` | 执行结果描述 |
| `ActionType` | `int (EventActionType)` | 动作类型（enum） |
| `ActionValue` | `int` | 动作数值 |

**EventActionType 枚举值**（`global/Enums.gd`）：

| 值 | 名称 | 效果 | 实现状态 |
|---|---|---|---|
| 0 | `None` | 无 | ✅ |
| 1 | `HealPlayer` | 治疗玩家 | ✅ |
| 2 | `DamagePlayer` | 伤害玩家 | ✅ |
| 3 | `AddGold` | 加金币 | ✅（`EventRoom.gd`） |
| 4 | `RemoveGold` | 扣金币 | ✅（`EventRoom.gd`） |
| 5 | `AddBlockToDeck` | 牌组加入方块 | ✅ |
| 6 | `RemoveBlockFromDeck` | 牌组移除方块 | ✅ |

---

### 3.12 随机事件池 — EventRand

**位置**: `resources/EventRand.gd`

| 字段 | 类型 | 用途 |
|---|---|---|
| `PossibleEvents` | `Array` | 可能触发的随机事件列表 |

---

### 3.13 属性定义 — StatDef

**位置**: `stats/StatDef.gd`

| 字段 | 类型 GDScript | 用途 |
|---|---|---|
| `StatName` | `String` | 属性名称 |
| `Description` | `String` | 描述（支持 `%N%` 占位符，运行时替换为数值） |
| `MaxValue` | `int` | 最大值 |
| `CanGoNegative` | `bool` | 是否允许负数 |
| `RemoveOnBattleEnd` | `bool` | 战斗结束是否移除 |
| `Icon` | `Texture2D` | 图标 |
| `Behavior` | `StatBehavior` | 绑定行为 |

**示例 `.tres`**（`resources/stat_defs/Growing.tres`）：

```
[gd_resource type="Resource" script_class="StatDef" format=3]

[ext_resource type="Script" path="res://stats/StatDef.gd" id="1_statdef"]
[ext_resource type="Script" path="res://resources/stat_behaviors/GrowingStatBehavior.gd" id="2_growing"]
[ext_resource type="Texture2D" path="res://resources/stat_images/Growing.png" id="3_icon"]

[sub_resource type="Resource" id="Resource_growing"]
script = ExtResource("2_growing")

[resource]
script = ExtResource("1_statdef")
Behavior = SubResource("Resource_growing")
Description = "战斗结束时回复 %N% 点生命"
Icon = ExtResource("3_icon")
MaxValue = 12
StatName = "Growing"
```

---

### 3.14 属性行为 — StatBehavior

**位置**: `stats/StatBehavior.gd`（详见 `stats/STAT_BEHAVIOR_SYSTEM.md`）

```gdscript
class_name StatBehavior extends Resource

var belonging_stat: Stat

func execute_at(_period: int) -> void:
    pass

func get_execute_periods() -> Array[int]:
    return []
```

**编写步骤：**

1. 在 `resources/stat_behaviors/` 下新建 `.gd` 文件。
2. 继承 `StatBehavior`。
3. 覆写 `get_execute_periods()` 声明关注的时期。
4. 覆写 `execute_at(period)`，用 `match period` 实现对应时期的逻辑。

**示例**（`resources/stat_behaviors/GrowingStatBehavior.gd`）：

```gdscript
class_name GrowingStatBehavior extends StatBehavior

func heal_player() -> void:
	var stat := belonging_stat
	if stat == null:
		return
	var tree := stat.get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group("Players"):
		if node is Node2D:
			var player := node as Node2D
			var health: HealthComponent = player.get_node("RenderingComponent/HealthComponent")
			if health != null:
				health.heal(12)

func get_execute_periods() -> Array[int]:
	return [Enums.StatExecuteAt.OnBattleEnded]

func execute_at(period: int) -> void:
	if period == Enums.StatExecuteAt.OnBattleEnded:
		heal_player()
```

**支持的执行时机**（由 `BattleTime` 信号或 `DamageAction` 钩子触发，详见 STAT_BEHAVIOR_SYSTEM.md）：

- `OnBattleStarted` — 战斗开始
- `OnTurnStarted` — 回合开始
- `OnPreBlockExecute` — Phase A
- `OnBlockExecute` — Phase B
- `OnPostBlockExecute` — Phase C
- `OnTurnEnded` — 回合结束
- `OnBattleEnded` — 战斗结束
- `OnBeforeDamageApply` — 伤害计算前
- `OnAfterDamageApply` — 伤害计算后

> ⚠️ `## @period OnXxx` 注释仅为文档约定，实际分发由 `execute_at()` 决定。

---

### 3.15 卡牌包 — BlockPack / MiniPack / CardPool

**位置**: `packs/`

| 类 | 类型 | 用途 |
|---|---|---|
| `BlockPack` | `Resource` | 主卡包，`PackName` + `BlockNames: Array[String]`，对应角色核心卡池 |
| `MiniPack` | `Resource` | 小卡包，`PackName` + `BlockNames: Array[String]`，为每局注入变化 |
| `CardPool` | 运行时类 | 由 1 个主包 + 4 个随机小包合并去重（`MainPack`/`SelectedMiniPacks`） |

> ✅ **当前状态：系统已接入游戏流程**。
> `PackManager._ready()` 自动扫描目录注册卡包；主菜单选择主包后调用
> `build_card_pool()` 构建卡池；`BattleRoom` 初始牌组校验、`ShopRoom` 商品上架
> 均消费 `CurrentCardPool`；战败/通关时调用 `clear_card_pool()`。

---

## 4. 创建 .tres 实例文件

### 方法一：Godot 编辑器（推荐）

1. 在 `FileSystem` 面板右键 → `New Resource...`。
2. 选择你的 `class_name` 类型。
3. 保存到对应的子目录（如 `resources/enemy_defs/`）。
4. 在 Inspector 中填充字段。

### 方法二：手写 .tres

格式示例：

```
[gd_resource type="Resource" script_class="YourClassName" format=3]

[ext_resource type="Script" path="res://path/to/YourClass.gd" id="1"]

[resource]
script = ExtResource("1")
FieldName = value
ArrayField = Array[Type]([item1, item2])
```

> 注意：`ext_resource` 引用脚本时如果项目使用了 UID，Godot 保存时会自动补充
> `uid="uid://..."` 属性；手写时省略也可以按路径解析。

---

## 5. SubResource 与 ExtResource

| 概念 | 用途 | 写法 |
|---|---|---|
| **ExtResource** | 引用 **另一个文件**（.tres 或 .gd） | `ExtResource("id")` |
| **SubResource** | 内联定义**不单独存文件**的 Resource | `[sub_resource type="Resource" id="xxx"]` |

**何时用 SubResource：**
- 该 Resource 只有一处使用，不值得单独存文件（如 `BlockPlacementDef` 永远属于某个 `IntentDefinition`）。

**何时用 ExtResource：**
- 该 Resource 被多处引用（如 `EnemyDefinition` 被多个 Chart 引用）。
- 是 Texture2D、Script 等引擎资源。

---

## 6. 编写 Behavior（行为）子类

所有 Behavior 类都在 `resources/blockpart_behaviors/` 或 `resources/stat_behaviors/` 下。

### BlockPartBehavior

```gdscript
class_name MyBehavior extends BlockPartBehavior

func create_action(block, part):
	# block:  所属的方块实例
	# part:   所属的部件实例
	# 返回 AbstractGameAction 子类（如 DamageAction）或 null
	return DamageAction.new(block, target, part.Damage, 0.4)
```

### StatBehavior

```gdscript
class_name MyStatBehavior extends StatBehavior

func get_execute_periods() -> Array[int]:
	return [Enums.StatExecuteAt.OnTurnEnded]

func execute_at(period: int) -> void:
	if period == Enums.StatExecuteAt.OnTurnEnded:
		# 通过 belonging_stat 访问绑定的 Stat 实例
		GameLog.debug("value = " + str(belonging_stat.CurrentValue))
```

---

## 7. Enum 与 Resource 配合

Enum 写在 `global/Enums.gd`（Autoload 脚本）中，作为全局枚举供所有脚本使用：

```gdscript
enum EventActionType { None, HealPlayer, DamagePlayer, AddGold, RemoveGold, AddBlockToDeck, RemoveBlockFromDeck }
```

在 `.tres` 中枚举值用整数表示：

```
ActionType = 1    # 对应 HealPlayer
```

---

## 目录结构参考

```
resources/
├── block_defs.json          # ★ 所有 BlockDef 的 JSON 描述（注册入口）
├── enemy_defs.json          # ★ 所有敌人定义 + stageCharts（注册入口）
├── DataResource.gd          # 存档数据
├── StageDef.gd              # 关卡定义
├── EventRand.gd             # 随机事件池
├── EventDef.gd              # 事件定义
├── EventChoiceDef.gd        # 事件选项
├── EnemyDefinition.gd       # 敌人定义
├── EnemyChartDef.gd         # 敌人图鉴
├── BlockPlacementDef.gd     # 方块放置点
├── IntentDefinition.gd      # 行动意图
│
├── blockpart_behaviors/     # BlockPartBehavior .gd
├── blockpart_picture/       # 方块贴图
├── enemy_defs/              # EnemyDefinition .tres（旧方案，仅作格式参考）
├── enemy_intents/           # IntentDefinition .tres（旧方案，仅作格式参考）
├── enemy_images/            # 敌人贴图
├── stat_defs/               # StatDef .tres
├── stat_behaviors/          # StatBehavior .gd
└── stat_images/             # 属性图标
```

> **建议**：每种 Resource 类型在 `resources/` 下建一个子目录存放它的 `.tres` 实例文件，保持整洁。
> Block 类内容（新增 Block/Behavior/Stat）请优先阅读 `docs/如何制作BlockAndStat内容.md`。
