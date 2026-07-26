class_name ResonanceBot extends Node2D

## 共鸣 Bot（蓝色）
## 主 Bot 触发共鸣 Block 时生成，沿共鸣链独立遍历
## 搜索算法：按曼哈顿距离 1→2→3 逐层查找共鸣部件
## 排序规则：列优先（左→右），同列行优先（上→下）
## 特殊方向处理：遇到非向下方向时中断共鸣，召唤主 Bot

signal resonance_completed
signal summon_bot_requested(target_pos: Vector2i, new_direction: Vector2i)

var _block_piles_here: BlockPilesHere
var _battle_time: BattleTime
var _animated_sprite_2d: AnimatedSprite2D
var _resonance_depth: int = 0
var _triggered_parts: Array = []
var _triggered_blocks: Array = []
var _special_direction_found: bool = false
var _summon_target: Vector2i
var _summon_direction: Vector2i
var _is_running: bool = false

func _ready() -> void:
	_animated_sprite_2d = %AnimatedSprite2D as AnimatedSprite2D

## 启动共鸣遍历
func start_resonance(source_block: Block, start_depth: int, block_piles: BlockPilesHere, battle_time: BattleTime) -> void:
	_block_piles_here = block_piles
	_battle_time = battle_time
	_resonance_depth = start_depth
	_is_running = true
	_triggered_blocks = [source_block]
	_triggered_parts = []
	_special_direction_found = false

	if _animated_sprite_2d != null:
		_animated_sprite_2d.play("bot_animation")

	# 定位到起始 Block 的位置
	var start_cells := _get_block_cells(source_block)
	if start_cells.size() > 0:
		global_position = GridState.get_grid_pos(start_cells[0])
	visible = true

	GameLog.debug("ResonanceBot: Starting resonance traversal depth=" + str(start_depth))

	# 搜索并执行共鸣链
	_execute_resonance_chain(source_block)

# ──────────── 核心算法 ────────────

## 逐层搜索曼哈顿距离 1→2→3
func _execute_resonance_chain(source_block: Block) -> void:
	if not _is_running:
		return

	var source_cells := _get_block_cells(source_block)

	for dist in range(1, 4):
		if _special_direction_found:
			break

		var candidates := _find_resonance_parts_at_distance(source_cells, dist)
		if candidates.is_empty():
			continue

		GameLog.debug("ResonanceBot: Found " + str(candidates.size()) + " parts at distance " + str(dist))

		var chain_depth: int = _resonance_depth + dist - 1
		for c in candidates:
			if _special_direction_found:
				break
			_visit_part(c.block, c.part, c.grid_pos, chain_depth)

	# 遍历结束
	if _special_direction_found:
		GameLog.debug("ResonanceBot: Summoning main Bot to (" + str(_summon_target.x) + ", " + str(_summon_target.y) + ")")
		emit_signal("summon_bot_requested", _summon_target, _summon_direction)
	else:
		GameLog.debug("ResonanceBot: Chain completed")
		emit_signal("resonance_completed")

	_is_running = false
	_cleanup()

## 按曼哈顿距离搜索共鸣部件，返回按列→行排序的候选列表
func _find_resonance_parts_at_distance(source_cells: Array[Vector2i], distance: int) -> Array:
	var candidates: Array = []
	var checked: Array[Vector2i] = []

	for sc in source_cells:
		for dx in range(-distance, distance + 1):
			var dy_abs: int = distance - abs(dx)
			if dy_abs < 0:
				continue
			var signs: Array[int] = [1] if dy_abs == 0 else [1, -1]
			for s in signs:
				var dy: int = dy_abs * s
				var pos := Vector2i(sc.x + dx, sc.y + dy)

				if _is_checked(checked, pos):
					continue
				checked.append(pos)

				if _is_out_of_bounds(pos):
					continue
				if GridState.get_grid_state(pos.x, pos.y) != Enums.GridStateEnum.Occupied:
					continue

				for block in _block_piles_here.PlacedPile.Pile:
					if not is_instance_valid(block):
						continue
					if _triggered_blocks.has(block):
						continue
					if block.Faction != Block.BlockFaction.Player:
						continue
					if not _is_block_at(block, pos):
						continue
					if not _has_any_resonance(block):
						continue

					for part in block.get_parts():
						if not _has_resonance_behavior(part):
							continue
						if not _is_part_at(part, pos):
							continue
						if _triggered_parts.has(part):
							continue
						candidates.append({"block": block, "part": part, "grid_pos": pos})

					_triggered_blocks.append(block)
					break

	# 排序：列优先 (x)→同列行优先 (y)
	candidates.sort_custom(func(a, b):
		if a.grid_pos.x != b.grid_pos.x:
			return a.grid_pos.x < b.grid_pos.x
		return a.grid_pos.y < b.grid_pos.y
	)
	return candidates

## 访问一个共鸣部件：检查方向→执行→加回响
func _visit_part(block: Block, part: BlockPart, grid_pos: Vector2i, chain_depth: int) -> void:
	# 移动到该位置（视觉反馈）
	global_position = GridState.get_grid_pos(grid_pos)

	var move_dir := part.MovingDirection if part.MovingDirection != Vector2i.ZERO else Vector2i.DOWN
	GameLog.debug("ResonanceBot: Visit (" + str(grid_pos.x) + "," + str(grid_pos.y) + ") dir=(" + str(move_dir.x) + "," + str(move_dir.y) + ")")

	# 特殊方向：非向下 → 中断并召唤主 Bot
	if move_dir != Vector2i.DOWN:
		var target := grid_pos + move_dir
		if not _is_out_of_bounds(target):
			_special_direction_found = true
			_summon_target = target
			_summon_direction = move_dir
			_triggered_parts.append(part)
			return

	_triggered_parts.append(part)

	# 执行部件效果（沿用主 Bot 的 _process_block_part 逻辑）
	_process_block_part(block, part, chain_depth)

	# 增加回响
	var tree := get_tree()
	if tree != null:
		_add_echo(tree, 1)

