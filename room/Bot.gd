class_name Bot extends Node2D

var _animated_sprite_2d: AnimatedSprite2D
var _battle_time: BattleTime
var _block_piles_here: BlockPilesHere
var _current_direction := Vector2i.DOWN
var _current_grid_pos: Vector2i
var _ending_turn: bool
var _patrol_timer: SceneTreeTimer
var _stopped: bool

func _ready() -> void:
	_battle_time = get_tree().root.get_node("BattleTime")
	_animated_sprite_2d = %AnimatedSprite2D as AnimatedSprite2D
	_block_piles_here = get_parent().get_node("BlockPilesHere")
	_battle_time.say_battle_started()
	visible = false
	_go_to_starter_point()

func start_patrol() -> void:
	_stopped = false
	_ending_turn = false
	_current_direction = Vector2i.DOWN
	visible = true
	_animated_sprite_2d.play("bot_animation")
	_schedule_next_step()

func stop_patrol() -> void:
	_stopped = true
	_go_to_starter_point()

func _schedule_next_step() -> void:
	_patrol_timer = get_tree().create_timer(1.0)
	_patrol_timer.timeout.connect(_on_patrol_timer_timeout)

func _on_patrol_timer_timeout() -> void:
	if not is_instance_valid(self):
		return
	if _stopped:
		return
	_battle_time.say_pre_block_execute()
	_move_to_next_cell()
	if _ending_turn:
		return
	_battle_time.say_post_block_execute()
	_schedule_next_step()

func _exit_tree() -> void:
	if _patrol_timer != null and is_instance_valid(_patrol_timer) and _patrol_timer.timeout.is_connected(_on_patrol_timer_timeout):
		_patrol_timer.timeout.disconnect(_on_patrol_timer_timeout)

func _move_to_next_cell() -> void:
	var calc_result: Array = _try_calculate_next_cell2()
	if calc_result[0] == false:
		_end_turn()
		return
	var new_pos := calc_result[1] as Vector2i
	var target_has_block: bool = GridState.get_grid_state(new_pos.x, new_pos.y) == Enums.GridStateEnum.Occupied
	_release_cell_safely(_current_grid_pos)
	_current_grid_pos = new_pos
	global_position = GridState.get_grid_pos(_current_grid_pos)
	GridState.set_grid_state(_current_grid_pos.x, _current_grid_pos.y, Enums.GridStateEnum.Occupied)
	if target_has_block:
		_enqueue_block_actions_at(new_pos)

func _try_calculate_next_cell2() -> Array:
	var new_pos := _current_grid_pos + _current_direction
	if _current_direction == Vector2i.DOWN:
		if new_pos.y > 4:
			new_pos = Vector2i(_current_grid_pos.x + 1, 0)
		if new_pos.x > 6:
			return [false, new_pos]
	elif _is_out_of_bounds(new_pos):
		return [false, new_pos]
	return [true, new_pos]

func _is_out_of_bounds(pos: Vector2i) -> bool:
	return pos.x < 0 or pos.x > 6 or pos.y < 0 or pos.y > 4

func _enqueue_block_actions_at(grid_pos: Vector2i) -> void:
	for block in _block_piles_here.PlacedPile.Pile:
		if not is_instance_valid(block):
			continue
		for part in block.get_parts():
			if not _is_part_at_grid(part, grid_pos):
				continue
			GameLog.debug("Bot detected BlockPart at (" + str(grid_pos.x) + ", " + str(grid_pos.y) + ")")
			_process_block_part(block, part)
			return

func _is_part_at_grid(part: BlockPart, grid_pos: Vector2i) -> bool:
	var part_grid_point: Vector2 = GridState.find_nearest_grid_point(part.global_position)
	var coords: Vector2i = GridState.get_grid_coords(part_grid_point)
	return coords == grid_pos

func _process_block_part(block: Block, part: BlockPart) -> void:
	_battle_time.say_block_execute()
	var move_dir := part.PartDefinition.MovingDirection if part.PartDefinition != null else Vector2i.DOWN
	_current_direction = move_dir
	if move_dir != Vector2i.DOWN:
		GameLog.debug("  Bot direction changed to (" + str(move_dir.x) + ", " + str(move_dir.y) + ")")
	if part.PartDefinition == null or part.PartDefinition.Behaviors == null:
		return
	var should_exhaust := false
	for behavior in part.PartDefinition.Behaviors:
		if behavior == null:
			continue
		var action: AbstractGameAction = behavior.create_action(block, part) as AbstractGameAction
		if action != null:
			if ActionManager.Instance != null:
				ActionManager.Instance.add_to_bottom(action)
			GameLog.debug("  Queued Action: " + action.get_class() + " (amount=" + str(action.amount) + ")")
			if action.exhaust_source_block():
				should_exhaust = true
	if should_exhaust and block.Faction == Block.BlockFaction.Player:
		GameLog.debug("  Block " + str(block.Definition.BlockName if block.Definition != null else "") + " exhausted, removed from battle")
		_exhaust_block(block)

func _exhaust_block(block: Block) -> void:
	for p in block.get_parts():
		var grid_point: Vector2 = GridState.find_nearest_grid_point(p.global_position)
		var coords: Vector2i = GridState.get_grid_coords(grid_point)
		if coords.x >= 0 and coords.y >= 0:
			GridState.restore_grid_state(coords.x, coords.y)
	_block_piles_here.PlacedPile.remove_block(block)
	if block.get_parent() != null and is_instance_valid(block.get_parent()):
		block.get_parent().remove_child(block)
	block.queue_free()

func _end_turn() -> void:
	GameLog.info("Bot turn ended")
	_stopped = true
	_ending_turn = true
	_battle_time.say_turn_ended()
	_go_to_starter_point()

func _release_cell_safely(pos: Vector2i) -> void:
	if _is_out_of_bounds(pos):
		return
	if not _has_enemy_block_at(pos) and GridState.get_grid_state(pos.x, pos.y) != Enums.GridStateEnum.Unable:
		GridState.restore_grid_state(pos.x, pos.y)

func _go_to_starter_point() -> void:
	global_position = Vector2(GridState.get_grid_pos(Vector2i(0, 0)).x, GridState.get_grid_pos(Vector2i(0, 0)).y - 96)
	_release_cell_safely(_current_grid_pos)
	_current_grid_pos = Vector2i(0, -1)
	_animated_sprite_2d.stop()
	visible = false

func _has_enemy_block_at(grid_pos: Vector2i) -> bool:
	for block in _block_piles_here.PlacedPile.Pile:
		if not is_instance_valid(block):
			continue
		if block.Faction != Block.BlockFaction.Enemy:
			continue
		for part in block.get_parts():
			var coords: Vector2i = GridState.get_grid_coords(GridState.find_nearest_grid_point(part.global_position))
			if coords == grid_pos:
				return true
	return false
