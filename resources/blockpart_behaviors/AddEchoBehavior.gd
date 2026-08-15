class_name AddEchoBehavior extends BlockPartBehavior

## 增加回响 (Add Echo) Behavior
## 星语术士：触发时玩家回响层数 +N（共鸣传播计数资源）
## 用于：星火（回响 +1）

@export var LayersPerTrigger: int = 1

func create_action(block, part):
	if block == null:
		return null
	var layers: int = LayersPerTrigger
	if part != null and part.MagicNum > 0:
		layers = part.MagicNum
	return CallbackAction.new(func():
		_add_echo(block, layers)
	, Enums.ActionType.Callback)

func _add_echo(block: Block, layers: int) -> void:
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
			if not stats_comp.has_status("Echo"):
				var echo_def: Resource = load("res://resources/stat_defs/Echo.tres")
				if echo_def == null:
					printerr("AddEchoBehavior: Echo.tres not found!")
					return
				var stat: Stat = Stat.new()
				stat.Definition = echo_def
				stats_comp.add_status(stat)
				stat.add_value(layers)
			else:
				stats_comp.get_status("Echo").add_value(layers)
			GameLog.debug("AddEchoBehavior: Echo +" + str(layers))
			return
