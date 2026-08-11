# Grid and Groves

Godot 4.7+ GDScript Roguelike Deckbuilder（类 Slay the Spire）。玩家通过放置方块（Block）到网格上，由 Bot 巡逻触发行事效果，与敌人进行回合制战斗。

## 🚀 快速开始

### 环境要求

- **Godot Engine** 4.7+（标准版即可，无需 .NET）

### 运行项目

1. 使用 Godot 编辑器打开项目根目录
2. 在编辑器中按 **F5** 运行
3. 主菜单选择 **New Game** 开始

## 🏗️ 项目结构

| 目录 | 用途 |
|------|------|
| `actions/` | 动作系统（AbstractGameAction 及其子类） |
| `actors/` | 玩家与敌人（Player, Enemy, ActorSprite） |
| `blocks/` | 方块系统（Block, BlockPart, BlockPartBehavior） |
| `components/` | 可复用组件（Health, Shield, Stats, Pile, Tooltip 等） |
| `global/` | Autoload 单例（见下） |
| `packs/` | 卡包系统（BlockPack, MiniPack, CardPool） |
| `registerers/` | JSON 扫描注册器（JsonBlockScanner, JsonEnemyScanner） |
| `resources/` | Godot Resource 定义、.tres 数据文件、block_defs.json |
| `room/` | 房间系统（StageRoom, BattleRoom, EventRoom, Bot） |
| `stats/` | 属性系统（Stat, StatBehavior, StatDef） |
| `vfx/` | 视觉特效 |
| `docs/` | 中文开发文档 |
| `planning/` | 设计文档（世界观、卡包设计、机制设计） |
| `.github/` | AI 代理与项目指南文件 |

## 🌐 Autoload 单例

| Autoload | 文件 | 职责 |
|----------|------|------|
| GameLog | `global/GameLog.gd` | 日志输出 |
| GridState | `global/GridState.gd` | 网格状态管理 |
| RngManager | `global/RngManager.gd` | 多流随机数管理 |
| BlockRegistry | `global/BlockRegistry.gd` | 方块/敌人注册与创建（JSON 扫描） |
| PackManager | `global/PackManager.gd` | 卡包注册与卡池构建（*尚未接入游戏流程*） |
| BattleTime | `global/BattleTime.gd` | 战斗信号总线，触发 StatBehavior |
| SaveLoad | `global/SaveLoad.gd` | 存档读写与玩家状态恢复 |
| _mcp_game_helper | `addons/godot_ai/runtime/game_helper.gd` | Godot AI 插件运行时（不入库） |

> `ActionManager` 不是 Autoload，而是由 BattleRoom 在战斗场景中创建的运行时节点。

## 📖 文档

- `docs/如何编写Resource文件.md` — Resource 类型和 .tres 文件编写指南
- `docs/如何制作BlockAndStat内容.md` — Block/Stat 内容制作完整指南（含 JSON 注册说明）
- `docs/StageRoom.md` — 楼层内循环系统文档
- `stats/STAT_BEHAVIOR_SYSTEM.md` — StatBehavior 自动执行系统文档（GDScript 实现）
- `planning/card_pack_design/` — 三个主卡包与五个小卡包的完整设计示例

## 🧩 核心架构

- **BlockRegistry** (Autoload): 方块注册与创建，运行时从 `resources/block_defs.json` 扫描注册
- **BattleTime** (Autoload): 战斗事件总线，发出信号触发 `StatBehavior.execute_at()`
- **ActionManager**: 动作队列调度器（战斗场景内节点），每帧推进
- **Bot**: 网格巡逻机器人（每 tick 1 秒），触发 BlockPart 效果
- **Block**: 方块（Node2D），由多个 BlockPart 组成
- **Stat**: 状态节点，通过 `StatBehavior.get_execute_periods()` + `execute_at()` 实现自动触发效果

> 详见 `.github/copilot-instructions.md` 和 `.github/instructions/architecture.instructions.md`
