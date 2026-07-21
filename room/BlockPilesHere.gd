class_name BlockPilesHere extends Node2D

const ShowingPileBaseX := 0.0
const ShowingPileBaseY := 0.0
const MaxShowingPileColumns := 4
const CellSize := 96

var _block_layout_positions: Dictionary = {}
var _pending_draws: int

@export var DiscardedPile: PileComponent
@export var DrawPile: PileComponent
@export var PlacedPile: PileComponent
@export var PlayerCharacter: Player
@export var ShowingPile: PileComponent

func _ready() -> void:
	ShowingPile.child_entered_tree.connect(_on_showing_pile_child_added)

func initialize_draw_pile() -> void:
	var player_pile := PlayerCharacter.get_node("%PlayerPile") as PileComponent
	for b in player_pile.Pile:
		if not is_instance_valid(b):
			continue
		if b.Definition != null:
			DrawPile.add_block(BlockRegistry.create_block(b.Definition))
	GameLog.debug("Draw pile initialized, total " + str(DrawPile.Count) + " cards")

func draw_cards(count: int) -> void:
	_pending_draws += count
	if _pending_draws > count:
		return
	_process_pending_draws()

func _process_pending_draws() -> void:
	while _pending_draws > 0:
		_pending_draws -= 1
		if DrawPile.Count == 0:
			_reshuffle_discard_to_draw()
			if DrawPile.Count == 0:
				_pending_draws = 0
				break
		_show_one_block()

func clear_player_round() -> void:
	_clear_showing_pile_blocks()
	_clear_placed_player_blocks()
	_block_layout_positions.clear()

func _clear_showing_pile_blocks() -> void:
	var showing := ShowingPile.Pile.duplicate()
	for block in showing:
		if block is Block:
			if block.placed.is_connected(_on_block_placed):
				block.placed.disconnect(_on_block_placed)
			if block.left_grid.is_connected(_on_block_left_grid):
				block.left_grid.disconnect(_on_block_left_grid)
			_unparent_block(block, ShowingPile)
			ShowingPile.remove_block(block)
			if not block.IsPlaced:
				DiscardedPile.add_block(block)

func _clear_placed_player_blocks() -> void:
	var placed: Array[Block] = []
	for b in PlacedPile.Pile:
		if not is_instance_valid(b):
			continue
		if b.Faction == Block.BlockFaction.Player:
			placed.append(b)
	for block in placed:
		var prevents := false
		for part in block.get_parts():
			if part.PartDefinition != null and part.PartDefinition.Behaviors != null:
				for bh in part.PartDefinition.Behaviors:
					if bh != null and bh.prevents_clear():
						prevents = true
						break
			if prevents:
				break
		if prevents:
			GameLog.debug("Block " + str(block.Definition.BlockName if block.Definition != null else "") + " declares PreventsClear, staying on grid")
			continue
		if block.placed.is_connected(_on_block_placed):
			block.placed.disconnect(_on_block_placed)
		if block.left_grid.is_connected(_on_block_left_grid):
			block.left_grid.disconnect(_on_block_left_grid)
		PlacedPile.remove_block(block)
		_free_block_grid_cells(block)
		_unparent_block(block, null)
		DiscardedPile.add_block(block)

func _unparent_block(block: Block, expected_parent: Node) -> void:
	if not is_instance_valid(block) or block.get_parent() == null:
		return
	if expected_parent != null and block.get_parent() != expected_parent:
		return
	block.get_parent().remove_child(block)

func _free_block_grid_cells(block: Block) -> void:
	for part in block.get_parts():
		var grid_pos: Vector2 = GridState.find_nearest_grid_point(part.global_position)
		var coords: Vector2i = GridState.get_grid_coords(grid_pos)
		if coords.x >= 0 and coords.y >= 0:
			GridState.restore_grid_state(coords.x, coords.y)

