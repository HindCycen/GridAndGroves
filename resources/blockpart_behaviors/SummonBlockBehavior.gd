class_name SummonBlockBehavior extends BlockPartBehavior

## 生成 Block (Summon Block) Behavior
## 触发时在随机空格生成 1 个指定 Block（1×1，来自 block_defs.json，非手牌）
## 用于：种子地雷（生成小树苗 Sapling）/ 荆棘领域（生成荆棘陷阱 ThornTrap）

@export var SummonName: String = "Sapling"

func create_action(block, _part):
	if block == null:
		return null
	var block_piles := block.get_parent() as BlockPilesHere
	if block_piles == null:
		return null
	return CallbackAction.new(func():
		_summon(block_piles)
	, Enums.ActionType.Callback)

func _summon(block_piles: BlockPilesHere) -> void:
	var tree := block_piles.get_tree()
	if tree == null:
		return
	var cell: Vector2i = _find_random_free_cell()
	if cell.x < 0:
		GameLog.debug("SummonBlockBehavior: no free cell to summon")
		return
	var new_block: Block = BlockRegistry.create_block_by_name(SummonName)
	if new_block == null:
		GameLog.err("SummonBlockBehavior: cannot create [" + SummonName + "]")
		return
	# 放置到网格
	new_block.global_position = GridState.get_grid_pos(cell)
	block_piles.add_child(new_block)
	block_piles.add_block_to_placed(new_block)
	new_block.add_to_group("placed_blocks")
	for p in new_block.get_parts():
		var coord: Vector2i = GridState.get_grid_coords(GridState.find_nearest_grid_point(p.global_position))
		if coord.x >= 0 and coord.y >= 0:
			GridState.set_grid_state(coord.x, coord.y, Enums.GridStateEnum.Occupied)
	GameLog.debug("SummonBlockBehavior: summoned [" + SummonName + "] at " + str(cell))

func _find_random_free_cell() -> Vector2i:
	var free_cells: Array[Vector2i] = []
	for x in range(7):
		for y in range(5):
			if GridState.get_grid_state(x, y) == Enums.GridStateEnum.Free:
				free_cells.append(Vector2i(x, y))
	if free_cells.size() == 0:
		return Vector2i(-1, -1)
	var idx: int = RngManager.get_misc_rand(free_cells.size())
	return free_cells[idx]
