class_name GiveGrowingStatBehavior extends BlockPartBehavior

func create_action(block, _part):
	# exhaust=true：效果结算后由 Bot 统一将 Block 移出战斗（延迟处理，避免 Action 引用已销毁的 Block）
	return CallbackAction.new(func():
		var tree: SceneTree = block.get_tree()
		if tree == null:
			return
		for node in tree.get_nodes_in_group("Players"):
			if node is Node2D:
				var player: Node2D = node as Node2D
				_try_add_growing_stat(player)
				_try_remove_growing_block(player)
	, Enums.ActionType.ApplyStatus, true)

func _try_add_growing_stat(player: Node2D) -> void:
	var rendering = player.get_node("RenderingComponent")
	var stats_comp: StatsComponent = rendering.StatsComponentRef if rendering != null else null
	if stats_comp == null or stats_comp.has_status("Growing"):
		return
	var stat_def: Resource = load("res://resources/stat_defs/Growing.tres")
	if stat_def == null:
		return
	var stat: Stat = Stat.new()
	stat.Definition = stat_def
	stats_comp.add_status(stat)
	stat.add_value(stat_def.MaxValue)

func _try_remove_growing_block(player: Node2D) -> void:
	var player_pile = player.get_node("%PlayerPile")
	if player_pile == null:
		return
	for b in player_pile.Pile:
		if not is_instance_valid(b):
			continue
		if not b.BlockName.is_empty() and b.BlockName == "Growing":
			player_pile.remove_block(b)
			if is_instance_valid(b) and b.get_parent() != null:
				b.get_parent().remove_child(b)
			b.queue_free()
			return
