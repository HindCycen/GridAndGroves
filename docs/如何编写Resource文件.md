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

| 字段 | 类型 GDScript | 用途 |
|---|---|---|
| `PlayerCurrentHealth` | `int` | 玩家当前血量 |
| `PlayerMaxHealth` | `int` | 玩家最大血量 |
| `PlayerDeckBlockNames` | `Array[String]` | 牌组中的 Block 名称列表 |
| `PlayerStatNames` | `Array[String]` | 玩家属性名称 |
| `PlayerStatValues` | `Array[int]` | 玩家属性值 |
| `StageCount` | `int` | 当前层数 |
| `RoomCount` | `int` | 当前房间数 |
| `GridClickable` | `Array[int]` | 可点击格子 |
| `GridLeft` | `Array[int]` | 剩余格子 |
| `StageDefPath` | `String` | 当前层的 StageDef 路径 |
| `Seed` | `int` | 随机种子 |
| `各种 RandUsage` | `int` | 各随机流已使用次数 |

> 这是一个**存档用** Resource，由代码读写，一般不需要手动创建 `.tres`。

---

### 3.2 关卡定义 — StageDef

| 字段 | 类型 GDScript | 用途 |
|---|---|---|
| `StageEnemyChart` | `Resource` | 本层敌人配置表 |
| `StageEventRand` | `EventRand` | 本层随机事件池 |
| `StartingDeck` | `Array[String]` | 初始牌组 Block 名称列表 |

```
resources/
  EgStageDef.tres ───── StageDef 示例
  EgStageEnemyChart.tres ── StageEnemyChartDef 示例
```

---

### 3.3 敌人配置表 — StageEnemyChartDef

| 字段 | 类型 GDScript | 用途 |
|---|---|---|
| `WeakEnemyChart` | `Array` | 普通弱敌池 |
| `StrongEnemyChart` | `Array` | 普通强敌池 |
| `EliteChart` | `Array` | 精英敌池 |
| `BossChart` | `Array` | BOSS 敌池 |

> 每个 Chart 是一个 `EnemyChartDef`，里面是 `EnemyDefinition[]`。

---

### 3.4 敌人图鉴 — EnemyChartDef

| 字段 | 类型 GDScript | 用途 |
|---|---|---|
| `EnemyDefs` | `Array` | 此 Chart 包含的敌人定义 |

---

### 3.5 敌人定义 — EnemyDefinition

| 字段 | 类型 GDScript | 用途 |
|---|---|---|
| `EnemyName` | `String` | 敌人名称 |
| `MaxHealth` | `int` | 最大血量（默认 50） |
| `AttackDamage` | `int` | 攻击力（默认 10） |
| `EnemyImage` | `Texture2D` | 敌人贴图 |
| `IntentCycle` | `Array` | 行动循环（每回合按顺序执行） |
| `InitialStats` | `Array` | 初始属性 |

**示例 `.tres`** (`resources/enemy_defs/Gonh.tres`)：

```
[gd_resource type="Resource" script_class="EnemyDefinition" format=3]

[ext_resource type="Script" path="res://resources/EnemyDefinition.gd" id="1_define"]
[ext_resource type="Resource" path="res://resources/enemy_intents/PlaceAttackAtCenter.tres" id="2_intent1"]
[ext_resource type="Texture2D" path="res://resources/enemy_images/Gonh.png" id="4_image"]

[resource]
script = ExtResource("1_define")
AttackDamage = 5
EnemyName = "Gonh"
EnemyImage = ExtResource("4_image")
IntentCycle = Array[Object]([ExtResource("2_intent1")])
InitialStats = Array[Object]([ExtResource("5_shooting")])
MaxHealth = 30
```

---

### 3.6 行动意图 — IntentDefinition

| 字段 | 类型 GDScript | 用途 |
|---|---|---|
| `IntentName` | `String` | 意图名称 |
| `RepeatCount` | `int` | 重复次数（默认 1） |
| `BlockPlacements` | `Array` | 要放置的方块组 |

**示例 `.tres`** (`resources/enemy_intents/PlaceAttackAtCenter.tres`)：

```
[gd_resource type="Resource" script_class="IntentDefinition" format=3]

[ext_resource type="Script" path="res://resources/IntentDefinition.gd" id="2_intent"]
[ext_resource type="Script" path="res://resources/BlockPlacementDef.gd" id="3_placement"]
[ext_resource type="Resource" path="res://resources/blockdefs/EnemyAttackBlock.tres" id="4_block"]

[sub_resource type="Resource" id="Place_1"]
script = ExtResource("3_placement")
BlockRef = ExtResource("4_block")
GridPosition = Vector2i(2, 2)

[resource]
script = ExtResource("2_intent")
BlockPlacements = [SubResource("Place_1")]
IntentName = "PlaceAttackAtCenter"
RepeatCount = 2
```

---

### 3.7 方块放置点 — BlockPlacementDef

