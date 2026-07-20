# Grid and Groves 项目编辑指南

> 本文档是 AI 助手与人类开发者协作的核心参考文件，每次阅读项目时都会被自动加载。
> 请确保在做出更改时同步更新本文档。

## 项目概况

- **引擎**: Godot 4.7 (GDScript)
- **游戏类型**: 2D 游戏
- **脚本语言**: 仅使用 `.gd` 脚本，不使用 C#（`.cs`）
- **协作模式**: AI 助手 + 人类开发者共同编码

---

## 一、核心约定（不可违反）

以下约定是项目的基础规则，AI 助手必须严格遵守：

1. **场景创建** — 不要直接生成 `.tscn` 文件。描述场景的创建方式（节点结构、属性设置等），由人类开发者通过编辑器创建。直接生成的 `.tscn` 文件无法被编辑器正确识别。

2. **脚本创建** — 不要直接生成 `.gd` 文件。描述脚本的名称、路径，由人类开发者使用编辑器创建空文件，之后你再来填充内容。直接生成的文件会存在 `.uid` 问题，无法与编辑器良好协作。

3. **资源创建** — 可以直接创建 `.tres` 文件（如资源定义、数据配置等），这类文件适合通过代码生成。

4. **脚本语言** — 一律使用 GDScript（`.gd`），不得创建 C#（`.cs`）脚本。

5. **组合优于继承** — 能通过子节点组合实现的功能，不要使用继承来实现。避免单个节点管理大量内容的"上帝对象"架构。保持低耦合、高内聚。

6. **类名与文件名一致** — 每个脚本第一行必须是：
   ```gdscript
   class_name <ClassName> extends <ParentClass>
   ```
   `<ClassName>` 必须与文件名（不含扩展名）完全一致，使用 PascalCase。

---

## 二、项目组织与文件结构

### 2.1 文件夹命名规范

- 使用 **snake_case**（全小写+下划线）命名所有文件夹和文件（包括 `.gd`、`.tscn`、`.tres` 文件）
- 例外：`addons/` 目录下的第三方插件保留其原始命名

### 2.2 推荐目录结构

```
/project.godot
/.github/
    copilot-instructions.md      # 本文件
    instructions/                 # 按主题拆分的高级指令
    agents/                       # AI 代理定义
/docs/                            # 项目文档
/ assets/                         # 导入的原始资源（图片、音频等）
    /images/
    /audio/
    /fonts/
/scenes/                          # 通用场景
    /ui/                          # UI 相关场景
    /levels/                      # 关卡场景
/scripts/                         # 通用脚本（工具类、辅助函数）
    /autoload/                    # 自动加载的单例脚本
/components/                      # 可复用的节点组合（组件）
/resources/                       # .tres 资源定义
    /block_parts/
    /enemies/
    /items/
/blocks/                          # 方块模块
/rooms/                           # 房间模块
/enemies/                         # 敌人模块
/players/                         # 玩家模块
/addons/                          # 第三方插件
```

> **原则**: 资源按使用场景就近组织。与特定场景强相关的资源（图片、音效等）放在该场景所在文件夹下，全局共享的资源放在 `assets/` 中。

### 2.3 版本控制

- `.godot/` 目录应加入 `.gitignore`（自动生成的缓存）
- `*.translation` 文件应加入 `.gitignore`
- `*.uid` 文件应加入 `.gitignore`（由编辑器自动管理）
- 使用 LF 换行符（通过 `.gitattributes` 强制）
- 大文件（图片、音频等）建议使用 Git LFS 跟踪

---

## 三、场景组织最佳实践

### 3.1 场景即类

将场景视为面向对象中的"类"：
- 场景 = 节点组合的声明式定义（初始化方式 + 结构）
- 脚本 = 命令式行为（逻辑 + 方法）
- 两者配合使用：场景定义结构，脚本添加行为

### 3.2 场景设计原则

1. **单一职责** — 每个场景只负责一个明确的功能领域
2. **松耦合** — 场景应尽可能设计为无外部依赖，自包含（所需一切保留在内部）
3. **可复用** — 场景应能在不同上下文中复用，不依赖于特定父节点

### 3.3 场景间通信（依赖注入）

当场景必须与外部交互时，优先使用以下方式（从优到劣）：

1. **信号（Signal）** — 用于"响应"行为，信号名使用过去时态：
   ```gdscript
   signal door_opened
   signal item_collected
   signal damage_taken(amount: int)
   ```
   
2. **导出属性（@export）** — 父节点通过 Inspector 或代码注入依赖：
   ```gdscript
   @export var target: Node2D
   @export var move_speed: float = 100.0
   ```

3. **Callable 属性** — 比直接调用方法更灵活：
   ```gdscript
   var on_completed: Callable
   ```

4. **NodePath 属性** — 通过路径引用其他节点：
   ```gdscript
   @export var target_path: NodePath
   ```

