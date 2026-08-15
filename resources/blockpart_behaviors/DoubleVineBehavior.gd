class_name DoubleVineBehavior extends BlockPartBehavior

## 藤蔓翻倍 (Double Vine) Behavior
## 翠绿哨兵：触发时敌人当前藤蔓层数翻倍
## 用于：藤蔓陷阱部件 B（一旦触发，藤蔓翻倍蔓延）

func create_action(block, _part):
	if block == null:
		return null
	var tree: SceneTree = block.get_tree()
	if tree == null:
		return null
	return CallbackAction.new(func():
		_double(tree)
	, Enums.ActionType.ApplyStatus)

func _double(tree: SceneTree) -> void:
	for node in tree.get_nodes_in_group("Enemies"):
		if node is Node2D:
			var rendering = node.get_node_or_null("RenderingComponent")
			if rendering == null:
				continue
			var stats_comp: StatsComponent = rendering.StatsComponentRef if rendering != null else null
			if stats_comp == null:
				continue
			if stats_comp.has_status("Vine"):
				var stat: Stat = stats_comp.get_status("Vine")
				stat.add_value(stat.CurrentValue)
				GameLog.debug("DoubleVineBehavior: vine doubled to " + str(stat.CurrentValue))
			return
