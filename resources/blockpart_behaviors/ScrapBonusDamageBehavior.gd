class_name ScrapBonusDamageBehavior extends BlockPartBehavior

## 废品加成伤害 (Scrap Bonus Damage) Behavior
## 铁锈游侠：伤害 = 部件基础伤害 + 本回合已触发松动数 × BonusPerScrap
## 触发时读取玩家 ScrapCounterStat（Bot._loose_block 递增）
## 用于：废料弹（每松动 1 个 +1 伤害）

@export var BonusPerScrap: int = 1

func create_action(block, part):
	if block == null:
		return null
	var tree: SceneTree = block.get_tree()
	if tree == null:
		return null
	var base_damage: int = part.Damage if part != null else 0
	var scrap_count: int = _get_scrap_counter(tree)
	var total_damage: int = base_damage + scrap_count * BonusPerScrap
	GameLog.debug("ScrapBonusDamageBehavior: damage " + str(base_damage) + " + scrap(" + str(scrap_count) + ")*" + str(BonusPerScrap) + " = " + str(total_damage))
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

func _get_scrap_counter(tree: SceneTree) -> int:
	for node in tree.get_nodes_in_group("Players"):
		if node is Node2D:
			var player := node as Node2D
			var rendering = player.get_node("RenderingComponent")
			var stats_comp: StatsComponent = rendering.StatsComponentRef if rendering != null else null
			if stats_comp != null and stats_comp.has_status("ScrapCounter"):
				return stats_comp.get_status("ScrapCounter").CurrentValue
	return 0
