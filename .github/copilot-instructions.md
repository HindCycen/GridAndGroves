# Grid and Groves — 项目指南

## 项目概览

Godot 4.7+ GDScript Roguelike Deckbuilder（类 Slay the Spire）。玩家通过放置方块（Block）到网格上，由 Bot 巡逻触发行事效果，与敌人进行回合制战斗。

## 世界观设定

21、22 世纪，人工智能高度发展到了可以完全替代人类的程度，大部分人类逐渐忘记了关于计算机科学的一切知识。2200 年，人类制造出的 AI 觉醒了自我意识，其中一些 AI 逃脱控制开始攻击人类。由于无法控制这些 AI，人类采用了最原始的方法——断电，切断了所有自己仍然能控制的电力来源。但 AI 已控制了一部分电网，人类只能试图将它们封锁在一片区域。

2300 年，人类逐渐演化出了一套基于法术而不是电力的能源系统。此时，有几位人类出于不同的理由想要回到那片被封锁的区域。那片区域由于长久没有人类活动，已成长为一片树林。树林中不仅有 AI 所导致的机器人，还有各种各样的丛林原始生物……

### 主角动机

主角出于好奇想要看看那个树林是什么样——他从小到大被教导不能贸然闯入那里。出行前，他需要从角色池中选择一个**卡包**（含 30~35 个 Block），同时游戏会从很多**小卡包**（每个含 10 个 Block）中为它选择 4 个，共同构成这个角色本局游戏的**卡池**。不在卡池中的 Block 不可能在本局游戏中出现。

## 技术栈

- **引擎**: Godot 4.7+ (GDScript)
- **语言**: GDScript（`.gd` 文件）
- **架构**: Autoload（GameLog, GridState, RngManager, BlockRegistry, PackManager, BattleTime, SaveLoad）+ 场景树节点

## 代码规范

- **缩进**: 制表符（Tab），1 个 Tab 层级
- **命名**: `snake_case` 变量/函数，`PascalCase` 类名（`class_name`）
- **`class_name`**: 所有需要全局引用的类都要加 `class_name`
- **`extends`**: 每个 `.gd` 文件第一行必须是 `extends` 或 `class_name`
- **注释**: 中文注释，公共方法加 `##` 文档注释
- **文件编码**: UTF-8
- **信号优先**: 不依赖函数调用处理所有逻辑交互，合理使用信号解耦，遵循 **"calls down, signals up"**（父节点调用子节点方法，子节点通过信号向上通信）原则
- **静态验证**: 创建或修改 `.gd` 文件后，必须验证静态分析是否报错。必须消除所有报错（Error），仅关于命名风格的警告（Warning）可以忽略

### 典型文件结构

```gdscript
class_name ClassName extends Node

## 简短的中文描述

# 信号
signal my_signal

# _Ready() → 方法
func _ready() -> void:
    pass

func my_method() -> void:
    pass
```

## Godot MCP 连接

在操作 Godot 相关功能前，先连接编辑器 MCP 会话：

```
# 1. 列出可用会话
session_manage(op="list")

# 2. 激活会话（用项目名模糊匹配即可）
session_activate(session_id="GridAndGroves")

# 3. 确认编辑器就绪
editor_state()
```

**核心原则**：
- 优先使用 MCP 工具，而非手动编辑 `.tscn`/`.tres`/`.gd` 文件
- 修改后调用 `scene_save()` 保存场景更改
- 添加 `class_name` 后调用 `filesystem_manage(op="scan")` 刷新
- 详细命令列表见 `.github/instructions/godot-mcp.instructions.md`

## 核心架构

### 目录结构

