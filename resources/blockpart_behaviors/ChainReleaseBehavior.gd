class_name ChainReleaseBehavior extends BlockPartBehavior

## 链式释放 (Chain Release) Behavior
## 铁锈游侠：松动 Block 触发时同时释放相邻的松动 Block
## 仅释放格子 + 进入弃牌堆（不触发效果）
## 注意：不递归传播（防止一次性释放全网格）

func create_action(block, part):
	if block == null:
		return null
	return CallbackAction.new(func():
		_chain_release(block)
	, Enums.ActionType.Callback)

func _chain_release(block: Block) -> void:
	var tree := block.get_tree()
	if tree == null:
		return
	var block_piles = block.get_parent()
	if block_piles == null or not block_piles.has_method("PlacedPile"):
		return
	var all_placed: Array = block_piles.PlacedPile.Pile
	# 获取本 Block 所有部件占用的格子坐标
	var my_cells: Array[Vector2i] = []
	for p in block.get_parts():
		var gp: Vector2 = GridState.find_nearest_grid_point(p.global_position)
		var coord: Vector2i = GridState.get_grid_coords(gp)
		if coord.x >= 0 and coord.y >= 0:
			my_cells.append(coord)
	# 遍历相邻格子，找其他玩家的松动 Block
	var adjacent_offsets: Array[Vector2i] = [
		Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 0), Vector2i(-1, 0)
	]
	for cell in my_cells:
		for offset in adjacent_offsets:
			var neighbor_cell: Vector2i = cell + offset
			if _is_out_of_bounds(neighbor_cell):
				continue
			# 检查该格子是否有 Block
			if GridState.get_grid_state(neighbor_cell.x, neighbor_cell.y) != Enums.GridStateEnum.Occupied:
				continue
			# 查找该格子上的玩家 Block
			for b in all_placed:
				if not is_instance_valid(b) or b == block:
					continue
				if b.Faction != Block.BlockFaction.Player:
					continue
				if _is_block_at_grid(b, neighbor_cell) and _has_loose_behavior(b):
					_release_loose_block(b, tree, block_piles)
					# 仅释放第一个找到的（防止一次释放太多）
					return

func _is_block_at_grid(block_node: Block, grid_pos: Vector2i) -> bool:
	for p in block_node.get_parts():
		var gp: Vector2 = GridState.find_nearest_grid_point(p.global_position)
		var coord: Vector2i = GridState.get_grid_coords(gp)
		if coord == grid_pos:
			return true
	return false

func _has_loose_behavior(block_node: Block) -> bool:
	for p in block_node.get_parts():
		if p.PartDefinition == null or p.PartDefinition.Behaviors == null:
			continue
		for behavior in p.PartDefinition.Behaviors:
			if behavior is LooseBlockBehavior:
				return true
	return false

func _release_loose_block(block_node: Block, tree: SceneTree, block_piles) -> void:
	# 释放格子
	for p in block_node.get_parts():
		var gp: Vector2 = GridState.find_nearest_grid_point(p.global_position)
		var coord: Vector2i = GridState.get_grid_coords(gp)
		if coord.x >= 0 and coord.y >= 0:
			GridState.restore_grid_state(coord.x, coord.y)
	# 从放置堆移除
	block_piles.PlacedPile.remove_block(block_node)
	# 进入弃牌堆
	for node in tree.get_nodes_in_group("Players"):
		if node is Node2D:
			var player := node as Node2D
			var pile_node = player.get_node("%PlayerPile")
			if pile_node != null and pile_node.has_method("DiscardedPile"):
				var discard = pile_node.DiscardedPile
				if discard != null and discard.has_method("add_block"):
					block_node.IsPlaced = false
					block_node.global_position = block_node.OriginalPos
					discard.add_block(block_node)
					GameLog.debug("ChainReleaseBehavior: Released adjacent loose block " + str(block_node.Definition.BlockName if block_node.Definition != null else "") + " to discard")
					return
	# 安全兜底
	block_node.global_position = Vector2(9999, 9999)

func _is_out_of_bounds(pos: Vector2i) -> bool:
	return pos.x < 0 or pos.x > 6 or pos.y < 0 or pos.y > 4
