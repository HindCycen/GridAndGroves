class_name Bot extends Node2D

## 单回合共鸣 Bot 生成上限：防止病态共鸣网络导致无限生成/递归
const MAX_RESONANCE_SPAWNS_PER_TURN := 24

var _animated_sprite_2d: AnimatedSprite2D
var _battle_time: BattleTime
var _block_piles_here: BlockPilesHere
var _current_direction := Vector2i.DOWN
var _current_grid_pos: Vector2i
var _ending_turn: bool
var _patrol_timer: SceneTreeTimer
var _stopped: bool
var _resonance_spawn_count: int

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
	_resonance_spawn_count = 0
	visible = true
	_animated_sprite_2d.play("bot_animation")
	_schedule_next_step()

func stop_patrol() -> void:
	_stopped = true
	_go_to_starter_point()

func _schedule_next_step() -> void:
	# 先取消旧定时器，避免共鸣打断后出现多个计时器并发（Bot 双倍步进）
	if _patrol_timer != null and is_instance_valid(_patrol_timer) and _patrol_timer.timeout.is_connected(_on_patrol_timer_timeout):
		_patrol_timer.timeout.disconnect(_on_patrol_timer_timeout)
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
	var calc_result: Array = _try_calculate_next_cell()
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

func _try_calculate_next_cell() -> Array:
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
	for block in _block_piles_here.get_blocks_on_grid():
		if not is_instance_valid(block):
			continue
		for part in block.get_parts():
			if part.IsSpent:
				continue
			if not _is_part_at_grid(part, grid_pos):
				continue
			GameLog.debug("Bot detected BlockPart at (" + str(grid_pos.x) + ", " + str(grid_pos.y) + ")")
			_process_block_part(block, part, resonance_depth)
			# 共鸣连锁：部件带 ResonanceTriggerBehavior → 生成 ResonanceBot 处理
			if _has_resonance_behavior(part) and resonance_depth < 3:
				_spawn_resonance_bot(block, resonance_depth + 1, part)
			return

func _is_part_at_grid(part: BlockPart, grid_pos: Vector2i) -> bool:
	var part_grid_point: Vector2 = GridState.find_nearest_grid_point(part.global_position)
	var coords: Vector2i = GridState.get_grid_coords(part_grid_point)
	return coords == grid_pos

func _process_block_part(block: Block, part: BlockPart, resonance_depth: int = 0) -> void:
	_battle_time.say_block_execute()
	# 记录共鸣链深度到 Block meta（供 ChainBonusDamageBehavior 等链加成 Behavior 读取）
	block.set_meta("resonance_depth", resonance_depth)
	var move_dir := part.MovingDirection if part.MovingDirection != Vector2i.ZERO else Vector2i.DOWN
	_current_direction = move_dir
	if move_dir != Vector2i.DOWN:
		GameLog.debug("  Bot direction changed to (" + str(move_dir.x) + ", " + str(move_dir.y) + ")")
	if part.IsSpent:
		return
	var should_exhaust := false
	var has_loose := false
	# 一次性标记：部件声明 Exhaust 时触发后立即移出战斗
	if part.Exhaust:
		should_exhaust = true
	for behavior in part.Behaviors:
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
			GameLog.debug("  Queued Action: " + action.get_script().resource_path.get_file() + " (amount=" + str(action.amount) + ")")
			if action.exhaust_source_block():
				should_exhaust = true
	# 处理 Block 生命周期：松动 > 耗尽 > 留在网格
	# 松动是“部件级”的：被触发的松动部件自身落场（释放其格子），
	# 同一 Block 的其余部件保留到回合结束（由 clear_player_round 统一处理）。
	# 延迟到该 Block 本 tick 的所有 Action 执行完毕后再处理，
	# 避免已入队的 Action 引用已离开场景树的 Block 而报错/失效
	if has_loose and block.Faction == Block.BlockFaction.Player:
		GameLog.debug("  Loose part " + str(part.PartId) + " falls off the grid")
		_block_piles_here.enqueue_loose_part(block, part)
	elif should_exhaust and block.Faction == Block.BlockFaction.Player:
		GameLog.debug("  Block " + str(block.BlockName if not block.BlockName.is_empty() else "") + " exhausted, removed from battle")
		_block_piles_here.enqueue_exhaust_block(block)

func _end_turn() -> void:
	GameLog.info("Bot turn ended")
	_stopped = true
	_ending_turn = true
	_battle_time.say_turn_ended()
	_go_to_starter_point()

