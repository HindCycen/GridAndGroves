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

func _enqueue_block_actions_at(grid_pos: Vector2i, resonance_depth: int = 0) -> void:
	for block in _block_piles_here.PlacedPile.Pile:
		if not is_instance_valid(block):
			continue
		for part in block.get_parts():
			if not _is_part_at_grid(part, grid_pos):
				continue
			GameLog.debug("Bot detected BlockPart at (" + str(grid_pos.x) + ", " + str(grid_pos.y) + ")")
			_process_block_part(block, part, resonance_depth)
			# 共鸣连锁：部件带 ResonanceTriggerBehavior 且深度 < 3 时递归触发相邻共鸣
			if _has_resonance_behavior(part) and resonance_depth < 3:
				_trigger_resonance_chain(block, resonance_depth + 1)
			return

func _is_part_at_grid(part: BlockPart, grid_pos: Vector2i) -> bool:
	var part_grid_point: Vector2 = GridState.find_nearest_grid_point(part.global_position)
	var coords: Vector2i = GridState.get_grid_coords(part_grid_point)
	return coords == grid_pos

func _process_block_part(block: Block, part: BlockPart, resonance_depth: int = 0) -> void:
	_battle_time.say_block_execute()
	var move_dir := part.PartDefinition.MovingDirection if part.PartDefinition != null else Vector2i.DOWN
	_current_direction = move_dir
	if move_dir != Vector2i.DOWN:
		GameLog.debug("  Bot direction changed to (" + str(move_dir.x) + ", " + str(move_dir.y) + ")")
	if part.PartDefinition == null or part.PartDefinition.Behaviors == null:
		return
	var should_exhaust := false
	var has_loose := false
	for behavior in part.PartDefinition.Behaviors:
		if behavior == null:
			continue
		# 检测松动 Behavior
		if behavior is LooseBlockBehavior:
			has_loose = true
		# 创建并入队 Action
		var action: AbstractGameAction = behavior.create_action(block, part) as AbstractGameAction
		if action != null:
			# 如果是共鸣链触发（depth > 0），给 Action 传递链深度参数
			if resonance_depth > 0 and action.has_method("set_chain_bonus"):
				action.set_chain_bonus(resonance_depth)
			if ActionManager.Instance != null:
				ActionManager.Instance.add_to_bottom(action)
			GameLog.debug("  Queued Action: " + action.get_class() + " (amount=" + str(action.amount) + ")")
			if action.exhaust_source_block():
				should_exhaust = true
	# 处理 Block 生命周期：松动 > 耗尽 > 留在网格
	if has_loose and block.Faction == Block.BlockFaction.Player:
		# 松动：释放格子 + 进弃牌堆（不销毁）
		GameLog.debug("  Block " + str(block.Definition.BlockName if block.Definition != null else "") + " loosened, entering discard pile")
		_loose_block(block)
	elif should_exhaust and block.Faction == Block.BlockFaction.Player:
		# 耗尽：移出战斗并销毁
		GameLog.debug("  Block " + str(block.Definition.BlockName if block.Definition != null else "") + " exhausted, removed from battle")
		_exhaust_block(block)

func _exhaust_block(block: Block) -> void:
	for p in block.get_parts():
		var grid_point: Vector2 = GridState.find_nearest_grid_point(p.global_position)
		var coords: Vector2i = GridState.get_grid_coords(grid_point)
		if coords.x >= 0 and coords.y >= 0:
			GridState.restore_grid_state(coords.x, coords.y)
	_block_piles_here.PlacedPile.remove_block(block)
	block.remove_from_group("placed_blocks")
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

# ---- 松动 (Loose) 机制 ----

## 将松动 Block 从网格释放，放入弃牌堆
func _loose_block(block: Block) -> void:
	var tree := get_tree()
	if tree == null:
		return
	# 释放所有占用的格子
	for p in block.get_parts():
		var grid_point: Vector2 = GridState.find_nearest_grid_point(p.global_position)
		var coords: Vector2i = GridState.get_grid_coords(grid_point)
		if coords.x >= 0 and coords.y >= 0:
			GridState.restore_grid_state(coords.x, coords.y)
	# 从放置堆中移除
	_block_piles_here.PlacedPile.remove_block(block)
	block.remove_from_group("placed_blocks")
	# 将 Block 移入弃牌堆
	_enter_discard_pile(block, tree)
	# 触发废品回收（ScrapPayoffBehavior）
	_trigger_scrap_payoff(block)

## 将 Block 放入玩家弃牌堆（不销毁节点，保留重用）
func _enter_discard_pile(block: Block, tree: SceneTree) -> void:
	for node in tree.get_nodes_in_group("Players"):
		if node is Node2D:
			var player := node as Node2D
			var pile_node = player.get_node("%PlayerPile")
			if pile_node != null and pile_node.has_method("DiscardedPile"):
				var discard = pile_node.DiscardedPile
				if discard != null and discard.has_method("add_block"):
					# 断开信号连接防止残留
					if block.placed.is_connected(_block_piles_here._on_block_placed):
						block.placed.disconnect(_block_piles_here._on_block_placed)
					if block.left_grid.is_connected(_block_piles_here._on_block_left_grid):
						block.left_grid.disconnect(_block_piles_here._on_block_left_grid)
					# 重置 Block 状态
					block.IsPlaced = false
					block.global_position = block.OriginalPos
					discard.add_block(block)
					# 如果原父节点仍然持有，移除之
					if block.get_parent() != null and is_instance_valid(block.get_parent()):
						block.get_parent().remove_child(block)
					return
	# 安全兜底
	if block.get_parent() != null and is_instance_valid(block.get_parent()):
		block.get_parent().remove_child(block)
	block.global_position = Vector2(9999, 9999)