5. **分组（Groups）** — 用组标签来标识和查找节点：
   ```gdscript
   add_to_group("enemies")
   get_tree().call_group("enemies", "take_damage", 10)
   ```

### 3.4 节点树结构建议

```
Main (main.gd)
├── World (Node2D)       # 游戏世界
│   ├── Player
│   ├── Enemies
│   └── Level
├── GUI (Control)        # 游戏界面
│   ├── HUD
│   └── Menus
└── Systems (Node)       # 系统节点（无变换传递）
    ├── AudioManager
    └── InputHandler
```

### 3.5 场景继承 vs 实例化

- 优先使用 **实例化（Instantiation）** 来复用场景
- 场景继承（Inheritance）仅在"是一个"关系明确时使用
- 场景实例化后可通过 `export` 变量定制行为，而非通过继承覆盖

---

## 四、GDScript 编写规范

### 4.1 代码顺序

每个脚本应遵循以下结构顺序：

```gdscript
@tool                           # 1. 注解（如需要）
class_name MyClass              # 2. 类名
extends Node                    # 3. 继承
## 类的文档注释                 # 4. 文档注释
                                # 5. 信号
signal my_signal
                                # 6. 枚举
enum State { IDLE, ACTIVE }
                                # 7. 常量
const MAX_SPEED = 200
                                # 8. 静态变量（如需要）
static var instances := 0
                                # 9. @export 变量
@export var speed := 100.0
                                # 10. 公共变量
var health := 100
                                # 11. 私有变量（前导下划线）
var _state := State.IDLE
                                # 12. @onready 变量
@onready var sprite := $Sprite
                                # 13. 内置虚方法（按生命周期顺序）
func _init():
    pass
func _ready():
    pass
func _process(delta: float):
    pass
                                # 14. 自定义方法
func my_method() -> void:
    pass
                                # 15. 内部类
class InnerClass:
    pass
```

### 4.2 命名规范

| 类别 | 规范 | 示例 |
|------|------|------|
| 文件名 | `snake_case` | `player_controller.gd` |
| 类名 | `PascalCase` | `class_name PlayerController` |
| 节点名 | `PascalCase` | `$HealthBar`, `%AnimationPlayer` |
| 函数/方法 | `snake_case` | `func take_damage(amount: int) -> void:` |
| 变量 | `snake_case` | `var current_health := 100` |
| 私有变量 | `_snake_case` | `var _internal_state := 0` |
| 信号 | `snake_case`（过去时态） | `signal health_changed` |
| 常量 | `CONSTANT_CASE` | `const MAX_LIVES := 3` |
| 枚举名 | `PascalCase`（单数） | `enum Element { ... }` |
| 枚举成员 | `CONSTANT_CASE` | `ELEMENT_FIRE` |

### 4.3 代码风格

- **缩进**: 使用制表符（Tab）（Godot 编辑器默认）
- **编码**: UTF-8 无 BOM，LF 换行符
- **行宽**: 尽量控制在 100 字符以内
- **运算符空格**: 运算符前后加空格，逗号后加空格
- **布尔运算符**: 使用英文 `and` / `or` / `not`，而非 `&&` / `||` / `!`
- **引号**: 优先使用双引号
- **浮点数**: 不省略前导/后缀零（`0.5` 而非 `.5`，`2.0` 而非 `2.`）
- **大数字**: 使用下划线分隔（`1_000_000`）
- **行尾逗号**: 多行数组/字典/枚举末尾加逗号

### 4.4 静态类型

充分利用 GDScript 的可选静态类型：

```gdscript
# 变量类型注解
var health: int = 100
var speed: float = 5.0
var direction: Vector2 = Vector2.ZERO
@export var player_node: Node2D

# 函数参数与返回值类型
func heal(amount: int) -> void:
    health += amount

func calculate_damage(base: int, multiplier: float) -> int:
    return roundi(base * multiplier)

# 使用 := 推断类型（赋值与声明在同一行时）
var position := Vector2.ZERO         # 推断为 Vector2
@onready var sprite := $Sprite       # 推断为 Node（精确类型需显式）
@onready var health_bar: ProgressBar = $UI/HealthBar  # 显式指定
```

### 4.5 注释规范

- 使用 `##` 文档注释为类和方法编写说明（支持 BBCode 标记）
- 使用 `#` 普通注释说明复杂逻辑
- 注释与代码之间空一格（`# 注释` 而非 `#注释`）
- 被注释掉的代码前不加空格（`#print("disabled")`）

---

## 五、架构设计原则

### 5.1 组合优于继承（重申）

- **用子节点组合实现功能复用**，而非通过类继承
- 例如：一个"可受伤"的角色，应包含 `HealthComponent` 子节点，而非继承自 `Damageable` 基类
- 避免"上帝节点"——单个节点不应对超过两个不同领域负责

### 5.2 何时使用场景 vs 纯脚本

