class_name ScrapThresholdBehavior extends BlockPartBehavior

## 废品阈值 (Scrap Threshold) Behavior
## 铁锈游侠：本回合松动触发数 ≥ Threshold 时，对敌人追加 BonusDamage 伤害
## 回调执行（在同类部件的普通伤害之后），用"追加等量伤害"实现"伤害翻倍"
## 用于：废料洪流部件 B（≥3 个松动时伤害翻倍）

@export var Threshold: int = 3
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
	var scrap_count: int = _get_scrap_counter(tree)
	if scrap_count < Threshold:
		return
	for node in tree.get_nodes_in_group("Enemies"):
		if node is Node2D:
			var hc: HealthComponent = node.get_node_or_null("RenderingComponent/HealthComponent") as HealthComponent
			if hc != null and not hc.is_dead:
				if ActionManager.Instance != null:
					ActionManager.Instance.add_to_bottom(DamageAction.new(block, node, BonusDamage))
				GameLog.debug("ScrapThresholdBehavior: scrap(" + str(scrap_count) + ") >= " + str(Threshold) + ", bonus +" + str(BonusDamage))
				return

func _get_scrap_counter(tree: SceneTree) -> int:
	for node in tree.get_nodes_in_group("Players"):
		if node is Node2D:
			var player := node as Node2D
			var rendering = player.get_node("RenderingComponent")
			var stats_comp: StatsComponent = rendering.StatsComponentRef if rendering != null else null
			if stats_comp != null and stats_comp.has_status("ScrapCounter"):
				return stats_comp.get_status("ScrapCounter").CurrentValue
	return 0
