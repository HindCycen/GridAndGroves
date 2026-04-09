# Grid and Groves

一个基于 Godot 4.6 + C# 开发的策略战斗游戏，采用网格系统和卡牌机制。

## 🎮 游戏特色

- **网格战斗系统**：基于网格的战术布局，玩家需要策略性地放置方块
- **卡牌构筑玩法**：通过牌堆管理系统获取和使用不同的方块卡牌
- **属性状态系统**：支持自定义的状态行为和效果触发机制
- **回合制战斗**：包含完整的回合流程（开始、执行、结束）
- **可视化组件**：生命值、防御值、状态图标等 UI 渲染系统

## 🛠️ 技术栈

- **游戏引擎**: Godot Engine 4.6
- **编程语言**: C# (.NET)
- **架构模式**: 组件化设计 + 自动加载全局管理器

## 📁 屎山结构

```
GridAndGroves/
├── actors/              # 角色系统（玩家、敌人等）
│   └── player/         # 玩家相关组件
├── attributes/          # 特性定义（用于行为标记）
├── battle/             # 战斗场景和逻辑
├── blocks/             # 方块系统核心
│   ├── blockdefs/      # 方块定义资源
│   ├── blockparts/     # 方块部件资源
│   └── blockpart_behaviors/  # 方块部件行为
├── components/         # 可复用组件
│   ├── healthbar/      # 生命条相关资源
│   └── *.cs           # 各种组件（生命、防御、状态、牌堆等）
├── global/             # 全局管理器和常量
├── registerers/        # 注册器系统
├── resources/          # 资源文件
│   └── stat_behaviors/ # 状态行为实现
└── stats/              # 属性状态系统
```

## 🔑 核心系统

### 1. 方块系统 (Blocks)

方块是游戏的核心玩法元素，由多个部件组成：

- **Block**: 方块主体，处理拖放、放置验证等逻辑
- **BlockDef**: 方块定义资源，描述方块的属性和部件配置
- **BlockPart**: 方块部件，构成方块的各个单元
- **BlockPartBehavior**: 部件行为，定义部件的特殊效果

### 2. 牌堆系统 (Pile)

管理方块的抽取、展示和弃置：

- **Draw Pile**: 抽牌堆
- **Showing Pile**: 展示堆（当前可用的方块）
- **Placed Pile**: 已放置堆
- **Discarded Pile**: 弃牌堆

### 3. 属性状态系统 (Stats)

基于特性标记的自动化状态行为系统：

- **Stat**: 属性节点，管理数值变化
- **StatBehavior**: 行为基类，支持自动触发
- **StatusBehaviorAttribute**: 特性标记，指定执行时机

支持的触发时机：
- `OnBattleStarted` - 战斗开始
- `OnTurnStarted` - 回合开始
- `OnTicTac` - 滴答事件
- `OnTurnEnded` - 回合结束
- `OnBattleEnded` - 战斗结束

### 4. 战斗时间管理 (BattleTime)

全局战斗流程控制器，负责：

- 管理战斗各阶段的信号发射
- 触发对应的状态行为
- 协调回合流程

### 5. 全局管理器 (Glob)

提供全局服务：

- 网格坐标管理
- 随机数生成
- 方块注册和创建
- 网格状态追踪

## 🚀 快速开始

### 环境要求

- Godot Engine 4.6 或更高版本
- .NET SDK 8.0+

### 运行项目

1. 克隆仓库
```bash
git clone <repository-url>
cd GridAndGroves
```

2. 使用 Godot 编辑器打开项目根目录

3. 在 Godot 编辑器中点击运行按钮（F5）

### 构建导出

1. 在 Godot 编辑器中选择 `项目` → `导出`
2. 选择目标平台
3. 配置导出参数
4. 点击 `导出项目`

## 📝 开发指南

### 创建新的方块

1. 创建 `BlockPartDef` 资源定义部件
2. 创建 `BlockDef` 资源，组合部件
3. （可选）实现自定义 `BlockPartBehavior`
4. 在 `GlobBlockInitializer` 中注册

### 创建新的状态行为

```csharp
public class MyStatBehavior : StatBehavior {
    [StatusBehavior(Period = Glob.StatExecuteAt.OnTurnEnded)]
    public void ExecuteEffect() {
        // 在回合结束时执行的逻辑
        GD.Print("效果触发！");
    }
}
```

### 添加新组件

组件应继承自合适的 Godot 节点类型，并放置在 `components/` 目录下。

## 🎯 游戏流程

1. **战斗开始** (`OnBattleStarted`)
   - 初始化双方单位
   - 填充抽牌堆
   - 触发战斗开始时的状态效果

2. **回合开始** (`OnTurnStarted`)
   - 从抽牌堆抽取方块到展示堆
   - 重置临时状态（如防御值）
   - 触发回合开始时的状态效果

3. **玩家操作阶段**
   - 拖拽方块到战场网格
   - 方块部件检测碰撞并执行效果
   - Bot 移动和交互

4. **回合结束** (`OnTurnEnded`)
   - 处理放置的方块
   - 清理临时状态
   - 触发回合结束时的状态效果

5. **战斗结束** (`OnBattleEnded`)
   - 判定胜负
   - 触发战斗结束时的状态效果

目前主要在开发Battle场景喵。Main.tscn好像没东西。