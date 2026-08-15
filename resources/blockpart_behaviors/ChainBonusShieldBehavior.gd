class_name ChainBonusShieldBehavior extends BlockPartBehavior

## 链加成护盾 (Chain Bonus Shield) Behavior
## 星语术士/星尘余烬：护盾 = 部件基础护盾 + 共鸣链深度 × BonusPerDepth
## 用于：以太护盾（链中翻倍）/ 星尘回响（每层 +1）

@export var BonusPerDepth: int = 1

func create_action(block, part):
	if block == null:
		return null
	var tree: SceneTree = block.get_tree()
	if tree == null:
		return null
	var depth: int = block.get_meta("resonance_depth", 0)
	var base_shield: int = part.Shield if part != null else 0
	var total_shield: int = base_shield + depth * BonusPerDepth
	GameLog.debug("ChainBonusShieldBehavior: depth=" + str(depth) + ", shield " + str(base_shield) + " -> " + str(total_shield))
	return CallbackAction.new(func():
		for node in tree.get_nodes_in_group("Players"):
			if node is Node2D:
				var player := node as Node2D
				var shield_comp: ShieldComponent = _find_shield_component(player)
				if shield_comp != null:
					shield_comp.add_shield(total_shield)
				return
	, Enums.ActionType.Block)

func _find_shield_component(root: Node) -> ShieldComponent:
	if root is ShieldComponent:
		return root
	for child in root.get_children():
		var found: ShieldComponent = _find_shield_component(child)
		if found != null:
			return found
	return null
