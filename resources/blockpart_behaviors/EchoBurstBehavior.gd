class_name EchoBurstBehavior extends BlockPartBehavior

## 回响爆发 (Echo Burst) Behavior
## 星语术士：触发时对敌人造成 本回合回响层数 × DamagePerEcho 伤害
## 用于：星语法阵（每一声共鸣都是一次轰炸——按回响计数结算）

@export var DamagePerEcho: int = 4

func create_action(block, _part):
	if block == null:
		return null
	var tree: SceneTree = block.get_tree()
	if tree == null:
		return null
	return CallbackAction.new(func():
		_burst(block, tree)
	, Enums.ActionType.Damage)

func _burst(block: Block, tree: SceneTree) -> void:
	var echo_layers: int = 0
	for node in tree.get_nodes_in_group("Players"):
		if node is Node2D:
			var player := node as Node2D
			var rendering = player.get_node("RenderingComponent")
			var stats_comp: StatsComponent = rendering.StatsComponentRef if rendering != null else null
			if stats_comp != null and stats_comp.has_status("Echo"):
				echo_layers = stats_comp.get_status("Echo").CurrentValue
			break
	if echo_layers <= 0:
		return
	var total: int = echo_layers * DamagePerEcho
	for node in tree.get_nodes_in_group("Enemies"):
		if node is Node2D:
			var hc: HealthComponent = node.get_node_or_null("RenderingComponent/HealthComponent") as HealthComponent
			if hc != null and not hc.is_dead:
				if ActionManager.Instance != null:
					ActionManager.Instance.add_to_bottom(DamageAction.new(block, node, total))
	GameLog.debug("EchoBurstBehavior: burst " + str(total) + " damage from " + str(echo_layers) + " echo")
