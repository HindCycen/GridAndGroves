class_name OverloadToRustBehavior extends BlockPartBehavior

## 过载转锈蚀 Behavior
## 铁锈游侠：消耗过载层数，每层给敌人施加 1 层锈蚀
## 是过载体系的第二种消费方式

@export var RustPerLayer: int = 1

func create_action(block, part):
	if block == null:
		return null
	return CallbackAction.new(func():
		_convert_overload_to_rust(block)
	, Enums.ActionType.ApplyStatus)

func _convert_overload_to_rust(block: Block) -> void:
	var tree := block.get_tree()
	if tree == null:
		return
	# 获取玩家身上的过载层数
	var overload_layers: int = 0
	for node in tree.get_nodes_in_group("Players"):
		if node is Node2D:
			var player := node as Node2D
			var rendering = player.get_node("RenderingComponent")
			var stats_comp: StatsComponent = rendering.StatsComponentRef if rendering != null else null
			if stats_comp != null and stats_comp.has_status("Overload"):
				overload_layers = stats_comp.get_status("Overload").CurrentValue
				stats_comp.get_status("Overload").set_value(0)
			break
	if overload_layers <= 0:
		return
	var rust_layers: int = overload_layers * RustPerLayer
	GameLog.debug("OverloadToRustBehavior: Converted " + str(overload_layers) + " overload to " + str(rust_layers) + " rust")
	# 给所有敌人施加锈蚀
	var rust_def: Resource = load("res://resources/stat_defs/Rust.tres")
	if rust_def == null:
		printerr("OverloadToRustBehavior: Rust.tres not found!")
		return
	for enemy in tree.get_nodes_in_group("Enemies"):
		if enemy is Node2D:
			var rendering = enemy.get_node_or_null("RenderingComponent")
			if rendering == null:
				continue
			var stats_comp: StatsComponent = rendering.StatsComponentRef if rendering != null else null
			if stats_comp == null:
				continue
			if not stats_comp.has_status("Rust"):
				var stat: Stat = Stat.new()
				stat.Definition = rust_def
				stats_comp.add_status(stat)
				stat.add_value(rust_layers)
			else:
				var existing: Stat = stats_comp.get_status("Rust")
				if existing != null:
					existing.add_value(rust_layers)
			GameLog.debug("OverloadToRustBehavior: Applied " + str(rust_layers) + " Rust to " + enemy.name)
