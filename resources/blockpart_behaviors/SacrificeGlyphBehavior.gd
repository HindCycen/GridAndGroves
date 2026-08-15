class_name SacrificeGlyphBehavior extends BlockPartBehavior

## 献祭法阵 (Sacrifice Glyph) Behavior
## 星语术士：触发时销毁场上 1 个己方法阵/扎根 Block（优先法阵 variant glyph）
## 用于：虚空裂隙（伤害 15 并献祭法阵）/ 坍缩星（伤害已合并，部件 B 仅献祭）

func create_action(block, _part):
	if block == null:
		return null
	var block_piles := block.get_parent() as BlockPilesHere
	if block_piles == null:
		return null
	return CallbackAction.new(func():
		_sacrifice(block_piles)
	, Enums.ActionType.Callback)

func _sacrifice(block_piles: BlockPilesHere) -> void:
	# 优先找法阵（variant glyph），其次扎根
	var target: Block = _find_glyph(block_piles, "glyph")
	if target == null:
		target = _find_glyph(block_piles, "root")
	if target == null:
		GameLog.debug("SacrificeGlyphBehavior: no glyph/root on field to sacrifice")
		return
	# 释放格子并移除
	for p in target.get_parts():
		var gp: Vector2 = GridState.find_nearest_grid_point(p.global_position)
		var coord: Vector2i = GridState.get_grid_coords(gp)
		if coord.x >= 0 and coord.y >= 0:
			GridState.restore_grid_state(coord.x, coord.y)
	block_piles.remove_block_from_placed(target)
	target.remove_from_group("placed_blocks")
	if is_instance_valid(target.get_parent()):
		target.get_parent().remove_child(target)
	target.queue_free()
	GameLog.debug("SacrificeGlyphBehavior: sacrificed [" + (target.BlockName if not target.BlockName.is_empty() else "?") + "]")

func _find_glyph(block_piles: BlockPilesHere, variant: String) -> Block:
	for b in block_piles.PlacedPile.Pile:
		if not is_instance_valid(b) or b is not Block:
			continue
		if b.Faction != Block.BlockFaction.Player:
			continue
		for p in b.get_parts():
			for bh in p.Behaviors:
				if bh is GlyphRootBehavior and (bh as GlyphRootBehavior).IsVariant == variant:
					return b
				if bh is RootBehavior and variant == "root":
					return b
	return null
