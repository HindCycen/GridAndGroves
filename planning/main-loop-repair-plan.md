# 游戏主循环修补计划

> 本文档描述当前项目与"正常 Roguelike 卡牌游戏主循环"及项目设计文档（`planning/`、`.github/copilot-instructions.md`）之间的差距，并给出分阶段的详细修补计划。
> 状态：**Phase 0/1 已完成；Phase 2/3 大部分已落地（2026-08-18 起）；Phase 5 意图 UI 已完成。
> 2026-09-12 完成 P0 闭环修补（敌人扩充/精英/楼层缩放/通关结局/StageCount 修复/EnemyAttackBlock 修复）。**

---

## 0. 进度快照（2026-09-12 核实）

> 本节以**代码现实**为准，修正此前文档滞后与自相矛盾之处。核实手段：全库 grep + 文件通读 + Godot 4.7 headless 冒烟。

| 计划项 | 实际状态 | 证据 |
|--------|----------|------|
| Phase 1 卡包内容 147 Block | ✅ 已完成（2026-08-15） | `resources/block_defs.json` 151 Block（147 卡包 + Strike/Defend/Sapling/ThornTrap） |
| Phase 2 主菜单卡包选择 / 卡池构建 / Continue 恢复 | ✅ 已完成（2026-08-18） | `MainMenu.gd:26-85`、`PackManager.gd:70-113` |
| Phase 2.3 初始牌组读 `StartingDeck` | ✅ 已完成 | `room/BattleRoom.gd:92-100`、`EgStageDef.tres` |
| Phase 2.4 `clear_card_pool()` 游戏结束清理 | ✅ 已完成（2026-09-12 接线） | `BattleRoom._on_defeat/_on_victory`、`Victory.gd` |
| Phase 3.1 金币存档 + 顶栏显示 | ✅ 已完成 | `DataResource.Gold`、`Room.gd:83-85` |
| Phase 3.2 战后奖励 | ✅ 金币奖励已完成（2026-08-18）；**卡牌三选一改为商店购买**（设计变更） | `BattleRoom.gd:143-179`、`ShopRoom.gd` |
| Phase 3.3 事件 AddGold/RemoveGold | ✅ 代码已支持（`EventRoom.gd:77-82`）；事件池仍为 3 个（待扩充） | `EgStageDef.tres` |
| Phase 4 商店房间 | ⚠️ 部分：`ShopRoom` 已实现且每战必进；地图商店格（`IsShopCell`）未实现 | `ShopRoom.gd`（309 行） |
| Phase 5.1 敌人数量 | ⚠️ 2026-09-12 扩充至 6 个（3 普通 + 1 精英 + 2 Boss） | `resources/enemy_defs.json` |
| Phase 5.2 精英接入 | ✅ 已完成（2026-09-12）：roomCount 7~13 有 25% 概率抽 `eliteCharts` | `StageRoom.gd` |
| Phase 5.3 楼层缩放 | ✅ 已完成（2026-09-12）：血量/攻击 +12%/层（`StageCount`） | `EnemyManager.gd`、`Enemy.gd` |
| Phase 5.4 意图 UI | ✅ 已完成（2026-08-18） | `Enemy.gd:38-47`、`enemy_intents/icons/` |
| Phase 6.1 通关结局 | ✅ 已完成（2026-09-12）：Stage 3 Boss 后进入 `Victory` | `ShopRoom.gd`、`Victory.gd/.tscn` |
| Phase 6.2 Stat 三时期接线 | ⬜ 仍未实现 | `BattleTime.gd` 仅 7 信号 |
| 旧计划未记录的问题 | ✅ 修复：① `EnemyAttackBlock` 曾丢失（敌人无法放置攻击方块）；② `StageCount` 每层双重 +1；③ 初始牌组不校验卡池 | 见下文各节 |

**遗留真实待办（截至 2026-09-12）**：