func _release_cell_safely(pos: Vector2i) -> void:
	if _is_out_of_bounds(pos):
		return
	if GridState.get_grid_state(pos.x, pos.y) == Enums.GridStateEnum.Unable:
		return
	if _has_block_at(pos):
		# 格子上仍有 Block（未被松动/耗尽）：恢复为 Occupied，
		# 而不是盲恢复为 Free，否则会抹掉 Block 的占格状态，导致玩家可重叠放置
		GridState.set_grid_state(pos.x, pos.y, Enums.GridStateEnum.Occupied)
		return
	GridState.restore_grid_state(pos.x, pos.y)

func _go_to_starter_point() -> void:
	global_position = Vector2(GridState.get_grid_pos(Vector2i(0, 0)).x, GridState.get_grid_pos(Vector2i(0, 0)).y - 96)
	_release_cell_safely(_current_grid_pos)
	_current_grid_pos = Vector2i(0, -1)
	_animated_sprite_2d.stop()
	visible = false

## 检查格子上是否有任意阵营的 Block（玩家或敌人）
func _has_block_at(grid_pos: Vector2i) -> bool:
	for block in _block_piles_here.get_blocks_on_grid():
		if not is_instance_valid(block):
			continue
		for part in block.get_parts():
			if part.IsSpent:
				continue
			var coords: Vector2i = GridState.get_grid_coords(GridState.find_nearest_grid_point(part.global_position))
			if coords == grid_pos:
				return true
	return false

# ---- 共鸣 (Resonance) 连锁机制 ----

## 检查部件是否带 ResonanceTriggerBehavior
func _has_resonance_behavior(part: BlockPart) -> bool:
	if part.Behaviors.size() == 0:
		return false
	for behavior in part.Behaviors:
		if behavior is ResonanceTriggerBehavior:
			return true
	return false

## 生成 ResonanceBot 处理共鸣链
func _spawn_resonance_bot(source_block: Block, start_depth: int, source_part: BlockPart = null) -> void:
	# 单回合生成上限：防止病态共鸣网络无限生成
	if _resonance_spawn_count >= MAX_RESONANCE_SPAWNS_PER_TURN:
		GameLog.warn("Bot: resonance spawn cap reached, skipping nested resonance")
		_resume_after_resonance()
		return
	_resonance_spawn_count += 1
	# 停止巡逻
	_stopped = true
	visible = false
	if _patrol_timer != null and is_instance_valid(_patrol_timer) and _patrol_timer.timeout.is_connected(_on_patrol_timer_timeout):
		_patrol_timer.timeout.disconnect(_on_patrol_timer_timeout)

	var scene := load("res://room/ResonanceBot.tscn") as PackedScene
	if scene == null:
		GameLog.err("Bot: Cannot load ResonanceBot.tscn")
		_resume_after_resonance()
		return

	var bot := scene.instantiate() as Node2D
	if bot == null:
		GameLog.err("Bot: ResonanceBot instantiation failed")
		_resume_after_resonance()
		return

	get_parent().add_child(bot)
	bot.owner = get_parent()

	# 连接信号
	if bot.has_signal("resonance_completed"):
		bot.resonance_completed.connect(_resume_after_resonance)
	if bot.has_signal("summon_bot_requested"):
		bot.summon_bot_requested.connect(_on_resonance_summon)

	# 启动
	if bot.has_method("start_resonance"):
		bot.start_resonance(source_block, start_depth, _block_piles_here, _battle_time, source_part)

## 共鸣链正常完成 → 恢复巡逻
func _resume_after_resonance() -> void:
	_stopped = false
	visible = true
	_animated_sprite_2d.play("bot_animation")
	_schedule_next_step()

## 共鸣链遇到特殊方向 → 召唤主 Bot 到目标位置
## chain_depth 继续沿链传递，保证共鸣链深度上限（< 3）仍然生效，避免 A↔B 互指时无限递归
func _on_resonance_summon(target_pos: Vector2i, new_direction: Vector2i, chain_depth: int = 0) -> void:
	var target_has_block: bool = GridState.get_grid_state(target_pos.x, target_pos.y) == Enums.GridStateEnum.Occupied
	_release_cell_safely(_current_grid_pos)
	_current_grid_pos = target_pos
	_current_direction = new_direction
	global_position = GridState.get_grid_pos(_current_grid_pos)
	GridState.set_grid_state(_current_grid_pos.x, _current_grid_pos.y, Enums.GridStateEnum.Occupied)
	GameLog.debug("Bot: Summoned to (" + str(target_pos.x) + ", " + str(target_pos.y) + ") dir=(" + str(new_direction.x) + ", " + str(new_direction.y) + ") depth=" + str(chain_depth))
	# 检查目标位置是否有 Block（沿用当前链深度，由 _enqueue 决定是否继续生成共鸣 Bot）
	if target_has_block:
		_enqueue_block_actions_at(target_pos, chain_depth)
	_resume_after_resonance()