| 目录 | 用途 |
|------|------|
| `actions/` | 动作系统（AbstractGameAction 及其子类） |
| `actors/` | 玩家与敌人（Player, Enemy, ActorSprite） |
| `blocks/` | 方块系统（Block, BlockPart, BlockPartBehavior） |
| `components/` | 可复用组件（Health, Shield, Stats, Pile, Tooltip 等） |
| `global/` | Autoload 单例（GameLog, GridState, RngManager, BlockRegistry, PackManager, BattleTime, SaveLoad） |
| `packs/` | 卡包系统（BlockPack, MiniPack, CardPool）— 已实现但尚未接入主流程 |
| `registerers/` | JSON 扫描注册器（JsonBlockScanner, JsonEnemyScanner） |
| `resources/` | Godot Resource 定义、.tres 数据文件、block_defs.json / enemy_defs.json |
| `room/` | 房间系统（StageRoom, BattleRoom, EventRoom, Bot 等） |
| `stats/` | 属性系统（Stat, StatBehavior, StatDef） |
| `vfx/` | 视觉特效 |
| `planning/` | 设计文档（世界观、卡包设计、机制设计参考） |
| `docs/` | 中文开发文档 |

### 关键类

- **`BlockRegistry`** (Autoload): 方块注册与创建（`subscribe_block_def`, `create_block_by_name`）
- **`PackManager`** (Autoload): 卡包注册与卡池构建（`subscribe_block_pack`, `build_card_pool`）— 尚未接入游戏流程
- **`BattleTime`** (Autoload): 战斗事件总线（信号系统），触发 StatBehavior 钩子
- **`SaveLoad`** (Autoload): 存档读写与玩家状态恢复
- **`GridState`** (Autoload): 网格状态管理
- **`RngManager`** (Autoload): 多流随机数管理
- **`GameLog`** (Autoload): 日志输出
- **`ActionManager`**: 动作队列调度器（战斗场景内运行时节点，非 Autoload），每帧推进
- **`Bot`**: 网格巡逻机器人，触发 BlockPart 效果
- **`Block`**: 方块（Node2D），由多个 BlockPart 组成
- **`BlockPart`**: 方块部件，包含伤害/护盾值和 Behavior
- **`BlockPartBehavior`**: 部件行为基类，返回 AbstractGameAction
- **`BlockDef` / `BlockPartDef`**: 不再是 Resource 类，数据在 `resources/block_defs.json` 中由 JSON 扫描器构建
- **`Stat`**: 属性节点，通过 StatBehavior 实现自动触发的状态效果
- **`Room`**: 房间基类，被 StageRoom/BattleRoom/EventRoom 继承
- **`BlockPack`**: 主卡包 Resource（`PackName` + `BlockNames`），对应角色核心卡池
- **`MiniPack`**: 小卡包 Resource（`PackName` + `BlockNames`），为每局注入变化
- **`CardPool`**: 运行时卡池，由 1 个 BlockPack + 4 个 MiniPack 合并去重而成

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

- `ActionManager.Instance.add_to_bottom(action)` — 追加到队尾（默认）
- `ActionManager.Instance.add_to_top(action)` — 插入到队首（紧急效果）

> `ActionManager` **不是 Autoload**，而是 BattleRoom 在战斗场景中创建的运行时节点，通过静态变量 `Instance` 访问，使用前判空。

### StatBehavior 系统

- 继承 `StatBehavior`，覆写 `get_execute_periods()` 声明时期，覆写 `execute_at(period)` 实现效果（内部 `match` 分发）
- `Stat._ready()` 自动加入 "stats" 组；`BattleTime` 发出信号时遍历该组，调用 `Definition.Behavior.execute_at(period)`
- `## @period OnXxx` 注释只是文档约定，**不参与分发**
- 已接线时期: `OnBattleStarted`, `OnTurnStarted`, `OnPreBlockExecute`, `OnBlockExecute`, `OnPostBlockExecute`, `OnTurnEnded`, `OnBattleEnded`, `OnBeforeDamageApply`, `OnAfterDamageApply`
- 枚举中 `OnBeforeBlockApply` / `OnAfterBlockApply` / `OnStatusApplied` 尚未接线