1. Phase 6.2 三个 Stat 时期接线（`OnBeforeBlockApply` / `OnAfterBlockApply` / `OnStatusApplied`）
2. 事件池扩充（当前 3 个；宝箱事件尚未配置 AddGold 数值）
3. 地图商店格（Phase 4.2）与商店格图片（Phase 4.3）——当前以"每战必进商店"替代
4. 卡组规模约束：实现为商店侧 15~50（balance.md 标注 10~50，需产品决策统一口径）
5. Phase 1 记录的 13 处设计省略（见 Phase 1 小节）
6. 换层不切换 StageDef：所有楼层共用 `EgStageDef`（当前以敌人缩放体现难度，切换 StageDef 留待内容需要时再做）

### 2026-09-12 修补记录（P0 闭环 + 美术管线）

**修复的严重 Bug（此前均为静默/软锁级）**：

| Bug | 影响 | 修复 |
|-----|------|------|
| `EnemyAttackBlock` 在 Phase 1 重写 JSON 时丢失 | 敌人 AI 放置攻击方块全部失败，网格战斗机制名存实亡 | 恢复 `EnemyAttackBlock`（5 伤）+ 新增 `EnemyHeavyAttackBlock`（8 伤） |
| Boss 判定永不触发 | 最短路径终点进入时 `roomCount=19 < 20`，Boss 图表永不选取，玩家卡在终点格 | 终点格（右上角）强制 `bossCharts`，`_build_enemy_chart_for_room(room_count, is_boss_cell)` |
| `advance_to_next_floor()` 赋 `[]` 给 `Array[int]` 字段报错 | 换层不清空地图 → 新楼层恢复上层死图（软锁） | 改用 `.clear()` 保留类型 |
| `StageCount` 每层双重 +1 | 楼层计数/顶栏显示/缩放系数全部偏移 | 仅在 `StageRoom._generate_map()` 递增 |

**新增内容与功能**：

- 敌人 6 个：普通 `Gonh` / `RustHound` / `SporeCrawler`；精英 `RustColossus`；Boss `IronWarden` / `BloomMother`（含各自意图循环）
- 楼层缩放：血量/攻击 = 基准 × (1 + 0.12 × (StageCount - 1))，`EnemyManager` 注入、`Enemy` 应用
- 精英遭遇：roomCount 7~13 有 25% 概率抽 `eliteCharts`
- 通关结局：`SaveLoad.FINAL_STAGE = 3`，第 3 层 Boss 后经商店进入 `Victory.tscn`（统计层数/房间/金币/击杀/卡组规模）
- 初始牌组：读 `StartingDeck` 时用 `CurrentCardPool.contains_name()` 校验（基础卡豁免）
- `clear_card_pool()` 接线（战败 + 通关）、击杀统计 `DataResource.KillCount`
- 敌人立绘程序化生成器 `tools/gen_enemy_sprites.py`（2 帧动画）+ 意图图标扩充 + `docs/美术管线.md`

**验证证据（Godot 4.7 headless）**：

```
134 脚本解析全检 → 0 失败
冒烟 A: EnemyAttackBlock faction=1 parts=1 DamagePlayerBehavior=true; Heavy dmg=8
冒烟 B: Stage3 IronWarden scaling=1.24 attack=12 maxhp=136
冒烟 C: elite 13/40; final-cell boss=BloomMother
冒烟 E: advance 后 StageCount=2（非 3）RoomCount=0
冒烟 D: Victory 场景加载=true 卡池清理=true RunEnded=true
主场景 --quit-after 5 → 无 ERROR
```

---

## 目录

