class_name ChainTriggerBehavior extends BlockPartBehavior

## 链式引爆 (Chain Trigger) Behavior
## 废品爆破：触发时同时触发相邻格上玩家 Block 的效果（不处理其生命周期）
## 深度 1，不递归。用于：炸药包（相邻格 Block 也被触发）

func create_action(block, _part):
	if block == null:
		return null
	var block_piles := block.get_parent() as BlockPilesHere
	if block_piles == null:
		return null
	return CallbackAction.new(func():
		_trigger_adjacent(block, block_piles)
	, Enums.ActionType.Callback)

func _trigger_adjacent(block: Block, block_piles: BlockPilesHere) -> void:
	var tree := block.get_tree()
	if tree == null:
		return
	# 本 Block 占用的格子
	var my_cells: Array[Vector2i] = []
	for p in block.get_parts():
		var gp: Vector2 = GridState.find_nearest_grid_point(p.global_position)
		var coord: Vector2i = GridState.get_grid_coords(gp)
		if coord.x >= 0 and coord.y >= 0:
			my_cells.append(coord)
	var offsets: Array[Vector2i] = [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]
	var triggered: Array = []
	for cell in my_cells:
		for offset in offsets:
			var nc: Vector2i = cell + offset
			if nc.x < 0 or nc.x > 6 or nc.y < 0 or nc.y > 4:
				continue
			if GridState.get_grid_state(nc.x, nc.y) != Enums.GridStateEnum.Occupied:
				continue
			for b in block_piles.get_blocks_on_grid():
				if not is_instance_valid(b) or b == block or triggered.has(b):
					continue
				if b.Faction != Block.BlockFaction.Player:
					continue
				if _is_block_at_grid(b, nc):
					triggered.append(b)
					_trigger_block(b)
					break
	GameLog.debug("ChainTriggerBehavior: chain-triggered " + str(triggered.size()) + " adjacent block(s)")

func _is_block_at_grid(block_node: Block, grid_pos: Vector2i) -> bool:
	for p in block_node.get_parts():
		var gp: Vector2 = GridState.find_nearest_grid_point(p.global_position)
		if GridState.get_grid_coords(gp) == grid_pos:
			return true
	return false

## 触发目标 Block 所有部件的 Behavior（仅入队 Action，不处理生命周期）
func _trigger_block(block_node: Block) -> void:
	for p in block_node.get_parts():
		for bh in p.Behaviors:
			if bh == null:
				continue
			var action: AbstractGameAction = bh.create_action(block_node, p) as AbstractGameAction
			if action != null and ActionManager.Instance != null:
				ActionManager.Instance.add_to_bottom(action)
