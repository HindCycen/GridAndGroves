# 项目状态快照

> **这是「现在在哪」的唯一事实来源。** 每次收尾由 AI 从代码事实重新生成（见 `.dsh/skills/session-handoff`）。
> 历史变更过程写在 `main-loop-repair-plan.md`；**不要把历史往这里塞**。
> 最后核实：2026-09-29（`tests/smoke.tscn` 12/12 通过）

## 一句话

主循环已闭环可玩（选包 → 地图 → 战斗 → 商店 → Boss → 通关），当前缺口集中在**美术接入**与**内容厚度**，不是功能缺失。

## 环境

| 项 | 值 |
|---|---|
| 引擎 | Godot **4.7.2** stable |
| 可执行 | `C:\Unpacked\Godot\Godot_v4.7.2-stable_win64_console.exe` |
| 主场景 | `res://MainMenu.tscn` |
| 解析 | 1920×1080，`stretch_mode=viewport` |
| Autoload | `GameLog` `GridState` `RngManager` `BlockRegistry` `PackManager` `BattleTime` `SaveLoad` |

## 内容量（实测）

| 类别 | 数量 | 来源 |
|---|---|---|
| Block | **153** | `resources/block_defs.json` |
| 敌人 | **6** | `resources/enemy_defs.json` |
| 卡包 | 3 主包 + 5 小包 | `PackManager` 启动日志 |
| 事件 | **3** | `EgStageDef.tres` → `PossibleEvents` |
| GDScript | ~283 | 全库 |
| 房间场景 | 7 | `room/*.tscn` |
| 美术产出 | 528 部件图 / 18 Stat 图 / 12 敌人图 / 32 意图图标 / 4 调色板 | `resources/*` |
| 战斗背景 | **18**（3 主题 × 时间点 16–21 时） | `room/battle_background/` |

**敌人**：Gonh / RustHound / SporeCrawler（普通）、RustColossus（精英）、IronWarden / BloomMother（Boss）。

## 工程状态

| 项 | 状态 |
|---|---|
| 工作区 | 干净 |
| 提交 | 125 个；**本地领先 `origin/main` 14 个，未推送**（最后推送 2026-08-11） |
| 分支 | `main`、`testbranch` |
| 测试 | `tests/smoke.tscn` —— 12 项资源完整性/DAG 检查，**通过** |
| 单元测试 | **无**。战斗逻辑、防刷、存档恢复均无自动化覆盖 |

## 已闭环（不要再当待办）

- Phase 1 卡包内容（147 卡包 Block 全部落地）
- Phase 2 主菜单选包 / 卡池构建 / Continue 恢复
- Phase 3 金币存档 + 顶栏 / 战后奖励（三选一已改为商店购买）
- Phase 4 商店房间（每战必进）
- Phase 5 敌人扩充 / 精英 / 楼层缩放 +12%/层 / 通关结算
- P0 防刷与软锁一轮：BackToStage 刷奖励、Boss 判定双轨、事件 0 血不死、锈蚀方向、临时 Stat 泄漏、占格泄漏
- 「松动」部件级重做；共鸣链深度与去重
- 像素美术管线 + `--hour` 时间参数化背景 + 256 色板 + 本地图生图精修

## 未闭环（当前待办）

| # | 事项 | 证据 |
|---|---|---|
| 1 | **事件池仅 3 个**：`EgHealEvent.tres` 存在但未进 `PossibleEvents` | `EgStageDef.tres:11` |
| 2 | 美术精修未批量：仅 1 张精修样张 | `demo_generated/` |
| 3 | 战斗逻辑无自动化覆盖（伤害结算 / 防刷 / 存档恢复） | `tests/smoke.tscn` 只守资源与跨系统不变量 |
| 4 | Stat 三时期接线（`OnBeforeBlockApply` / `OnAfterBlockApply` / `OnStatusApplied`） | 计划文档 Phase 6.2 |

> 已撤销的待办：~~地图商店格~~（口径 9：不做）、~~卡组 10 vs 15~~（口径 8：15 为准）、
> ~~背景接入 BattleRoom~~（2026-09-29 已完成，见下）。

## 战斗背景（2026-09-29 已接入）

按口径 10 做**纯查表**，无时钟推进、无交叉淡化。表在 `room/BattleRoom.gd` 的 `FLOOR_BACKGROUNDS`：

| 楼层 | 背景 | 剧情时间 |
|---|---|---|
| 1 | `ForestClearing_1800.png` | 黄昏森林 18:00 |
| 2 | `RustedRuins_2000.png` | 入夜遗迹 20:00 |
| 3 | `BloomCore_2100.png` | 深夜核心 21:00 |

图层：`FloorBackground(-2)` < `UpperLayer(-1)` < 网格无法放置贴片(0)。
未配楼层退回 `FLOOR_BACKGROUND_FALLBACK`。守卫：`every_floor_has_background` / `floors_use_distinct_backgrounds`。

## 下次开工建议起点

1. 跑 `tests/smoke.tscn` 确认基线绿（当前 15 项）
2. 可做：事件池扩充（`EgHealEvent.tres` 已存在未接线）
3. 可做：把已修过的防刷/占格/存档问题补成回归守卫（现在只守资源类不变量）


