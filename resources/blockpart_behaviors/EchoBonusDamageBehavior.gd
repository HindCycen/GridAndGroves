class_name EchoBonusDamageBehavior extends BlockPartBehavior

## 回响加成伤害 (Echo Bonus Damage) Behavior
## 星语术士：伤害 = 部件基础伤害 + 本回合回响层数 × BonusPerEcho
## 用于：星盘（每触发 1 个共鸣 Block +1 伤害）

@export var BonusPerEcho: int = 1

func create_action(block, part):
	if block == null:
		return null
	var tree: SceneTree = block.get_tree()
	if tree == null:
		return null
	var base_damage: int = part.Damage if part != null else 0
	var echo_layers: int = _get_echo_layers(tree)
	var total_damage: int = base_damage + echo_layers * BonusPerEcho
	GameLog.debug("EchoBonusDamageBehavior: echo=" + str(echo_layers) + ", damage " + str(base_damage) + " -> " + str(total_damage))
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
			ActionManager.Instance.add_to_bottom(DamageAction.new(block, targets[i], total_damage))
	return DamageAction.new(block, targets[0], total_damage, 0.4)

func _get_echo_layers(tree: SceneTree) -> int:
	for node in tree.get_nodes_in_group("Players"):
		if node is Node2D:
			var player := node as Node2D
			var rendering = player.get_node("RenderingComponent")
			var stats_comp: StatsComponent = rendering.StatsComponentRef if rendering != null else null
			if stats_comp != null and stats_comp.has_status("Echo"):
				return stats_comp.get_status("Echo").CurrentValue
	return 0
