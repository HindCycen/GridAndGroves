---
description: "Godot MCP 使用指南。Use when: 需要通过 MCP 操作 Godot 编辑器、创建/修改场景、操作节点、运行测试、管理资源"
applyTo: "**/*.gd"
---

# Godot MCP 使用指南

## 连接编辑器

开始操作前，先连接 Godot 编辑器会话：

```
session_manage(op="list")         # 查看可用会话
session_activate(session_id)      # 激活会话（或用项目名模糊匹配）
editor_state()                    # 确认编辑器就绪
```

## 常用操作映射

### 场景操作 (scene_manage)

| 操作 | MCP 调用 |
|------|----------|
| 创建新场景 | `scene_manage(op="create", params={path: "res://path/scene.tscn", root_type: "Node2D"})` |
| 保存当前场景 | `scene_save()` |
| 另存为 | `scene_manage(op="save_as", params={path: "res://path/new_name.tscn"})` |
| 打开场景 | `scene_open(path="res://path/scene.tscn")` |
| 列出已打开场景 | `scene_manage(op="get_roots")` |

### 节点操作 (node_manage + node_create + node_set_property + node_find)

| 操作 | MCP 调用 |
|------|----------|
| 创建节点 | `node_create(parent_path="路径", name="NodeName", type="Node2D")` |
| 设置属性 | `node_set_property(path="路径/NodeName", property="position", value=Vector2(...))` |
| 读取属性 | `node_get_properties(path="路径/NodeName")` |
| 查找节点 | `node_find(search="name", type="Area2D")` |
| 删除节点 | `node_manage(op="delete", params={path: "路径/NodeName"})` |
| 重命名 | `node_manage(op="rename", params={path: "...", new_name: "NewName"})` |
| 重设父级 | `node_manage(op="reparent", params={path: "...", new_parent: "..."})` |
| 获取子节点 | `node_manage(op="get_children", params={path: "..."})` |
| 获取分组 | `node_manage(op="get_groups", params={path: "..."})` |
| 添加到组 | `node_manage(op="add_to_group", params={path: "...", group: "stats"})` |

### 脚本操作 (script_create + script_patch + script_manage)

| 操作 | MCP 调用 |
|------|----------|
| 创建 GDScript | `script_create(path="res://scripts/my_script.gd", content="...")` |
| 修改 GDScript | `script_patch(path="res://scripts/my_script.gd", old_text="...", new_text="...")` |
| 读取脚本 | `script_manage(op="read", params={path: "res://scripts/my_script.gd"})` |
| 查找符号 | `script_manage(op="find_symbols", params={path: "res://scripts/my_script.gd"})` |
| 附加脚本 | `script_attach(path="场景路径/NodeName", script_path="res://scripts/my_script.gd")` |
| 分离脚本 | `script_manage(op="detach", params={path: "场景路径/NodeName"})` |

### 文件系统 (filesystem_manage)

| 操作 | MCP 调用 |
|------|----------|
| 读取文本文件 | `filesystem_manage(op="read_text", params={path: "res://file.txt"})` |
| 写入文本文件 | `filesystem_manage(op="write_text", params={path: "res://file.txt", content: "..."})` |
| 扫描文件系统 | `filesystem_manage(op="scan")` — 添加 `class_name` 后调用 |
| 搜索文件 | `filesystem_manage(op="search", params={name: "keyword", type: "Resource", path: "res://"})` |
| 重新导入 | `filesystem_manage(op="reimport", params={paths: ["res://file.tres"]})` |

### 资源管理 (resource_manage)

| 操作 | MCP 调用 |
|------|----------|
| 搜索资源 | `resource_manage(op="search", params={name: "...", type: "BlockDef"})` |
| 加载资源 | `resource_manage(op="load", params={path: "res://resources/...tres"})` |
| 获取资源信息 | `resource_manage(op="get_info", params={path: "res://resources/...tres"})` |

### UI 操作 (ui_manage)

| 操作 | MCP 调用 |
|------|----------|
| 设置锚点预设 | `ui_manage(op="set_anchor_preset", params={path: "...", preset: "full_rect"})` |
| 设置文字 | `ui_manage(op="set_text", params={path: "...", text: "新文字"})` |
| 构建布局树 | `ui_manage(op="build_layout", params={tree: {...}, parent_path: "..."})` |
| 绘制矢量图 | `ui_manage(op="draw_recipe", params={path: "...", ops: [...]})` |

### 场景层级与截图

| 操作 | MCP 调用 |
|------|----------|
| 查看场景树 | `scene_get_hierarchy(depth=10)` |
| 编辑器截图 | `editor_screenshot(source="viewport")` |
| 游戏截图 | `editor_screenshot(source="game")` |

### 测试运行

| 操作 | MCP 调用 |
|------|----------|
| 运行测试 | `test_run()` |
| 查看上次结果 | `test_manage(op="results_get")` |
| 查看详细结果 | `test_manage(op="results_get", params={verbose: true})` |

