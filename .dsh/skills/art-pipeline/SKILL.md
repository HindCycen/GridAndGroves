---
name: art-pipeline
description: Grid and Groves 的美术资产生成与验收协议。当需要新增或重做背景、敌人立绘、方块部件、图标、调色板时使用。程序化生成必须确定性、可复现，产出后必须做视觉复核与风格契约校验。
whenToUse: 用户提到美术资源、立绘、背景、图标、像素风、调色板、图生图时；或游戏内容新增后缺少配图时。
---

# 美术管线协议

用户的美术要求很具体，且会亲自评估原型。**先给可评估的原型，再谈批量生产。**

## 用户的既定偏好（不要再问一遍）

| 项 | 决定 |
|---|---|
| 主路线 | **Python + Pillow 程序化生成**，确定性、可复现 |
| 备选 | 外部免费 AI 出图 —— **已否决**（带水印、不可复现、风格漂移） |
| 精修 | 本地 SD1.5 + ControlNet Canny + PixelArt LoRA，`img2img_refine.py`（走 `%USERPROFILE%\gg-ai` venv） |
| 风格 | 像素风；**多级相近色带渐变**，禁止两种相差很远的颜色硬拼 |
| 调色板 | **256 色**（`resources/palette/gg256.*`），不用 32 色 |
| 时间维度 | 背景必须**单参数驱动**（`--hour`），同一场景几何可复用到任意时间点，不重画 |
| 底稿策略 | **先矢量/几何草稿，再像素化/图生图精修** —— 用户认可这条工作流 |

## 工具与调用顺序

```powershell
# 1) 生成（按需选）
python tools/gen_pixel_backgrounds.py --themes forest,ruins,core --hours 16,17,18,19,20,21 --strip --preview
python tools/gen_enemy_sprites.py --names Gonh --preview
python tools/gen_block_parts.py
python tools/gen_intent_icons.py
python tools/gen_stat_icons.py

# 2) 调色板（新增素材后重建）
python tools/build_palette.py

# 3) 像素化
python tools/pixelize_assets.py

# 4) 图生图精修（可选，走 AI venv）
& "$env:USERPROFILE\gg-ai\venv\Scripts\python.exe" tools\img2img_refine.py `
    --init room/battle_background/ForestClearing_2000.png `
    --out ForestClearing_2000_refined.png --theme forest `
    --work 1024x576 --grid 640x360 --clean 3 --preview

# 5) Godot 导入（新 PNG 必须导入才被识别）
& "C:\Unpacked\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --import

# 6) 把部件图写回定义
python tools/assign_part_art.py
```

## 风格契约（生成后必须核验）

| 项 | 要求 |
|---|---|
| 尺寸 | 部件图/敌人单帧 `96×96`/`192×192`；图标 `45×45`；敌人 spritesheet `384×192`（宽=高×2 自动切 2 帧） |
| 背景 | `480×270` 像素基准，整数倍放大到 `1920×1080` |
| 通道 | RGBA，透明背景 |
| 超采样 | 4× 画布绘制后 LANCZOS 缩小 |
| 描边 | 色 `(26,22,30)`，宽约 `5/192` |
| 确定性 | **不使用随机数**；同脚本永远产出同图 |
| 配色 | 用 `gen_block_parts.py` 的 `PALETTES`，不在绘制函数里硬编码颜色（敌人主题色除外） |

## 视觉复核（必做，不能省）

用户明确要求过用识图能力自检。生成后：

1. 用 `read_image` 真的看 `--preview` 拼图 / 输出 PNG
2. 逐条回答：

- 帧 0 与帧 1 是否只有呼吸/眨眼差异？
- 轮廓有无缺口、有无越界裁切？
- 渐变色带是否由**相近色**过渡，而不是硬拼？
- 与既有素材放在一起，风格/像素密度是否一致？
- 平坦区有没有被 AI 精修"脑补"出杂色？（有则用 `--keep-rect` / `--clean`）

3. 把**看到什么**写进汇报，不要只写"看起来正常"

## 汇报格式

```
产出：<文件名与尺寸>
位置：<目录>
参数：<完整命令，含 --hour / --seed>
复核：已用 read_image 查看 <path>；<逐条检查结果>
未决：<需要用户在风格上拍板的点>
```

**风格取舍（像不像、好不好看）必须回抛给用户**，不要让模型自己定。
