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
- **架构**: Autoload（BlockRegistry, PackManager, BattleTime, SaveLoad）+ 场景树节点

## 代码规范

- **缩进**: 制表符（Tab），1 个 Tab 层级
- **命名**: `snake_case` 变量/函数，`PascalCase` 类名（`class_name`）
- **`class_name`**: 所有需要全局引用的类都要加 `class_name`
- **`extends`**: 每个 `.gd` 文件第一行必须是 `extends` 或 `class_name`
- **注释**: 中文注释，公共方法加 `##` 文档注释
- **文件编码**: UTF-8

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

## 核心架构

### 目录结构

| 目录 | 用途 |
|------|------|
| `actions/` | 动作系统（AbstractGameAction 及其子类） |
| `blocks/` | 方块系统（Block, BlockPart, BlockDef, BlockPartBehavior） |
| `components/` | 可复用组件（Health, Shield, Stats, Pile, Tooltip 等） |
| `global/` | Autoload 单例（BlockRegistry, PackManager, BattleTime, SaveLoad） |
| `packs/` | 卡包系统（BlockPack, MiniPack, CardPool） |
| `registerers/` | 方块注册器（OriginalBlockRegisterer + JsonBlockScanner） |
| `resources/` | Godot Resource 定义和 .tres 数据文件 |
| `room/` | 房间系统（StageRoom, BattleRoom, EventRoom, Bot 等） |
| `stats/` | 属性系统（Stat, StatBehavior, StatDef） |
| `vfx/` | 视觉特效 |
| `docs/` | 中文开发文档 |

### 关键类

- **`BlockRegistry`** (Autoload): 方块注册与创建（`subscribe_block_def`, `create_block_by_name`）
- **`PackManager`** (Autoload): 卡包注册与卡池构建（`subscribe_block_pack`, `build_card_pool`）
- **`BattleTime`** (Autoload): 战斗事件总线（信号系统），触发 StatBehavior 钩子
- **`SaveLoad`** (Autoload): 存档读写
- **`ActionManager`** (Autoload): 动作队列调度器，每帧推进
- **`Bot`**: 网格巡逻机器人，触发 BlockPart 效果
- **`Block`**: 方块（Node2D），由多个 BlockPart 组成
- **`BlockPart`**: 方块部件，包含伤害/护盾值和 Behavior
- **`BlockPartBehavior`**: 部件行为基类，返回 AbstractGameAction
- **`BlockDef`**: 方块定义 Resource（BlockName, PartDefinitions）
- **`BlockPartDef`**: 部件定义 Resource（BaseDamage, Behaviors, MovingDirection 等）
- **`Stat`**: 属性节点，通过 StatBehavior 实现自动触发的状态效果
- **`Room`**: 房间基类，被 StageRoom/BattleRoom/EventRoom 继承
- **`BlockPack`**: 主卡包 Resource，含 30~35 个 BlockDef，对应角色核心卡池
- **`MiniPack`**: 小卡包 Resource，含 10 个 BlockDef，为每局注入变化
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

- `ActionManager.add_to_bottom(action)` — 追加到队尾（默认）
- `ActionManager.add_to_top(action)` — 插入到队首（紧急效果）

### StatBehavior 系统

- 继承 `StatBehavior`，在方法上加 `## @period OnTurnEnded` 标记触发时机
- 所有继承 `StatBehavior` 的类在 `_ready()` 中被自动扫描注册
- 支持时期: `OnBattleStarted`, `OnTurnStarted`, `OnTicTac`, `OnTurnEnded`, `OnBattleEnded`, `OnPreBlockExecute`, `OnBlockExecute`, `OnPostBlockExecute`, `OnBeforeDamageApply`, `OnAfterDamageApply`

## 常用命令

- **打开项目**: 用 Godot 4.7+ 打开项目根目录
- **运行**: Godot 编辑器中按 F5
- **构建**: Godot 编辑器自动重新解析脚本，或重启编辑器

## 资源系统

- Resource 类使用 `class_name Xxx extends Resource` 定义
- `.tres` 文件在 `resources/` 下按类型分目录
- BlockDef → BlockPartDef → BlockPartBehavior 三级引用链
- **不再使用单独的 `.tres` 注册 BlockDef**——改用 JSON 扫描（见下方注册机制）

## 注册机制

### BlockDef 注册（JSON 扫描器）

所有 BlockDef 及其 BlockPartDef 数据集中写在 `resources/block_defs.json` 中。
`JsonBlockScanner` 在运行时读取该 JSON，构建 Resource 实例并注册到 `BlockRegistry`。

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

### 卡包注册

在 `registerers/OriginalBlockRegisterer.gd` 的 `register()` 方法中：

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

# 从卡池中随机获取 BlockDef（用于战利品奖励）
var reward_block_def = PackManager.CurrentCardPool.get_random_block_def()

# 通过名称创建 Block 实例
var block = BlockRegistry.create_block_by_name("DamageBlock")
```

## 卡包系统 (packs/)

### 类体系

| 类 | 类型 | 说明 |
|------|------|------|
| `BlockPack` | `class_name Resource` | 主卡包，含 30~35 个 BlockDef，对应角色核心卡池 |
| `MiniPack` | `class_name Resource` | 小卡包，含 10 个 BlockDef，为每局注入变化 |
| `CardPool` | 运行时类 | 由 1 个 BlockPack + 4 个随机 MiniPack 合并去重而成 |

### 生命周期

```
开局 → 玩家从注册的 BlockPacks 中选择一个主卡包
     → PackManager.build_card_pool(main_pack_name)
       └→ 从注册的 MiniPacks 中随机选 4 个
       └→ 合并去重构建 CardPool
       └→ 存入 PackManager.CurrentCardPool
     → 整局游戏中只能使用卡池内的 BlockDef
     → 游戏结束 → PackManager.clear_card_pool()
```

### 注册方式

在 `OriginalBlockRegisterer`（或任何 `AbstractBlockRegisterer` 子类）的 `register()` 中：

```gdscript
# 注册主卡包
PackManager.subscribe_block_pack(load("res://resources/block_packs/MyPack.tres"))

# 注册小卡包
PackManager.subscribe_mini_pack(load("res://resources/mini_packs/MyMini.tres"))
```

## 文档

- `docs/如何编写Resource文件.md` — Resource 类型和 .tres 文件编写指南
- `docs/如何制作BlockAndStat内容.md` — Block/Stat 内容制作完整指南（含 JSON 注册说明）
- `docs/StageRoom.md` — 楼层内循环系统文档
- `.github/instructions/card-pack-design.instructions.md` — 卡包设计核心原则（三个主包的设计差异、特性标签、设计禁忌）
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
