class_name OverloadThresholdBehavior extends BlockPartBehavior

## 过载阈值 (Overload Threshold) Behavior
## 铁锈游侠：触发时玩家过载层数 ≥ Threshold 时，对敌人追加 BonusDamage 伤害
## 回调执行（在普通伤害之后追加），不消费过载层数（只检查）
## 用于：铁砧（过载 ≥5 时伤害总额外 +6）

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
	var overload_layers: int = _get_overload_layers(tree)
	if overload_layers < Threshold:
		return
	for node in tree.get_nodes_in_group("Enemies"):
		if node is Node2D:
			var hc: HealthComponent = node.get_node_or_null("RenderingComponent/HealthComponent") as HealthComponent
			if hc != null and not hc.is_dead:
				if ActionManager.Instance != null:
					ActionManager.Instance.add_to_bottom(DamageAction.new(block, node, BonusDamage))
				GameLog.debug("OverloadThresholdBehavior: overload(" + str(overload_layers) + ") >= " + str(Threshold) + ", bonus +" + str(BonusDamage))
				return

func _get_overload_layers(tree: SceneTree) -> int:
	for node in tree.get_nodes_in_group("Players"):
		if node is Node2D:
			var player := node as Node2D
			var rendering = player.get_node("RenderingComponent")
			var stats_comp: StatsComponent = rendering.StatsComponentRef if rendering != null else null
			if stats_comp != null and stats_comp.has_status("Overload"):
				return stats_comp.get_status("Overload").CurrentValue
	return 0