| 字段 | 类型 GDScript | 用途 |
|---|---|---|
| `BlockRef` | `BlockDef` | 要放置的方块的 BlockDef 引用 |
| `GridPosition` | `Vector2i` | 网格位置 |
| `RandomOffsetRange` | `int` | 随机偏移范围（默认 1） |

---

### 3.8 方块定义 — BlockDef

| 字段 | 类型 GDScript | 用途 |
|---|---|---|
| `BlockName` | `String` | 方块名称 |
| `Description` | `String` | 描述 |
| `PartDefinitions` | `Array` | 组成方块的部件 |

---

### 3.9 方块部件定义 — BlockPartDef

| 字段 | 类型 GDScript | 用途 |
|---|---|---|
| `PartId` | `String` | 部件 ID |
| `Description` | `String` | 描述 |
| `BaseDamage` | `int` | 基础伤害 |
| `BaseShield` | `int` | 基础护盾 |
| `BaseMagicNum` | `int` | 基础魔法值 |
| `MovingDirection` | `Vector2i` | 移动方向 |
| `PartialPosition` | `Vector2` | 局部位置 |
| `SpriteTexture` | `Texture2D` | 贴图 |
| `Behaviors` | `Array` | 行为列表 |

---

### 3.10 方块部件行为 — BlockPartBehavior

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

**示例** (`resources/blockpart_behaviors/DamageEnemyBehavior.gd`)：

```gdscript
class_name DamageEnemyBehavior extends BlockPartBehavior

func create_action(block, part):
    var tree: SceneTree = block.get_tree()
    if tree == null:
        return null
    var targets: Array[Node2D] = []
    for e in tree.get_nodes_in_group("Enemies"):
        if e is Node2D:
            var hc: HealthComponent = e.get_node_or_null("RenderingComponent/HealthComponent") as HealthComponent
            if hc != null and not hc.is_dead:
                targets.append(e)
    if targets.size() == 0:
        return null
    for i in range(1, targets.size()):
        ActionManager.add_to_bottom(DamageAction.new(block, targets[i], part.Damage))
    return DamageAction.new(block, targets[0], part.Damage, 0.4)
```

**注意**：BlockPartBehavior 不需要单独创建 `.tres` 文件。在 JSON 扫描器中通过 `"script"` 路径引用即可自动实例化。

---

### 3.11 事件 — EventDef

| 字段 | 类型 GDScript | 用途 |
|---|---|---|
| `EventDesc` | `String` | 事件描述（支持 BBCode） |
| `Choices` | `Array` | 可选选项 |

---

### 3.12 事件选项 — EventChoiceDef

| 字段 | 类型 GDScript | 用途 |
|---|---|---|
| `Name` | `String` | 选项名称 |
| `Description` | `String` | 选项描述 |
| `ResultDescription` | `String` | 执行结果描述 |
| `ActionType` | `int (EventActionType)` | 动作类型（enum） |
| `ActionValue` | `int` | 动作数值 |

**EventActionType 枚举值：**

| 值 | 名称 | 效果 |
|---|---|---|
| 0 | `None` | 无 |
| 1 | `HealPlayer` | 治疗玩家 |
| 2 | `DamagePlayer` | 伤害玩家 |
| 3 | `AddGold` | 加金币 |
| 4 | `RemoveGold` | 扣金币 |
| 5 | `AddBlockToDeck` | 牌组加入方块 |
| 6 | `RemoveBlockFromDeck` | 牌组移除方块 |

---

### 3.13 随机事件池 — EventRand

| 字段 | 类型 | 用途 |
|---|---|---|
| `PossibleEvents` | `Array` | 可能触发的随机事件列表 |

---

### 3.14 属性定义 — StatDef

| 字段 | 类型 GDScript | 用途 |
|---|---|---|
| `StatName` | `String` | 属性名称 |
| `Description` | `String` | 描述 |
| `MaxValue` | `int` | 最大值 |
| `CanGoNegative` | `bool` | 是否允许负数 |
| `RemoveOnBattleEnd` | `bool` | 战斗结束是否移除 |
| `Icon` | `Texture2D` | 图标 |
| `Behavior` | `StatBehavior` | 绑定行为 |

**示例 `.tres`** (`resources/stat_defs/Growing.tres`)：

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

### 3.15 属性行为 — StatBehavior

```gdscript
class_name StatBehavior extends Resource

## 使用 ## @period OnTurnEnded 标记触发时期
func execute_at(_period: int) -> void:
    pass
```

**编写步骤：**

1. 在 `resources/stat_behaviors/` 下新建 `.gd` 文件。
2. 继承 `StatBehavior`。
3. 在方法上加 `## @period OnXxx` 注释标记触发时机。

**示例** (`GrowingStatBehavior.gd`)：

