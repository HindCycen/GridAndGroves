class_name SpendEchoBehavior extends BlockPartBehavior

## 消耗回响 (Spend Echo) Behavior
## 星语术士：消耗当前回响层数，每层提供额外伤害或护盾
## 对应铁锈游侠的 SpendOverloadBehavior

@export var BonusPerLayer: int = 2  # 每层回响提供的额外效果
@export var EffectType: String = "damage"  # "damage" / "shield"

func create_action(block, part):
	if block == null:
		return null
	return CallbackAction.new(func():
		_spend_echo(block, part)
	, Enums.ActionType.Callback)

func _spend_echo(block: Block, part) -> void:
	var tree := block.get_tree()
	if tree == null:
		return
	# 获取玩家身上的回响层数
	var echo_layers: int = 0
	for node in tree.get_nodes_in_group("Players"):
		if node is Node2D:
			var player := node as Node2D
			var rendering = player.get_node("RenderingComponent")
			var stats_comp: StatsComponent = rendering.StatsComponentRef if rendering != null else null
			if stats_comp != null and stats_comp.has_status("Echo"):
				echo_layers = stats_comp.get_status("Echo").CurrentValue
				stats_comp.get_status("Echo").set_value(0)
			break
	var bonus: int = echo_layers * BonusPerLayer
	GameLog.debug("SpendEchoBehavior: Spent " + str(echo_layers) + " echo layers for +" + str(bonus) + " bonus")
	_apply_effect(block, part, bonus)

func _apply_effect(block: Block, part, bonus: int) -> void:
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
					GameLog.debug("SpendEchoBehavior: Gained " + str(total_shield) + " shield (base: " + str(base_shield) + ", echo bonus: " + str(bonus) + ")")
				return

func _find_shield_component(root: Node) -> ShieldComponent:
	if root is ShieldComponent:
		return root
	for child in root.get_children():
		var found: ShieldComponent = _find_shield_component(child)
		if found != null:
			return found
	return null
