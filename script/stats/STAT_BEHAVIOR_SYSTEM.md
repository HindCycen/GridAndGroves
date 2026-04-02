# StatBehavior 自动执行系统

## 概述

本系统实现了基于特性（Attribute）的 Stat 行为自动触发机制。当战斗中的特定事件发生时（如回合开始、回合结束等），所有标记了相应特性的方法会自动执行。

## 核心组件

### 1. StatusBehaviorAttribute - 特性定义

**位置**: `script/attributes/StatusBehavior.cs`

```csharp
[AttributeUsage(AttributeTargets.Method)]
public class StatusBehaviorAttribute : Attribute {
    public Glob.StatExecuteAt Period;
}
```

**作用**:

- 用于标记需要在特定时期执行的方法
- 通过 `Period` 参数指定执行时机

**可用时期** (`Glob.StatExecuteAt`):

- `OnBattleStarted` - 战斗开始时
- `OnTurnStarted` - 回合开始时
- `OnTicTac` - 滴答时
- `OnTurnEnded` - 回合结束时
- `OnBattleEnded` - 战斗结束时

---

### 2. StatBehavior - 基类扩展

**位置**: `script/core/stats/StatBehavior.cs`

**新增功能**:

#### a) StatExecuteMethod 结构体

```csharp
public struct StatExecuteMethod {
    public MethodInfo Method;        // 方法信息
    public Glob.StatExecuteAt ExecuteAt;  // 执行时机
}
```

#### b) ExecuteMethods 属性

```csharp
public StatExecuteMethod[] ExecuteMethods { get; private set; }
```

存储所有标记了 `[StatusBehavior]` 的方法

#### c) CacheExecuteMethods() 方法

```csharp
private void CacheExecuteMethods() {
    var methods = GetType().GetMethods(BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
    var executeList = new List<StatExecuteMethod>();
    
    foreach (var method in methods) {
        var attr = method.GetCustomAttribute<StatusBehaviorAttribute>();
        if (attr != null) {
            executeList.Add(new StatExecuteMethod {
                Method = method,
                ExecuteAt = attr.Period
            });
        }
    }
    
    ExecuteMethods = executeList.ToArray();
}
```

**作用**: 使用反射扫描并缓存所有标记方法

#### d) ExecuteAt() 方法

```csharp
public void ExecuteAt(Glob.StatExecuteAt period) {
    if (ExecuteMethods == null) return;
    
    foreach (var exec in ExecuteMethods) {
        if (exec.ExecuteAt == period && exec.Method != null) {
            exec.Method.Invoke(this, null);
        }
    }
}
```

**作用**: 根据指定时期调用对应的所有方法

---

### 3. Stat - 节点注册

**位置**: `script/core/stats/Stat.cs`

**修改内容**:

```csharp
public override void _Ready() {
    CurrentValue = 0;
    Definition.Behavior.SetBelongingStat(this);
    AddToGroup("stats");  // ← 新增：添加到 "stats" 组
}
```

**作用**:

- 将所有 Stat 节点添加到 "stats" 组，便于全局查找和管理

---

### 4. BattleTime - 事件触发器

**位置**: `script/global/BattleTime.cs`

**修改内容**:

#### a) 订阅战斗事件

```csharp
public override void _Ready() {
    EmitSignalBattleContextReady();
    
    // Subscribe to battle events and trigger stat behaviors
    BattleStarted += () => ExecuteStatBehaviors(Glob.StatExecuteAt.OnBattleStarted);
    TurnStarted += () => ExecuteStatBehaviors(Glob.StatExecuteAt.OnTurnStarted);
    TicTac += () => ExecuteStatBehaviors(Glob.StatExecuteAt.OnTicTac);
    TurnEnded += () => ExecuteStatBehaviors(Glob.StatExecuteAt.OnTurnEnded);
    BattleEnded += () => ExecuteStatBehaviors(Glob.StatExecuteAt.OnBattleEnded);
}
```

#### b) 执行 Stat 行为

```csharp
private void ExecuteStatBehaviors(Glob.StatExecuteAt period) {
    var stats = GetTree().GetNodesInGroup("stats");
    foreach (var node in stats) {
        if (node is Stat stat && stat.Definition?.Behavior != null) {
            stat.Definition.Behavior.ExecuteAt(period);
        }
    }
}
```

**作用**:

- 监听所有战斗事件信号
- 当事件触发时，查找场景中所有 Stat 节点
- 调用每个 Stat Behavior 在对应时期的所有方法

---

## 使用示例

### 创建自定义 StatBehavior

**文件**: `resources/stat_behaviors/ExampleStatBehavior.cs`

```csharp
using Godot;
using System;

public partial class ExampleStatBehavior : StatBehavior {
    [StatusBehavior(Period = Glob.StatExecuteAt.OnTurnEnded)]
    public void ExecuteStat() {
        GD.Print("Example Status Executed");
    }
}
```

**说明**:

- 继承自 `StatBehavior`
- 使用 `[StatusBehavior(Period = ...)]` 标记需要在特定时期执行的方法
- 一个类可以有多个标记方法
- 同一个方法可以在不同时期执行（使用多个标记）

---

## 数据流和协作关系

