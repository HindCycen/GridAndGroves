# Grid and Groves

Godot 4.7+ GDScript Roguelike Deckbuilder（类 Slay the Spire）。玩家通过放置方块（Block）到网格上，由 Bot 巡逻触发行事效果，与敌人进行回合制战斗。

**当前主循环**：主菜单选择主卡包（随机搭配 4 个小卡包构成卡池）→ 楼层地图（战斗/事件格）→ 战斗胜利获得金币 → 战后商店购买/卖出/重掷 → 到达第 3 层击败 Boss → 通关结算（Victory）；中途战败进入 Game Over。

## 🚀 快速开始

### 环境要求

- **Godot Engine** 4.7+（标准版即可，无需 .NET）

### 运行项目

1. 使用 Godot 编辑器打开项目根目录
2. 在编辑器中按 **F5** 运行
3. 主菜单选择 **New Game** → 选择主卡包 → 开始冒险

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
| `resources/` | Godot Resource 定义、.tres 数据文件、block_defs.json / enemy_defs.json |
| `room/` | 房间系统（StageRoom, BattleRoom, EventRoom, ShopRoom, Bot） |
| `stats/` | 属性系统（Stat, StatBehavior, StatDef） |
| `tools/` | 程序化美术生成脚本（部件图/图标/敌人立绘等，Python + Pillow） |
| `vfx/` | 视觉特效 |
| `docs/` | 中文开发文档（含 `美术管线.md`） |
| `planning/` | 设计文档（世界观、卡包设计、机制设计、主循环修补计划） |
| `.github/` | AI 代理与项目指南文件 |

## 🌐 Autoload 单例

| Autoload | 文件 | 职责 |
|----------|------|------|
| GameLog | `global/GameLog.gd` | 日志输出 |
| GridState | `global/GridState.gd` | 网格状态管理 |
| RngManager | `global/RngManager.gd` | 多流随机数管理 |
| BlockRegistry | `global/BlockRegistry.gd` | 方块/敌人注册与创建（JSON 扫描） |
| PackManager | `global/PackManager.gd` | 卡包注册与卡池构建（主菜单选包后构建，游戏结束清理） |
| BattleTime | `global/BattleTime.gd` | 战斗信号总线，触发 StatBehavior |
| SaveLoad | `global/SaveLoad.gd` | 存档读写与玩家状态恢复（含金币/卡池/层数） |
| _mcp_game_helper | `addons/godot_ai/runtime/game_helper.gd` | Godot AI 插件运行时（不入库） |

> `ActionManager` 不是 Autoload，而是由 BattleRoom 在战斗场景中创建的运行时节点。

## 📖 文档

- `docs/如何编写Resource文件.md` — Resource 类型和 .tres 文件编写指南
- `docs/如何制作BlockAndStat内容.md` — Block/Stat 内容制作完整指南（含 JSON 注册说明）
- `docs/StageRoom.md` — 楼层内循环系统文档
- `docs/美术管线.md` — 程序化美术生成管线（工具用法、风格约定、验证方式）
- `stats/STAT_BEHAVIOR_SYSTEM.md` — StatBehavior 自动执行系统文档（GDScript 实现）
- `planning/main-loop-repair-plan.md` — 主循环修补计划与最新进度快照
- `planning/card_pack_design/` — 三个主卡包与五个小卡包的完整设计示例

## 🧩 核心架构

- **BlockRegistry** (Autoload): 方块注册与创建，运行时从 `resources/block_defs.json` 扫描注册
- **PackManager** (Autoload): 卡包注册与卡池构建（`build_card_pool` / `restore_card_pool_from_save` / `clear_card_pool`）
- **BattleTime** (Autoload): 战斗事件总线，发出信号触发 `StatBehavior.execute_at()`
- **ActionManager**: 动作队列调度器（战斗场景内节点），每帧推进
- **Bot**: 网格巡逻机器人（每 tick 1 秒），触发 BlockPart 效果
- **Block**: 方块（Node2D），由多个 BlockPart 组成
- **EnemyBlock**: 敌人通过意图在网格上放置的 `EnemyAttackBlock`（灰色、DamagePlayerBehavior），触发时对玩家造成伤害
- **Stat**: 状态节点，通过 `StatBehavior.get_execute_periods()` + `execute_at()` 实现自动触发效果
- **Victory / GameOver**: 通关与战败结算场景（层数/房间/金币/击杀统计）

> 详见 `.github/copilot-instructions.md` 和 `.github/instructions/architecture.instructions.md`
