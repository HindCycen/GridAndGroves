#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
像素草稿精修（图生图 + ControlNet + Pixel-Art LoRA）
====================================================
把程序化生成的像素草稿（背景/角色/方块皆可）送入 SD1.5 + ControlNet(canny)
做低去噪 img2img 精修，再统一量化到全局 256 色调色板，保持像素网格与配色一致。

流程：草稿 -> 工作分辨率 -> Canny 控制图 -> img2img(低去噪) -> 回到像素网格
      -> gg256 调色板量化 -> 4x NEAREST -> 输出 + manifest

依赖（%USERPROFILE%\\gg-ai）：见 tools/ai_setup_models.py
用法（AI venv 的 python）：
    <gg-ai>\\venv\\Scripts\\python.exe tools\\img2img_refine.py ^
        --init room/battle_background/ForestClearing_2000.png ^
        --out ForestClearing_2000_refined.png --seed 20261001 --denoise 0.45
"""

import argparse
import datetime
import json
import os
import sys

import cv2
import numpy as np
import torch
from PIL import Image, ImageFilter
from diffusers import ControlNetModel, StableDiffusionControlNetImg2ImgPipeline

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AI_HOME = os.environ.get("GG_AI_HOME", os.path.join(os.path.expanduser("~"), "gg-ai"))
MODELS = os.path.join(AI_HOME, "models")
SD15_DIR = os.path.join(MODELS, "sd15")
CONTROLNET_DIR = os.path.join(MODELS, "controlnet_canny")
LORA_VARIANTS = {
    "none": "",
    "redmond15": os.path.join(MODELS, "lora_redmond15", "PixelArtRedmond15V-PixelArt-PIXARFK.safetensors"),
    "limbic": os.path.join(MODELS, "lora_limbic", "pytorch_lora_weights.safetensors"),
}
PALETTE_JSON = os.path.join(BASE, "resources", "palette", "gg256.json")
OUT_DIR = os.path.join(BASE, "room", "battle_background")
PREVIEW_DIR = os.path.join(BASE, "demo_generated")

DEFAULT_NEGATIVE = (
    "blurry, anti-aliased, smooth gradient, soft shading, 3d render, photorealistic, "
    "photo, text, watermark, signature, jpeg artifacts, depth of field, motion blur"
)
THEME_PROMPTS = {
    "forest": "pixel art forest clearing, flat shading, limited palette, crisp pixels, "
              "dithering, trees, bushes, distant hills, retro game background",
    "ruins": "pixel art ruined factory at dusk, flat shading, limited palette, crisp pixels, "
             "dithering, broken buildings, pipes, cables, rubble, retro game background",
    "core": "pixel art night bloom core, giant mechanical tree pillars, glowing spores, "
            "flat shading, limited palette, crisp pixels, dithering, retro game background",
}


def load_palette_image():
    with open(PALETTE_JSON, encoding="utf-8") as f:
        hexes = json.load(f)
    flat = []
    for h in hexes[:256]:
        h = h.lstrip("#")
        flat += [int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)]
    flat += [0] * (768 - len(flat))
    pal = Image.new("P", (1, 1))
    pal.putpalette(flat)
    return pal


def canny_control(img):
    gray = np.array(img.convert("L"))
    edges = cv2.Canny(gray, 80, 180)
    edges = cv2.cvtColor(edges, cv2.COLOR_GRAY2RGB)
    return Image.fromarray(edges)


def build_pipeline(low_vram=False, lora_scale=0.7, lora="redmond15"):
    dtype = torch.float16
    controlnet = ControlNetModel.from_pretrained(CONTROLNET_DIR, torch_dtype=dtype, variant="fp16")
    pipe = StableDiffusionControlNetImg2ImgPipeline.from_pretrained(
        SD15_DIR,
        controlnet=controlnet,
        torch_dtype=dtype,
        variant="fp16",
        safety_checker=None,
        requires_safety_checker=False,
    )
    if low_vram:
        pipe.enable_model_cpu_offload()
    else:
        pipe.to("cuda")
    pipe.set_progress_bar_config(disable=False)
    lora_path = LORA_VARIANTS.get(lora, "")
    if lora_path and os.path.exists(lora_path):
        try:
            pipe.load_lora_weights(os.path.dirname(lora_path), weight_name=os.path.basename(lora_path))
            print("lora loaded:", lora)
        except Exception as e:
            print("lora load failed (", lora, "):", e)
    return pipe


def parse_size(s):
    w, h = s.lower().split("x")
    return int(w), int(h)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--init", required=True, help="草稿图（像素背景/角色/方块）")
    ap.add_argument("--out", required=True, help="输出文件名（写入 room/battle_background）")
    ap.add_argument("--theme", default="", choices=["", "forest", "ruins", "core"])
    ap.add_argument("--prompt", default="")
    ap.add_argument("--negative", default=DEFAULT_NEGATIVE)
    ap.add_argument("--seed", type=int, default=20260926)
    ap.add_argument("--denoise", type=float, default=0.45)
    ap.add_argument("--steps", type=int, default=28)
    ap.add_argument("--cfg", type=float, default=6.5)
    ap.add_argument("--control-scale", type=float, default=0.9)
    ap.add_argument("--lora-scale", type=float, default=0.7)
    ap.add_argument("--lora", default="redmond15", choices=["none", "redmond15", "limbic"])
    ap.add_argument("--no-lora", action="store_true", help="等价于 --lora none")
    ap.add_argument("--keep-rect", action="append", default=[],
                    help="保留草稿的区域 x0,y0,x1,y1（1920x1080 坐标，可多次）")
    ap.add_argument("--no-keep-platform", action="store_true", help="不保留网格平台区域")
    ap.add_argument("--work", default="768x432", help="工作分辨率（16:9）")
    ap.add_argument("--grid", default="480x270", help="最终像素网格")
    ap.add_argument("--scale", type=int, default=0, help="最终整数放大倍率（0=按 1920 宽自动；角色/方块可显式指定）")
    ap.add_argument("--low-vram", action="store_true")
    ap.add_argument("--clean", type=int, default=0, help="量化前中值滤波核 0/3/5，清理噪点")
    ap.add_argument("--control-out", default="", help="同时导出 canny 控制图（调试用）")
    ap.add_argument("--preview", action="store_true")
    args = ap.parse_args()

    init_path = args.init if os.path.isabs(args.init) else os.path.join(BASE, args.init)
    init = Image.open(init_path).convert("RGB")
    ww, wh = parse_size(args.work)
    gw, gh = parse_size(args.grid)
    work = init.resize((ww, wh), Image.LANCZOS)
    control = canny_control(work)
    if args.control_out:
        cp = args.control_out if os.path.isabs(args.control_out) else os.path.join(PREVIEW_DIR, args.control_out)
        os.makedirs(os.path.dirname(cp), exist_ok=True)
        control.save(cp)
        print("control:", os.path.relpath(cp, BASE))

    prompt = args.prompt or THEME_PROMPTS.get(args.theme) or THEME_PROMPTS["forest"]
    print("prompt:", prompt)
    lora = "none" if args.no_lora else args.lora
    pipe = build_pipeline(low_vram=args.low_vram, lora_scale=args.lora_scale, lora=lora)
    gen = torch.Generator("cuda").manual_seed(args.seed)
    kwargs = {}
    if lora != "none":
        kwargs["cross_attention_kwargs"] = {"scale": args.lora_scale}
    t0 = datetime.datetime.now()
    result = pipe(
        prompt=prompt,
        negative_prompt=args.negative,
        image=work,
        control_image=control,
        strength=args.denoise,
        num_inference_steps=args.steps,
        guidance_scale=args.cfg,
        controlnet_conditioning_scale=args.control_scale,
        generator=gen,
        **kwargs,
    ).images[0]
    print("gen time: %.1fs" % (datetime.datetime.now() - t0).total_seconds())

    # 保留区域（网格平台等）：直接把草稿贴回，避免模型在平坦暗区"脑补"
    keep = []
    if not args.no_keep_platform:
        keep.append((216, 456, 936, 984))
    for r in args.keep_rect:
        keep.append(tuple(int(v) for v in r.split(",")))
    if keep:
        sx = ww / 1920.0
        sy = wh / 1080.0
        for (x0, y0, x1, y1) in keep:
            bx0, by0, bx1, by1 = int(x0 * sx), int(y0 * sy), int(x1 * sx), int(y1 * sy)
            patch = work.crop((bx0, by0, bx1, by1))
            result.paste(patch, (bx0, by0))
        print("kept regions:", keep)

    # 回到像素网格并量化到全局调色板
    pal = load_palette_image()
    small = result.resize((gw, gh), Image.BOX)
    if args.clean >= 3:
        small = small.filter(ImageFilter.MedianFilter(size=args.clean))
    quant = small.quantize(palette=pal, dither=Image.Dither.NONE).convert("RGB")
    # 像素密度：背景默认以 480x270@4x=1920x1080 为基准；素材可用 --scale 显式指定
    scale = args.scale if args.scale > 0 else 1920 // gw
    if scale < 1 or (args.scale == 0 and (gw * scale, gh * scale) != (1920, 1080)):
        print("warning: grid %dx%d does not scale to 1920x1080 by integer factor, fallback 480x270" % (gw, gh))
        gw, gh, scale = 480, 270, 4
        small = result.resize((gw, gh), Image.BOX)
        if args.clean >= 3:
            small = small.filter(ImageFilter.MedianFilter(size=args.clean))
        quant = small.quantize(palette=pal, dither=Image.Dither.NONE).convert("RGB")
    final = quant.resize((gw * scale, gh * scale), Image.NEAREST)

    os.makedirs(OUT_DIR, exist_ok=True)
    out_path = os.path.join(OUT_DIR, args.out)
    final.save(out_path)
    raw_path = os.path.splitext(out_path)[0] + "_raw.png"
    result.save(raw_path)
    print("saved:", os.path.relpath(out_path, BASE))
    print("raw  :", os.path.relpath(raw_path, BASE))

    manifest = {
        "init": os.path.relpath(init_path, BASE),
        "out": os.path.relpath(out_path, BASE),
        "prompt": prompt,
        "negative": args.negative,
        "seed": args.seed,
        "denoise": args.denoise,
        "steps": args.steps,
        "cfg": args.cfg,
        "control_scale": args.control_scale,
        "lora": lora,
        "lora_scale": None if lora == "none" else args.lora_scale,
        "keep": keep,
        "clean": args.clean,
        "work": args.work,
        "grid": args.grid,
        "scale": scale,
        "palette": "resources/palette/gg256.json",
        "models": {"sd15": os.path.relpath(SD15_DIR, AI_HOME), "controlnet": "controlnet_canny", "lora": LORA_VARIANTS.get(lora, "")},
        "time": datetime.datetime.now().isoformat(timespec="seconds"),
    }
    mpath = os.path.splitext(out_path)[0] + ".manifest.json"
    with open(mpath, "w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)
    print("manifest:", os.path.relpath(mpath, BASE))

    if args.preview:
        layer = final.convert("RGBA")
        upper = Image.open(os.path.join(BASE, "room", "battle_background", "UpperLayer.png")).convert("RGBA")
        layer.alpha_composite(upper, (0, 0))
        play = Image.open(os.path.join(BASE, "actors", "player", "Player-export.png")).convert("RGBA").crop((0, 0, 192, 192))
        layer.alpha_composite(play, (300 - 96, 200 - 96))
        gonh = Image.open(os.path.join(BASE, "resources", "enemy_images", "Gonh.png")).convert("RGBA").crop((0, 0, 192, 192))
        layer.alpha_composite(gonh, (1300 - 96, 150 - 96))
        pv = os.path.join(PREVIEW_DIR, "refined_preview_" + os.path.splitext(args.out)[0] + ".png")
        layer.convert("RGB").save(pv)
        print("preview:", os.path.relpath(pv, BASE))
    return 0


if __name__ == "__main__":
    sys.exit(main())
