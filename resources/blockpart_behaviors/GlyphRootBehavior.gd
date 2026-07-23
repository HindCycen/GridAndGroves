class_name GlyphRootBehavior extends BlockPartBehavior

## 法阵/扎根 (Glyph Root) Behavior
## 星语术士法阵 / 翠绿哨兵扎根 的通用驻留 Behavior
## 使用 PreventsClear = true 阻止回合结束清除
## Block 驻留在网格上，每回合可持续提供效果
## 最多允许的驻留 Block 数量由 MaxGlyphCount 控制

## 通过设置 IsVariant 来区分：
## - is_variant = "glyph"：星语术士法阵，最多 2 个
## - is_variant = "root"：翠绿哨兵扎根，最多 3 个（升到 4 需初始能力）

@export var IsVariant: String = "root"  # "glyph" 或 "root"
@export var MaxGlyphCount: int = 2      # 全局最大驻留数（法阵2 / 扎根3）

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

## 统计当前活跃的驻留 Block 数量
static func count_active_glyphs(tree: SceneTree, variant: String) -> int:
	var count: int = 0
	for block in tree.get_nodes_in_group("placed_blocks"):
		if not is_instance_valid(block) or not block is Block:
			continue
		for part in block.get_parts():
			if part.PartDefinition == null or part.PartDefinition.Behaviors == null:
				continue
			for behavior in part.PartDefinition.Behaviors:
				if behavior is GlyphRootBehavior:
					var gb: GlyphRootBehavior = behavior as GlyphRootBehavior
					if gb.IsVariant == variant:
						count += 1
						break
			if count > 0:
				break
	return count