```
┌─────────────────────────────────────────────────────────────┐
│                    游戏启动 / 战斗开始                        │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│  Stat._Ready()                                              │
│  ├─ 初始化 CurrentValue = 0                                 │
│  ├─ 调用 Behavior.SetBelongingStat(this)                    │
│  │   └─ CacheExecuteMethods() ← 反射扫描标记方法             │
│  └─ AddToGroup("stats") ← 注册到全局组                       │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│  BattleTime._Ready()                                        │
│  订阅所有战斗事件信号：                                      │
│  ├─ BattleStarted → OnBattleStarted                         │
│  ├─ TurnStarted → OnTurnStarted                             │
│  ├─ TicTac → OnTicTac                                       │
│  ├─ TurnEnded → OnTurnEnded ← 示例使用此事件                 │
│  └─ BattleEnded → OnBattleEnded                             │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
          战斗事件触发 (如：TurnEnded)
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│  BattleTime.ExecuteStatBehaviors(OnTurnEnded)               │
│  ├─ GetTree().GetNodesInGroup("stats")                      │
│  │   └─ 获取场景中所有 Stat 节点                              │
│  └─ 对每个 Stat 节点:                                         │
│      └─ stat.Definition.Behavior.ExecuteAt(OnTurnEnded)     │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│  StatBehavior.ExecuteAt(OnTurnEnded)                        │
│  ├─ 遍历 ExecuteMethods 数组                                 │
│  └─ 找到 ExecuteAt == OnTurnEnded 的方法                     │
│      └─ 调用：exec.Method.Invoke(this, null)                │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│  ExampleStatBehavior.ExecuteStat()                          │
│  └─ GD.Print("Example Status Executed") ✅                  │
└─────────────────────────────────────────────────────────────┘
```

---

## 关键设计模式

### 1. 特性驱动开发 (Attribute-Driven Development)

- 使用 `[StatusBehavior]` 特性声明式地标记方法
- 无需手动注册或配置
- 代码即文档，意图清晰

### 2. 反射缓存优化

- 在 `_Ready()` 时一次性扫描并缓存方法信息
- 避免每次事件触发时都进行反射操作
- 平衡了灵活性和性能

### 3. 观察者模式 (Observer Pattern)

- `BattleTime` 作为事件源
- `StatBehavior` 作为观察者
- 通过信号 - 槽机制解耦

### 4. 策略模式 (Strategy Pattern)

- `StatBehavior` 可被继承和重写
- 不同的 Stat 可以有不同的行为实现
- 支持热插拔

---

## 扩展指南

### 添加新的执行时期

1. 在 `GlobConstants.cs` 中添加枚举值:

```csharp
public enum StatExecuteAt {
    OnBattleStarted, 
    OnTurnStarted,
    OnTicTac,
    OnTurnEnded,
    OnBattleEnded,
    OnCustomEvent  // ← 新增值
}
```

2. 在 `BattleTime.cs` 中添加对应的事件处理:

```csharp
// 添加新信号
[Signal]
public delegate void CustomEventEventHandler();

// 在 _Ready() 中订阅
CustomEvent += () => ExecuteStatBehaviors(Glob.StatExecuteAt.OnCustomEvent);

// 添加触发方法
public void SayCustomEvent() {
    EmitSignalCustomEvent();
}
```

### 创建复杂的行为逻辑

```csharp
public partial class HealthRegenerationBehavior : StatBehavior {
    [StatusBehavior(Period = Glob.StatExecuteAt.OnTurnStarted)]
    public void RegenerateHealth() {
        // 每回合开始时恢复生命值
        if (_belongingStat != null && !_belongingStat.IsFull) {
            _belongingStat.AddValue(10);
        }
    }
    
    [StatusBehavior(Period = Glob.StatExecuteAt.OnTurnEnded)]
    public void CheckOverheal() {
        // 每回合结束时检查是否过量治疗
        GD.Print("Current HP: " + _belongingStat.CurrentValue);
    }
}
```

---

## 注意事项

1. **性能考虑**
    - 反射仅在初始化时执行一次
    - 方法调用使用缓存的 `MethodInfo`
    - 避免在标记方法中执行耗时操作

2. **方法签名**
    - 标记方法不能有参数
    - 返回值会被忽略
    - 建议使用 `void` 返回类型

3. **访问修饰符**
    - 支持 `public` 和 `private` 方法
    - 推荐使用 `public` 提高可读性

4. **错误处理**
    - 确保标记方法不会抛出未处理的异常
    - 异常会中断后续方法的执行

---

## 相关文件清单

| 文件路径                                              | 作用      | 修改状态  |
|---------------------------------------------------|---------|-------|
| `script/attributes/StatusBehavior.cs`             | 特性定义    | 已有    |
| `script/core/stats/StatBehavior.cs`               | 行为基类    | ✨ 已扩展 |
| `script/core/stats/Stat.cs`                       | 统计节点    | ✨ 已修改 |
| `script/global/BattleTime.cs`                     | 战斗时间管理  | ✨ 已扩展 |
| `script/global/GlobConstants.cs`                  | 全局常量/枚举 | 已有    |
| `resources/stat_behaviors/ExampleStatBehavior.cs` | 示例行为    | 用户创建  |

---

## 总结

该系统提供了一个灵活、可扩展的方式来管理战斗中的各种持续性效果（DoT、HoT、Buff、Debuff
等）。通过特性标记和自动触发，大大减少了样板代码，提高了开发效率和代码可维护性。
