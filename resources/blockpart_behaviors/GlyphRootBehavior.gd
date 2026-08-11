class_name GlyphRootBehavior extends BlockPartBehavior

## 法阵/扎根 (Glyph Root) Behavior
## 星语术士法阵 / 翠绿哨兵扎根 的通用驻留 Behavior
## 使用 PreventsClear = true 阻止回合结束清除
## Block 驻留在网格上，每回合可持续提供效果
## 最多允许的驻留 Block 数量由 variant 决定：
## - "glyph"：星语术士法阵，最多 2 个
## - "root"：翠绿哨兵扎根，最多 3 个（升到 4 需初始能力）

@export var IsVariant: String = "root"  # "glyph" 或 "root"

func prevents_clear() -> bool:
	return true

func create_action(block, part):
	if block == null:
		return null
	# 驻留 Block 被触发时依然提供效果
	# 具体效果由同部件的其他 Behavior 提供
	# 此 Behavior 仅负责驻留标记和数量限制
	return null

## 检查是否可以再放置一个驻留 Block
static func can_place_glyph(tree: SceneTree, variant: String) -> bool:
	var max_count: int = 2 if variant == "glyph" else 3
	var current_count: int = count_active_glyphs(tree, variant)
	return current_count < max_count

## 统计当前活跃的驻留 Block 数量（variant: "glyph" / "root"）
## 含 RootBehavior 标记的 Block（视为 "root" variant）
static func count_active_glyphs(tree: SceneTree, variant: String) -> int:
	var count: int = 0
	var seen: Dictionary = {}
	for block in tree.get_nodes_in_group("placed_blocks"):
		if not is_instance_valid(block) or not block is Block or seen.has(block):
			continue
		seen[block] = true
		var is_active := false
		for part in block.get_parts():
			for behavior in part.Behaviors:
				if behavior is RootBehavior:
					is_active = variant == "root"
				elif behavior is GlyphRootBehavior:
					is_active = (behavior as GlyphRootBehavior).IsVariant == variant
				if is_active:
					break
			if is_active:
				break
		if is_active:
			count += 1
	return count
