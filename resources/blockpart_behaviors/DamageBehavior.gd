class_name DamageBehavior extends BlockPartBehavior

## 通用伤害 Behavior
## 对指定目标群组中的存活单位造成伤害
## 通过 @export TargetGroup 指定目标群组（如 "Enemies" / "Players"）
## 支持多目标：对第一个目标返回 DamageAction，其余追加到队列尾部

@export var TargetGroup: String = "Enemies"

func create_action(block, part):
	if block == null:
		return null
	var tree: SceneTree = block.get_tree()
	if tree == null:
		return null
	var targets: Array[Node2D] = []
	for node in tree.get_nodes_in_group(TargetGroup):
		if node is Node2D:
			var hc: HealthComponent = node.get_node_or_null("RenderingComponent/HealthComponent") as HealthComponent
			if hc != null and not hc.is_dead:
				targets.append(node)
	if targets.size() == 0:
		return null
	# 对第一个目标返回 DamageAction，其余追加到队列
	for i in range(1, targets.size()):
		var target: Node2D = targets[i]
		if ActionManager.Instance != null:
			ActionManager.Instance.add_to_bottom(DamageAction.new(block, target, part.Damage))
	return DamageAction.new(block, targets[0], part.Damage, 0.4)