# ──────────── Block 处理（从原 Bot.gd 复用小部分逻辑） ────────────

func _process_block_part(block: Block, part: BlockPart, depth: int) -> void:
	if _battle_time != null:
		_battle_time.say_block_execute()
	if part.Behaviors.size() == 0:
		return
	var should_exhaust := false
	var has_loose := false
	for behavior in part.Behaviors:
		if behavior == null:
			continue
		if behavior is LooseBlockBehavior:
			has_loose = true
		var action: AbstractGameAction = behavior.create_action(block, part) as AbstractGameAction
		if action != null:
			if depth > 0 and action.has_method("set_chain_bonus"):
				action.set_chain_bonus(depth)
			if ActionManager.Instance != null:
				ActionManager.Instance.add_to_bottom(action)
			GameLog.debug("  ResonanceBot Queued: " + action.get_class() + " amt=" + str(action.amount))
			if action.exhaust_source_block():
				should_exhaust = true
	if has_loose and block.Faction == Block.BlockFaction.Player:
		_loose_block(block)
	elif should_exhaust and block.Faction == Block.BlockFaction.Player:
		_exhaust_block(block)

# ──────────── 辅助方法 ────────────

func _get_block_cells(block: Block) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for p in block.get_parts():
		var gp: Vector2 = GridState.find_nearest_grid_point(p.global_position)
		var coord: Vector2i = GridState.get_grid_coords(gp)
		if coord.x >= 0 and coord.y >= 0:
			cells.append(coord)
	return cells

func _is_out_of_bounds(pos: Vector2i) -> bool:
	return pos.x < 0 or pos.x > 6 or pos.y < 0 or pos.y > 4

func _is_checked(list: Array[Vector2i], pos: Vector2i) -> bool:
	for c in list:
		if c == pos:
			return true
	return false

func _is_block_at(block: Block, grid_pos: Vector2i) -> bool:
	for p in block.get_parts():
		var gp: Vector2 = GridState.find_nearest_grid_point(p.global_position)
		var coord: Vector2i = GridState.get_grid_coords(gp)
		if coord == grid_pos:
			return true
	return false

func _is_part_at(part: BlockPart, grid_pos: Vector2i) -> bool:
	var gp: Vector2 = GridState.find_nearest_grid_point(part.global_position)
	var coord: Vector2i = GridState.get_grid_coords(gp)
	return coord == grid_pos

func _has_resonance_behavior(part: BlockPart) -> bool:
	if part.Behaviors.size() == 0:
		return false
	for b in part.Behaviors:
		if b is ResonanceTriggerBehavior:
			return true
	return false

func _has_any_resonance(block: Block) -> bool:
	for p in block.get_parts():
		if _has_resonance_behavior(p):
			return true
	return false

func _exhaust_block(block: Block) -> void:
	for p in block.get_parts():
		var gp: Vector2 = GridState.find_nearest_grid_point(p.global_position)
		var coord: Vector2i = GridState.get_grid_coords(gp)
		if coord.x >= 0 and coord.y >= 0:
			GridState.restore_grid_state(coord.x, coord.y)
	_block_piles_here.PlacedPile.remove_block(block)
	block.remove_from_group("placed_blocks")
	if block.get_parent() != null and is_instance_valid(block.get_parent()):
		block.get_parent().remove_child(block)
	block.queue_free()

func _loose_block(block: Block) -> void:
	var tree := get_tree()
	if tree == null:
		return
	for p in block.get_parts():
		var gp: Vector2 = GridState.find_nearest_grid_point(p.global_position)
		var coord: Vector2i = GridState.get_grid_coords(gp)
		if coord.x >= 0 and coord.y >= 0:
			GridState.restore_grid_state(coord.x, coord.y)
	_block_piles_here.PlacedPile.remove_block(block)
	block.remove_from_group("placed_blocks")
	# 进弃牌堆
	for node in tree.get_nodes_in_group("Players"):
		if node is Node2D:
			var pl := node as Node2D
			var pn = pl.get_node("%PlayerPile")
			if pn != null and pn.has_method("DiscardedPile"):
				var dp = pn.DiscardedPile
				if dp != null and dp.has_method("add_block"):
					block.IsPlaced = false
					block.global_position = block.OriginalPos
					dp.add_block(block)
					if block.get_parent() != null and is_instance_valid(block.get_parent()):
						block.get_parent().remove_child(block)
					return
	if block.get_parent() != null and is_instance_valid(block.get_parent()):
		block.get_parent().remove_child(block)

func _add_echo(tree: SceneTree, layers: int) -> void:
	for node in tree.get_nodes_in_group("Players"):
		if node is Node2D:
			var pl := node as Node2D
			var ren = pl.get_node("RenderingComponent")
			var sc: StatsComponent = ren.StatsComponentRef if ren != null else null
			if sc == null:
				return
			if not sc.has_status("Echo"):
				var def: Resource = load("res://resources/stat_defs/Echo.tres")
				if def == null:
					return
				var s := Stat.new()
				s.Definition = def
				sc.add_status(s)
				s.add_value(layers)
			else:
				sc.get_status("Echo").add_value(layers)
			GameLog.debug("ResonanceBot: Echo +" + str(layers))
			return

func _cleanup() -> void:
	_is_running = false
	if _animated_sprite_2d != null:
		_animated_sprite_2d.stop()
	visible = false
