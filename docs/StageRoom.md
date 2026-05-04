# 楼层内循环系统文档

## 概述

本文档描述了游戏中的"楼层内循环"(Floor Loop)系统。玩家从 StageRoom 出发,
通过点击地图上的格子(ButtonNode, Bn)进入 BattleRoom 或 EventRoom,
完成后返回 StageRoom, 推进房间进度。

## 类层次结构

```
Room (res://room/Room.cs)
├── CountedRoom (res://room/CountedRoom.cs)
│   ├── BattleRoom (res://battle/BattleRoom.cs) — 战斗房间
│   └── EventRoom (res://room/EventRoom.cs) — 事件房间
└── UncountedRoom (res://room/UncountedRoom.cs)
    └── StageRoom (res://room/StageRoom.cs) — 楼层地图
```

## 核心变量

- `Player.RoomCount`: 当前楼层已探索的房间数(仅 CountedRoom 计入)
- `Player.StageCount`: 当前所处的楼层编号

## 房间行为

### Room (基类)
- 创建状态栏(顶部条, 心形图标, 血量标签)
- 显示 `Stage: {stageCount}    Room: {roomCount}` 于状态栏正中央
- 加载存档

### CountedRoom
- 首次进入时该场景时, 将 Player.RoomCount 加 1
- 使用场景路径(SceneFilePath)作为唯一标识, 防止重复计数

### UncountedRoom
- 不增加 RoomCount 的房间, 纯基类

### StageRoom
- 管理 7 列 × 14 行的地图网格(每个格子 96×96 像素)
- 网格容器 Node2D 位于屏幕正中央
- 格子图片: 左下角(0,13)和右上角(6,0)必须为 BattleRoomBn, 其余通过 `mapRand` 随机决定
- 导航规则:
  - 初次进入 StageRoom 时, 仅左下角 Bn 可点击(此时 roomCount == 0)
  - 离开一个房间后, 解锁其"上方"(row-1)和"右方"(col+1)的紧邻 Bn
  - 可点击 Bn 的透明度在 0~1 之间以 1 秒为周期循环
  - 点击 Bn: 先闪烁 3 次(0.15 秒 ON / 0.15 秒 OFF), 然后进入对应房间
  - 离开房间后, 对应 Bn 透明度固定为 50%
- 单击 BattleRoomBn:
  - 根据 roomCount 选择敌人:
    - roomCount == 20: 使用 BossChart
    - roomCount > 6: 使用 StrongEnemyChart
    - roomCount ≤ 6: 使用 WeakEnemyChart
  - 使用 `monsterRand` 从对应 Chart 中随机选择 EnemyChartDef
  - 实例化 BattleRoom 并跳转
- 单击 EventRoomBn: 实例化 EventRoom 并跳转

### BattleRoom
- 继承自 CountedRoom (计入房间数)
- 通过 EnemyChart 生成敌人
- 胜利(OnVictory)后回到 StageRoom (等待 1 秒)

### EventRoom
- 继承自 CountedRoom (计入房间数)
- 阶段 1: 显示 EventDesc + 2~4 个选项按钮
  - 按钮悬停时显示 Description Tooltip (支持颜色语法 [R]{}, [G]{}, [B]{}, [Y]{})
- 阶段 2: 点击按钮 → 执行 FollowingAction → 显示 ResultDescription + 一个 "Continue" 按钮
- 点击 Continue → 回到 StageRoom

## 资源数据结构

### EventChoiceDef (res://resources/EventChoiceDef.cs)
- Name: 按钮显示名
- Description: 悬停描述(支持颜色语法)
- ResultDescription: 执行后显示的文本
- ActionType: 执行动作类型(EventActionType 枚举)
- ActionValue: 动作参数

### EventDef (res://resources/EventDef.cs)
- EventDesc: 事件描述文本
- Choices: EventChoiceDef 数组

### EventRand (res://resources/EventRand.cs)
- PossibleEvents: EventDef 数组, 用于随机抽取

### StageEnemyChartDef (res://resources/StageEnemyChartDef.cs)
- WeakEnemyChart: EnemyChartDef[] (roomCount ≤ 6)
- StrongEnemyChart: EnemyChartDef[] (roomCount > 6)
- EliteChart: EnemyChartDef[] (预留)
- BossChart: EnemyChartDef[] (roomCount == 20)

### StageDef (res://resources/StageDef.cs)
- StageEnemyChart: StageEnemyChartDef
- StageEventRand: EventRand

## 存档数据

DataResource 额外保存:
- StageCount / RoomCount
- GridClickable / GridLeft (地图格子状态)
- StageDefPath (当前 StageDef 资源路径)

## 美术资源

- `res://room/room_pictures/BattleRoomBn.png`: 战斗房间 Bn 图片(96×96)
- `res://room/room_pictures/EventRoomBn.png`: 事件房间 Bn 图片(96×96)
- `res://room/room_pictures/BackToStage.png`: 返回按钮图片
