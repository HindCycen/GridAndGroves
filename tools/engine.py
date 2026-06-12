"""
GridAndGroves 像素画 AI 生成引擎
==================================
加载 CivitAI 单文件模型（.safetensors），提供：
- 模型加载卸载 / VRAM 自适应
- 文生图管线
- 后处理：降采样 → 调色板量化 → 3× 像素化放大
- 精灵表 (SpriteSheet) 拼合
"""

import os
import gc
import logging
from typing import Optional

import torch
import numpy as np
from PIL import Image
from diffusers import StableDiffusionPipeline

from config import (
    PIXEL_SCALE, SPECS, PALETTES, OUTPUT_DIRS, PROJECT_ROOT,
    MODEL_CACHE_DIR,
)

logger = logging.getLogger("gg-engine")

# 模型文件路径
MODEL_PATH = os.path.join(MODEL_CACHE_DIR, "pixelArtSpriteDiffusion_safetensors.safetensors")

# ═════════════════════════════════════════════════════════════════════
# 兼容性补丁: transformers 5.x + diffusers 0.38.0
# ═════════════════════════════════════════════════════════════════════
# transformers 5.x 移除了 CLIPTextTransformer 中间类。CLIPTextModel
# 不再有 .text_model 属性，diffusers 0.38.0 的 from_single_file 期望
# 该属性存在。同时，convert_ldm_clip_checkpoint 产出的状态字典键带有
# "text_model." 前缀，而 transformers 5.x 的模型期望无此前缀。
#
# 我们打两个补丁:
#   1. 在 CLIPTextModel 上添加 text_model 属性 → 修复属性访问
#   2. 从转换后的状态字典键中剥离 text_model. 前缀 → 修复 meta tensor

from transformers.models.clip.modeling_clip import CLIPTextModel

# ── 补丁 1: 属性重定向 ──
# model.text_model.X → model.X (因为中间层已被移除)
@property
def _clip_text_model_self(self):
    return self

CLIPTextModel.text_model = _clip_text_model_self
logger.debug("补丁 1: CLIPTextModel.text_model 已注入")

# ── 补丁 2: 状态字典键前缀剥离 ──
# 接管 convert_ldm_clip_checkpoint / convert_open_clip_checkpoint,
# 将产出的 "text_model.xxx" 键重映射为 "xxx"
import diffusers.loaders.single_file_utils as _sfu

_orig_ldm = _sfu.convert_ldm_clip_checkpoint
_orig_open = _sfu.convert_open_clip_checkpoint

def _patched_ldm(checkpoint, remove_prefix=None):
    result = _orig_ldm(checkpoint, remove_prefix)
    return {
        (k[len("text_model."):] if k.startswith("text_model.") else k): v
        for k, v in result.items()
    }

def _patched_open(text_model, checkpoint, prefix="cond_stage_model.model."):
    result = _orig_open(text_model, checkpoint, prefix)
    return {
        (k[len("text_model."):] if k.startswith("text_model.") else k): v
        for k, v in result.items()
    }

_sfu.convert_ldm_clip_checkpoint = _patched_ldm
_sfu.convert_open_clip_checkpoint = _patched_open
logger.debug("补丁 2: 状态字典键前缀剥离已注入")


# ═══════════════════════════════════════════════════════════════
# 模型管理
# ═══════════════════════════════════════════════════════════════

class PixelModel:
    """像素画扩散模型封装。加载 CivitAI 单 .safetensors 文件。"""

    def __init__(self, model_path: str = MODEL_PATH):
        if not os.path.exists(model_path):
            raise FileNotFoundError(
                f"模型文件不存在: {model_path}\n"
                f"请从 CivitAI 下载后放到 tools/models/ 目录"
            )
        self.model_path = model_path
        self.pipe = None
        self.device = self._pick_device()
        logger.info(f"模型文件: {model_path}")
        logger.info(f"文件大小: {os.path.getsize(model_path) / 1024**3:.2f} GB")
        logger.info(f"设备: {self.device}")

    @staticmethod
    def _pick_device() -> torch.device:
        if torch.cuda.is_available():
            return torch.device("cuda")
        return torch.device("cpu")

    def load(self) -> bool:
        """加载模型。以 fp16 精度加载到 GPU，配合 CPU offload 节省显存。"""
        try:
            logger.info("正在加载模型（4GB 模型加载需 10-30 秒）...")

            # 以 fp16 加载（4GB → ~2GB VRAM 占用）
            pipe = StableDiffusionPipeline.from_single_file(
                self.model_path,
                torch_dtype=torch.float16,
                use_safetensors=True,
                safety_checker=None,       # 游戏不需要安全检测器
                feature_extractor=None,
            )

            # 二次确保安全检测关闭（旧版 from_single_file 对 None 参数不完全遵守）
            pipe.safety_checker = None
            pipe.feature_extractor = None

            # 显存优化
            if self.device.type == "cuda":
                pipe.enable_attention_slicing()
                pipe.enable_model_cpu_offload()  # UNet/VAE 按需出入 GPU

            self.pipe = pipe
            logger.info("✅ 模型加载成功！")
            return True

        except Exception as e:
            logger.error(f"❌ 模型加载失败: {e}")
            return False

    def unload(self):
        """卸载模型，释放 VRAM"""
        if self.pipe is not None:
            del self.pipe
            self.pipe = None
        if self.device.type == "cuda":
            torch.cuda.empty_cache()
        gc.collect()
        logger.info("模型已卸载，VRAM 已释放")

    def is_loaded(self) -> bool:
        return self.pipe is not None


# ═══════════════════════════════════════════════════════════════
# 后处理管线
# ═══════════════════════════════════════════════════════════════

