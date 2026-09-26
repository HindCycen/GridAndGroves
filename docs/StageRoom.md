# 楼层内循环系统文档

## 概述

本文档描述了游戏中的"楼层内循环"(Floor Loop)系统。玩家从 StageRoom 出发,
通过点击地图上的格子(ButtonNode, Bn)进入 BattleRoom 或 EventRoom,
完成后返回 StageRoom, 推进房间进度。

`Room` 的四个子类：`BattleRoom` / `EventRoom` / `StageRoom` / `ShopRoom`。
战斗胜利后进入 `ShopRoom`（不直接回地图），从商店离开后才返回地图。

## 类层次结构

```
Room (res://room/Room.gd)
├── BattleRoom (res://room/BattleRoom.gd) — 战斗房间
├── EventRoom (res://room/EventRoom.gd) — 事件房间
├── ShopRoom (res://room/ShopRoom.gd) — 战后商店（每场胜利必经）
└── StageRoom (res://room/StageRoom.gd) — 楼层地图
```

## 核心变量

- `Player.RoomCount`: 当前楼层已探索的房间数
- `Player.StageCount`: 当前所处的楼层编号

## 房间行为

### Room (基类)
- 创建状态栏(顶部条, 心形图标, 血量标签)
- 显示 `Stage: {stageCount}    Room: {roomCount}` 于状态栏正中央
- 加载存档

### BattleRoom
- 战斗房间
- 继承自 Room，每次进入时会增加 roomCount

### EventRoom
- 事件房间
- 继承自 Room，每次进入时会增加 roomCount

### StageRoom
- 管理 **14 列 × 7 行** 的地图网格(每个格子 96×96 像素)，`Cols = 14, Rows = 7`
- 网格容器 Node2D 位于屏幕正中央
- 格子图片: 左下角(0,6)和右上角(13,0)必须为 BattleRoomBn, 其余通过 `mapRand` 随机决定
- 导航规则:
  - 初次进入 StageRoom 时, 仅左下角 Bn 可点击(此时 roomCount == 0)
  - 离开一个房间后, 解锁其"上方"(row-1)和"右方"(col+1)的紧邻 Bn
  - 可点击 Bn 的透明度在 0~1 之间以 1 秒为周期循环
  - 点击 Bn: 先闪烁 3 次(0.15 秒 ON / 0.15 秒 OFF), 然后进入对应房间
  - 离开房间后, 对应 Bn 透明度固定为 50%
- 单击 BattleRoomBn:
  - 根据 roomCount 选择敌人图表（`resources/enemy_defs.json` 的 `stageCharts`）:
    - roomCount >= 20: 使用 `bossCharts`
    - roomCount 7~13 且有 25% 概率（`monsterRand`）: 使用 `eliteCharts`（精英战）
    - roomCount > 6: 使用 `strongCharts`
    - roomCount ≤ 6: 使用 `weakCharts`
  - 敌人血量/攻击按楼层缩放：`×(1 + 0.12 × (StageCount - 1))`（在 EnemyManager 注入）
  - 使用 `monsterRand` 从对应图表中随机选择一组敌人
  - 实例化 BattleRoom 并跳转
- 单击 EventRoomBn: 实例化 EventRoom 并跳转

### BattleRoom
- 继承自 Room，每次进入计入房间数
- 通过 EnemyChart 生成敌人
- 胜利(OnVictory)后进入 ShopRoom（等待 1.2 秒）
- 战败 → GameOver（第 3 层 Boss 战胜利 → ShopRoom 离店时进入 Victory 通关结算）

### EventRoom
- 继承自 Room，每次进入计入房间数
- 阶段 1: 显示 EventDesc + 2~4 个选项按钮
  - 按钮悬停时显示 Description Tooltip (支持颜色语法 [R]{}, [G]{}, [B]{}, [Y]{})
- 阶段 2: 点击按钮 → 执行 FollowingAction → 显示 ResultDescription + 一个 "Continue" 按钮
- 点击 Continue → 回到 StageRoom

## 资源数据结构

### EventChoiceDef (res://resources/EventChoiceDef.gd)
- Name: 按钮显示名
- Description: 悬停描述(支持颜色语法)
- ResultDescription: 执行后显示的文本
- ActionType: 执行动作类型(EventActionType 枚举)
- ActionValue: 动作参数

### EventDef (res://resources/EventDef.gd)
- EventDesc: 事件描述文本
- Choices: EventChoiceDef 数组

### EventRand (res://resources/EventRand.gd)
- PossibleEvents: EventDef 数组, 用于随机抽取

### StageDef (res://resources/StageDef.gd)
- StageEventRand: EventRand
- StartingDeck: Array[String]（初始牌组 Block 名称）

## 存档数据

DataResource 额外保存:
- StageCount / RoomCount
- GridClickable / GridLeft (地图格子状态)
- StageDefPath (当前 StageDef 资源路径)

## 美术资源

- `res://room/room_pictures/BattleRoomBn.png`: 战斗房间 Bn 图片(96×96)
- `res://room/room_pictures/EventRoomBn.png`: 事件房间 Bn 图片(96×96)
- `res://room/room_pictures/BackToStage.png`: 返回按钮图片
