# Grid and Groves

Godot 4.6 C# Roguelike Deckbuilder（类 Slay the Spire）。玩家通过放置方块（Block）到网格上，由 Bot 巡逻触发行事效果，与敌人进行回合制战斗。

## 🚀 快速开始

### 环境要求

- **Godot Engine** 4.6+（带 .NET 支持）
- **.NET SDK** 8.0+

### 运行项目

1. 使用 Godot 编辑器打开项目根目录
2. 在编辑器中按 **F5** 运行
3. 主菜单选择 **New Game** 开始

### 构建

```bash
dotnet build
```

Godot 编辑器也会在运行前自动构建 C# 项目。

## 🏗️ 项目结构

| 目录 | 用途 |
|------|------|
| `actions/` | 动作系统（AbstractGameAction 及其子类） |
| `blocks/` | 方块系统（Block, BlockPart, BlockDef, BlockPartBehavior） |
| `components/` | 可复用组件（Health, Shield, Stats, Pile, Tooltip 等） |
| `global/` | Autoload 单例（Glob, BattleTime, SaveLoad） |
| `registerers/` | 方块注册器 |
| `resources/` | Godot Resource 定义和 .tres 数据文件 |
| `room/` | 房间系统（StageRoom, BattleRoom, EventRoom, Bot） |
| `stats/` | 属性系统（Stat, StatBehavior, StatDef） |
| `vfx/` | 视觉特效 |
| `docs/` | 中文开发文档 |
| `.github/` | AI 代理自定义文件 |

## 📖 文档

- `docs/如何编写Resource文件.md` — Resource 类型和 .tres 文件编写指南
- `docs/如何制作BlockAndStat内容.md` — Block/Stat 内容制作完整指南
- `docs/StageRoom.md` — 楼层内循环系统文档
- `stats/STAT_BEHAVIOR_SYSTEM.md` — StatBehavior 自动执行系统文档

## 🧩 核心架构

- **Glob** (Autoload): 全局状态、网格控制、随机数、方块注册
- **BattleTime** (Autoload): 战斗事件总线，触发 StatBehavior 钩子
- **ActionManager**: 动作队列调度器，每帧推进
- **Bot**: 网格巡逻机器人，触发 BlockPart 效果
- **Block**: 方块（Node2D），由多个 BlockPart 组成
- **Stat**: 通过 `[StatusBehavior]` 特性实现自动触发的状态效果

> 详见 `.github/copilot-instructions.md` 和 `.github/instructions/architecture.instructions.md`