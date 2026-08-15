class_name ScrapToRustBehavior extends BlockPartBehavior

## 废品转锈蚀 (Scrap to Rust) Behavior
## 铁锈游侠：触发时按本回合已松动数给敌人施加等量锈蚀层数
## 读取玩家 ScrapCounterStat（Bot._loose_block 递增）
## 用于：锈蚀炸弹部件 B（场上每有 1 个松动 Block 刚进弃牌堆，锈蚀 +1）

func create_action(block, _part):
	if block == null:
		return null
	var tree: SceneTree = block.get_tree()
	if tree == null:
		return null
	return CallbackAction.new(func():
		_apply_rust(block, tree)
	, Enums.ActionType.ApplyStatus)

func _apply_rust(block: Block, tree: SceneTree) -> void:
	var scrap_count: int = _get_scrap_counter(tree)
	if scrap_count <= 0:
		return
	var rust_def: Resource = load("res://resources/stat_defs/Rust.tres")
	if rust_def == null:
		printerr("ScrapToRustBehavior: Rust.tres not found!")
		return
	for node in tree.get_nodes_in_group("Enemies"):
		if node is Node2D:
			var rendering = node.get_node_or_null("RenderingComponent")
			if rendering == null:
				continue
			var stats_comp: StatsComponent = rendering.StatsComponentRef if rendering != null else null
			if stats_comp == null:
				continue
			if not stats_comp.has_status("Rust"):
				var stat: Stat = Stat.new()
				stat.Definition = rust_def
				stats_comp.add_status(stat)
				stat.add_value(scrap_count)
			else:
				stats_comp.get_status("Rust").add_value(scrap_count)
			GameLog.debug("ScrapToRustBehavior: Applied " + str(scrap_count) + " Rust from scrap count")
			return

func _get_scrap_counter(tree: SceneTree) -> int:
	for node in tree.get_nodes_in_group("Players"):
		if node is Node2D:
			var player := node as Node2D
			var rendering = player.get_node("RenderingComponent")
			var stats_comp: StatsComponent = rendering.StatsComponentRef if rendering != null else null
			if stats_comp != null and stats_comp.has_status("ScrapCounter"):
				return stats_comp.get_status("ScrapCounter").CurrentValue
	return 0
