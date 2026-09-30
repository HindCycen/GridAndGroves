---
name: godot-verify
description: Grid and Groves 的验收协议。改完 Godot 相关代码后、或用户说 验证/测试一下/看看能不能跑 时使用。跑固定冒烟套件与脚本解析检查，并用截图做视觉复核；禁止用「应该没问题」代替验证。
whenToUse: 修改了 .gd/.tscn/.tres 之后；用户要求验证功能、复现 bug、或说「你操作一下看看」时。
---

# 验收协议

用户抓到过一次典型的偷懒：AI 声称拖拽功能正常，实际「并不是每个符合要求的地方都能按照预期放置符合要求的方块」。**从此验证必须是可复现的、有输出的、最好还是看得见的。**

## 铁律

- 禁止「应该没问题」「看起来是对的」「逻辑上应该成立」。
- 每个断言必须有一条**真实运行的命令**和它的**真实输出**。
- 跑完不能删测试。删掉的验证等于没验证，下次要从头再来。

## 环境

```powershell
$GODOT = "C:\Unpacked\Godot\Godot_v4.7.2-stable_win64_console.exe"
```

项目要求 Godot **4.7**（`project.godot` 的 `config/features` 为 `4.7`）。用 `_console.exe` 才能在 PowerShell 里拿到 stdout。

## 第 1 层 — 脚本解析全检（最便宜，先跑）

任何 GDScript 语法错误都会在这里暴露，**不要跳过**：

```powershell
& $GODOT --headless --path . --check-only --script <file>   # 单文件
& $GODOT --headless --path . --import                       # 触发全量导入与解析
```

报告格式：`N 个脚本解析，0 失败`。有失败就逐个列出**文件 + 行号 + 原文**。

## 第 2 层 — 固定冒烟套件

```powershell
& $GODOT --headless --path . res://tests/smoke.tscn
```

**`tests/` 目录目前不存在，需要建立。** 这是本项目最大的工程缺口：历史上每次冒烟都是临时写、跑完即删，导致「占格跨战斗泄漏」「商店重复刷牌」这类 bug 反复出现。

建立后的约定：
- 一个场景 `tests/smoke.tscn` + 一个驱动脚本 `tests/smoke.gd`
- 每条检查独立命名，对应一个不变量，例如：
  - `player_can_place_block_on_every_valid_cell` ← 拖拽那次翻车的守卫
  - `grid_occupy_resets_between_battles`
  - `shop_cannot_reenter_for_free_cards`
  - `temp_stats_do_not_persist_across_battles`
  - `event_damage_can_kill_player`
  - `boss_cell_always_spawns_boss`
  - `stage_count_increments_once_per_floor`
- 输出 `PASS/FAIL` 每行一条，最后一行 `N passed, M failed`
- **失败必须让退出码非零**，否则 CI/自动化读不到

新修一个 bug，就加一条同名守卫（见 `session-handoff`）。

## 第 3 层 — 视觉复核（用户明确要求过）

用户说过「**你是识图模型**」。当前模型接受图像输入，所以**必须真的看图**，不要只描述代码。

- 用 `read_image` 读截图或 `--preview` 拼图
- 逐项对照检查表，把**看到什么**写出来，而不是「看起来正常」

拖拽/布局类改动的检查表：
1. 每个高亮可放置格，都能放下符合要求的方块吗？
2. 有没有格子在预览中被标为可放、实际放不下（或反之）？
3. 方块落位后与格线、相邻方块是否有错位/重叠？
4. 提示 tooltip / 预览面板内容是否与方块实际效果一致？

美术产出的检查表见 `art-pipeline`。

**若截图工具不可用**，明说「本次未做视觉复核」，不要假装看过。

## 第 4 层 — 实机流程走查

按主循环顺序跑一遍，每步确认无报错：

```
主菜单选包 → 地图 → 战斗 → 中途返回 → 重进 → 胜利 → 商店 → Continue 恢复 → Boss 商店 → 换层/通关
```

这条路径是历史 bug 的高发区（BackToStage 刷奖励、Continue 丢现场、Boss 判定双轨、换层软锁）。

## 汇报格式

```
验证结果
- 脚本解析：135 检查，0 失败
- 冒烟：12 passed, 0 failed
- 视觉复核：已做（读到 <path>），检查项 1-4 全部通过
- 实机流程：主菜单→…→通关，无 ERROR
未覆盖：<诚实列出没验的部分>
```

**没验的部分必须写出来。**
