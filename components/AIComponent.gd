class_name AIComponent extends Node

static var _search_offsets := [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1),
	Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2)
]

var _block_piles_here
var _cycle_index: int
var _owner: Node2D
var _repeat_count: int

func _ready() -> void:
	_owner = get_parent() as Node2D

func setup(block_piles_here) -> void:
	_block_piles_here = block_piles_here

func reset() -> void:
	_cycle_index = 0
	_repeat_count = 0

func get_current_intent(definition) -> Variant:
	if definition == null or definition.IntentCycle == null or definition.IntentCycle.size() == 0:
		return null
	return definition.IntentCycle[_cycle_index]

func advance_turn(definition) -> void:
	if definition == null or definition.IntentCycle == null or definition.IntentCycle.size() == 0:
		return
	var intent = definition.IntentCycle[_cycle_index]
	_repeat_count += 1
	if _repeat_count >= intent.RepeatCount:
		_repeat_count = 0
		_cycle_index = (_cycle_index + 1) % definition.IntentCycle.size()

func execute_intent(definition) -> void:
	var intent = get_current_intent(definition)
	if intent == null or intent.BlockPlacements == null or _block_piles_here == null:
		return
	for placement in intent.BlockPlacements:
		if placement == null:
			continue
		# 兼容两种注册方式：Json方案用BlockName，旧tres方案用BlockRef
		var block_name: String = ""
		if not placement.BlockName.is_empty():
			block_name = placement.BlockName
		elif placement.BlockRef != null:
			block_name = placement.BlockRef.BlockName
		else:
			continue
		var pos: Vector2i = placement.GridPosition
		if placement.RandomOffsetRange > 0:
			var range_val: int = placement.RandomOffsetRange
			pos.x += RngManager.get_misc_rand(range_val * 2 + 1) - range_val
			pos.y += RngManager.get_misc_rand(range_val * 2 + 1) - range_val
			pos.x = clampi(pos.x, 0, 6)
			pos.y = clampi(pos.y, 0, 4)
		pos = _find_free_cell_near(pos)
		if pos.x < 0:
			continue
		var block: Block = BlockRegistry.create_block_by_name(block_name)
		if block == null:
			continue
		# Faction 已在 BlockRegistry.create_block() 中根据 BlockDef.Faction 自动设置
		_block_piles_here.add_child(block)
		block.place_at_grid(pos)
		_block_piles_here.PlacedPile.add_block(block)
	advance_turn(definition)

func clear_existing_blocks() -> void:
	if _block_piles_here == null:
		return
	var old_blocks: Array[Block] = []
	for b in _block_piles_here.PlacedPile.Pile:
		if not is_instance_valid(b):
			continue
		if b.Faction == Block.BlockFaction.Enemy:
			old_blocks.append(b)
	for block in old_blocks:
		_block_piles_here.PlacedPile.remove_block(block)
		for part in block.get_parts():
			var grid_point: Vector2 = GridState.find_nearest_grid_point(part.global_position)
			var coords: Vector2i = GridState.get_grid_coords(grid_point)
			if coords.x >= 0 and coords.y >= 0:
				GridState.restore_grid_state(coords.x, coords.y)
		if block.get_parent() != null and is_instance_valid(block.get_parent()):
			block.get_parent().remove_child(block)
		block.queue_free()

static func _find_free_cell_near(center: Vector2i) -> Vector2i:
	for offset in _search_offsets:
		var candidate: Vector2i = center + offset
		if candidate.x < 0 or candidate.x >= 7 or candidate.y < 0 or candidate.y >= 5:
			continue
		if GridState.get_grid_state(candidate.x, candidate.y) != Enums.GridStateEnum.Free:
			continue
		return candidate
	return Vector2i(-1, -1)