### 游戏运行与交互 (project_manage + game_manage)

| 操作 | MCP 调用 |
|------|----------|
| 运行项目 | `project_run()` |
| 停止项目 | `project_manage(op="stop")` |
| 获取游戏场景树 | `game_manage(op="get_scene_tree", params={depth: 10})` |
| 获取节点信息 | `game_manage(op="get_node_info", params={path: "..."})` |
| 获取 UI 元素 | `game_manage(op="get_ui_elements")` |
| 发送按键 | `game_manage(op="input_key", params={key: "A", pressed: true})` |
| 发送鼠标事件 | `game_manage(op="input_mouse", params={event: "button", position: {x: 100, y: 200}})` |
| 执行 GDScript | `editor_manage(op="game_eval", params={code: "print('hello')"})` |

### 日志查看 (logs_read)

| 操作 | MCP 调用 |
|------|----------|
| 查看最近日志 | `logs_read(source="all", count=50)` |
| 查看游戏日志 | `logs_read(source="game", count=50, include_details=true)` |
| 查看编辑器日志 | `logs_read(source="editor", include_details=true)` |
| 清除日志 | `editor_manage(op="logs_clear")` |

### 编辑器操作 (editor_manage)

| 操作 | MCP 调用 |
|------|----------|
| 获取编辑器状态 | `editor_manage(op="state")` |
| 获取选中节点 | `editor_manage(op="selection_get")` |
| 设置选中节点 | `editor_manage(op="selection_set", params={paths: ["..."]})` |
| 获取性能监视器 | `editor_manage(op="monitors_get")` |

### 信号管理 (signal_manage)

| 操作 | MCP 调用 |
|------|----------|
| 列出信号 | `signal_manage(op="list", params={path: "..."})` |
| 连接信号 | `signal_manage(op="connect", params={path: "...", signal: "signal_name", target: "...", method: "method_name"})` |
| 断开信号 | `signal_manage(op="disconnect", params={path: "...", signal: "signal_name", target: "...", method: "method_name"})` |

### 动画管理 (animation_manage)

| 操作 | MCP 调用 |
|------|----------|
| 创建动画播放器 | `animation_manage(op="player_create", params={path: "..."})` |
| 创建动画 | `animation_manage(op="create_simple", params={player_path: "...", animation_name: "..."})` |
| 添加属性轨道 | `animation_manage(op="add_property_track", params={player_path: "...", animation_name: "...", ...})` |
| 应用预设 | `animation_manage(op="preset_fade", params={...})` |

### 相机管理 (camera_manage)

| 操作 | MCP 调用 |
|------|----------|
| 创建相机 | `camera_manage(op="create", params={parent_path: "...", type: "2d", make_current: true})` |
| 配置相机 | `camera_manage(op="configure", params={camera_path: "...", properties: {...}})` |
| 设置 2D 边界 | `camera_manage(op="set_limits_2d", params={camera_path: "...", left: 0, right: 1920})` |

### 音效管理 (audio_manage)

| 操作 | MCP 调用 |
|------|----------|
| 创建音频播放器 | `audio_manage(op="player_create", params={parent_path: "...", name: "SFXPlayer"})` |
| 设置音频流 | `audio_manage(op="player_set_stream", params={player_path: "...", stream_path: "res://..."})` |
| 播放/停止 | `audio_manage(op="play", params={player_path: "..."})` / `audio_manage(op="stop", params={player_path: "..."})` |

## 典型工作流示例

### 创建新 Block 内容

```
1. script_create(path="res://resources/blockpart_behaviors/MyBehavior.gd", content="...")
2. filesystem_manage(op="scan")  # 刷新 class_name 注册
3. 编辑 resources/block_defs.json 添加新 Block 条目（直接使用文件编辑工具）
4. 启动游戏验证 | project_run() → 观察 game 日志
```

### 调试场景问题

```
1. editor_screenshot(source="viewport")   # 看编辑器当前视图
2. scene_get_hierarchy(depth=5)           # 看场景树结构
3. node_get_properties(path="问题节点")     # 检查节点属性
4. logs_read(source="all", include_details=true)  # 查看错误日志
```

### 创建 UI 界面

```
1. node_create(parent_path="...", name="MyPanel", type="Panel")
2. ui_manage(op="set_anchor_preset", params={path: ".../MyPanel", preset: "full_rect"})
3. ui_manage(op="build_layout", params={parent_path: ".../MyPanel", tree: {...}})
4. scene_save()
```

## 注意事项

- MCP 写操作（创建/修改/删除）需要编辑器处于**可写状态**（非播放中）
- 如果编辑器正在播放，先 `project_manage(op="stop")` 再操作
- 添加 `class_name` 的脚本后，调用 `filesystem_manage(op="scan")` 刷新全局注册
- 对 `.gd` 文件的大幅修改优先使用 `script_patch`（锚点替换），而非重写整个文件
- 场景/资源操作后调用 `scene_save()` 保存更改
