class_name SpendOverloadBehavior extends BlockPartBehavior

## 消耗过载 (Overload) Behavior
## 消耗当前过载层数，每层提供额外伤害/护盾
## 过载层数归零
## 是铁锈游侠 "攒→花" 循环的核心消费端

@export var BonusPerLayer: int = 1  # 每层过载提供的额外伤害
@export var EffectType: String = "damage"  # "damage" 或 "shield"

func create_action(block, part):
	if block == null:
		return null
	return CallbackAction.new(func():
		_spend_overload(block, part)
	, Enums.ActionType.Callback)

func _spend_overload(block: Block, part) -> void:
	var tree := block.get_tree()
	if tree == null:
		return
	# 获取玩家身上的过载 Stat
	var overload_layers: int = _get_overload_layers(tree)
	if overload_layers <= 0:
		# 没有过载层数时只触发基础效果
		_apply_base_effect(block, part, 0)
		return
	# 消耗过载层数
	_clear_overload(tree)
	var bonus: int = overload_layers * BonusPerLayer
	GameLog.debug("SpendOverloadBehavior: Spent " + str(overload_layers) + " overload layers for +" + str(bonus) + " bonus")
	_apply_base_effect(block, part, bonus)

func _get_overload_layers(tree: SceneTree) -> int:
	for node in tree.get_nodes_in_group("Players"):
		if node is Node2D:
			var player := node as Node2D
			var rendering = player.get_node("RenderingComponent")
			var stats_comp: StatsComponent = rendering.StatsComponentRef if rendering != null else null
			if stats_comp != null and stats_comp.has_status("Overload"):
				return stats_comp.get_status("Overload").CurrentValue
	return 0

func _clear_overload(tree: SceneTree) -> void:
	for node in tree.get_nodes_in_group("Players"):
		if node is Node2D:
			var player := node as Node2D
			var rendering = player.get_node("RenderingComponent")
			var stats_comp: StatsComponent = rendering.StatsComponentRef if rendering != null else null
			if stats_comp != null and stats_comp.has_status("Overload"):
				stats_comp.get_status("Overload").set_value(0)
				return

func _apply_base_effect(block: Block, part, bonus: int) -> void:
	var tree := block.get_tree()
	if tree == null:
		return
	if EffectType == "damage":
		var base_damage: int = part.Damage if part != null else 0
		var total_damage: int = base_damage + bonus
		var targets: Array[Node2D] = []
		for e in tree.get_nodes_in_group("Enemies"):
			if e is Node2D:
				var hc: HealthComponent = e.get_node_or_null("RenderingComponent/HealthComponent") as HealthComponent
				if hc != null and not hc.is_dead:
					targets.append(e)
		if targets.size() > 0:
			for i in range(1, targets.size()):
				if ActionManager.Instance != null:
					ActionManager.Instance.add_to_bottom(DamageAction.new(block, targets[i], total_damage))
			if ActionManager.Instance != null:
				ActionManager.Instance.add_to_bottom(DamageAction.new(block, targets[0], total_damage, 0.4))
	elif EffectType == "shield":
		var base_shield: int = part.Shield if part != null else 0
		var total_shield: int = base_shield + bonus
		for node in tree.get_nodes_in_group("Players"):
			if node is Node2D:
				var player := node as Node2D
				var shield_comp: ShieldComponent = _find_shield_component(player)
				if shield_comp != null:
					shield_comp.add_shield(total_shield)
					GameLog.debug("SpendOverloadBehavior: Gained " + str(total_shield) + " shield (base: " + str(base_shield) + ", bonus: " + str(bonus) + ")")
				return

func _find_shield_component(root: Node) -> ShieldComponent:
	if root is ShieldComponent:
		return root
	for child in root.get_children():
		var found: ShieldComponent = _find_shield_component(child)
		if found != null:
			return found
	return null
