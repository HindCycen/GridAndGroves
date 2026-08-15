# 游戏主循环修补计划

> 本文档描述当前项目与"正常 Roguelike 卡牌游戏主循环"及项目设计文档（`planning/`、`.github/copilot-instructions.md`）之间的差距，并给出分阶段的详细修补计划。
> 状态：**Phase 0 已完成（2026-08-11），其余阶段待实施**

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

对照现状：

| # | 标准循环环节 | 现状 | 严重度 |
|---|--------------|------|--------|
| 1 | 卡包/角色选择界面 | ❌ 主菜单直接 New Game，无任何选择 | 高 |
| 2 | 卡池（主包 + 4 小包）构建 | ❌ `PackManager` 无任何调用方，`CardPool` 从未构建 | 高 |
| 3 | 战后奖励（金币 + 卡牌三选一） | ❌ 胜利后静默回地图，无任何奖励 | 高 |
| 4 | 游戏内经济（金币/商店/买卖/重掷） | ❌ 商店不存在；金币字段已加（Phase 0）但未接入 UI | 高 |
| 5 | Boss 战与关卡递进 | ⚠️ 有 `bossCharts` 判定（roomCount ≥ 20）与 `advance_to_next_floor()`，但所有图表内容相同、换层后 StageDef 不变、**无通关结局** | 高 |
| 6 | 敌人内容与意图可见性 | ⚠️ 只有 1 个敌人 Gonh（普通/精英/Boss 全是它）；`eliteCharts` 预留未用；敌人意图无 UI 展示（仅数据层） | 中 |
| 7 | 难度曲线 | ❌ 无敌人强度随楼层缩放，无 Ascension 类系统 | 中 |
| 8 | 卡组规模约束（10~50） | ❌ 无任何上下限检查 | 中 |
| 9 | 事件多样性 | ⚠️ 仅 3 个事件；`AddGold/RemoveGold` ActionType 未实现 | 中 |
| 10 | 结算画面 | ⚠️ GameOver 只有 Stage/Room 数字 | 低 |

---

## 3. 与文档设计目标的差距

### 3.1 `.github/copilot-instructions.md`（卡包系统接入待办 4 项）

- ✅ 卡包 `.tres` 已创建（Phase 0）：3 主包 + 5 小包（`resources/block_packs/`、`resources/mini_packs/`）
- ❌ 开局未注册卡包、未调用 `build_card_pool()`；主菜单无卡包选择界面
- ❌ 初始牌组/战利品不从 `CurrentCardPool` 生成——`BattleRoom._initialize_player_deck()` 仍为硬编码回退逻辑；`EgStageDef.tres` 已配 `StartingDeck`（Phase 0）
- ❌ 游戏结束未调用 `clear_card_pool()`

### 3.2 `planning/card_pack_design/balance.md`（完整经济规格）

- ⚠️ 金币字段 `DataResource.Gold` 已加（默认 10）；战斗奖励、商店价格表、重掷费用未实现
- ⚠️ 初始卡组基准已配（4 Strike + 4 Defend）；角色固有 + 角色能力 2 格待 Phase 2 动态追加
- ❌ 离店检查（<10 自动补牌、>10 禁离店）未实现
- ⚠️ 两条 Scaling 路径（跨战斗 Stat 积累 / Bot 路径操控）机制已在代码层支持，但无对应 Block 内容

### 3.3 `planning/sts-design-reference.md` 第 9 章

- ⚠️ 稀有度体系已入库（Phase 0）：JSON `rarity` 字段 + `Block.Rarity` + `BlockRegistry.RarityWeights` 权重表 + `pick_random_rarity()`；战利品加权逻辑待 Phase 3
- ❌ "饥饿保护"（稀有保底）、Boss 意图可观察（无 UI）、Ascension 难度系统（+1~+10）均未实现
- ⚠️ 跨战斗 Stat ≈ 10~15 个/局、"遗物类 Block 永久移除"——无内容支撑

### 3.4 `planning/card_pack_design/*.md`（内容层）

- ❌ 3 主包（约 30~35 个/包）+ 5 小包（10 个/包）共约 140 个 Block 设计**未落地**——`block_defs.json` 仅 8 个 Block（7 示例 + 新增 Defend）
- ⚠️ `technical.md` 中的游戏循环修改：松动/共鸣/驻留/过载**已实现**；`PlacementRestrictionBehavior`（放置限制钩子）**未实现**；法阵上限 2 / 扎根上限 3 等约束未实现

