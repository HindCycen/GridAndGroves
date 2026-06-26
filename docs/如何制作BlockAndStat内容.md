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

| 概念 | 文件位置 | 作用 |
|------|----------|------|
| **BlockDef** | `resources/blockdefs/` | 方块的元数据（名称、包含哪些 Part） |
| **BlockPartDef** | `resources/blockparts/` | 部件定义（伤害值、方向、绑定哪些行为） |
| **BlockPartBehavior** | `resources/blockpart_behaviors/` | 部件被触发时的实际效果（C# 代码） |

### ActionManager — 中央调度器

所有效果不再同步执行，而是转为 `AbstractGameAction` 入队，由 `ActionManager` 每帧推进。

| 入队方式 | 方法 | 效果 |
|----------|------|------|
| 追加到队尾 | `ActionManager.Instance.AddToBottom(action)` | 大多数效果使用 |
| 插入到队首 | `ActionManager.Instance.AddToTop(action)` | 紧急效果（如触发类反击） |

> `BlockPartBehavior` 通过 `CreateAction(block, part)` 方法返回具体 Action 类型，
> 支持动画时长和 VFX。返回 null 表示无需 Action 入队（如纯方向修改行为）。

---

## 2. 制作一个方块

一个方块 = **BlockDef**（.tres）→ 引用若干个 **BlockPartDef**（.tres）→ 每个 Part 引用若干个 **BlockPartBehavior**（.cs）。

### 流程概览

```
1. 编写 BlockPartBehavior 代码          → resources/blockpart_behaviors/XXXBehavior.cs
2. 在 Godot 编辑器中创建 BlockPartDef    → resources/blockparts/XXXPart.tres
   └→ 配置 Behaviors、BaseDamage、MovingDirection 等
3. 在 Godot 编辑器中创建 BlockDef        → resources/blockdefs/XXXBlock.tres
   └→ 配置 PartDefinitions 数组，引用上一步的 PartDef
4. 在代码中注册该方块                   → 见 GlobBlockInitializer / OriginalBlockRegisterer
```

### 2.1 步骤一：编写行为代码（如有需要）

