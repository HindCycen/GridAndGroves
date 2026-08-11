class_name ChainReleaseBehavior extends BlockPartBehavior

## 链式释放 (Chain Release) Behavior
## 铁锈游侠：松动 Block 触发时同时释放相邻的松动 Block
## 仅释放格子 + 进入弃牌堆（不触发效果）
## 注意：不递归传播（防止一次性释放全网格）

func create_action(block, part):
	if block == null:
		return null
	# 在创建时捕获 BlockPilesHere（回调执行时 Block 可能已被移出场景树）
	var block_piles := block.get_parent() as BlockPilesHere
	if block_piles == null:
		return null
	return CallbackAction.new(func():
		_chain_release(block, block_piles)
	, Enums.ActionType.Callback)

func _chain_release(block: Block, block_piles: BlockPilesHere) -> void:
	var tree := block.get_tree()
	if tree == null:
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
					_release_loose_block(b, block_piles)
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
		if p.Behaviors.size() == 0:
			continue
		for behavior in p.Behaviors:
			if behavior is LooseBlockBehavior:
				return true
	return false

func _release_loose_block(block_node: Block, block_piles: BlockPilesHere) -> void:
	# 释放格子
	for p in block_node.get_parts():
		var gp: Vector2 = GridState.find_nearest_grid_point(p.global_position)
		var coord: Vector2i = GridState.get_grid_coords(gp)
		if coord.x >= 0 and coord.y >= 0:
			GridState.restore_grid_state(coord.x, coord.y)
	# 从放置堆移除并进入弃牌堆（统一走公共 API）
	block_piles.remove_block_from_placed(block_node)
	block_node.remove_from_group("placed_blocks")
	block_piles.send_block_to_discard(block_node)
	GameLog.debug("ChainReleaseBehavior: Released adjacent loose block " + str(block_node.BlockName if not block_node.BlockName.is_empty() else "") + " to discard")

func _is_out_of_bounds(pos: Vector2i) -> bool:
	return pos.x < 0 or pos.x > 6 or pos.y < 0 or pos.y > 4
