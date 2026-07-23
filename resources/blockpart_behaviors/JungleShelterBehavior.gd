class_name JungleShelterBehavior extends BlockPartBehavior

## 丛林庇护 (Jungle Shelter) Behavior
## 翠绿哨兵：扎根 Block 给相邻的己方 Block 提供额外护盾
## 此 Behavior 应挂在扎根 Block 的部件上
## 庇护效果在扎根 Block 被触发时为目标 Block 添加护盾

@export var ShelterShieldPerRoot: int = 2  # 每个相邻扎根提供的护盾量

func create_action(block, part):
	if block == null:
		return null
	return CallbackAction.new(func():
		_apply_shelter(block)
	, Enums.ActionType.Block)

func _apply_shelter(block: Block) -> void:
	var tree := block.get_tree()
	if tree == null:
		return
	var block_piles = block.get_parent()
	if block_piles == null or not block_piles.has_method("PlacedPile"):
		return
	# 获取本 Block 所有部件占用的格子坐标
	var my_cells: Array[Vector2i] = []
	for p in block.get_parts():
		var gp: Vector2 = GridState.find_nearest_grid_point(p.global_position)
		var coord: Vector2i = GridState.get_grid_coords(gp)
		if coord.x >= 0 and coord.y >= 0:
			my_cells.append(coord)
	# 查找相邻的己方 Block 并给予护盾
	var adjacent_offsets: Array[Vector2i] = [
		Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 0), Vector2i(-1, 0)
	]
	var sheltered_blocks: Array = []
	for cell in my_cells:
		for offset in adjacent_offsets:
			var neighbor_cell: Vector2i = cell + offset
			if _is_out_of_bounds(neighbor_cell):
				continue
			if GridState.get_grid_state(neighbor_cell.x, neighbor_cell.y) != Enums.GridStateEnum.Occupied:
				continue
			# 查找该格子上的己方 Block
			for b in block_piles.PlacedPile.Pile:
				if not is_instance_valid(b) or b == block:
					continue
				if b.Faction != Block.BlockFaction.Player:
					continue
				if _is_block_at_grid(b, neighbor_cell) and not sheltered_blocks.has(b):
					sheltered_blocks.append(b)
					_grant_shelter_shield(b, tree)
					break

func _is_block_at_grid(block_node: Block, grid_pos: Vector2i) -> bool:
	for p in block_node.get_parts():
		var gp: Vector2 = GridState.find_nearest_grid_point(p.global_position)
		var coord: Vector2i = GridState.get_grid_coords(gp)
		if coord == grid_pos:
			return true
	return false

func _grant_shelter_shield(target_block: Block, tree: SceneTree) -> void:
	# 给目标 Block 的所有者添加护盾
	for node in tree.get_nodes_in_group("Players"):
		if node is Node2D:
			var player := node as Node2D
			var shield_comp: ShieldComponent = _find_shield_component(player)
			if shield_comp != null:
				shield_comp.add_shield(ShelterShieldPerRoot)
				GameLog.debug("JungleShelterBehavior: Sheltered adjacent block, granted " + str(ShelterShieldPerRoot) + " shield")
			return

func _find_shield_component(root: Node) -> ShieldComponent:
	if root is ShieldComponent:
		return root
	for child in root.get_children():
		var found: ShieldComponent = _find_shield_component(child)
		if found != null:
			return found
	return null

func _is_out_of_bounds(pos: Vector2i) -> bool:
	return pos.x < 0 or pos.x > 6 or pos.y < 0 or pos.y > 4
