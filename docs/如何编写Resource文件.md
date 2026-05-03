# Grid & Groves — Resource 文件编写指南

本文档介绍项目中所有继承自 Godot `Resource` 的 C# 类型以及对应的 `.tres` 数据文件如何编写。

---

## 目录

1. [什么是 Resource？](#1-什么是-resource)
2. [编写一个新的 Resource 类型](#2-编写一个新的-resource-类型)
3. [Resource 一览](#3-resource-一览)
4. [创建 .tres 实例文件](#4-创建-tres-实例文件)
5. [SubResource 与 ExtResource](#5-subresource-与-extresource)
6. [编写 Behavior（行为）子类](#6-编写-behavior行为子类)
7. [Enum 与 Resource 配合](#7-enum-与-resource-配合)

---

## 1. 什么是 Resource？

Godot 的 `Resource` 是引擎内置的数据容器，支持序列化（存为 `.tres`/`.res`）、在编辑器中可视化编辑、复制时独立实例化。

在 C# 中定义一个 Resource 类：

```csharp
using Godot;

[GlobalClass]
public partial class MyResource : Resource {
    [Export] public string MyField;
}
```

- **必须加 `[GlobalClass]`** 才能在编辑器「新建资源」对话框中看到。
- **必须 `public partial class`**。
- **字段用 `[Export]`** 暴露给编辑器。

---

## 2. 编写一个新的 Resource 类型

### 步骤

1. 在 `resources/` 下新建 `.cs` 文件（如 `MyNewDef.cs`）。
2. 继承 `Resource`，加 `[GlobalClass]`，字段加 `[Export]`。
3. 引用其他 Resource 时直接声明类型：

```csharp
using Godot;

[GlobalClass]
public partial class MyNewDef : Resource {
    [Export] public string Name;
    [Export] public int Value = 10;            // 默认值
    [Export] public SomeOtherDef LinkedDef;    // 引用另一个 Resource
    [Export] public SomeOtherDef[] DefList;    // 数组
}
```

---

## 3. Resource 一览

### 3.1 数据持久化 — DataResource

| 字段 | 类型 | 用途 |
|---|---|---|
| `PlayerCurrentHealth` | `int` | 玩家当前血量 |
| `PlayerMaxHealth` | `int` | 玩家最大血量 |
| `PlayerDeckBlockNames` | `string[]` | 牌组中的 Block 名称列表 |
| `PlayerStatNames` | `string[]` | 玩家属性名称 |
| `PlayerStatValues` | `int[]` | 玩家属性值 |
| `StageCount` | `int` | 当前层数 |
| `RoomCount` | `int` | 当前房间数 |
| `GridClickable` | `int[]` | 可点击格子 |
| `GridLeft` | `int[]` | 剩余格子 |
| `StageDefPath` | `string` | 当前层的 StageDef 路径 |
| `Seed` | `int` | 随机种子 |
| `各种 RandUsage` | `int` | 各随机流已使用次数 |

> 这是一个**存档用** Resource，由代码读写，一般不需要手动创建 `.tres`。

---

### 3.2 关卡定义 — StageDef

| 字段 | 类型 | 用途 |
|---|---|---|
| `StageEnemyChart` | `StageEnemyChartDef` | 本层敌人配置表 |
| `StageEventRand` | `EventRand` | 本层随机事件池 |

```
resources/
  EgStageDef.tres ───── StageDef 示例
  EgStageEnemyChart.tres ── StageEnemyChartDef 示例
```

---

### 3.3 敌人配置表 — StageEnemyChartDef

| 字段 | 类型 | 用途 |
|---|---|---|
| `WeakEnemyChart` | `EnemyChartDef[]` | 普通弱敌池 |
| `StrongEnemyChart` | `EnemyChartDef[]` | 普通强敌池 |
| `EliteChart` | `EnemyChartDef[]` | 精英敌池 |
| `BossChart` | `EnemyChartDef[]` | BOSS 敌池 |

> 每个 Chart 是一个 `EnemyChartDef`，里面是 `EnemyDefinition[]`。

---

### 3.4 敌人图鉴 — EnemyChartDef

| 字段 | 类型 | 用途 |
|---|---|---|
| `EnemyDefs` | `EnemyDefinition[]` | 此 Chart 包含的敌人定义 |

---

### 3.5 敌人定义 — EnemyDefinition

| 字段 | 类型 | 用途 |
|---|---|---|
| `EnemyName` | `string` | 敌人名称 |
| `MaxHealth` | `int` | 最大血量（默认 50） |
| `AttackDamage` | `int` | 攻击力（默认 10） |
| `Image` | `Texture2D` | 敌人贴图 |
| `IntentCycle` | `IntentDefinition[]` | 行动循环（每回合按顺序执行） |
| `InitialStats` | `StatDef[]` | 初始属性 |

**示例 `.tres`** (`resources/enemy_defs/Gonh.tres`)：

```
[gd_resource type="Resource" script_class="EnemyDefinition" format=3]

[ext_resource type="Script" path="res://resources/EnemyDefinition.cs" id="1"]
[ext_resource type="Resource" path="res://resources/enemy_intents/PlaceAttackAtCenter.tres" id="2"]
[ext_resource type="Texture2D" path="res://resources/enemy_images/Gonh.png" id="3"]

[resource]
script = ExtResource("1")
EnemyName = "Gonh"
MaxHealth = 30
AttackDamage = 5
Image = ExtResource("3")
IntentCycle = Array[Object]([ExtResource("2")])
InitialStats = Array[Object]([/* StatDef 引用 */])
```

---

### 3.6 行动意图 — IntentDefinition

| 字段 | 类型 | 用途 |
|---|---|---|
| `IntentName` | `string` | 意图名称 |
| `RepeatCount` | `int` | 重复次数（默认 1） |
| `BlockPlacements` | `BlockPlacementDef[]` | 要放置的方块组 |

**示例 `.tres`** (`resources/enemy_intents/PlaceAttackAtCenter.tres`)：

```
[gd_resource type="Resource" script_class="IntentDefinition" format=3]

[ext_resource type="Resource" path="res://resources/blockdefs/EnemyAttackBlock.tres" id="1"]
[ext_resource type="Script" path="res://resources/IntentDefinition.cs" id="2"]
[ext_resource type="Script" path="res://resources/BlockPlacementDef.cs" id="3"]

[sub_resource type="Resource" id="Place_1"]
script = ExtResource("3")
Block = ExtResource("1")
GridPosition = Vector2i(2, 2)

[resource]
script = ExtResource("2")
BlockPlacements = Array[Object]([SubResource("Place_1")])
IntentName = "PlaceAttackAtCenter"
RepeatCount = 2
```

---

### 3.7 方块放置点 — BlockPlacementDef

| 字段 | 类型 | 用途 |
|---|---|---|
| `Block` | `BlockDef` | 要放置的方块 |
| `GridPosition` | `Vector2I` | 网格位置 |
| `RandomOffsetRange` | `int` | 随机偏移范围（默认 1） |

---

### 3.8 方块定义 — BlockDef

| 字段 | 类型 | 用途 |
|---|---|---|
| `BlockName` | `string` | 方块名称 |
| `Description` | `string` | 描述 |
| `PartDefinitions` | `BlockPartDef[]` | 组成方块的部件 |

---

### 3.9 方块部件定义 — BlockPartDef

| 字段 | 类型 | 用途 |
|---|---|---|
| `PartId` | `string` | 部件 ID |
| `Description` | `string` | 描述 |
| `BaseDamage` | `int` | 基础伤害 |
| `BaseShield` | `int` | 基础护盾 |
| `BaseMagicNum` | `int` | 基础魔法值 |
| `MovingDirection` | `Vector2I` | 移动方向 |
| `PartialPosition` | `Vector2` | 局部位置 |
| `SpriteTexture` | `Texture2D` | 贴图 |
| `Behaviors` | `BlockPartBehavior[]` | 行为列表 |

---

### 3.10 方块部件行为 — BlockPartBehavior（abstract）

```csharp
[GlobalClass]
public abstract partial class BlockPartBehavior : Resource {
    public abstract void Execute(Block block, BlockPart part);
}
```

**编写步骤：**

1. 在 `resources/blockpart_behaviors/` 下新建 `.cs`。
2. 继承 `BlockPartBehavior`。
3. 实现 `Execute` 方法。
4. 加 `[GlobalClass]`。

**示例** (`DamageEnemyBehavior.cs`)：

```csharp
[GlobalClass]
public partial class DamageEnemyBehavior : BlockPartBehavior {
    public override void Execute(Block block, BlockPart part) {
        var damage = part.Damage;
        var enemies = block.GetTree().GetNodesInGroup("Enemies");
        foreach (var node in enemies) {
            if (node is not Node2D enemy) continue;
            var health = enemy.GetNode<HealthComponent>("RenderingComponent/HealthComponent");
            health?.TakeDamage(damage);
        }
    }
}
```

然后在 `.tres` 中以 SubResource 引用：

```
[sub_resource type="Resource" id="Resource_behavior"]
script = ExtResource("_DamageEnemyBehaviorScript_")

[resource]
script = ExtResource("_BlockPartDefScript_")
Behaviors = Array[Resource]([SubResource("Resource_behavior")])
```

---

### 3.11 事件 — EventDef

| 字段 | 类型 | 用途 |
|---|---|---|
| `EventDesc` | `string` | 事件描述（支持 BBCode） |
| `Choices` | `EventChoiceDef[]` | 可选选项 |

---

### 3.12 事件选项 — EventChoiceDef

| 字段 | 类型 | 用途 |
|---|---|---|
| `Name` | `string` | 选项名称 |
| `Description` | `string` | 选项描述 |
| `ResultDescription` | `string` | 执行结果描述 |
| `ActionType` | `EventActionType` | 动作类型（enum） |
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
| `PossibleEvents` | `EventDef[]` | 可能触发的随机事件列表 |

---

### 3.14 属性定义 — StatDef

| 字段 | 类型 | 用途 |
|---|---|---|
| `StatName` | `string` | 属性名称 |
| `Description` | `string` | 描述 |
| `MaxValue` | `int` | 最大值 |
| `CanGoNegative` | `bool` | 是否允许负数 |
| `Icon` | `Texture2D` | 图标 |
| `Behavior` | `StatBehavior` | 绑定行为 |

**示例 `.tres`** (`resources/stat_defs/Growing.tres`)：

```
[gd_resource type="Resource" script_class="StatDef" format=3]

[ext_resource type="Script" path="res://stats/StatDef.cs" id="1"]
[ext_resource type="Script" path="res://resources/stat_behaviors/GrowingStatBehavior.cs" id="2"]
[ext_resource type="Texture2D" path="res://resources/stat_images/Growing.png" id="3"]

[sub_resource type="Resource" id="Resource_behavior"]
script = ExtResource("2")

[resource]
script = ExtResource("1")
Behavior = SubResource("Resource_behavior")
Description = "战斗结束时回复 %N% 点生命"
Icon = ExtResource("3")
MaxValue = 12
StatName = "Growing"
```

---

### 3.15 属性行为 — StatBehavior

```csharp
[GlobalClass]
public partial class StatBehavior : Resource {
    // 通过反射调用带 [StatusBehavior] 特性的方法
    public void ExecuteAt(Glob.StatExecuteAt period) { ... }
}
```

**编写步骤：**

1. 在 `resources/stat_behaviors/` 下新建 `.cs`。
2. 继承 `StatBehavior`。
3. 方法上加 `[StatusBehavior(Period = Glob.StatExecuteAt.XXX)]`。

**示例** (`GrowingStatBehavior.cs`)：

```csharp
public partial class GrowingStatBehavior : StatBehavior {
    [StatusBehavior(Period = Glob.StatExecuteAt.OnBattleEnded)]
    public void HealPlayer() {
        var stat = BelongingStat;
        var tree = stat.GetTree();
        var players = tree.GetNodesInGroup("Players");
        foreach (var node in players) {
            if (node is not Node2D player) continue;
            var health = player.GetNode<HealthComponent>("RenderingComponent/HealthComponent");
            health?.Heal(12);
        }
    }
}
```

**支持的执行时机** (`Glob.StatExecuteAt`)：
- `OnBattleEnded` — 战斗结束
- 其他值见 `Glob.StatExecuteAt` 枚举定义。

---

## 4. 创建 .tres 实例文件

### 方法一：Godot 编辑器（推荐）

1. 在 `FileSystem` 面板右键 → `New Resource...`。
2. 选择你的 `[GlobalClass]` 类型。
3. 保存到对应的子目录（如 `resources/enemy_defs/`）。
4. 在 Inspector 中填充字段。

### 方法二：手写 .tres

格式示例：

```
[gd_resource type="Resource" script_class="YourClassName" format=3]

[ext_resource type="Script" path="res://path/to/YourClass.cs" id="1"]

[resource]
script = ExtResource("1")
FieldName = value
ArrayField = Array[Type]([item1, item2])
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
    public override void Execute(Block block, BlockPart part) {
        // block:  所属的方块实例
        // part:   所属的部件实例
        // 通过 block.GetTree() 访问场景
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
├── BlockPlacementDef.cs      # 方块放置点
├── IntentDefinition.cs       # 行动意图
│
├── blockdefs/                # BlockDef .tres
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