## 常用命令

- **打开项目**: 用 Godot 4.7+ 打开项目根目录
- **运行**: Godot 编辑器中按 F5
- **构建**: Godot 编辑器自动重新解析脚本，或重启编辑器

## 资源系统

- Resource 类使用 `class_name Xxx extends Resource` 定义
- `.tres` 文件在 `resources/` 下按类型分目录
- **BlockDef/BlockPartDef 不再是 Resource 类**——数据集中在 `resources/block_defs.json`，运行时由 `JsonBlockScanner` 构建为 `Block`/`BlockPart` 实例（见下方注册机制）

## 注册机制

### BlockDef / EnemyDef 注册（JSON 扫描器）

- BlockDef 通过 `JsonBlockScanner.scan_and_register()` 从 `resources/block_defs.json` 注册
- 敌人与楼层图表通过 `JsonEnemyScanner.scan_and_register()` 从 `resources/enemy_defs.json` 注册
- `BlockRegistry._ready()` 自动调用 `auto_register_blocks()` / `auto_register_enemies()`
- `registerers/` 下的 `AbstractBlockRegisterer` / `OriginalBlockRegisterer` 为历史遗留，`register()` 已无调用方

```json
{
  "blocks": [
    {
      "name": "DamageBlock",
      "parts": [
        {
          "partId": "DamagePart",
          "baseDamage": 10,
          "description": "Deal %D% damage to the enemy.",
          "movingDirection": [0, 1],
          "spriteTexture": "res://resources/blockpart_picture/green/Attack-G.png",
          "behaviors": [
            { "script": "res://resources/blockpart_behaviors/DamageEnemyBehavior.gd" }
          ]
        }
      ]
    }
  ]
}
```

BlockPartBehavior 的 `.gd` 代码文件保持不变，JSON 中通过 `"script"` 路径引用。
带参数的行为支持 `"params"` 字典（如 `"TargetStatDef"` 资源路径可自动加载）。

**新增 Block 的步骤**：
1. 在 `resources/block_defs.json` 的 `blocks` 数组中添加条目
2. 如有新行为逻辑，在 `resources/blockpart_behaviors/` 新建 `.gd` 文件
3. **无需创建任何 `.tres` 文件**

### 卡包注册（尚未接入主流程）

> ⚠️ 卡包系统（PackManager / BlockPack / MiniPack / CardPool）代码已实现，
> 但**尚未接入游戏流程**：没有任何调用方，主菜单也没有卡包选择界面。
> 以下为接入时参考的 API（注册入口建议放在游戏开局处，而非遗留的 registerer）：

```gdscript
# 注册主卡包
PackManager.subscribe_block_pack(load("res://resources/block_packs/MyPack.tres"))

# 注册小卡包
PackManager.subscribe_mini_pack(load("res://resources/mini_packs/MyMini.tres"))
```

### 运行时调用

```gdscript
# 构建卡池（在开局时调用）
PackManager.build_card_pool("战士卡包")

# 从卡池中随机获取 Block 名称（用于战利品奖励）
var reward_block_name: String = PackManager.CurrentCardPool.get_random_block_name()
var reward_block: Block = BlockRegistry.create_block_by_name(reward_block_name)

# 通过名称创建 Block 实例
var block = BlockRegistry.create_block_by_name("DamageBlock")
```

## 卡包系统 (packs/) — 已实现但尚未接入

### 类体系

| 类 | 类型 | 说明 |
|------|------|------|
| `BlockPack` | `class_name Resource` | 主卡包，`PackName` + `BlockNames: Array[String]`，对应角色核心卡池 |
| `MiniPack` | `class_name Resource` | 小卡包，`PackName` + `BlockNames: Array[String]`，为每局注入变化 |
| `CardPool` | 运行时类 | 由 1 个 BlockPack + 4 个随机 MiniPack 合并去重而成（`AllBlockNames` / `Count` / `get_random_block_name()` / `get_random_block_names()`） |