def pixel_downscale(img: Image.Image, target_native: int) -> Image.Image:
    """降采样到目标像素画分辨率（Nearest 保持硬边）"""
    return img.resize((target_native, target_native), Image.NEAREST)


def pixel_upscale(img: Image.Image, scale: int = PIXEL_SCALE) -> Image.Image:
    """3× 无损放大（Nearest Neighbor，保持像素硬边）"""
    w, h = img.size
    return img.resize((w * scale, h * scale), Image.NEAREST)


def quantize_to_palette(
    img: Image.Image,
    palette_colors: list[tuple[int, int, int]],
    threshold: int = 30,
) -> Image.Image:
    """将图像量化到指定调色板。alpha < threshold → 透明。"""
    img = img.convert("RGBA")
    pixels = np.array(img, dtype=np.float32)
    r, g, b, a = pixels[:, :, 0], pixels[:, :, 1], pixels[:, :, 2], pixels[:, :, 3]

    pal = np.array(palette_colors, dtype=np.float32)

    diff = np.sqrt(
        (r[:, :, np.newaxis] - pal[np.newaxis, np.newaxis, :, 0]) ** 2 +
        (g[:, :, np.newaxis] - pal[np.newaxis, np.newaxis, :, 1]) ** 2 +
        (b[:, :, np.newaxis] - pal[np.newaxis, np.newaxis, :, 2]) ** 2
    )

    best = np.argmin(diff, axis=2)

    result = np.zeros((*best.shape, 4), dtype=np.uint8)
    for i, color in enumerate(palette_colors):
        mask = (best == i) & (a >= threshold)
        result[mask] = (*color, 255)

    return Image.fromarray(result, mode="RGBA")


def generate_pixel_art(
    engine: PixelModel,
    prompt: str,
    palette_colors: list[tuple[int, int, int]],
    native_size: int,
    final_size: int,
    negative_prompt: Optional[str] = None,
    num_inference_steps: int = 30,
    seed: Optional[int] = None,
    guidance_scale: float = 7.5,
) -> Image.Image:
    """
    完整的像素画生成管线：
    1. AI 生成（尺寸 ≈ final_size × 2）
    2. 降采样到 native_size
    3. 量化到指定调色板
    4. 3× 放大到 final_size
    """
    if negative_prompt is None:
        negative_prompt = (
            "photo, realistic, smooth, gradient, blur, "
            "complex, high detail, 3d, round edges"
        )

    # 截断 prompt 到 CLIP 最大 77 tokens
    tokenizer = engine.pipe.tokenizer
    tokens = tokenizer.encode(prompt)
    if len(tokens) > 77:
        # 暴力截断字符（比 decode 再编码更干净）
        while len(tokenizer.encode(prompt)) > 77 and len(prompt) > 10:
            prompt = prompt.rsplit(", ", 1)[0] if ", " in prompt else prompt[:-20]

    generator = None
    if seed is not None:
        generator = torch.Generator(device=engine.device).manual_seed(seed)

    # 生成尺寸：final_size * 2，且必须为 8 的倍数（SD 强制要求）
    gen_size = final_size * 2
    if gen_size % 8 != 0:
        gen_size = ((gen_size + 7) // 8) * 8

    logger.info(f"Prompt: {prompt[:60]}...")

    result = engine.pipe(
        prompt=prompt,
        negative_prompt=negative_prompt,
        num_inference_steps=num_inference_steps,
        guidance_scale=guidance_scale,
        generator=generator,
        width=gen_size,
        height=gen_size,
    ).images[0]

    # 降采样到像素画原始分辨率 → 量化 → 3× 放大
    result = pixel_downscale(result, native_size)
    result = quantize_to_palette(result, palette_colors)
    result = pixel_upscale(result)
    result = result.resize((final_size, final_size), Image.NEAREST)

    return result


# ═══════════════════════════════════════════════════════════════
# 精灵表生成
# ═══════════════════════════════════════════════════════════════

def generate_spritesheet(
    engine: PixelModel,
    prompts: list[str],
    palette_colors: list[tuple[int, int, int]],
    native_size: int,
    final_frame_size: int,
    cols: int = 8,
    negative_prompt: Optional[str] = None,
    inference_steps: int = 25,
    seed: Optional[int] = None,
) -> Image.Image:
    """生成动画精灵表。"""
    frames = []
    for i, prompt in enumerate(prompts):
        logger.info(f"帧 {i + 1}/{len(prompts)}: {prompt[:40]}...")
        frame_seed = (seed or 42) + i * 7
        frame = generate_pixel_art(
            engine=engine,
            prompt=prompt,
            palette_colors=palette_colors,
            native_size=native_size,
            final_size=final_frame_size,
            negative_prompt=negative_prompt,
            num_inference_steps=inference_steps,
            seed=frame_seed,
        )
        frames.append(frame)

    n = len(frames)
    rows = (n + cols - 1) // cols
    sheet_width = min(n, cols) * final_frame_size
    sheet_height = rows * final_frame_size

    sheet = Image.new("RGBA", (sheet_width, sheet_height), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        x = (i % cols) * final_frame_size
        y = (i // cols) * final_frame_size
        sheet.paste(frame, (x, y), frame)

    return sheet


# ═══════════════════════════════════════════════════════════════
# 文件输出
# ═══════════════════════════════════════════════════════════════

def ensure_output_dir(asset_type: str) -> str:
    rel = OUTPUT_DIRS.get(asset_type, "tools/output")
    full = os.path.join(PROJECT_ROOT, rel)
    os.makedirs(full, exist_ok=True)
    return full


def save_image(img: Image.Image, filepath: str) -> str:
    img.save(filepath, "PNG")
    logger.info(f"已保存: {filepath}")
    return os.path.abspath(filepath)