## 触发废品回收：查找 Block 的 ScrapPayoffBehavior 并执行
func _trigger_scrap_payoff(block: Block) -> void:
	for part in block.get_parts():
		if part.PartDefinition == null or part.PartDefinition.Behaviors == null:
			continue
		for behavior in part.PartDefinition.Behaviors:
			if behavior is ScrapPayoffBehavior:
				# ScrapPayoffBehavior 的触发靠其 create_action 返回的 CallbackAction
				# 这里直接创建一个新的 Action 执行回收效果
				var payoff_action: AbstractGameAction = behavior.create_action(block, part)
				if payoff_action != null and ActionManager.Instance != null:
					ActionManager.Instance.add_to_top(payoff_action)
					GameLog.debug("Bot: ScrapPayoffBehavior triggered for " + str(block.Definition.BlockName if block.Definition != null else ""))

# ---- 共鸣 (Resonance) 连锁机制 ----

## 检查部件是否带 ResonanceTriggerBehavior
func _has_resonance_behavior(part: BlockPart) -> bool:
	if part.PartDefinition == null or part.PartDefinition.Behaviors == null:
		return false
	for behavior in part.PartDefinition.Behaviors:
		if behavior is ResonanceTriggerBehavior:
			return true
	return false

## 递归触发相邻的共鸣 Block
func _trigger_resonance_chain(source_block: Block, depth: int) -> void:
	if depth > 3:
		return
	var tree := get_tree()
	if tree == null:
		return
	# 获取 source_block 所有部件占用的单元格
	var source_cells: Array[Vector2i] = []
	for p in source_block.get_parts():
		var gp: Vector2 = GridState.find_nearest_grid_point(p.global_position)
		var coord: Vector2i = GridState.get_grid_coords(gp)
		if coord.x >= 0 and coord.y >= 0:
			source_cells.append(coord)
	# 扫描邻格
	var adjacent_offsets: Array[Vector2i] = [
		Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 0), Vector2i(-1, 0)
	]
	var triggered_blocks: Array = []
	for cell in source_cells:
		for offset in adjacent_offsets:
			var neighbor_cell: Vector2i = cell + offset
			if _is_out_of_bounds(neighbor_cell):
				continue
			if GridState.get_grid_state(neighbor_cell.x, neighbor_cell.y) != Enums.GridStateEnum.Occupied:
				continue
			# 查找该格子上的共鸣 Block
			for block in _block_piles_here.PlacedPile.Pile:
				if not is_instance_valid(block) or block == source_block:
					continue
				if triggered_blocks.has(block):
					continue
				if block.Faction != Block.BlockFaction.Player:
					continue
				if _is_block_at_grid_pos(block, neighbor_cell) and _block_has_any_resonance(block):
					triggered_blocks.append(block)
					GameLog.debug("Bot: Resonance chain triggered at depth " + str(depth) + " for " + str(block.Definition.BlockName if block.Definition != null else ""))
					# 每次成功传播，给玩家增加回响（Echo）层数
					_add_echo_to_player(tree, 1)
					# 触发该 Block 的所有部件
					for part in block.get_parts():
						if _has_resonance_behavior(part):
							_process_block_part(block, part, depth)
							# 继续递归
							_trigger_resonance_chain(block, depth + 1)
					break

## 检查 Block 是否有至少一个共鸣部件
func _block_has_any_resonance(block: Block) -> bool:
	for part in block.get_parts():
		if _has_resonance_behavior(part):
			return true
	return false

## 检查 Block 是否占据指定网格坐标
func _is_block_at_grid_pos(block: Block, grid_pos: Vector2i) -> bool:
	for p in block.get_parts():
		var gp: Vector2 = GridState.find_nearest_grid_point(p.global_position)
		var coord: Vector2i = GridState.get_grid_coords(gp)
		if coord == grid_pos:
			return true
	return false

## 给玩家增加回响层数（共鸣传播时调用）
func _add_echo_to_player(tree: SceneTree, layers: int) -> void:
	for node in tree.get_nodes_in_group("Players"):
		if node is Node2D:
			var player := node as Node2D
			var rendering = player.get_node("RenderingComponent")
			var stats_comp: StatsComponent = rendering.StatsComponentRef if rendering != null else null
			if stats_comp == null:
				return
			if not stats_comp.has_status("Echo"):
				var echo_def: Resource = load("res://resources/stat_defs/Echo.tres")
				if echo_def == null:
					return
				var stat: Stat = Stat.new()
				stat.Definition = echo_def
				stats_comp.add_status(stat)
				stat.add_value(layers)
			else:
				var echo_stat: Stat = stats_comp.get_status("Echo")
				echo_stat.add_value(layers)
			GameLog.debug("Bot: Added " + str(layers) + " Echo from resonance chain (total: " + str(stats_comp.get_status("Echo").CurrentValue) + ")")
			return
