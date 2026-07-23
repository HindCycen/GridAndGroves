class_name SymbiosisBoostBehavior extends BlockPartBehavior

## 共生增益 (Symbiosis Boost) Behavior
## 翠绿哨兵：场上每有 1 个己方 Block（含扎根），效果 +X
## 需要配合共生 Stat 使用，但也可以独立计算场上 Block 数

@export var BonusPerBlock: int = 1   # 每个己方 Block 提供的额外伤害/护盾
@export var EffectType: String = "damage"  # "damage" / "shield"

func create_action(block, part):
	if block == null:
		return null
	return CallbackAction.new(func():
		_apply_symbiosis_boost(block, part)
	, Enums.ActionType.Callback)

func _apply_symbiosis_boost(block: Block, part) -> void:
	var tree := block.get_tree()
	if tree == null:
		return
	var block_piles = block.get_parent()
	if block_piles == null or not block_piles.has_method("PlacedPile"):
		return
	# 统计场上己方 Block 数量（包括此 Block 自身）
	var ally_block_count: int = 0
	for b in block_piles.PlacedPile.Pile:
		if is_instance_valid(b) and b is Block and b.Faction == Block.BlockFaction.Player:
			ally_block_count += 1
	# 计算加成
	var bonus: int = ally_block_count * BonusPerBlock
	GameLog.debug("SymbiosisBoostBehavior: " + str(ally_block_count) + " ally blocks, bonus = " + str(bonus))
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
					GameLog.debug("SymbiosisBoostBehavior: Gained " + str(total_shield) + " shield (base: " + str(base_shield) + ", symbiosis: +" + str(bonus) + ")")
				return

func _find_shield_component(root: Node) -> ShieldComponent:
	if root is ShieldComponent:
		return root
	for child in root.get_children():
		var found: ShieldComponent = _find_shield_component(child)
		if found != null:
			return found
	return null