参见[第 3 章](#3-制作一个方块部件行为)。

### 2.2 步骤二：创建 BlockPartDef (.tres)

在 Godot 编辑器中右键 `resources/blockparts/` → **New Resource...** → 选择 `BlockPartDef`。

| 字段 | 类型 | 用途 |
|------|------|------|
| `PartId` | string | 唯一标识（如 `"DamagePart"`） |
| `Description` | string | 悬停描述，支持 `%D%`(伤害) `%S%`(护盾) `%M%`(魔数) 占位符 |
| `BaseDamage` | int | 基础伤害值（运行时可通过 `part.Damage` 访问） |
| `BaseShield` | int | 基础护盾值 |
| `BaseMagicNum` | int | 基础魔法值 |
| `MovingDirection` | Vector2I | **Bot 触碰到此部件后的巡逻方向** |
| `PartialPosition` | Vector2 | 在方块内的相对位置（以 `96×96` 为单位） |
| `SpriteTexture` | Texture2D | 部件显示的贴图 |
| `Behaviors` | BlockPartBehavior[] | 绑定到此部件的**行为列表** |

#### 关于 MovingDirection

| 值 | 含义 |
|----|------|
| `(0, 1)` (默认) | 恢复向下蛇行巡逻 |
| `(1, 0)` | Bot 改为向右移动 |
| `(0, -1)` | Bot 改为向上移动 |
| `(-1, 0)` | Bot 改为向左移动 |

> 不附加转向要求的部件应保留 `MovingDirection = (0, 1)`（默认 Down）。
> Bot 碰到后会恢复蛇形下降，不再继续原方向。

#### 关于 Behaviors

`Behaviors` 是一个数组，按顺序执行。每个 Behavior 的 `CreateAction()` 返回的 Action 按数组顺序入队到 `ActionManager`。

```
Behaviors = [MoveRightBehavior, DamageEnemyBehavior]
入队顺序: null (方向修改无 Action), DamageAction(伤害)
```

> 用 Godot 编辑器添加时，点 `Behaviors` 右侧的箭头 → `Add Element` → 下拉选择 `New XxxBehavior` 或引用已存文件。

### 2.3 步骤三：创建 BlockDef (.tres)

在 Godot 编辑器中右键 `resources/blockdefs/` → **New Resource...** → 选择 `BlockDef`。

| 字段 | 类型 | 用途 |
|------|------|------|
| `BlockName` | string | 方块名称（显示在 UI 中） |
| `Description` | string | 描述文字 |
| `PartDefinitions` | BlockPartDef[] | 组成此方块的所有部件 |

> **注意**：同一个方块可以有多个 Part，每个 Part 的 `PartialPosition` 决定了它在方块内的位置。
> 例如 `(0, 0)` 是左上，`(1, 0)` 是右上。

### 2.4 步骤四：注册方块

大多数方块在 `OriginalBlockRegisterer.cs` 中使用 `Glob.SubscribeBlockDef()` 注册。

```csharp
// 在 OriginalBlockRegisterer.Register() 中添加：
Glob.SubscribeBlockDef(GD.Load<BlockDef>("res://resources/blockdefs/MyBlock.tres"));
```

注册后可通过 `Glob.CreateBlock("MyBlock")` 在代码中生成实例。

---

## 3. 制作一个方块部件行为

### 3.1 基本行为（用 `CreateAction`）

在 `resources/blockpart_behaviors/` 下新建 `.cs` 文件：

```csharp
using Godot;

[GlobalClass]
public partial class MyBehavior : BlockPartBehavior {
    public override AbstractGameAction CreateAction(Block block, BlockPart part) {
        // 返回一个具体的 Action，用来在队列中异步执行
        return new DamageAction(block, targetNode, part.Damage, 0.4f);
    }
}
```

### 3.2 内置 Action 类型

| Action 类型 | 构造参数 | 效果 |
|-------------|----------|------|
| `DamageAction` | `(Block source, Node target, int amount, float duration)` | 造成伤害，duration 期间播放 VFX |
| `HealAction` | `(Node target, int amount, float duration)` | 治疗，duration 期间播放 VFX |
| `ApplyStatusAction` | `(Node target, StatDef statDef, int initialValue, float duration)` | 给目标施加/增减状态 |
| `CallbackAction` | `(Action callback, ActionType type = Callback, bool exhaustSourceBlock = false)` | 包装一个同步回调 |
| `WaitAction` | `(float duration)` | 等待一段时间（停顿动作） |
| `VFXAction` | `(Node2D vfxNode, float duration, Node parent = null)` | 播放一个视觉效果后销毁 |

### 3.3 示例：简洁的伤害行为

```csharp
[GlobalClass]
public partial class DamagePlayerBehavior : BlockPartBehavior {
    public override AbstractGameAction CreateAction(Block block, BlockPart part) {
        var players = block.GetTree()?.GetNodesInGroup("Players");
        var target = players?.Count > 0 ? players[0] as Node2D : null;
        if (target != null && part.Damage > 0) {
            return new DamageAction(block, target, part.Damage, 0.4f);
        }
        return null;
    }
}
```

### 3.4 示例：复合效果（用 CallbackAction 包装复杂逻辑）

如果效果无法用单个内置 Action 表达，可以用多个 Action 组合：

```csharp
public override AbstractGameAction CreateAction(Block block, BlockPart part) {
    // 先用一个 WaitAction 等待 0.3s
    ActionManager.Instance.AddToBottom(new WaitAction(0.3f));
    // 再用 CallbackAction 执行复杂逻辑
    return new CallbackAction(() => {
        // 你的复杂逻辑...
    });
}
```

或直接返回 `CallbackAction` 完成全部操作（无动画延时）：

```csharp
public override AbstractGameAction CreateAction(Block block, BlockPart part) {
    return new CallbackAction(() => {
        // 复杂逻辑直接在这里写
    });
}
```

---

## 4. 制作一个属性（Stat）

属性 = 状态栏中持久显示的图标，有数值和触发行为。跨战斗保留。

### 4.1 结构

```
StatDef (resources/stat_defs/) ──→ StatBehavior (resources/stat_behaviors/)
  .tres 文件                      .cs 代码
  ├─ StatName                     └─ [StatusBehavior(Period=...)] 标记的方法
  ├─ MaxValue
  ├─ Icon
  └─ Behavior ───→ StatBehavior
```

### 4.2 步骤一：编写 StatBehavior

在 `resources/stat_behaviors/` 下新建 `.cs`：

```csharp
using Godot;

public partial class MyStatBehavior : StatBehavior {
    [StatusBehavior(Period = Glob.StatExecuteAt.OnTurnEnded)]
    public void OnTurnEnd() {
        var stat = BelongingStat;
        if (stat == null || stat.CurrentValue <= 0) return;

        var players = stat.GetTree().GetNodesInGroup("Players");
        foreach (var node in players) {
            if (node is not Node2D player) continue;
            var health = player.GetNode<HealthComponent>(
                "RenderingComponent/HealthComponent"
            );
            health?.TakeDamage(stat.CurrentValue);
        }
    }
}
```

### 4.3 支持的触发时机

所有 `Glob.StatExecuteAt` 枚举值：

| 枚举值 | 触发时机 | 对标 StS |
|--------|----------|----------|
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

> **注意**：`OnTurnEnded` 由 Bot.EndTurn() 触发，发生在敌人攻击之前。
> `OnBattleEnded` 由 BattleRoom.OnDefeat() 或 OnVictory() 触发。

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

```csharp
var statDef = GD.Load<StatDef>("res://resources/stat_defs/MyStat.tres");
if (statDef != null) {
    var stat = new Stat { Definition = statDef };
    statsComponent.AddStatus(stat);
    stat.AddValue(amount); // 设置数值
}
```

> `StatsComponent.AddStatus(stat)` 会自动将 `Stat` 节点加入场景树、添加到 "stats" 组，
> 并绑定 `StatBehavior.SetBelongingStat(stat)`。

---

## 5. 制作一个自定义动作

如果内置 Action 无法满足需求，可以继承 `AbstractGameAction`。

### 5.1 基类 API

```csharp
public abstract class AbstractGameAction {
    public float Duration { get; set; }         // 总时长（秒）
    public float StartDuration { get; protected set; } // 起始时长
    public bool IsDone { get; protected set; }  // 是否已完成
    public int Amount { get; set; }             // 数值
    public Node Source { get; set; }            // 动作发出者
    public Node Target { get; set; }            // 动作目标
    public Glob.ActionType ActionType { get; set; }  // 动作类型
    public virtual bool ExhaustSourceBlock => false; // 是否耗尽来源方块

    // 每帧推进，子类重写
    public abstract void Update(float delta);

    // 推进 Duration，归零时标记 IsDone
    protected void TickDuration(float delta);

    // 快捷入队
    protected void AddToBot(AbstractGameAction action);
    protected void AddToTop(AbstractGameAction action);
}
```

### 5.2 示例：自定义动作

```csharp
using Godot;

public class MyCustomAction : AbstractGameAction {
    private Node _target;
    private bool _hasExecuted;

    public MyCustomAction(Node target, int amount, float duration) {
        Target = target;
        Amount = amount;
        Duration = duration;
        StartDuration = duration;
        ActionType = Glob.ActionType.Special;
    }

    public override void Update(float delta) {
        if (IsDone) return;

        TickDuration(delta);
        if (!IsDone) return;

        // duration 归零 → 执行逻辑
        if (!_hasExecuted && GodotObject.IsInstanceValid(Target)) {
            // 在这里做实际效果
            _hasExecuted = true;
        }
    }
}
```

### 5.3 入队方式

```csharp
// 在 Behavior.CreateAction 或任何代码中：
var action = new MyCustomAction(target, amount, 0.5f);
ActionManager.Instance.AddToBottom(action); // 追加到队尾
// 或
ActionManager.Instance.AddToTop(action);    // 插入到队首
```

---

## 6. 制作一个自定义 VFX

### 6.1 使用 VFXAction

```csharp
// 在 Behavior.CreateAction 或 Action 代码中：
var vfxNode = new MyCoolVFX();
vfxNode.GlobalPosition = target.GlobalPosition;
GetTree().CurrentScene.AddChild(vfxNode); // 添加到场景树
var vfxAction = new VFXAction(vfxNode, 0.5f); // 0.5s 后自动销毁
ActionManager.Instance.AddToBottom(vfxAction);
```

### 6.2 自定义 VFX 节点

继承 `Node2D`，在 `_Process` 中实现动画。

```csharp
using Godot;

public partial class MyCoolVFX : Node2D {
    private float _lifetime = 0.5f;

    public override void _Process(double delta) {
        // 每帧更新位置、透明度、缩放等
        Scale += Vector2.One * (float)delta * 2f;
        Modulate = new Color(1, 1, 1, Modulate.A - (float)delta * 2f);
    }
}
```

> `VFXAction` 会在 duration 结束后调用 `vfxNode.QueueFree()`。

### 6.3 内置 VFX 参考

| VFX | 用途 |
|-----|------|
| `DamageNumberVFX` | 红色浮动数字（上飘 + 淡出） |
| `BlockNumberVFX` | 蓝色浮动数字 |

用法（DamageAction 内部）：

```csharp
if (target is Node2D targetNode) {
    var vfx = new DamageNumberVFX(targetNode.GlobalPosition, amount);
    GetTree().Root.AddChild(vfx);
    AddToBot(new VFXAction(vfx, 0.5f));
}
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
├── blockdefs/               # BlockDef .tres
│   ├── DamageBlock.tres
│   ├── ExampleMoveRight.tres
│   ├── GrowingBlock.tres
│   └── ...
├── blockparts/              # BlockPartDef .tres
│   ├── DamagePart00.tres
│   ├── ExampleMoveRight00.tres
│   ├── GrowingPart00.tres
│   └── ...
├── blockpart_behaviors/     # BlockPartBehavior .cs
│   ├── DamageEnemyBehavior.cs
│   ├── DamagePlayerBehavior.cs
│   ├── MoveRightBehavior.cs
│   ├── GiveGrowingStatBehavior.cs
│   └── ...
├── blockpart_picture/       # 方块贴图
├── stat_defs/               # StatDef .tres
│   ├── Growing.tres
│   ├── Shooting.tres
│   └── ...
├── stat_behaviors/          # StatBehavior .cs
│   ├── GrowingStatBehavior.cs
│   ├── ShootingStatBehavior.cs
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
├── AbstractGameAction.cs    # 动作基类
├── ActionManager.cs         # 中央调度器
├── DamageAction.cs          # 伤害动作（含 VFX）
├── HealAction.cs            # 治疗动作
├── ApplyStatusAction.cs     # 施加状态动作
├── CallbackAction.cs        # 回调包装动作
├── WaitAction.cs            # 等待动作
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
