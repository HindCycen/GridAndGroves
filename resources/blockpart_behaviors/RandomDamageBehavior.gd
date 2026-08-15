class_name RandomDamageBehavior extends BlockPartBehavior

## 随机伤害 (Random Damage) Behavior
## 星尘余烬：伤害 = RandomMin ~ RandomMax 随机值
## 用于：随机火花（3~12）

@export var RandomMin: int = 3
@export var RandomMax: int = 12

func create_action(block, _part):
	if block == null:
		return null
	var tree: SceneTree = block.get_tree()
	if tree == null:
		return null
	var total: int = RandomMin + RngManager.get_misc_rand(RandomMax - RandomMin + 1)
	GameLog.debug("RandomDamageBehavior: rolled " + str(total))
	var targets: Array[Node2D] = []
	for node in tree.get_nodes_in_group("Enemies"):
		if node is Node2D:
			var hc: HealthComponent = node.get_node_or_null("RenderingComponent/HealthComponent") as HealthComponent
			if hc != null and not hc.is_dead:
				targets.append(node)
	if targets.size() == 0:
		return null
	for i in range(1, targets.size()):
		if ActionManager.Instance != null:
			ActionManager.Instance.add_to_bottom(DamageAction.new(block, targets[i], total))
	return DamageAction.new(block, targets[0], total, 0.4)
