class_name AddOverloadBehavior extends BlockPartBehavior

## 增加过载 (Add Overload) Behavior
## 铁锈游侠：被触发时增加过载层数
## 是过载体系"攒"端的基础 Behavior
## 用过载标签的 Block 携带此 Behavior

@export var LayersPerTrigger: int = 1

func create_action(block, part):
	if block == null:
		return null
	var layers: int = LayersPerTrigger
	if part.MagicNum > 0:
		layers = part.MagicNum
	return CallbackAction.new(func():
		_add_overload(block, layers)
	, Enums.ActionType.Callback)

func _add_overload(block: Block, layers: int) -> void:
	var tree := block.get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group("Players"):
		if node is Node2D:
			var player := node as Node2D
			var rendering = player.get_node("RenderingComponent")
			var stats_comp: StatsComponent = rendering.StatsComponentRef if rendering != null else null
			if stats_comp == null:
				return
			if not stats_comp.has_status("Overload"):
				# 自动创建 Overload Stat
				var overload_def: Resource = load("res://resources/stat_defs/Overload.tres")
				if overload_def == null:
					printerr("AddOverloadBehavior: Overload.tres not found!")
					return
				var stat: Stat = Stat.new()
				stat.Definition = overload_def
				stats_comp.add_status(stat)
				stat.add_value(layers)
			else:
				var overload_stat: Stat = stats_comp.get_status("Overload")
				overload_stat.add_value(layers)
			GameLog.debug("AddOverloadBehavior: Added " + str(layers) + " overload (total: " + str(stats_comp.get_status("Overload").CurrentValue if stats_comp.has_status("Overload") else 0) + ")")
			return