### 3.5 其他文档注明的小缺口

- `architecture.instructions.md`：`OnBeforeBlockApply` / `OnAfterBlockApply` / `OnStatusApplied` 三个时期**尚未接线**（Enums 与 BattleTime 均有定义但无信号发出）
- `StageRoom.md`：`eliteCharts` 标注"为预留"——符合文档现状，但与设计目标（有精英战）有差距

---

## 4. 修补计划总览

| 阶段 | 主题 | 优先级 | 内容概要 | 状态 |
|------|------|--------|----------|------|
| Phase 0 | 数据层扩展 | P0 | 金币/卡池存档字段、Block 稀有度入库、Defend 补全、卡包 .tres、初始卡组配置 | ✅ 已完成 |
| Phase 1 | 卡包内容落地 | P0 | 3 主包 + 5 小包约 140 个 Block 写入 `block_defs.json`（按设计文档 + 数值验算） | ⬜ |
| Phase 2 | 卡包接入主流程 | P0 | 主菜单卡包选择界面、卡池构建、初始牌组/战利品从卡池生成、结束清理 | ⬜ |
| Phase 3 | 战后奖励与经济 | P0 | 金币系统、战后奖励弹窗（金币+三选一）、事件补全 | ⬜ |
| Phase 4 | 商店房间 | P1 | ShopRoom、地图商店格、买卖/重掷/离店检查 | ⬜ |
| Phase 5 | 敌人与难度曲线 | P1 | 敌人内容扩充、精英接入、楼层缩放、意图 UI | ⬜ |
| Phase 6 | 结局与打磨 | P2 | 通关判定与胜利结算、Stat 时期接线、结算统计增强、全量验证 | ⬜ |

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

### Phase 2 — 卡包接入主流程（P0）

| # | 任务 | 涉及文件 |
|---|------|----------|
| 2.1 | 主菜单卡包选择界面 | `MainMenu.gd` + `MainMenu.tscn` 改造：展示 3 主包（名称/机制/风格简介），选中后显示 4 个随机小包与卡池预览 |
| 2.2 | 开局注册与构建卡池 | `MainMenu.gd`：`subscribe_block_pack` / `subscribe_mini_pack` → `build_card_pool(主包名)` → 将主包/小包名写入 `SaveLoad.Data.MainPackName` / `SelectedMiniPackNames`；`New Game` 与 `Continue` 均走此路径（Continue 从存档恢复卡池） |
| 2.3 | 初始牌组从 StageDef + 卡池生成 | `room/BattleRoom.gd`：`_initialize_player_deck()` 改为读 `StartingDeck`，并用 `PackManager.CurrentCardPool.contains_name()` 校验；从卡池生成"角色固有/能力"（`CardPool.get_random_block_name()`） |
| 2.4 | 游戏结束清理 | `BattleRoom._on_defeat()` / GameOver 返回时调用 `PackManager.clear_card_pool()` |

### Phase 3 — 战后奖励与经济（P0）

| # | 任务 | 涉及文件 |
|---|------|----------|
| 3.1 | 金币系统 | `SaveLoad.gd`（保存/恢复 `Gold`）、`Room.gd` 顶栏加金币显示 |
| 3.2 | 战后奖励弹窗（新场景 `RewardPanel`） | `room/BattleRoom.gd` 胜利流程中插入：金币（weak 3~5 / strong 5~7 / boss 10~15，用 `get_reward_rand`）、卡牌三选一（`BlockRegistry.pick_random_rarity()` + `CardPool` 按稀有度筛选），可选"跳过"；结束时才 `_navigate_to_stage()` |
| 3.3 | 事件补全 | `room/EventRoom.gd` 实现 `AddGold/RemoveGold`；`EgStageDef.tres` 扩充事件池（新增 5~8 个事件：加金币、删卡、加卡、受伤换 Stat 等） |
| 3.4 | 奖励与存档联动 | 奖励选择写回 `PlayerDeckBlockNames`；`Room._exit_tree` 已自动 save |

### Phase 4 — 商店房间（P1）

