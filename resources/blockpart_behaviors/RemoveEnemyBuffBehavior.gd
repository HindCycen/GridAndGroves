class_name RemoveEnemyBuffBehavior extends BlockPartBehavior

## 移除增益 (Remove Enemy Buff) Behavior
## 暗网契约/废品爆破：移除敌人 1 个 Stat（取第一个，简化"正面 Stat"判定）
## 用于：黑客入侵 / 电磁脉冲部件 B

func create_action(block, _part):
	if block == null:
		return null
	var tree: SceneTree = block.get_tree()
	if tree == null:
		return null
	return CallbackAction.new(func():
		_remove(tree)
	, Enums.ActionType.Callback)

func _remove(tree: SceneTree) -> void:
	for node in tree.get_nodes_in_group("Enemies"):
		if node is Node2D:
			var rendering = node.get_node_or_null("RenderingComponent")
			if rendering == null:
				continue
			var stats_comp: StatsComponent = rendering.StatsComponentRef if rendering != null else null
			if stats_comp == null:
				continue
			var statuses := stats_comp.get_all_statuses()
			if statuses.size() == 0:
				return
			var target: Stat = statuses[0]
			var name: String = target.Definition.StatName if target.Definition != null else ""
			stats_comp.remove_status(name)
			GameLog.debug("RemoveEnemyBuffBehavior: removed [" + name + "]")
			return
