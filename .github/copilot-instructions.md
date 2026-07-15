# Grid and Groves — 项目指南

## 项目概览

Godot 4.6 C# Roguelike Deckbuilder（类 Slay the Spire）。玩家通过放置方块（Block）到网格上，由 Bot 巡逻触发行事效果，与敌人进行回合制战斗。

## 技术栈

- **引擎**: Godot 4.6+ (C#/.NET 8.0)
- **语言**: C# (Godot.NET.Sdk/4.6.3)
- **架构**: Autoload (Glob, BattleTime, SaveLoad) + 场景树节点

## 代码规范

- **大括号风格**: K&R (同行左大括号) — `csharp_new_line_before_open_brace = none`
- **缩进**: 空格, 4 格
- **using**: 用 `#region`/`#endregion` 包裹，放在文件顶部
- **XML 文档注释**: 所有公共类型和方法都要有 `/// <summary>` 注释（中文）
- **命名**: PascalCase 类/方法，_camelCase 私有字段
- **文件编码**: UTF-8

### 典型文件结构

```csharp
#region

using Godot;
using System.Collections.Generic;

#endregion

/// <summary>
///     简短的中文描述
/// </summary>
public partial class ClassName : Node {
    // 字段 → 属性 → 信号 → _Ready() → 方法
}
```

## 核心架构

### 目录结构

| 目录 | 用途 |
|------|------|
| `actions/` | 动作系统（AbstractGameAction 及其子类） |
| `blocks/` | 方块系统（Block, BlockPart, BlockDef, BlockPartBehavior） |
| `components/` | 可复用组件（Health, Shield, Stats, Pile, Tooltip 等） |
| `global/` | Autoload 单例（Glob, BattleTime, SaveLoad） |
| `registerers/` | 方块注册器（带 `[BlockRegisterer]` 特性） |
| `resources/` | Godot Resource 定义和 .tres 数据文件 |
| `room/` | 房间系统（StageRoom, BattleRoom, EventRoom, Bot） |
| `stats/` | 属性系统（Stat, StatBehavior, StatDef） |
| `vfx/` | 视觉特效 |
| `docs/` | 中文开发文档 |

### 关键类

- **`Glob`** (Autoload): 全局状态、网格控制、随机数、方块注册
- **`BattleTime`** (Autoload): 战斗事件总线（信号系统），触发 StatBehavior 钩子
- **`ActionManager`**: 动作队列调度器，每帧推进
- **`AbstractGameAction`**: 所有动作基类，对标 StS AbstractGameAction
- **`Bot`**: 网格巡逻机器人，触发 BlockPart 效果
- **`Block`**: 方块（Node2D），由多个 BlockPart 组成
- **`BlockPart`**: 方块部件，包含伤害/护盾值和 Behavior
- **`BlockPartBehavior`**: 部件行为基类，返回 AbstractGameAction
- **`Stat`**: 属性节点，通过 StatBehavior 实现自动触发的状态效果
- **`Room`**: 房间基类，被 StageRoom/BattleRoom/EventRoom 继承

### 战斗管线（TicTac 三段式）

```
TurnStarted → 玩家放方块 → End Turn
  → Bot.StartPatrol()
    ┌─ 每个 tick (1秒):
    │  Phase A: PreBlockExecute (修饰器)
    │  Phase B: BlockExecute (BlockPart 自身效果)
    │  Phase C: PostBlockExecute (触发类效果)
    └─
  → Bot 到边界 → TurnEnded → 敌人行动
```

### ActionManager 入队方式

- `AddToBottom(action)` — 追加到队尾（默认）
- `AddToTop(action)` — 插入到队首（紧急效果）

### StatBehavior 系统

- 用 `[StatusBehavior(Period = Glob.StatExecuteAt.OnTurnEnded)]` 特性标记方法
- 继承 `StatBehavior` 的类会被自动扫描
- 支持时期: `OnBattleStarted`, `OnTurnStarted`, `OnTicTac`, `OnTurnEnded`, `OnBattleEnded`, `OnPreBlockExecute`, `OnBlockExecute`, `OnPostBlockExecute`, `OnBeforeDamageApply`, `OnAfterDamageApply`

## 常用命令

- **打开项目**: 用 Godot 4.6+ 打开项目根目录
- **构建**: Godot 编辑器自动构建 C# 项目，或 `dotnet build`
- **运行**: Godot 编辑器中按 F5

## 资源系统

- Resource 类需加 `[GlobalClass]` 和 `public partial class`
- `.tres` 文件在 `resources/` 下按类型分目录
- BlockDef → BlockPartDef → BlockPartBehavior 三级引用链

## 注册机制

- 方块: 在 `OriginalBlockRegisterer.Register()` 中用 `Glob.SubscribeBlockDef()` 注册
- 自动注册: `[BlockRegisterer]` 特性标记的类会被 `AutoRegisterBlocks()` 自动调用
- StatBehavior: 继承 `StatBehavior` 并加 `[StatusBehavior]` 特性标记方法即可

## 文档

- `docs/如何编写Resource文件.md` — Resource 类型和 .tres 文件编写指南
- `docs/如何制作BlockAndStat内容.md` — Block/Stat 内容制作完整指南
- `docs/StageRoom.md` — 楼层内循环系统文档
- `stats/STAT_BEHAVIOR_SYSTEM.md` — StatBehavior 自动执行系统文档