| # | 任务 | 说明 |
|---|------|------|
| 4.1 | 新建 `ShopRoom` | `room/ShopRoom.gd/.tscn`，继承 Room：商品区（从 CardPool 按稀有度权重刷 4~6 件，价格 8-10 / 15-20 / 25-35 / 40-60）、重掷按钮（3 起 +1/次）、卖出区（打击/防御 1 金，其他半价）、离店检查（<10 补 Strike/Defend、>10 禁离店） |
| 4.2 | 地图接入商店格 | `room/StageRoom.gd` + `DataResource` 增加 `IsShopCell` 数组与存档；`_enter_room` 分发到 ShopRoom；Boss 战后商店（0 金、不可重掷）由 `advance_to_next_floor()` 后首个房间触发 |
| 4.3 | 商店格图片资源 | `room/room_pictures/ShopRoomBn.png`（参考现有 Bn 96×96） |

### Phase 5 — 敌人与难度曲线（P1）

| # | 任务 | 说明 |
|---|------|------|
| 5.1 | 敌人内容扩充 | `resources/enemy_defs.json`：新增 2~3 个普通敌人（不同意图周期）+ 1 精英 + 2 个 Boss（各有 3+ 意图）；图片与意图资源放入 `enemy_images/`、`enemy_intents/` |
| 5.2 | 精英接入 | `room/StageRoom.gd`：roomCount 7~13 区间有概率（约 25%，用 `get_monster_rand`）抽 `eliteCharts`；填充 eliteCharts 数据 |
| 5.3 | 楼层缩放 | `EnemyManager.queue_attacks` / AI 处按 `StageCount` 对敌人伤害/血量乘系数（如 +10%/层，参考 Ascension +1）；`advance_to_next_floor()` 增加换 StageDef 的逻辑（后续楼层可配不同图表/事件池） |
| 5.4 | 意图 UI | `actors/enemy/Enemy.tscn` 加头顶意图图标/文字（读 `AIComponent.get_current_intent()`，回合开始刷新），敌我双方均可观察 |

### Phase 6 — 结局与打磨（P2）

| # | 任务 | 说明 |
|---|------|------|
| 6.1 | 通关判定与胜利结算画面 | 定义最终层（如 StageCount ≥ 3 或专属 StageDef 的 bossCharts 打完）→ 新 `Victory.tscn`（统计：层数/房间数/金币/击杀） |
| 6.2 | 接线剩余 Stat 时期 | `global/BattleTime.gd` 增加 `before_block_apply` / `after_block_apply` / `status_applied` 信号与 `say_*` 方法；在 `GrantShieldBehavior`（或护盾获取处）与 `StatsComponent.add_status` 处发出 |
| 6.3 | GameOver 统计增强 | 回合数/击杀数/金币显示 |
| 6.4 | 全量验证 | 静态分析零 Error；新 Game → 选择卡包 → 战斗 → 奖励 → 商店 → Boss → 通关全链路手测；旧存档 Continue 兼容性测试 |

---

## 6. 依赖关系与执行顺序

```
Phase 0（数据层） → Phase 1（内容） → Phase 2（卡包接入） → Phase 3（奖励/经济） → Phase 4（商店）
                                              ↘ Phase 5（敌人/难度，与 2、3 并行）
                                                          ↘ Phase 6（结局，依赖 3、5）
```

**建议执行顺序**：0 → 1 → 2 → 3 为主链路，完成即形成"可选卡包 → 战斗 → 奖励 → 消费"的完整循环；4、5 可与 3 并行；6 最后。

**可裁剪项**（若时间有限，可推迟到下一迭代）：
- Phase 1 可先落地铁锈游侠 + 5 小包（打通"游侠"一条主线），其余两包后续迭代
- Phase 4（商店）可先用"战后简单奖励 + 事件金币消耗"顶替
- Phase 6.3（GameOver 统计增强）为锦上添花

---

## 7. 工作量估计

| 阶段 | 任务数 | 预估规模 | 状态 |
|------|--------|----------|------|
| Phase 0 | 5 | 小（半天） | ✅ 已完成 |
| Phase 1 | 5 | 最大（约 140 Block 落地 + 验算，2~3 天） | ⬜ |
| Phase 2 | 4 | 中 | ⬜ |
| Phase 3 | 4 | 中 | ⬜ |
| Phase 4 | 3 | 中 | ⬜ |
| Phase 5 | 4 | 中 | ⬜ |
| Phase 6 | 4 | 小~中 | ⬜ |

> 合计约 29 个任务，主链路（Phase 0~3）约 18 个任务。
