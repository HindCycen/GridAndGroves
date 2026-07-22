# Grid & Groves 机制设计指南

> 本文档从零开始讲解如何为 G&G 设计一个新的游戏机制——从灵感、到落地、到深度拓展。
> 结合项目实际代码架构（Bot 巡逻管线、ActionManager、BattleTime、Stat 系统），
> 同时提供脱离现有设计框架的开放思路。

---

## 目录

1. [什么是"机制"？](#1-什么是机制)
2. [机制设计的 5 步法](#2-机制设计的-5-步法)
3. [落地的技术选择](#3-落地的技术选择)
4. [围绕机制设计 Block 效果](#4-围绕机制设计-block-效果)
5. [机制的深度拓展](#5-机制的深度拓展)
6. [9 个全新机制提案](#6-9-个全新机制提案)
7. [机制设计检查清单](#7-机制设计检查清单)

---

## 1. 什么是"机制"？

在 G&G 语境下，**机制（Mechanic）** 是指游戏中**一组相互关联的规则**，它影响玩家如何放置 Block、Bot 如何巡逻、伤害如何计算，以及 Stat 如何交互。

### 机制 vs 效果 vs 玩法

| 概念 | 定义 | 例子 |
|------|------|------|
| **效果 (Effect)** | 一次性的、局部的规则变化 | "造成 6 伤害"、"获得 5 护盾" |
| **机制 (Mechanic)** | 跨 Block、跨回合的系统级规则 | 松动（Loose）、共鸣（Resonance）、过载（Overload） |
| **玩法 (Playstyle)** | 多个机制共同塑造的玩家策略倾向 | "铁锈游侠的高频松动玩法"、"星语术士的共振链玩法" |

### 好机制的特征

| 特征 | 说明 | 反面例子 |
|------|------|---------|
| **可理解** | 玩家看一眼就能明白怎么用 | 需要读三段说明才能懂的连锁规则 |
| **可交互** | 玩家有主动操作空间 | "每回合自动回 2 HP"——太被动 |
| **有代价** | 不是纯增益，需要策略权衡 | "松动 Block 伤害 x2 无副作用"——太无脑 |
| **可扩展** | 能衍生出多张卡和多层玩法 | "过载"既可消耗换爆发，也可攒层换效果 |
| **有趣** | 让玩家在特定时刻感到兴奋 | "伤害 +2"无聊 vs "共鸣链引爆整列"兴奋 |

### 现有机制的快速回顾

| 机制 | 所属包 | 核心规则 | 代价 |
|------|--------|---------|------|
| 松动 (Loose) | 铁锈游侠 | Block 触发后释放格子回到弃牌堆 | 提前离场（本回合不能复用），数值补偿 +15%~30% |
| 过载 (Overload) | 铁锈游侠 | 本回合触发计数，消耗换增益 | 回合结束未消耗则清零 |
| 锈蚀 (Rust) | 铁锈游侠 | 降低敌人伤害 | 需要叠层，不叠没效果 |
| 共鸣 (Resonance) | 星语术士 | 相邻共鸣 Block 链式触发 | 需要精确布局，占格多 |
| 星涌 (Starburst) | 星语术士 | 链位置越深加成越大 | 链越长越难排布 |
| 法阵/扎根 (Glyph/Root) | 星语/哨兵 | Block 驻留，每回合触发 | 永久占格不可移除，数值补偿 ×1.1 |
| 藤蔓 (Vine) | 翠绿哨兵 | 类似中毒，每回合扣血 | 需要叠层，有延迟 |
| 共生 (Symbiosis) | 翠绿哨兵 | 场上 Block 越多收益越大 | 需要在场上保留 Block |

---

## 2. 机制设计的 5 步法

### 第 1 步：找到"游戏中的空白"

每个好机制都源于发现了**现有规则没有覆盖到的地方**。

**在 G&G 中找空白的方法**：

| 观察角度 | 问自己 | 可能的空白 |
|---------|--------|-----------|
| **网格**(Grid) | 网格除了放 Block 还能做什么？ | 网格的可破坏性、网格的动态变化 |
| **Bot** | Bot 除了蛇行还能怎么走？ | Bot 速度、Bot 多体、Bot 特殊状态 |
| **Block** | Block 之间的关系是什么？ | Block 合并、Block 献祭、Block 复制 |
| **回合**(Turn) | 玩家回合/Bot 回合的边界能模糊吗？ | 中间回合、紧急行动、反击时机 |
| **敌人** | 敌人除了攻击还能产生什么交互？ | 偷 Block、转嫁效果、敌人之间的互动 |
| **手牌** | 手牌除了放置还有别的用途吗？ | 弃牌收益、手牌中的 Block 效果 |

> **例子**：铁锈游侠的"松动"机制就是发现了"网格格子是有限资源，但 Block 一旦放下就占一回合"这个空白——如果能让 Block 提前释放格子呢？

### 第 2 步：定义核心规则（一句话描述）

用**一句话**描述机制的核心，确保它满足"可理解"原则。

| 机制 | 一句话描述 |
|------|-----------|
| 松动 | "松动 Block 被触发后立即释放格子，回到弃牌堆。" |
| 共鸣 | "共鸣 Block 被触发时，以链式反应触发相邻共鸣 Block。" |
| 过载 | "本回合每触发一个过载 Block，获得一层<过载>，可消耗层数增强效果。" |

**练习**：试着用一句话描述你的机制。如果你做不到，说明它还太模糊。

### 第 3 步：在游戏管线中找到插入点

这是最关键的技术步骤。G&G 的游戏管线决定了机制**能做什么、不能做什么**。

#### G&G 核心管线回顾

```
TurnStarted
  ↓ [玩家放置 Block]
EndTurnClicked
  ↓
Bot.StartPatrol()
  ┌─ 每个 tick (1 秒):
  │  Phase A: SayPreBlockExecute()  ← Stat 修饰伤害
  │  └─ 管线锚点 A
  │
  │  MoveToNextCell()
  │  └─ 碰到 Block?
  │     └─ EnqueueBlockActions()
  │        ├─ _process_block_part()
  │        │  ├─ SayBlockExecute()  ← Phase B 锚点
  │        │  ├─ 修改 _currentDirection
  │        │  └─ Behavior.create_action() → ActionManager
  │        └─ 管线锚点 B
  │
  │  (if _endingTurn: return)
  │
  │  Phase C: SayPostBlockExecute()  ← Stat 触发类效果
  │  └─ 管线锚点 C
  │
  └─ ScheduleNextStep()
  │
Bot 到边界 → EndTurn()
  → SayTurnEnded()        ← Stat 回合结算
  → 敌人攻击
  → StartPlayerTurn()
```

#### 机制插入点表格

| 插入点 | 时机 | 适合的机制类型 | 技术实现 |
|--------|------|--------------|---------|
| **Phase A** | 每个 tick 开始，在移动前 | 全局修饰器（"本回合每触发 X 个 Block 则..."） | 新 StatBehavior，`OnPreBlockExecute` |
| **移动判定** | `_try_calculate_next_cell2()` | 修改 Bot 路径（跳跃、折返、加速减速） | 在 `_try_calculate_next_cell2()` 中加钩子 |
| **Phase B** | 碰到 Block 时 | Block 自身效果、Block 间交互 | `BlockPartBehavior.create_action()` |
| **Phase B 后** | Behavior.Action 入队后，`_exhaust_block` 前 | 触发后效果（"触发时复制"、"触发时分裂"） | 在 `_process_block_part()` 中加钩子 |
| **Phase C** | 每个 tick 结束 | 持续效果、全局触发 | 新 StatBehavior，`OnPostBlockExecute` |
| **回合结束** | `SayTurnEnded()` | 结算类效果（"回合结束时..."） | 新 StatBehavior，`OnTurnEnded` |
| **伤害前** | DamageAction 执行 | 伤害修饰（增幅/减免/转移） | `OnBeforeDamageApply` |
| **伤害后** | DamageAction 结束 | 伤害触发（"造成伤害时..."） | `OnAfterDamageApply` |
| **格挡前** | 护盾生效前 | 护盾修饰 | `OnBeforeBlockApply` |
| **格挡后** | 护盾生效后 | 护盾触发（"获得护盾时..."） | `OnAfterBlockApply` |

### 第 4 步：确定技术实现方案

根据插入点，选择实现方式：

| 实现方式 | 适用场景 | 技术复杂度 |
|---------|---------|-----------|
| **BlockPartBehavior** | Block 自身触发效果 | 低——新建 .gd，重写 `create_action()` |
| **StatBehavior** | 需要跨 Block/跨回合的计数或修饰 | 中——新建 .gd + .tres |
| **修改 Bot.gd 核心循环** | 改变 Bot 行为逻辑 | 高——需要理解 Bot 管线全貌 |
| **修改 ActionManager** | 改变动作队列行为 | 中——需要理解 Action 调度 |
| **新增 Action 类型** | 没有现有 Action 能表达的效果 | 中——继承 AbstractGameAction |
| **新增信号/钩子** | 需要新的触发时机 | 中高——需要修改 BattleTime 和多个调用处 |

### 第 5 步：设计代价与限制

没有代价的机制是作弊。每个机制必须有明确的**权衡点**。

| 代价类型 | 例子 | 适用机制 |
|---------|------|---------|
| **格子代价** | 多格 Block、扎根永久占格不可移除 | 共鸣、法阵（数值需补偿 ×1.1）|
| **提前离场** | 松动 Block 提前消失，本回合无法复用 | 松动（需数值补偿） |
| **回合延迟** | 藤蔓需要多回合叠层 | 藤蔓、Stat 积累 |
| **条件限制** | "场上必须有 X 才能触发" | 共生、共鸣 |
| **自伤代价** | 触发时对自己造成伤害 | 暗网契约 |
| **牌组代价** | 触发后消耗（Exhaust） | 一次性强力效果 |
| **随机代价** | 伤害有浮动范围 | 星尘余烬 |
| **放置限制** | "只能放在第 X 列" | 精密传动 |

---

## 3. 落地的技术选择

### 3.1 通过 BlockPartBehavior 实现（低复杂度）

适合**只影响当前 Block 自身**的效果。

```gdscript
# 例子：一个"燃烧"Behavior——每次触发自伤 1，但伤害 +3
class_name BurningRageBehavior extends BlockPartBehavior

func create_action(block, part):
    # 先对自己造成伤害
    var self_damage = CallbackAction.new(func():
        var health = _get_player_health(block)
        if health:
            health.take_damage(1)
    )
    ActionManager.add_to_bottom(self_damage)
    # 再对敌人造成伤害
    return DamageAction.new(block, _get_enemy(block), part.Damage + 3, 0.4)
```

**优点**：简单、自包含、无需注册
**缺点**：无法跨 Block、跨回合

### 3.2 通过 StatBehavior 实现（中复杂度）

适合**需要计数**、**跨回合**、**跨 Block** 的效果。

```gdscript
# 例子：一个"连击"Stat——本回合每触发 1 个 Block，伤害 +1
class_name ComboStatBehavior extends StatBehavior

var _combo_count: int = 0

## @period OnPreBlockExecute
func on_pre_block_execute() -> void:
    # 在伤害前给敌人加一个临时易伤？
    pass

## @period OnPostBlockExecute
func on_post_block_execute() -> void:
    _combo_count += 1
    # 给玩家施加一个临时力量
    var players = get_tree().get_nodes_in_group("Players")
    if players.size() > 0:
        # 可以在这里给玩家加一个临时伤害增益
        pass

## @period OnTurnStarted
func on_turn_started() -> void:
    _combo_count = 0
```

**优点**：可跨回合、可注册到任何 Stat 时机
**缺点**：需要创建 .tres，架构较重

### 3.3 修改 Bot 核心循环（高复杂度）

适合：**改变 Bot 移动方式**、**Block 触发方式**。

**建议的修改模式**：不要直接修改 `Bot.gd`，而是在 `Bot.gd` 中加**虚拟方法**或**信号钩子**，让 Behavior 或全局系统通过钩子注入修改。

```gdscript
# Bot.gd 中建议加的钩子：

# 在移动前调用——Behavior 可以通过此钩子修改方向
var _on_before_move: Callable  # 可被 Behavior 设置
# 在碰到 Block 后、处理完行为后调用
var _on_after_process_block: Callable
# 获取额外的 tick 速度修饰
var _get_tick_speed_modifier: Callable
```

**优点**：最灵活
**缺点**：容易引入 Bug，需要大量测试

### 3.4 新增自定义 Action（中复杂度）

适合：**需要动画/延迟/特殊效果**的复合行为。

```gdscript
class_name ChainDamageAction extends AbstractGameAction

var _targets: Array[Node]
var _current_index: int = 0
var _chain_delay: float

func _init(source: Node, targets: Array[Node], base_damage: int, chain_delay: float):
    self.source = source
    self._targets = targets
    self.amount = base_damage
    self._chain_delay = chain_delay
    self.duration = chain_delay
    self.start_duration = chain_delay

func _update(delta: float) -> void:
    if is_done:
        return
    tick_duration(delta)
    if not is_done:
        return
    if _current_index >= _targets.size():
        is_done = true
        return
    var target = _targets[_current_index]
    if is_instance_valid(target):
        # 对当前目标造成伤害，伤害递减
        var dmg = max(1, amount - _current_index)
        var health = target.get_node("RenderingComponent/HealthComponent")
        if health:
            health.take_damage(dmg)
    _current_index += 1
    # 重置 duration，让动作继续
    if _current_index < _targets.size():
        duration = _chain_delay
```

**优点**：自包含、可复用、支持动画时序
**缺点**：需要手动管理状态

---

## 4. 围绕机制设计 Block 效果

有了一个机制后，怎么设计具体的 Block？

### 4.1 Block 设计的金字塔模型

```
            ╱╲
           ╱  ╲          第 3 层：传说级改变规则
          ╱    ╲          （每个包 1~2 个）
         ╱──────╲
        ╱        ╲       第 2 层：机制核心牌
       ╱          ╲       （稀有/史诗，展现机制的独特玩法）
      ╱────────────╲
     ╱              ╲    第 1 层：机制基础牌
    ╱                ╲    （普通/稀有，引入机制、展示基本用法）
   ╱──────────────────╲
  ╱                    ╲  第 0 层：白板基准
 ╱                      ╲  （纯伤害/纯护盾，无机制）
```

**例子——围绕"松动"机制设计 Block**：

| 层级 | Block 例子 | 说明 |
|------|-----------|------|
| 0-白板 | 铁片（5伤害+松动） | 白板伤害+松动标签，数值略高于纯白板（补偿提前离场）|
| 1-基础 | 废铁投掷（双格松动） | 用多格展示松动腾挪价值 |
| 2-核心 | 弹簧（护盾4+松动+抽1） | 松动释放格子+弃牌堆回收复合收益 |
| 3-传说 | 磁力收束 | 松动 Block 进弃牌堆后回收再利用——改变资源循环 |

### 4.2 一个机制至少需要 5~8 个 Block

| 角色 | 数量 | 目的 |
|------|------|------|
| 2~3 个纯机制标签 Block | 让玩家"接触"机制 | 机制+白板，最简单 |
| 2~3 个机制互动 Block | 让玩家"使用"机制 | 机制+额外效果 |
| 1~2 个机制核心 Block | 让玩家"围绕"机制构建 | 核心收益来源 |
| 0~1 个机制改变 Block | 给老玩家惊喜 | 改变机制规则的传说 |

### 4.3 Block 效果设计的 6 种基本模式

所有 Block 效果可归为以下模式：

#### 模式 1：标签 + 数值

最简单的形式。Block 有一个机制标签，外加基础数值。

```
[铁片]         1×1，伤害 4，松动
```

- 设计要点：标签本身影响了玩家对这个 Block 的使用方式
- 在这个例子中，"松动"意味着玩家会优先把它放在"需要释放格子"的位置

#### 模式 2：条件触发

"When X, do Y"——最常见的设计模式。

```
[废品炸弹]     1×1，伤害 4，松动。本回合每触发 1 个松动 Block +1 伤害
```

- 条件触发的**条件**应该和机制相关
- 奖励应该符合直觉（"松动越多→伤害越高"）

#### 模式 3：消耗/资源转换

用某个资源换取效果。

```
[过载线圈]     1×1，伤害 3，过载+1，松动
[过载爆发]     1×1，消耗所有过载层数，每层造成 4 伤害
```

- 需要一个"可消耗的资源"（过载层数、格子数、HP…）
- 消耗的回报应该 > 不消耗的直接使用

#### 模式 4：连锁/组合

Block A + Block B > Block A + Block A。

```
[共鸣水晶]     标记——共鸣触发源（本身无伤害）
[星能碎片]     共鸣，伤害 4
```

- 两个单独的 Block 各自还好，放在一起很强
- 创造"找齐组件"的快乐

#### 模式 5：延迟收益

现在的投入，换来未来的回报。

```
[藤蔓缠绕]     施加 3 层藤蔓
[毒藤]         施加 2 层藤蔓 + 松动
```

- 延迟收益需要补偿（比立即收益高 30%~50%）
- 适合防守型/控制型机制

#### 模式 6：风险/回报

"如果你敢…就会得到…"

```
[血契]         伤害 10，失去 4 HP
[不稳定核心]   伤害 20，自伤 8
```

- 风险必须可见且可控
- 回报必须让人感觉"值得冒险"

### 4.4 复合机制设计

当一个包有多个机制时，需要设计**机制间互动**的 Block。

以铁锈游侠为例（松动 + 过载 + 锈蚀）：

| 互动类型 | Block | 设计 |
|---------|-------|------|
| 松动 ↔ 过载 | 过载线圈 | 松动 + 过载+1——释放格子同时积累过载 |
| 过载 → 锈蚀 | 锈蚀弹 | 过载+2，消耗 3 层过载可额外施加 2 层锈蚀 |
| 松动 + 过载 → 爆发 | 过载爆发 | 消耗过载换伤害，松动释放格子 |
| 锈蚀 ↔ 生存 | 铁锈护盾 | 若敌人有锈蚀，额外获得护盾 |

**设计原则**：
1. **每个 Block 最多绑定 2 个机制**（超过则太复杂）
2. **机制间的联系应该是自然的**（松动释放格子→可以放更多过载 Block→过载层数更高）
3. **至少有一个 Block 是纯单机制的**（让只想浅尝的玩家也能用）

---

## 5. 机制的深度拓展

一个机制不应该只有 5 个 Block 就结束了。好的机制可以横向和纵向拓展。

### 5.1 横向拓展：增大覆盖面

让机制影响**更多的游戏元素**：

| 拓展方向 | "松动"的例子 | "共鸣"的例子 |
|---------|------------|------------|
| **影响敌人** | 松动 Block 可以"推开"敌人占据的格子 | 共鸣可以对敌人造成连锁伤害 |
| **影响 Bot** | 松动格子多了 → Bot 走得更快 | 共鸣链可以改变 Bot 方向 |
| **影响 Stat** | 松动次数 → 累积 Stat | 共鸣链长度 → 某种 Stat 层数 |
| **影响牌组** | 松动 Block 回到弃牌堆 → 可以被回收 | 共鸣触发时复制一个 Block 到手牌 |
| **影响商店** | 松动 Block 售价更高？ | 共鸣 Block 在商店有特殊标签 |

### 5.2 纵向拓展：增加深度

让机制有**更多的策略维度**：

| 深度层次 | 含义 | "过载"的例子 |
|---------|------|------------|
| **Lv1 使用** | 玩家会用机制 | 放置过载 Block → 获得过载层数 |
| **Lv2 优化** | 玩家能规划使用时机 | 决定何时消耗过载 vs 留着叠层 |
| **Lv3 组合** | 玩家能与其他机制联动 | 过载+松动→刷层数→大爆发 |
| **Lv4 创新** | 玩家能发现设计者没想到的用法 | 用极低伤害过载 Block 叠层→不清零的遗物→无限叠层 |

### 5.3 跨包互动

机制不应该只在一个包里自嗨。好的机制能在**不同卡包**之间产生交互。

| 跨包互动 | 说明 |
|---------|------|
| **松动 + 共鸣** | 松动释放格子 → 更容易排共鸣链 |
| **松动 + 扎根** | 松动释放格子 → 为扎根 Block 腾出长期位置 |
| **过载 + 藤蔓** | 过载消耗增加藤蔓层数 |
| **共鸣 + 共生** | 共鸣链产生多个触发 → 共生加成更高 |
| **扎根 + 过载** | 扎根 Block 每回合触发→每回合叠过载 |

**设计跨包 Block 的两种方式**：

1. **主包内包含少数跨包 Block**：例如铁锈游侠的某个稀有 Block 有"共鸣"标签
2. **MiniPack 作为粘合剂**：MiniPack 中的 Block 往往有多包机制，是跨包配合的桥梁

### 5.4 在 Stat 系统中拓展

机制不应该只存在于 Block 层面。在 Stat 层面拓展机制，可以让它有**跨战斗的生命力**。

```gdscript
# 例子：一个"松动大师"Stat——累计松动触发次数，永久增加松动伤害
class_name LooseMasterStatBehavior extends StatBehavior

## @period OnPostBlockExecute
func on_post_block_execute() -> void:
    # 检查当前触发的 Block 是否松动
    # 如果是，累计计数
    # 每累计 5 次，永久增加松动 Block 伤害 +1
    pass
```

| 机制 | 可能的 Stat 拓展 |
|------|----------------|
| 松动 | 松动大师（累计松动次数，永久提升松动伤害） |
| 过载 | 过载容量（永久增加过载层数上限） |
| 锈蚀 | 锈蚀精通（锈蚀额外降低敌人伤害） |
| 共鸣 | 共鸣链条（共鸣链最大长度+1） |
| 藤蔓 | 毒藤之种（藤蔓不再每回合衰减） |
| 扎根 | 深根（可同时扎根数 +1） |

---

## 6. 9 个全新机制提案

以下机制**与现有三包（游侠/术士/哨兵）的设计思路不同**，提供了全新的玩法方向。
每个机制都配有：一句话定义、管线插入点、Block 设计示例、拓展方向。

---

### 提案 1：共鸣（Echo）— Block 复制

> **"一个 Block 被触发时，在随机空闲位置生成一个副本（复制体）。"**

- **插入点**：Phase B 后，`_process_block_part()` 的"触发后"钩子
- **代价**：复制体是临时的（回合结束消失），数值减半
- **与现有"共鸣"的区别**：现有共鸣是链式触发，这是生成副本

**Block 示例**：
| Block | 效果 |
|-------|------|
| 回声石 (Echo Stone) | 1×1，伤害 4，触发时在随机空位生成一个 2 伤害副本 |
| 镜面阵列 (Mirror Array) | 1×2，双部件各伤害 3，每部件触发时各复制 1 个副本 |
| 回响水晶 (Resonant Crystal) | L 形，3 部件每部件触发时生成一个 1×1 护盾 2 副本 |

**拓展方向**：
- 副本可以继承/不继承原 Block 的机制标签
- 有 Stat 可以增加副本的伤害保留比例
- 副本可以被其他机制利用（如副本也有"回声"→ 链式爆炸）

---

### 提案 2：重力（Gravity）— Bot 速度操控

> **"改变 Bot 在网格上的行进速度——变慢让你有更多时间准备，变快则 Bot 在本回合内触发更多 Block。"**

- **插入点**：Bot 的 `_schedule_next_step()` 和 `_patrol_timer`
- **代价**：加速时 Bot 触发加快，但你也可能来不及放完 Block
- **核心思路**：目前 Bot 固定 1 秒/tick。改变 tick 节奏 = 改变"每个回合能放多少 Block"

**技术实现**：
```gdscript
# 在 Bot.gd 中：
var _speed_modifier: float = 1.0  # 1.0 = 正常速度, 2.0 = 双倍速, 0.5 = 半速

func _schedule_next_step() -> void:
    var interval = 1.0 / _speed_modifier
    _patrol_timer = get_tree().create_timer(interval)
    _patrol_timer.timeout.connect(_on_patrol_timer_timeout)

# StatBehavior 或其他系统可以修改 _speed_modifier
```

**Block 示例**：
| Block | 效果 |
|-------|------|
| 加速场 (Acceleration Field) | 1×1，无伤害，触发后 Bot 速度 ×1.5，持续 3 tick |
| 时间沙漏 (Hourglass) | 1×1，伤害 6，触发后 Bot 速度 ×0.5，持续 2 tick |
| 快慢双极 (Dual Polarity) | 1×2，A:加速 Bot；B:对敌人造成(速度倍率×4)伤害 |

**拓展方向**：
- 某些 Block 在 Bot 高速时额外加成（"趁热打铁"）
- 某些 Block 在 Bot 低速时效果更好（"精心瞄准"）
- 可以和"过载"联动——加速时每 tick 更多触发=更多过载

---

### 提案 3：电网（Gridlock）— 网格状态修改

> **"暂时或永久改变网格格子的状态——封锁格子让敌人无法占用，或激活格子给 Block 额外加成。"**

- **插入点**：`GridState.set_grid_state()` + 新枚举值 `GridStateEnum.Energized`
- **代价**：激活格子需要消耗额外的资源（HP/Block 弃置）
- **核心思路**：目前格子只有 Free/Occupied/Unable 三种状态。加入更多状态！

**技术实现**：
```gdscript
# Enums.gd 中新增：
enum GridStateEnum { Free, Unable, Occupied, Energized, Blocked }

# 新 Behavior：
class_name EnergizeGridBehavior extends BlockPartBehavior

func create_action(block, part):
    return CallbackAction.new(func():
        var grid_point = GridState.find_nearest_grid_point(part.global_position)
        var coords = GridState.get_grid_coords(grid_point)
        GridState.set_grid_state(coords.x, coords.y, Enums.GridStateEnum.Energized)
    )

# 在其他 Behavior 中：
func create_action(block, part):
    var coords = _get_part_coords(part)
    if GridState.get_grid_state(coords.x, coords.y) == Enums.GridStateEnum.Energized:
        return DamageAction.new(block, target, part.Damage * 2, 0.4)  # 翻倍伤害！
    return DamageAction.new(block, target, part.Damage, 0.4)
```

**Block 示例**：
| Block | 效果 |
|-------|------|
| 充能器 (Charger) | 1×1，无伤害，将所在格变为 Energized，持续 2 回合 |
| 高压电网 (High Voltage) | 1×2，每部件伤害 3，若在 Energized 格上伤害翻倍 |
| 电磁封锁 (EMP Lock) | 1×1，将一个 Enemy 占用的格变为 Blocked（敌人无法使用该格） |

**拓展方向**：
- Energized 格子可以被"引爆"（对周围造成 AOE）
- Blocked 格子阻止敌人放置 Block
- 有 Stat 可以让你开局自动 Energize 几格

---

### 提案 4：献祭（Sacrifice）— 消耗其他 Block 换取强力效果

> **"触发此 Block 时，消耗场上另一个己方 Block，获得其数值的一部分加成。"**

- **插入点**：Phase B，Behavior 的 `create_action()` 中调用 `_exhaust_block()` 类似逻辑
- **代价**：失去一个场上 Block（格子释放，但 Block 不回到牌组，直接消耗）
- **核心思路**：让玩家做"保留 vs 消耗"的决策

**Block 示例**：
| Block | 效果 |
|-------|------|
| 献祭祭坛 (Sacrificial Altar) | 1×1，消耗相邻 1 个己方 Block，获得该 Block 总伤害 150% 的伤害 |
| 能量转化 (Energy Conversion) | 1×1，消耗场上 1 个己方 Block，获得其护盾值作为治疗 |
| 灵魂熔炉 (Soul Forge) | 1×2，A:消耗 1 个己方 Block；B:生成一个"消耗过的 Block 总伤害"的爆发 |

**拓展方向**：
- 有 Stat 让你从献祭中获得额外收益
- 可以和"共鸣"联动——献祭链中的某个 Block
- 可以和"扎根"联动——献祭扎根 Block（"拔根"）获得大量收益

---

### 提案 5：寒冬（Frost）— 延迟触发/冻结

> **"Block 放置后不是立即生效，而是延迟 N 个 tick 后才被 Bot 触发。冻结（Frozen）状态的 Block 不可被触发，需要 Bot 额外踩一次解冻。"**

- **插入点**：Block 放置时的状态标记，以及 Bot 检测 Block 时的额外判断
- **代价**：延迟 = 不确定性，冻结 = 需要额外消耗 Bot tick

**技术实现**：
```gdscript
# Block 上加一个新状态
enum BlockState { Normal, Frozen, Delayed }

# 在 Bot._enqueue_block_actions_at() 中修改
func _enqueue_block_actions_at(grid_pos):
    for block in _block_piles_here.PlacedPile.Pile:
        if block.custom_state == BlockState.Frozen:
            block.custom_state = BlockState.Normal  # 解冻
            GameLog.debug("Block unfrozen, not triggered this tick")
            return  # 不触发
        if block.custom_state == BlockState.Delayed:
            if block.delay_counter > 0:
                block.delay_counter -= 1
                return  # 还没到触发时间
        # ... 正常触发逻辑
```

**Block 示例**：
| Block | 效果 |
|-------|------|
| 冰锥 (Ice Shard) | 1×1，伤害 8，延迟 2 tick 后触发 |
| 寒冬护盾 (Frost Shield) | 1×1，护盾 8，冻结——触发后不消耗，转为普通 |
| 暴风雪 (Blizzard) | 2×2，4 部件每部件伤害 4，冻结 1 回合——下回合同时解冻全部触发 |
| 暖阳 (Warm Sun) | 1×1，治疗 3，解除相邻 1 个 Block 的冻结/延迟 |

**拓展方向**：
- "霜冻 Stat"——每触发一个冻结 Block 累积，解冻时造成额外伤害
- 可以有 Block 主动"冻结"另一个 Block（延迟它的触发，配合 timing）
- 和 Bot 速度联动——Bot 越快，冻结越短

---

### 提案 6：寄生（Parasite）— 占用敌人格子

> **"寄生 Block 被触发后，不在己方格子上，而是『跳』到敌人占用的格子上，每回合从敌人处偷取生命/护盾。"**

- **插入点**：触发后的特殊移动逻辑 + 新的 StatBehavior
- **代价**：寄生 Block 本身数值很低，需要时间产生收益
- **核心思路**：把 Block 放到敌人"身上"

**Block 示例**：
| Block | 效果 |
|-------|------|
| 吸血藤 (Vampire Vine) | 1×1，伤害 2，触发后寄生到随机敌人格子，每回合偷 2 HP |
| 能量寄生虫 (Energy Parasite) | 1×1，护盾 2，寄生后每回合偷敌人 1 能量（敌人伤害 -2） |
| 孢子寄生 (Spore Parasite) | L 形，3 部件各伤害 1，每部件独立寄生不同敌人 |

**拓展方向**：
- 寄生 Block 可以被"驱散"（敌人某种攻击移除寄生）
- 有 Stat 增加寄生数量上限或偷取效率
- 寄生 Block 被清除时可能回馈一定的资源

---

### 提案 7：过载（Surge）— 连击/段数系统

> **"Block 触发时，计数器 +1。Block 的伤害取决于它的『段数位置』——本回合第 1/2/3/… 次触发的 Block 伤害递增。"**

- **插入点**：Phase A 或 Phase B 时读取全局计数器
- **注意**：这和已有的"过载(Overload)"不同——过载是**可消耗资源**，这里是**纯递增计数器**
- **代价**：段数越高越好，但开局低段数的 Block 很弱

**技术实现**：
```gdscript
# 全局计数器（可以用 StatBehavior 或者 BattleTime 的变量）
var _surge_counter: int = 0

# 在 TurnStarted 时重置
# 每个 BlockBehavior 在 create_action 时读取当前段数
func get_surge_multiplier() -> float:
    return 1.0 + (_surge_counter * 0.3)  # 每段 +30% 伤害
```

**Block 示例**：
| Block | 效果 |
|-------|------|
| 起手式 (Opening Strike) | 1×1，伤害 3，段数越高伤害越高 |
| 连击拳 (Combo Fist) | 1×2 横，A:伤害 2 当前段数；B:伤害 4 段数+1 |
| 百裂拳 (Hundred Fists) | 松动，每次触发段数+2（高速叠段） |
| 终结技 (Finisher) | 1×1，伤害 = 段数 × 3，消耗后段数清零 |

**拓展方向**：
- 某些 Block "重置"段数（适合中段爆发）
- 某些 Block "锁定"段数（本回合最低段数为 X）
- 可以和 Bot 速度联动——Bot 越快，段数叠越快

---

### 提案 8：虚空（Void）— 牌组/弃牌堆操纵

> **"与弃牌堆中的 Block 交互——回收、强化、或『埋葬』（永久移出游戏）弃牌堆的 Block 换取收益。"**

- **插入点**：Behavior 中调用 `BlockPileComponent` 的方法
- **代价**：弃牌堆操作通常伴随效果打折或消耗额外资源
- **核心思路**：目前弃牌堆只进不出，增加弃牌堆的战略意义

**技术实现**：
```gdscript
# 从弃牌堆回收 Block
class_name RecallBehavior extends BlockPartBehavior

func create_action(block, part):
    return CallbackAction.new(func():
        var pile = block.get_node_or_null("/root/BattleRoom/BlockPilesHere/DiscardedPile")
        if pile and pile.Pile.size() > 0:
            var recalled = pile.Pile.pick_random()
            pile.remove_block(recalled)
            # 将 recalled 加入手牌（待实现）
    )
```

**Block 示例**：
| Block | 效果 |
|-------|------|
| 回溯 (Recall) | 1×1，从弃牌堆回收 1 个 Block 到手牌，松动 |
| 虚空吞噬 (Void Devour) | 1×1，埋葬弃牌堆 3 个 Block，每 1 个 +4 伤害 |
| 时间裂隙 (Time Rift) | 1×2，A:回收弃牌堆 1 个松动 Block；B:该 Block 立即放置到相邻空格 |
| 遗忘祭坛 (Oblivion Altar) | 1×1，埋葬全场所有 Block，每埋葬 1 个治疗 2 HP |

**拓展方向**：
- 和"消耗(Exhaust)"联动——消耗的 Block 进入"虚空区"，有专属效果
- 有 Stat 可以让你从虚空区获得 buff
- "埋葬"可以有计数器——累计埋葬 N 个 Block 换大奖

---

### 提案 9：催化（Catalyst）— Block 升级/进化

> **"满足条件的 Block 会在战斗中『进化』成更强的版本——数值提升、增加部件、或改变机制。"**

- **插入点**：Phase C（`OnPostBlockExecute`）或回合结束（`OnTurnEnded`）
- **代价**：进化需要条件，未进化前数值偏低
- **核心思路**：让 Block 有"成长感"

**技术实现**：
```gdscript
# 在 Block 上加一个标记
var _evolution_stage: int = 0
var _evolution_trigger_count: int = 0

# 在触发时累计
func on_triggered():
    _evolution_trigger_count += 1
    if _evolution_trigger_count >= 3 and _evolution_stage == 0:
        _evolve_to_stage_1()

func _evolve_to_stage_1():
    _evolution_stage = 1
    for part in _parts:
        part.Damage = part.Damage * 1.5  # 伤害 +50%
    # 更新外观、描述等
```

**Block 示例**：
| Block | 效果 |
|-------|------|
| 幼体孢子 (Young Spore) | 1×1，伤害 2，每触发 1 次 +1 伤害（上限 +6） |
| 蛹 (Chrysalis) | 1×1，护盾 3，扎根。触发 2 次后进化——每回合额外提供 3 护盾 |
| 进化催化剂 (Evolution Catalyst) | 1×1，加速相邻 Block 的进化进度 +1 |
| 完全体 (Perfect Form) | 2×2，全部件基础伤害 2，每个部件独立进化 |

**拓展方向**：
- 可以有多种进化路径（分支进化）
- 进化后的 Block 可以解锁新标签（如"进化后获得松动"）
- 有 Stat 可以加速进化

---

## 7. 机制设计检查清单

在设计一个新机制时，逐条检查：

### 基础检查

- [ ] 能用一句话说清楚这个机制吗？
- [ ] 新玩家第一次看到能理解吗？（不需要读说明书）
- [ ] 它解决了什么"空白"？（不是已有机制的简单变体）
- [ ] 它有明确的代价或限制吗？
- [ ] 它和现有机制有至少一种交互可能吗？

### 实现检查

- [ ] 找到了合适的管线插入点吗？
- [ ] 是否需要修改 Bot.gd 核心循环？（尽量用 Behavior/Stat 方式避免）
- [ ] 是否需要新增 Action 类型？
- [ ] 是否需要新增 GridState 枚举值？
- [ ] 是否需要新增 Enums.StatExecuteAt 时机？

### 内容检查

- [ ] 至少有 5~8 个 Block 使用这个机制吗？
- [ ] 这 5~8 个 Block 覆盖了"接触→使用→围绕→惊喜"的层级吗？
- [ ] 至少有 1 个 Block 让机制与其他机制交互吗？
- [ ] 有跨战役的 Stat 拓展方案吗？
- [ ] 这个机制有"被玩家玩出花"的潜力吗？

### 平衡检查

- [ ] 机制的收益是否**小于**它的代价？（至少在有更好选择时如此）
- [ ] 机制是否会破坏游戏的核心循环？
- [ ] 机制是否会让某些现有 Block 变得完全没用？
- [ ] 机制是否过于依赖特定条件（"如果敌人有 X，但 X 不常有"）？
- [ ] 在 Ascension 高难度下，机制还能正常运作吗？

---

## 附录：设计哲学速查

| 原则 | 一句话 |
|------|--------|
| **可理解第一** | 玩家读不懂的机制，等于不存在 |
| **代价在前** | 告诉玩家"代价是什么"，再告诉"收益是什么" |
| **不要所有都好** | 有些 Block 就是为其他 Block 服务的（润滑剂） |
| **骰子不要乱** | 随机应该是"有趣的变化"，不是"致命的运气" |
| **机制间要有对话** | 两个机制放一起时，应该产生新的可能性 |
| **新机制不是新数值** | 机制的核心是"让玩家做新决策"，不是"更大数字" |
| **失败要归因明确** | 玩家输了应该知道"是因为我没用好 X 机制"而不是"这机制垃圾" |

---

> *本文档由 AI 助理综合项目代码分析、卡牌游戏设计理论、社区讨论整理而成。*
> *最后更新: 2026-07-22*