- [1. 现状：已实现的主循环](#1-现状已实现的主循环)
- [2. 与标准主循环的差距](#2-与标准主循环的差距)
- [3. 与文档设计目标的差距](#3-与文档设计目标的差距)
- [4. 修补计划总览](#4-修补计划总览)
- [5. 详细任务清单](#5-详细任务清单)
- [6. 依赖关系与执行顺序](#6-依赖关系与执行顺序)
- [7. 工作量估计](#7-工作量估计)

---

## 1. 现状：已实现的主循环

```
MainMenu (Continue / New Game)
  → StageRoom（14×7 地图，战斗/事件随机格）
    → BattleRoom：放 Block → End Turn → Bot 巡逻(1s/tick, 三段式) → 敌人放置攻击块 → 敌人回合末直伤 → 循环
    → EventRoom：描述 + 2~4 选项 → 执行 Action → Continue
  → 回 StageRoom（解锁相邻格）… 直到战败 → GameOver
```

### 已完整实现的子系统（无需修补）

| 子系统 | 说明 |
|--------|------|
| Bot 巡逻管线 | Phase A/B/C + `BattleTime` 信号总线，1 秒 tick，蛇形巡逻 7×5 网格 |
| ActionManager 动作队列 | `add_to_bottom` / `add_to_top`，每帧推进 |
| StatBehavior 系统 | 8 个时期已接线（OnBattleStarted / OnTurnStarted / OnPreBlockExecute / OnBlockExecute / OnPostBlockExecute / OnTurnEnded / OnBattleEnded / OnBeforeDamageApply / OnAfterDamageApply），8 个 StatDef（Overload / Rust / Vine / Echo / Symbiosis / ScrapCounter / Growing / Shooting） |
| 三包机制 Behavior | Loose / Resonance / Root+Glyph / SpendOverload / ApplyRust / ApplyVine / ChainRelease / ScrapPayoff / SporeBurst / JungleShelter / NatureCycle |
| 楼层地图 | 地图生成 / 导航解锁 / 闪烁动画 / 存档恢复 |
| 存档系统 | 含 RNG 六流 usage 恢复、玩家状态（血量/卡组/属性/计数）跨房间持久 |
| 敌人 AI | 意图周期（intentCycle）+ 网格放置攻击 Block |
| 房间往返 | BackToStage 返回、Boss 战后 `advance_to_next_floor()` |

---

## 2. 与标准主循环的差距

标准 Roguelike 卡牌游戏循环：

```
主菜单 → 角色/卡包选择 → 楼层地图 → 战斗 → 战后奖励（金币+卡牌）→ 商店/事件
→ Boss → 下一层（敌人变强）→ … → 通关结算
```

对照现状（**2026-09-12 更新**，✅ 表示已解决）：

| # | 标准循环环节 | 现状 | 严重度 |
|---|--------------|------|--------|
| 1 | 卡包/角色选择界面 | ✅ 已实现（`MainMenu.gd`，主包 3 选 1 + 随机 4 小包预览） | — |
| 2 | 卡池（主包 + 4 小包）构建 | ✅ 已实现（`PackManager.build_card_pool` / `restore_card_pool_from_save`） | — |
| 3 | 战后奖励 | ✅ 金币奖励已实现；卡牌获取并入战后商店（设计变更，取代"三选一"弹窗） | — |
| 4 | 游戏内经济（金币/商店/买卖/重掷） | ✅ 已实现（`ShopRoom.gd`）+ 金币顶栏；⏳ 地图商店格未实现 | 低 |
| 5 | Boss 战与关卡递进 | ✅ Boss 判定（roomCount ≥ 20）；✅ Stage 3 Boss 后通关结算 `Victory.tscn`；⏳ 换层不切换 StageDef（以缩放替代） | 低 |
| 6 | 敌人内容与意图可见性 | ✅ 6 个敌人（3 普通 + 1 精英 + 2 Boss）+ 意图图标 UI；⏳ 敌人数量仍可继续扩充 | 低 |
| 7 | 难度曲线 | ✅ 血量/攻击随楼层 +12%/层；尚无 Ascension 类系统 | 低 |
| 8 | 卡组规模约束 | ⚠️ 商店侧 15~50（balance.md 写 10~50，口径待统一） | 低 |
| 9 | 事件多样性 | ⚠️ 仅 3 个事件；`AddGold/RemoveGold` 已实现但宝箱事件未配置数值 | 中 |
| 10 | 结算画面 | ✅ GameOver / Victory 均含 Stage/Room/Gold/击杀统计 | 低 |

---

## 3. 与文档设计目标的差距

### 3.1 `.github/copilot-instructions.md`（卡包系统接入待办 4 项）

- ✅ 卡包 `.tres` 已创建（Phase 0）：3 主包 + 5 小包（`resources/block_packs/`、`resources/mini_packs/`）
- ✅ 开局自动注册卡包（`PackManager._ready` 扫描目录）、主菜单卡包选择、`build_card_pool()` 已接通
- ✅ 初始牌组读 `EgStageDef.StartingDeck`；✅ 已用 `CurrentCardPool.contains_name()` 校验非基础卡
- ✅ 游戏结束（战败/通关）调用 `clear_card_pool()`

### 3.2 `planning/card_pack_design/balance.md`（完整经济规格）

- ✅ 金币字段 `DataResource.Gold`（默认 10）；✅ 战斗奖励、✅ 商店价格表、✅ 重掷费用均已实现
- ⚠️ 初始卡组基准已配（4 Strike + 4 Defend）；角色固有 + 角色能力 2 格仍未实现（待内容设计）
- ⚠️ 离店检查已实现但为 15/50（无 <10 自动补牌；>50 禁离店），与本文档 <10/>10 的表述不一致，待产品口径统一
- ⚠️ 两条 Scaling 路径（跨战斗 Stat 积累 / Bot 路径操控）机制已在代码层支持，但无对应 Block 内容

### 3.3 `planning/sts-design-reference.md` 第 9 章

- ✅ 稀有度体系已入库：JSON `rarity` 字段 + `Block.Rarity` + `BlockRegistry.RarityWeights` 权重表 + `pick_random_rarity()`，已用于商店上架
- ⚠️ "饥饿保护"（稀有保底）、Ascension 难度系统（+1~+10）未实现；✅ Boss/精英意图图标可观察（敌人头顶 IntentIcon）
- ⚠️ 跨战斗 Stat ≈ 10~15 个/局、"遗物类 Block 永久移除"——无内容支撑

### 3.4 `planning/card_pack_design/*.md`（内容层）

- ✅ 3 主包（33/32/32）+ 5 小包（各 10）共 147 个 Block 已全部落地（2026-08-15）
- ⚠️ `technical.md`：松动/共鸣/驻留/过载**已实现**；`PlacementRestrictionBehavior`（放置限制钩子）**已实现**（奇点中央限制）；法阵上限 2 / 扎根上限 3 约束**已实现**（`GlyphRootBehavior.can_place_glyph`）

### 3.5 其他文档注明的小缺口

- `architecture.instructions.md`：`OnBeforeBlockApply` / `OnAfterBlockApply` / `OnStatusApplied` 三个时期**尚未接线**（Enums 与 BattleTime 均有定义但无信号发出）——**仍准确**
- ✅ `eliteCharts` 已启用（2026-09-12）：roomCount 7~13 有 25% 概率进入精英战

---

## 4. 修补计划总览

| 阶段 | 主题 | 优先级 | 内容概要 | 状态 |
|------|------|--------|----------|------|
| Phase 0 | 数据层扩展 | P0 | 金币/卡池存档字段、Block 稀有度入库、Defend 补全、卡包 .tres、初始卡组配置 | ✅ 已完成 |
| Phase 1 | 卡包内容落地 | P0 | 3 主包 + 5 小包 147 个 Block 写入 `block_defs.json`（按设计文档 + 数值验算） | ✅ 已完成（2026-08-15） |
| Phase 2 | 卡包接入主流程 | P0 | 主菜单卡包选择界面、卡池构建、初始牌组从卡池生成、结束清理 | ✅ 已完成（2026-09-12） |
| Phase 3 | 战后奖励与经济 | P0 | 金币系统、战后奖励（金币 + 商店购买）、事件补全 | ✅ 金币/商店已完成；⏳ 事件池待扩充 |
| Phase 4 | 商店房间 | P1 | ShopRoom 已实现（每战必进）；⏳ 地图商店格、商店格图片未做 | ⚠️ 大部分完成 |
| Phase 5 | 敌人与难度曲线 | P1 | 6 敌人（3 普通/1 精英/2 Boss）、精英接入、楼层缩放、意图 UI | ✅ 已完成（2026-09-12） |
| Phase 6 | 结局与打磨 | P2 | 通关判定与胜利结算、结算统计增强、全量验证 | ✅ 6.1/6.3/6.4 已完成；⬜ 6.2 Stat 三时期未接线 |

---

## 5. 详细任务清单

### Phase 0 — 数据层扩展（P0）✅ 已完成（2026-08-11）

| # | 任务 | 涉及文件 | 状态 |
|---|------|----------|------|
| 0.1 | `DataResource` 增加金币与卡池存档字段 | `resources/DataResource.gd` | ✅ 新增 `Gold: int = 10`、`MainPackName: String = ""`、`SelectedMiniPackNames: Array[String] = []`；旧存档缺失字段自动使用默认值 |
| 0.2 | Block 稀有度入库 | `resources/block_defs.json` + `registerers/JsonBlockScanner.gd` + `blocks/Block.gd` + `global/BlockRegistry.gd` | ✅ JSON 条目 `"rarity": 0~3`；扫描器读入；`Block.Rarity`；`BlockRegistry.RarityWeights`（普通 10 / 稀有 4 / 史诗 1.5 / 传说 0.5）+ `pick_random_rarity()`（reward RNG 流，可存档复现） |
| 0.3 | 补齐基础 Block：`Defend`（1×1 护盾 6） | `resources/block_defs.json` | ✅ 已添加，全部 8 个 Block 均带 rarity 字段 |
| 0.4 | 创建卡包 `.tres` | `resources/block_packs/*.tres`、`resources/mini_packs/*.tres` | ✅ 3 主包（铁锈游侠 33 / 星语术士 32 / 翠绿哨兵 32）+ 5 小包（紧急补给 / 废品爆破 / 暗网契约 / 精密传动 / 星尘余烬，各 10），已通过 Godot headless 加载验证（无重复名） |
| 0.5 | 初始卡组配置 | `resources/EgStageDef.tres` | ✅ `StartingDeck = [Strike×4, Defend×4]`（角色固有/能力 2 格在 Phase 2 动态追加），已通过 Godot headless 加载验证 |

> **Phase 1 命名约定**：`block_defs.json` 的 Block `name` 必须与 `.tres` 中 `BlockNames` 完全一致（英文 CamelCase，如 `RustyWrench`）。这是 `.tres` ↔ JSON 的命名契约。

### Phase 1 — 卡包内容落地（P0，工作量最大）

> **进度：全部完成（2026-08-15）：147/147 Block 落地，命名契约 100% 匹配，headless 冒烟验证通过**

| # | 任务 | 状态 |
|---|------|------|
| 1.1 | 按 `pack_ranger.md` 落地铁锈游侠约 33 Block | ✅ 33/33（18 普通 / 10 稀有 / 4 史诗 / 1 传说），22 松动 / 7 一次性 |
| 1.2 | 按 `pack_weaver.md` 落地星语术士约 32 Block | ✅ 32/32（16 普通 / 11 稀有 / 5 史诗 / 1 传说），共鸣 20 / 法阵 3 / 回响 4 |
| 1.3 | 按 `pack_sentinel.md` 落地翠绿哨兵约 30 Block | ✅ 32/32（16 普通 / 11 稀有 / 4 史诗 / 1 传说），藤蔓 10 / 扎根 8 / 共生 6 |
| 1.4 | 按 `minipacks.md` 落地 5 小包各 10 Block | ✅ 50/50（紧急补给 / 废品爆破 / 暗网契约 / 精密传动 / 星尘余烬），含 `PlacementRestrictionBehavior`（奇点中央限制）+ `Sapling`/`ThornTrap` 生成物 Block |
| 1.5 | 数值验算 | ✅ 全部按 `balance.md` 锚点验算（松动 ×1.2 / 一次性 ×1.4 / 稀有 ×1.4 / 史诗 ×2.0 / 传说 ×2.5） |

**配套代码改动（已随 Phase 1 落地）：**

- `BlockPart` 新增 `Exhaust` 字段（一次性标记）+ `Heal` 字段（治疗量），`JsonBlockScanner` / `Block` 读取；`Bot` / `ResonanceBot` 触发时移出战斗
- `ScrapCounterStat` 递增接线：松动入弃牌堆时玩家计数 +1（此前 Stat 从未递增，依赖它的增幅效果全部失效）
- `BlockPilesHere` 新增公共 API：`recall_from_discard(require_loose, require_exhaust)`（弃牌堆回收）、`return_placed_to_hand()`（场上回手）
- `Block._check_placement_conditions` 新增通用放置限制钩子（遍历部件 Behavior 的 `check_placement()`，基类默认放行）
- `Bot` / `ResonanceBot` 触发时写 `block meta "resonance_depth"`（链加成 Behavior 读取；`set_chain_bonus` 钩子此前无消费者）
- 新增 32 个 Behavior（`resources/blockpart_behaviors/`）：
  - 铁锈游侠 7：`RecallFromDiscard` / `ScrapBonusDamage` / `ScrapThreshold` / `OverloadThreshold` / `ScrapToRust` / `SpendOverloadBoost` / `FullTriggerReward`（含 EchoReward 参数）
  - 星语术士 8：`ChainBonusDamage` / `ChainBonusShield` / `AddEcho` / `EchoBonusDamage` / `EchoThreshold` / `EchoBurst` / `SacrificeGlyph` / `DrawBlock`
  - 翠绿哨兵 7：`Heal` / `ApplyVineAll` / `DoubleVine` / `ConsumeVineDamage` / `ShieldReflect` / `RootCountDamage` / `RootCountVine`
  - 小包 10：`SummonBlock` / `ChainTrigger` / `Detonator` / `RemoveEnemyBuff` / `RandomDamage` / `RandomDebuff` / `ColumnConditionDamage` / `RemoveFromDiscard` / `ReturnPlacedToHand` / `PlacementRestriction`

> **已知取舍（未完全实现的设计点，共 13 处，均已在 Block description 注明）：**
> 星门链位置 +1 效果省略（仅护盾 10）；新星全触发 AOE 省略；超新星前兆"四部件全被链触发"简化为全部件触发；星语法阵"回合结束结算"改为触发时按回响计数结算；光合作用扎根条件省略；孢子喷射 ≥3 层条件省略；静态场"每触发 1 Block +1"省略；奇点"共鸣链 ≥3 才可放置"省略；磁力收束/蒸汽锤消费端位置调整（数值等价）；烟雾弹 -50% 改 -4 锈蚀；闪光弹同理；痛觉强化 HP 统计省略；引力波/炸药包/弹射的 Bot 交互效果部分省略。
> **验证**：130 脚本解析全检 0 失败；headless 冒烟 147/147 实例化 + 行为创建 0 错误；8 卡包命名契约 100% 匹配。

### Phase 2 — 卡包接入主流程（P0）✅ 已完成（2026-09-12 收尾）

| # | 任务 | 涉及文件 | 状态 |
|---|------|----------|------|
| 2.1 | 主菜单卡包选择界面 | `MainMenu.gd` + `MainMenu.tscn` | ✅ 主包列表动态生成，选中后显示 4 个随机小包与卡池规模 |
| 2.2 | 开局注册与构建卡池 | `MainMenu.gd`、`PackManager.gd` | ✅ 注册由 `PackManager._ready` 自动扫描完成；`build_card_pool` 写入存档；Continue 走 `restore_card_pool_from_save` |
| 2.3 | 初始牌组从 StageDef + 卡池生成 | `room/BattleRoom.gd` | ✅ 读 `StartingDeck` 并用 `CurrentCardPool.contains_name()` 校验（非基础卡不在卡池时告警并回退）；"角色固有/能力"仍待内容设计 |
| 2.4 | 游戏结束清理 | `BattleRoom._on_defeat()` / `Victory.gd` | ✅ 战败与通关均调用 `PackManager.clear_card_pool()` |

### Phase 3 — 战后奖励与经济（P0）✅ 核心已完成

| # | 任务 | 涉及文件 | 状态 |
|---|------|----------|------|
| 3.1 | 金币系统 | `SaveLoad.gd`、`Room.gd` | ✅ 存档字段 + 顶栏显示 |
| 3.2 | 战后奖励 | `room/BattleRoom.gd`、`room/ShopRoom.gd` | ✅ 金币（3~5 / 5~7 / 10~15）；**设计变更**：卡牌获取改为商店购买（按稀有度加权上架），未做"三选一"弹窗 |
| 3.3 | 事件补全 | `room/EventRoom.gd`、`EgStageDef.tres` | ⚠️ `AddGold/RemoveGold` 已实现；事件池仍为 3 个，宝箱"Open"未配置数值 |
| 3.4 | 奖励与存档联动 | `Room._exit_tree` | ✅ 自动 save |

### Phase 4 — 商店房间（P1）⚠️ 大部分完成

| # | 任务 | 说明 | 状态 |
|---|------|------|------|
| 4.1 | 新建 `ShopRoom` | 商品区（4 件，Boss 5 件全免费）、重掷（3 起 +1/次）、卖出（基础卡 1 金/其他半价）、离店检查（15/50） | ✅ 已完成 |
| 4.2 | 地图接入商店格 | `DataResource.IsShopCell` + `StageRoom` 分发 | ⬜ 未做；当前设计为"每战必进商店" |
| 4.3 | 商店格图片资源 | `room/room_pictures/ShopRoomBn.png` | ⬜ 未做（无地图格则不需要） |

### Phase 5 — 敌人与难度曲线（P1）✅ 已完成（2026-09-12）

| # | 任务 | 说明 | 状态 |
|---|------|------|------|
| 5.1 | 敌人内容扩充 | 6 个敌人：普通 Gonh / RustHound / SporeCrawler；精英 RustColossus；Boss IronWarden / BloomMother。立绘由 `tools/gen_enemy_sprites.py` 确定性生成 | ✅ |
| 5.2 | 精英接入 | roomCount 7~13 有 25% 概率（`get_monster_rand`）抽 `eliteCharts` | ✅ |
| 5.3 | 楼层缩放 | 血量/攻击 = 基准 × (1 + 0.12 × (StageCount - 1))，`EnemyManager` 注入、`Enemy` 应用 | ✅（换 StageDef 仍不做） |
| 5.4 | 意图 UI | 头顶 IntentIcon，执行前刷新 | ✅（2026-08-18 已完成） |

### Phase 6 — 结局与打磨（P2）⚠️ 6.2 待做

| # | 任务 | 说明 | 状态 |
|---|------|------|------|
| 6.1 | 通关判定与胜利结算画面 | Stage 3 Boss 战后 → `Victory.tscn`（层数/房间数/金币/击杀/卡组规模） | ✅ |
| 6.2 | 接线剩余 Stat 时期 | `before_block_apply` / `after_block_apply` / `status_applied` 信号 + 发出点 | ⬜ 未做 |
| 6.3 | GameOver 统计增强 | Stage/Room/Gold/击杀 | ✅ |
| 6.4 | 全量验证 | 静态解析全检 + headless 冒烟（新敌人/精英抽取/缩放/胜利流转） | ✅（见各阶段验证记录） |

---

## 6. 依赖关系与执行顺序

```
Phase 0（数据层） → Phase 1（内容） → Phase 2（卡包接入） → Phase 3（奖励/经济） → Phase 4（商店）
                                              ↘ Phase 5（敌人/难度，与 2、3 并行）
                                                          ↘ Phase 6（结局，依赖 3、5）
```

**已按序完成**：0 → 1 → 2 → 3 → 5 → 6（主链路"选卡包 → 战斗 → 奖励 → 消费 → Boss → 通关"已打通）。

**剩余可选项**：
- Phase 6.2（Stat 三时期）——需要新内容消费时再做
- Phase 3.3 事件池扩充、Phase 4.2 地图商店格——内容迭代
- Phase 1 遗留 13 处设计省略——按设计优先级逐个补

---

## 7. 工作量估计

| 阶段 | 任务数 | 预估规模 | 状态 |
|------|--------|----------|------|
| Phase 0 | 5 | 小（半天） | ✅ 已完成 |
| Phase 1 | 5 | 最大（147 Block 落地 + 验算） | ✅ 已完成 |
| Phase 2 | 4 | 中 | ✅ 已完成 |
| Phase 3 | 4 | 中 | ✅ 核心（事件池待扩充） |
| Phase 4 | 3 | 中 | ⚠️ 商店本体完成，地图格未做 |
| Phase 5 | 4 | 中 | ✅ 已完成 |
| Phase 6 | 4 | 小~中 | ✅ 除 6.2 外完成 |

> 主链路 18 个任务全部闭环；剩余为内容迭代项。