| 场景（.tscn） | 纯脚本（.gd） |
|---|---|
| 定义节点组合结构 | 定义逻辑行为 |
| 声明式（编辑器友好） | 命令式（代码驱动） |
| 性能更优（引擎批量处理） | 适合通用工具/库 |
| 适合游戏特定概念 | 适合跨项目复用工具 |
| 设计人员可编辑 | 仅程序员可编辑 |

**经验法则**: 如果某概念有固定的节点结构，就做成场景；如果是纯粹的算法/数据操作，就做成脚本。

### 5.3 自动加载（Autoload）的使用

自动加载适合：
- **全局游戏管理器**（如：回合管理器、对话系统）
- **跨场景持久数据**（如：玩家进度、游戏设置）
- **系统级服务**（如：音频管理、输入处理）

自动加载不适合：
- **场景本地数据** — 应属于具体场景
- **可复用的工具函数** — 应使用静态函数（`static func`）或 `class_name` 脚本
- **任何应随场景销毁的状态**

> Godot 4.1+ 已支持 `static var`，部分全局状态可不用自动加载。

### 5.4 轻量级替代方案

当不需要完整节点功能时，使用更轻量的对象：

| 类 | 适用场景 | 内存管理 |
|---|---|---|
| `Object` | 自定义数据结构、树形结构 | 手动 `free()` |
| `RefCounted` | 数据容器、共享状态 | 自动引用计数 |
| `Resource` | 可序列化数据、检查器兼容 | 自动引用计数 |

---

## 六、数据与逻辑偏好

### 6.1 数据容器选择

| 需求 | 推荐 | 原因 |
|---|---|---|
| 顺序迭代、按索引访问 | `Array` | 连续内存，迭代最快 |
| 键值对映射、快速查找 | `Dictionary` | 哈希表，插入/删除最快 |
| 复杂数据结构、需要信号 | 自定义 `Object`/`RefCounted` | 可封装行为 |
| 可序列化配置数据 | `Resource`（`.tres`） | 检查器可见，可导出 |

### 6.2 枚举选择

- **整数枚举** — 性能优先，适合内部逻辑判断
- **字符串枚举**（`@export_enum`）— 可读性优先，适合打印/调试

### 6.3 加载策略

- **`preload()`** — 脚本加载时同步加载，适合确定会用到的小资源
- **`load()`** — 运行时按需加载，适合大型资源或条件性资源
- **常量 `const`** — 使用 `preload()` 给常量赋值（编译期确定）
- **导出属性 `@export`** — 由场景文件或检查器赋值（最灵活）

> 经验法则：如果资源几乎肯定会用到且体积小，用 `preload()`；否则用 `load()`。

### 6.4 节点初始化顺序

1. 创建节点（`Node.new()`）
2. 设置属性（名称、位置、脚本等）
3. 添加到场景树（`add_child()`）

在添加到场景树之前完成属性设置，某些属性 setter 会触发额外的计算，放在场景树外执行性能更好。

---

## 七、AI 协作规范

### 7.1 AI 助手的工作方式

- AI 助手每次读取项目时都会自动加载本文档
- AI 助手应主动查阅项目现有代码风格和结构，保持一致
- AI 助手需在做出结构性变更时同步更新本文档

### 7.2 AI 助手的输出规范

1. **场景设计** — 描述节点层次结构、属性设置、信号连接方式，不直接生成 `.tscn`
2. **脚本提供** — 描述脚本的完整路径、类名和完整代码内容，不直接生成 `.gd` 文件
3. **资源提供** — 可以直接生成 `.tres` 文件（纯文本格式）
4. **代码示例** — 提供完整的、可直接使用的代码片段，而不是伪代码或"省略"标记

### 7.3 变更流程

1. **分析** — AI 助手先阅读相关现有代码，理解架构上下文
2. **规划** — 给出清晰的实现计划，等待人类确认
3. **实施** — 按照约定输出代码/方案
4. **验证** — 确认变更的完整性和一致性
5. **文档** — 更新本文档中的相关部分

### 7.4 沟通风格

- AI 助手提供解释性注释和文档，方便人类理解意图
- 复杂逻辑应在代码中附带注释说明"为什么"而非"是什么"
- 当发现潜在问题或改进机会时，AI 助手应向人类提出建议

---

## 八、性能注意事项

- **节点数量**：避免创建数千个节点，对大量同质对象使用 `MultiMeshInstance2D` 或 `TileMap`
- **场景 vs 脚本**：场景（`PackedScene.instantiate()`）比纯脚本创建节点性能更好
- **`@onready`**：在 `_ready()` 之前缓存节点引用，避免重复 `$` 查找
- **资源缓存**：`load()` 和 `preload()` 会返回缓存的资源实例，需新实例时使用 `.duplicate()`
- **`is_instance_valid()`**：访问可能已销毁的对象前进行检查
- **`_process()` vs `_physics_process()`**：游戏逻辑放在 `_physics_process()`，视觉效果放在 `_process()`