```gdscript
class_name GrowingStatBehavior extends StatBehavior

## @period OnBattleEnded
func heal_player() -> void:
    var tree: SceneTree = belonging_stat.get_tree()
    var players: Array[Node] = tree.get_nodes_in_group("Players")
    if players.size() > 0:
        var health: HealthComponent = players[0].get_node("RenderingComponent/HealthComponent")
        if health != null:
            health.heal(12)
```

**支持的执行时机**（`BattleTime` 信号触发）：
- `OnBattleStarted` — 战斗开始
- `OnTurnStarted` — 回合开始
- `OnTicTac` — 每个 Bot tick
- `OnPreBlockExecute` — Phase A
- `OnBlockExecute` — Phase B
- `OnPostBlockExecute` — Phase C
- `OnTurnEnded` — 回合结束
- `OnBattleEnded` — 战斗结束
- `OnBeforeDamageApply` — 伤害计算前
- `OnAfterDamageApply` — 伤害计算后

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

### 3.16 卡牌包 — BlockBag

| 字段 | 类型 | 用途 |
|---|---|---|
| `CommonBlocks` | `BlockDef[]` | 普通稀有度卡牌（3 张） |
| `UncommonBlocks` | `BlockDef[]` | 罕见稀有度卡牌（4 张） |
| `RareBlocks` | `BlockDef[]` | 稀有卡牌（3 张） |

> 共 10 个 `BlockDef`，按稀有度从低到高 3/4/3 分布。
> 可通过 `All` 属性获取全部 10 个方块的合并数组。

**示例 `.tres`** (`resources/blockdefs/ExampleBag.tres`)：

```
[gd_resource type="Resource" script_class="BlockBag" format=3]

[ext_resource type="Script" path="res://resources/BlockBag.cs" id="1"]
[ext_resource type="Resource" path="res://resources/blockdefs/DamageBlock.tres" id="2"]
[ext_resource type="Resource" path="res://resources/blockdefs/ExampleBlock.tres" id="3"]

[resource]
script = ExtResource("1")
CommonBlocks = Array[Object]([ExtResource("2"), ExtResource("2"), ExtResource("3")])
UncommonBlocks = Array[Object]([ExtResource("2"), ExtResource("3"), ExtResource("2"), ExtResource("3")])
RareBlocks = Array[Object]([ExtResource("3"), ExtResource("2"), ExtResource("3")])
```

---

## 5. SubResource 与 ExtResource

| 概念 | 用途 | 写法 |
|---|---|---|
| **ExtResource** | 引用 **另一个文件**（.tres 或 .cs） | `ExtResource("id")` |
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

```csharp
[GlobalClass]
public partial class MyBehavior : BlockPartBehavior {
    public override AbstractGameAction CreateAction(Block block, BlockPart part) {
        // block:  所属的方块实例
        // part:   所属的部件实例
        // 返回 AbstractGameAction 子类（如 DamageAction）或 null
        return new DamageAction(block, target, part.Damage, 0.4f);
    }
}
```

### StatBehavior

```csharp
[GlobalClass]
public partial class MyStatBehavior : StatBehavior {
    [StatusBehavior(Period = Glob.StatExecuteAt.OnBattleEnded)]
    public void OnBattleEnd() {
        // 通过 BelongingStat 访问绑定的 Stat 实例
        var stat = BelongingStat;
    }
}
```

---

## 7. Enum 与 Resource 配合

Enum 可以直接写在 Resource 文件下方作为独立枚举：

```csharp
public enum EventActionType {
    None,
    HealPlayer,
    DamagePlayer,
    // ...
}
```

在 `.tres` 中枚举值用整数表示：
```
ActionType = 1    // 对应 HealPlayer
```

---

## 目录结构参考

```
resources/
├── README_如何编写Resource文件.md
├── DataResource.cs           # 存档数据
├── StageDef.cs               # 关卡定义
├── StageEnemyChartDef.cs     # 关卡敌人表
├── EventRand.cs              # 随机事件池
├── EventDef.cs               # 事件定义
├── EventChoiceDef.cs         # 事件选项
├── EnemyDefinition.cs        # 敌人定义
├── EnemyChartDef.cs          # 敌人图鉴
├── BlockBag.cs               # 卡牌包
├── BlockPlacementDef.cs      # 方块放置点
├── IntentDefinition.cs       # 行动意图
│
├── blockdefs/                # BlockDef .tres (含 BlockBag/BigBlockBag)
├── blockparts/               # BlockPartDef .tres
├── blockpart_behaviors/      # BlockPartBehavior .cs
├── blockpart_picture/        # 方块贴图
├── enemy_defs/               # EnemyDefinition .tres
├── enemy_intents/            # IntentDefinition .tres
├── enemy_images/             # 敌人贴图
├── stat_defs/                # StatDef .tres
├── stat_behaviors/           # StatBehavior .cs
└── stat_images/              # 属性图标
```

> **建议**：每种 Resource 类型在 `resources/` 下建一个子目录存放它的 `.tres` 实例文件，保持整洁。
