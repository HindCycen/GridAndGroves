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
| `docs/美术管线.md` | 美术产出方法与工作流 |
| `planning/card_pack_design/` | 卡包设计完整示例 |
| **`planning/STATE.md`** | **当前状态快照 —— 「现在在哪」的唯一事实来源** |
| **`planning/design-rulings.md`** | **设计口径登记册 —— 与它冲突的代码是 bug** |
| `planning/main-loop-repair-plan.md` | 历史修复日志（只看最新一节，不要通读） |
| `.dsh/skills/` | 本项目重复性操作的固定协议，见下 |
| `tests/smoke.tscn` | 固定冒烟套件 |

## 协作协议

本项目由 AI 长期自主推进，用户只在**短时段**（通常 10 分钟–1.5 小时，多在工作日夜里）介入做裁决。因此重复性操作已固化为技能，**匹配到就直接加载，不要临场发挥**：

| 技能 | 何时用 |
|---|---|
| `project-audit` | 用户说「检查项目 / 现在什么状态 / 下一步做什么」 |
| `session-handoff` | 一轮收尾；用户说「提交 / 收尾 / 先到这」 |
| `commit-triage` | 用户要求提交 |
| `godot-verify` | 改了 `.gd`/`.tscn`/`.tres` 之后；用户要求验证 |
| `art-pipeline` | 涉及背景 / 立绘 / 图标 / 调色板 / 像素风 |

三条不可违反的约定：

1. **读 `planning/STATE.md` 再动手**，不要每次重新考古全库。
2. **设计口径以 `planning/design-rulings.md` 为准**。机制语义、数值口径、美术取舍**必须回抛给用户**；纯实现、纯验证、纯清理**直接做，不要问**。
3. **验证要有真实输出**。禁止「应该没问题」。看图就用识图能力真的看。

## 核心原则

### 1. 优先使用 Godot MCP 而非直接编辑文件

该项目已安装 `godot_ai` MCP 插件并配置了 Autoload。所有 Godot 相关操作（场景编辑、节点操作、脚本创建、资源管理、测试运行等）请优先使用 MCP 工具，而不是直接编辑 `.tscn`/`.tres` 文件或手动运行 Godot。

### 2. 交付前确保代码无错误

- 创建或修改 GDScript 文件后，检查语法和逻辑错误
- 对于 Godot 场景/资源操作，确认 MCP 操作成功返回
- 运行 `tests/smoke.tscn` 确认冒烟套件通过（见 `godot-verify` 技能）
- 修掉一个 bug，就在冒烟套件里加一条同名守卫，不要跑完即删
- 不因粗心引入编译错误或运行时异常

### 3. 链接不重复

所有具体知识已在链接的文档中覆盖，本文件仅提供索引和行为准则。不要将已有文档的内容复制到新文件中。
