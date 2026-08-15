class_name ApplyVineAllBehavior extends BlockPartBehavior

## 全体藤蔓 (Apply Vine All) Behavior
## 翠绿哨兵：对所有敌人施加 N 层藤蔓（区别于单目标的 ApplyVineBehavior）
## 用于：孢子云（全体 2 层）/ 剧毒新星（全体 3 层）

@export var VineLayers: int = 2

func create_action(block, part):
	if block == null:
		return null
	var layers: int = VineLayers
	if part != null and part.MagicNum > 0:
		layers = part.MagicNum
	var tree: SceneTree = block.get_tree()
	if tree == null:
		return null
	return CallbackAction.new(func():
		_apply_all(tree, layers)
	, Enums.ActionType.ApplyStatus)

func _apply_all(tree: SceneTree, layers: int) -> void:
	var vine_def: Resource = load("res://resources/stat_defs/Vine.tres")
	if vine_def == null:
		printerr("ApplyVineAllBehavior: Vine.tres not found!")
		return
	for node in tree.get_nodes_in_group("Enemies"):
		if node is Node2D:
			var rendering = node.get_node_or_null("RenderingComponent")
			if rendering == null:
				continue
			var stats_comp: StatsComponent = rendering.StatsComponentRef if rendering != null else null
			if stats_comp == null:
				continue
			if not stats_comp.has_status("Vine"):
				var stat: Stat = Stat.new()
				stat.Definition = vine_def
				stats_comp.add_status(stat)
				stat.add_value(layers)
			else:
				stats_comp.get_status("Vine").add_value(layers)
	GameLog.debug("ApplyVineAllBehavior: applied " + str(layers) + " vine to all enemies")
