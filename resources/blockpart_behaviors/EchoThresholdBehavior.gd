class_name EchoThresholdBehavior extends BlockPartBehavior

## 回响阈值 (Echo Threshold) Behavior
## 星语术士：回响层数 ≥ Threshold 时对敌人追加 BonusDamage 伤害
## 用于：群星齐鸣（回响 ≥5 额外 5 伤害）

@export var Threshold: int = 5
@export var BonusDamage: int = 0

func create_action(block, _part):
	if block == null:
		return null
	var tree: SceneTree = block.get_tree()
	if tree == null:
		return null
	return CallbackAction.new(func():
		_try_bonus(block, tree)
	, Enums.ActionType.Callback)

func _try_bonus(block: Block, tree: SceneTree) -> void:
	var echo_layers: int = 0
	for node in tree.get_nodes_in_group("Players"):
		if node is Node2D:
			var player := node as Node2D
			var rendering = player.get_node("RenderingComponent")
			var stats_comp: StatsComponent = rendering.StatsComponentRef if rendering != null else null
			if stats_comp != null and stats_comp.has_status("Echo"):
				echo_layers = stats_comp.get_status("Echo").CurrentValue
			break
	if echo_layers < Threshold:
		return
	for node in tree.get_nodes_in_group("Enemies"):
		if node is Node2D:
			var hc: HealthComponent = node.get_node_or_null("RenderingComponent/HealthComponent") as HealthComponent
			if hc != null and not hc.is_dead:
				if ActionManager.Instance != null:
					ActionManager.Instance.add_to_bottom(DamageAction.new(block, node, BonusDamage))
				GameLog.debug("EchoThresholdBehavior: echo(" + str(echo_layers) + ") >= " + str(Threshold) + ", bonus +" + str(BonusDamage))
				return
