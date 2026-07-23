class_name RootBehavior extends BlockPartBehavior

## 扎根 (Root) Behavior
## 翠绿哨兵核心机制：Block 驻留网格（PreventsClear = true）
## 每回合可持续提供效果
## 使用 GlyphRootBehavior 的驻留逻辑，但扎根有独立的计数和上限

## 注意：扎根使用 GlyphRootBehavior 的 prevents_clear 机制
## 部件配置时需同时包含 RootBehavior（用于标记）和本体效果 Behavior
## 如果部件已有 GlyphRootBehavior 则无需额外此文件
## 此文件作为翠绿哨兵专用的扎根标记类，便于统计和条件检查

func prevents_clear() -> bool:
	return true

func create_action(_block, _part):
	# 扎根 Behavior 本身不返回 Action
	# 实际效果由同部件的其他 Behavior 提供
	return null

## 检查是否可以再放置一个扎根 Block
static func can_place_root(tree: SceneTree) -> bool:
	var max_roots: int = 3
	var current: int = count_active_roots(tree)
	return current < max_roots

## 统计当前活跃的扎根 Block 数量
static func count_active_roots(tree: SceneTree) -> int:
	var count: int = 0
	var seen: Dictionary = {}
	for block in tree.get_nodes_in_group("placed_blocks"):
		if not is_instance_valid(block) or not block is Block:
			continue
		if seen.has(block):
			continue
		seen[block] = true
		for part in block.get_parts():
			if part.PartDefinition == null or part.PartDefinition.Behaviors == null:
				continue
			for behavior in part.PartDefinition.Behaviors:
				if behavior is RootBehavior or (behavior is GlyphRootBehavior and (behavior as GlyphRootBehavior).IsVariant == "root"):
					count += 1
					break
			if count > 0:
				break
	return count
