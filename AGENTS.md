# Grid and Groves — AI 代理指南

> **入口文件** — 新代理首次在此项目中工作时，请优先阅读此文件及链接的文档。

## 快速导航

| 文件 | 说明 |
|------|------|
| `.github/copilot-instructions.md` | 项目概览、技术栈、代码规范、核心架构说明 |
| `.github/instructions/architecture.instructions.md` | 架构详细说明（Autoload、动作系统、Bot管线、StatBehavior、注册机制） |
| `.github/instructions/card-pack-design.instructions.md` | 卡包设计核心原则（三个主包的设计差异、特性标签、设计禁忌） |
| `.github/instructions/godot-mcp.instructions.md` | **Godot MCP 使用指南** — 优先使用 MCP 工具操作 Godot |
| `.github/agents/content-creator.agent.md` | 内容创建代理 — 创建 Block/Stat/Action/Enemy |
| `.github/agents/debug.agent.md` | 调试代理 — 排查错误、追踪 Bug |
| `.github/agents/explore.agent.md` | 探索代理 — 分析代码库结构和架构 |
| `docs/如何编写Resource文件.md` | Resource 类型和 .tres 文件编写指南 |
| `docs/如何制作BlockAndStat内容.md` | Block/Stat 内容制作完整指南 |
| `docs/StageRoom.md` | 楼层内循环系统文档 |
| `planning/card_pack_design/` | 卡包设计完整示例 |

## 核心原则

### 1. 优先使用 Godot MCP 而非直接编辑文件

该项目已安装 `godot_ai` MCP 插件并配置了 Autoload。所有 Godot 相关操作（场景编辑、节点操作、脚本创建、资源管理、测试运行等）请优先使用 MCP 工具，而不是直接编辑 `.tscn`/`.tres` 文件或手动运行 Godot。

### 2. 交付前确保代码无错误

- 创建或修改 GDScript 文件后，检查语法和逻辑错误
- 对于 Godot 场景/资源操作，确认 MCP 操作成功返回
- 运行 `test_run` 确认现有测试通过
- 不因粗心引入编译错误或运行时异常

### 3. 链接不重复

所有具体知识已在链接的文档中覆盖，本文件仅提供索引和行为准则。不要将已有文档的内容复制到新文件中。
