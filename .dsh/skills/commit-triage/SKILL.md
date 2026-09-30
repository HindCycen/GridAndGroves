---
name: commit-triage
description: Grid and Groves 的提交协议。当用户说 提交/commit/做一个提交/把这些提交 时使用。先对改动做「纳入/排除/待定」三分类，再用项目既有格式本地提交，并汇报领先 origin 的提交数。
whenToUse: 用户要求提交、或一轮工作收尾需要落库时。
---

# 提交协议

用户明确要求过：**「提交前判断哪些内容是有用的，哪些内容需要排除」**。不要 `git add -A`。

## 1. 三分类

```powershell
git status --porcelain
git diff --stat
```

把每个改动塞进三类：

**纳入** —— 源码、资源定义（`*.json` / `*.tres`）、文档、生成器脚本、测试。

**排除** —— 以下一律不入库：

| 类别 | 例子 | 原因 |
|---|---|---|
| 生成物 | `demo_generated/`、`tools/enemy_preview.png` | 可由脚本重跑 |
| Godot 导入产物 | `*.import`、`.godot/` | 机器生成 |
| 模型权重 | `*.safetensors` / `*.ckpt` / `*.pt` | 体积大 |
| 本地环境 | `%USERPROFILE%\gg-ai` | 不入库 |
| 第三方插件 | `addons/` | 已在 `.gitignore` |
| 临时验证脚本 | 一次性冒烟文件 | 除非已按 `session-handoff` 固化为守卫 |

**待定** —— 拿不准的**单独列出来问用户**，不要自己猜着提交。

> `.gitignore` 已覆盖上述大部分。若发现有该忽略却仍被跟踪的文件，报告出来，别静默处理。

## 2. 提交信息格式

沿用仓库既有风格（Conventional Commits + 中文正文）：

```
<type>: <一句话主题>

<可选：为什么这么改、影响什么>
```

- `type`：`feat` / `fix` / `chore` / `refactor` / `docs`
- 主题写**用户视角的收益**，不要写「修改了 XX 文件」
- **不要加 `Co-authored-by`**，也不要加任何 AI 署名——仓库 125 个提交都没有
- 大改动拆成多个语义独立的提交（见历史：`ebdf1f9` P0 闭环 / `c3db4f9` 美术管线与文档 是两次独立提交）

参考历史好例子：
- `fix: 拖拽释放兜底 + 商店卡牌预览与离店补牌防刷`
- `chore: 代码清理与去重 + 共鸣链运行时修复`

## 3. 提交后

```powershell
git rev-list --left-right --count origin/main...main
```

**默认只做本地提交，不推送。** 用户把本地提交当作缓冲区，`origin/main` 停在 `08-11` 是他的既定状态，不是遗漏。

在汇报里写一句：

> 已提交 `<hash> <subject>`（N 文件，+A/−D），工作区干净，本地领先 `origin/main` N 个提交。

**若领先数超过 20**，额外提示一次：备份已明显滞后，建议推到备份分支（见下）。只提示一次，不要反复念。

## 4. 备份（需用户拍板）

本地长期领先意味着没有异地备份。若用户同意，用**备份分支**而不是 `main`，以保留他「本地缓冲」的意图：

```powershell
git push origin main:refs/heads/backup/local-wip
```

**这是不可逆的对外操作，必须先问。** 用户没明说就不要做。
