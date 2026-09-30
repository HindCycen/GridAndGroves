---
name: session-handoff
description: Grid and Groves 的「收尾交接」协议。在一轮工作结束时、或用户说 提交/收尾/先到这 时使用。重新生成 planning/STATE.md、登记新的设计口径、把回归守卫写进固定测试，并汇报未推送提交数。
whenToUse: 一轮开发收尾时；用户说「提交」「收尾」「先到这」「总结一下」时。
---

# 收尾交接协议

用户的工作时段很短（通常 10 分钟到 1.5 小时），中间会隔好几天。**下一次开工的 AI 只能靠磁盘上的东西恢复上下文。** 这个协议负责把这次会话的成果固化到磁盘，让下次的勘察成本接近零。

## 为什么必须做

历史教训：`planning/main-loop-repair-plan.md` 顶部写 Phase 0、正文写 Phase 1 已完成，自相矛盾；文档滞后于代码，导致每次开工都要重新考古。**不交接 = 下次多花 12 分钟和 100 条消息重新摸清现状。**

## 流程

### 1. 重新生成 `planning/STATE.md`

**从代码事实重新生成，不要凭记忆写。**

```powershell
git rev-list --count HEAD
git rev-list --left-right --count origin/main...main
python -c "import json;print(len(json.load(open('resources/block_defs.json',encoding='utf-8'))['blocks']))"
python -c "import json;print(len(json.load(open('resources/enemy_defs.json',encoding='utf-8'))['enemies']))"
(Get-ChildItem -Recurse -Filter *.gd -File).Count
```

`STATE.md` 必须保持 **120 行以内**。它是快照，不是日志。写不下就说明你在往里塞历史——历史该进 `main-loop-repair-plan.md`。

### 2. 登记新的设计口径

本次会话里用户拍板过的**语义与取舍**，逐条追加到 `planning/design-rulings.md`。

判断标准：如果一条规则没写下来，下一个 AI 就有可能反着实现它，那它就该被登记。

例：
- 「松动是 BlockPart 的行为，不是 Block」
- 「四段废品计数 +4」
- 「中途退出战斗的操作是对的」

**每条要写明：口径、理由、受影响文件。** 只写结论不算。

### 3. 把回归守卫固化进测试

本次修掉的每个 bug，都要在 `tests/` 里留下一条**命名对应的检查**。

禁止再把冒烟脚本「跑完即删」——历史上这样做导致「占格跨战斗泄漏」这类 bug 反复出现，且每次都要重新发明验证方法。

守卫命名与 bug 同名，例如：
- `guard_grid_occupy_reset_between_battles`
- `guard_shop_no_reenter_farming`
- `guard_temp_stats_not_persisted`

### 4. 维护修复日志

把本次的修复记录追加到 `planning/main-loop-repair-plan.md` 的**最新一节**（含代码清理）。用表格：`问题 | 修复`。附上验证证据。

### 5. 汇报（一段话，别写作文）

必须包含：

- 本次改了什么（按主题分组，不逐文件罗列）
- **如何验证的**（真实命令与结果，不是「应该没问题」）
- **本地领先 `origin/main` N 个提交，未推送**
- 已知风险 / 遗留项
- 下次开场的建议起点

## 提交

要走提交时，用 `commit-triage` 技能，不要在收尾里临时决定。