func _reshuffle_discard_to_draw() -> void:
	GameLog.debug("Draw pile empty, reshuffling discard pile!")
	var discarded := DiscardedPile.Pile.duplicate()
	for block in discarded:
		DiscardedPile.remove_block(block)
		DrawPile.add_block(block)

func _on_showing_pile_child_added(node: Node) -> void:
	if node is not Block:
		return
	var block := node as Block
	block.IsPlaced = false
	if block.placed.is_connected(_on_block_placed):
		block.placed.disconnect(_on_block_placed)
	block.placed.connect(_on_block_placed)
	if block.left_grid.is_connected(_on_block_left_grid):
		block.left_grid.disconnect(_on_block_left_grid)
	block.left_grid.connect(_on_block_left_grid)
	var layout_pos: Vector2 = _find_available_position(block)
	_block_layout_positions[block] = layout_pos
	block.position = layout_pos
	block.OriginalPos = block.global_position

func _find_available_position(block: Block) -> Vector2:
	if block == null or block.Definition == null:
		return Vector2(ShowingPileBaseX, ShowingPileBaseY)
	var part_count := block.Definition.PartDefinitions.size()
	var grid_cols := ceili(sqrt(part_count))
	var grid_rows := ceili(float(part_count) / float(grid_cols))
	var occupied := _collect_occupied_cells(block)
	for row in 100:
		for col in MaxShowingPileColumns:
			var base_pos := Vector2(ShowingPileBaseX + col * CellSize * grid_cols, ShowingPileBaseY + row * CellSize * grid_rows)
			if not _is_cell_occupied(base_pos, grid_rows, grid_cols, occupied):
				return base_pos
	GameLog.err("No available position found for block")
	return Vector2(ShowingPileBaseX, ShowingPileBaseY)

func _collect_occupied_cells(exclude_block: Block) -> Dictionary:
	var occupied := {}
	for key in _block_layout_positions.keys():
		if key == exclude_block:
			continue
		var other_part_count: int = key.Definition.PartDefinitions.size()
		var other_cols: int = ceili(sqrt(other_part_count))
		var other_rows: int = ceili(float(other_part_count) / float(other_cols))
		var pos := _block_layout_positions[key] as Vector2
		for r in other_rows:
			for c in other_cols:
				var p := Vector2i(int((pos.x + c * CellSize - ShowingPileBaseX) / CellSize), int((pos.y + r * CellSize - ShowingPileBaseY) / CellSize))
				occupied[p] = true
	return occupied

func _is_cell_occupied(base_pos: Vector2, grid_rows: int, grid_cols: int, occupied: Dictionary) -> bool:
	for r in grid_rows:
		for c in grid_cols:
			var p := Vector2i(int((base_pos.x + c * CellSize - ShowingPileBaseX) / CellSize), int((base_pos.y + r * CellSize - ShowingPileBaseY) / CellSize))
			if occupied.has(p):
				return true
	return false

func _show_one_block() -> void:
	if DrawPile.Count == 0:
		return
	var b := DrawPile.get_random_block_reference()
	if b != null:
		ShowingPile.add_block(b)
		DrawPile.remove_block(b)
		ShowingPile.add_child(b)

func _on_block_left_grid(block: Block) -> void:
	block.IsPlaced = false
	PlacedPile.remove_block(block)
	if block.get_parent() != null and is_instance_valid(block.get_parent()):
		block.get_parent().remove_child(block)
	ShowingPile.add_block(block)
	ShowingPile.add_child(block)

func _on_block_placed(block: Block) -> void:
	var is_new_placement := ShowingPile.Pile.has(block)
	if is_new_placement:
		var global_pos := block.global_position
		_block_layout_positions.erase(block)
		if block.get_parent() != null and is_instance_valid(block.get_parent()):
			block.get_parent().remove_child(block)
		add_child(block)
		block.global_position = global_pos
		ShowingPile.remove_block(block)
		PlacedPile.add_block(block)
		draw_cards(1)