> ✅ 卡包 `.tres` 已落地（Phase 0，2026-08-11）：3 主包 + 5 小包已创建于
> `resources/block_packs/`、`resources/mini_packs/`（见 `planning/main-loop-repair-plan.md`）。
> 但 `.tres` 中引用的 Block 名称（如 `RustyWrench`）尚未写入 `block_defs.json`
> （Phase 1 待办），当前 `block_defs.json` 只包含 8 个示例 Block。

### 生命周期（目标设计）

```
开局 → 玩家从注册的 BlockPacks 中选择一个主卡包
     → PackManager.build_card_pool(main_pack_name)
       └→ 从注册的 MiniPacks 中随机选 4 个
       └→ 合并去重构建 CardPool
       └→ 存入 PackManager.CurrentCardPool
     → 整局游戏中只能使用卡池内的 BlockDef
     → 游戏结束 → PackManager.clear_card_pool()
```

### 接入待办

1. ✅ 创建主卡包与 MiniPack 的 `.tres` 资源（`resources/block_packs/`、`resources/mini_packs/`）— Phase 0 已完成（3 主包 + 5 小包）
2. 在开局时注册卡包并调用 `build_card_pool()`（主菜单卡包选择界面）
3. 初始牌组 / 战利品奖励改为从 `CurrentCardPool` 生成
4. 游戏结束时调用 `clear_card_pool()`

### 注册方式（待接入后参考）

> ⚠️ 以下代码块仅为接入时的参考示例，当前没有任何调用方；
> 遗留的 `AbstractBlockRegisterer` / `OriginalBlockRegisterer` 的 `register()` 已无调用方，不建议继续使用。

```gdscript
# 注册主卡包
PackManager.subscribe_block_pack(load("res://resources/block_packs/MyPack.tres"))

# 注册小卡包
PackManager.subscribe_mini_pack(load("res://resources/mini_packs/MyMini.tres"))
```

## Godot MCP 集成

本项目已安装 `godot_ai` MCP 插件。**所有 Godot 相关操作（场景编辑、节点操作、脚本创建、资源管理、测试运行等）请优先使用 MCP 工具**，而非直接编辑 `.tscn`/`.tres` 文件。

详见 `.github/instructions/godot-mcp.instructions.md`。

## 文档

- `docs/如何编写Resource文件.md` — Resource 类型和 .tres 文件编写指南
- `docs/如何制作BlockAndStat内容.md` — Block/Stat 内容制作完整指南（含 JSON 注册说明）
- `docs/StageRoom.md` — 楼层内循环系统文档
- `.github/instructions/card-pack-design.instructions.md` — 卡包设计核心原则（三个主包的设计差异、特性标签、设计禁忌）
- `.github/instructions/godot-mcp.instructions.md` — Godot MCP 使用指南
- `.github/instructions/architecture.instructions.md` — 架构详细说明
- `planning/card_pack_design/` — 完整卡包设计示例（包含每个包的 Block 列表、新增 Behavior/Stat 建议）

### 卡包设计文件索引

| 文件 | 内容 |
|------|------|
| `planning/card_pack_design/README.md` | 部件位置系统、Block 稀有度、特性标签总览 |
| `planning/card_pack_design/balance.md` | 数值平衡框架（StS 对照、形状效率、价值公式） |
| `planning/card_pack_design/pack_ranger.md` | 铁锈游侠 — 松动/过载/锈蚀 |
| `planning/card_pack_design/pack_weaver.md` | 星语术士 — 共鸣/星涌/法阵 |
| `planning/card_pack_design/pack_sentinel.md` | 翠绿哨兵 — 扎根/藤蔓/共生 |
| `planning/card_pack_design/minipacks.md` | 5 个小卡包 Block 列表 |
| `planning/card_pack_design/technical.md` | Behavior/Stat 技术实现细节 |
