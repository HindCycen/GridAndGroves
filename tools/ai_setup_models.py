#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
AI 精修环境：模型下载脚本
==========================
下载 img2img/ControlNet 精修流程所需的模型（默认走 hf-mirror 镜像）：
  - SD 1.5 基础模型（fp16 变体，约 2.2GB）
  - ControlNet Canny（SD1.5，fp16，约 700MB）
  - PixelArtRedmond LoRA（约 150MB）

模型统一放在 %USERPROFILE%\\gg-ai\\models\\ 下（不入库）。

用法（使用 AI venv 的 python）：
    set HF_ENDPOINT=https://hf-mirror.com
    <gg-ai>\\venv\\Scripts\\python.exe tools\\ai_setup_models.py
"""

import os
import sys

os.environ.setdefault("HF_ENDPOINT", "https://hf-mirror.com")
os.environ.setdefault("HF_HUB_DISABLE_XET", "1")

from huggingface_hub import snapshot_download  # noqa: E402

AI_HOME = os.environ.get("GG_AI_HOME", os.path.join(os.path.expanduser("~"), "gg-ai"))
MODELS = os.path.join(AI_HOME, "models")

JOBS = [
    (
        "stable-diffusion-v1-5/stable-diffusion-v1-5",
        "sd15",
        [
            "model_index.json",
            "scheduler/*",
            "feature_extractor/*",
            "tokenizer/*",
            "text_encoder/*.json",
            "text_encoder/*.fp16.safetensors",
            "unet/*.json",
            "unet/*.fp16.safetensors",
            "vae/*.json",
            "vae/*.fp16.safetensors",
        ],
    ),
    (
        "lllyasviel/control_v11p_sd15_canny",
        "controlnet_canny",
        ["config.json", "*.fp16.safetensors"],
    ),
    (
        "artificialguybr/PixelArtRedmond",
        "lora_pixelart",
        ["*.safetensors"],
    ),
]


def main():
    print("HF_ENDPOINT =", os.environ["HF_ENDPOINT"])
    print("models dir  =", MODELS)
    os.makedirs(MODELS, exist_ok=True)
    for repo, folder, patterns in JOBS:
        dest = os.path.join(MODELS, folder)
        print("\n=== downloading", repo, "->", dest)
        snapshot_download(repo_id=repo, local_dir=dest, allow_patterns=patterns)
    total = 0
    for root, _dirs, files in os.walk(MODELS):
        for f in files:
            total += os.path.getsize(os.path.join(root, f))
    print("\nall done. models size: %.1f GB" % (total / 1024**3))


if __name__ == "__main__":
    sys.exit(main())
