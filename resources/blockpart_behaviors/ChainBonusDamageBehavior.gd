class_name ChainBonusDamageBehavior extends BlockPartBehavior

## 链加成伤害 (Chain Bonus Damage) Behavior
## 星语术士：伤害 = 部件基础伤害 + 共鸣链深度 × BonusPerDepth
## 链深度由 Bot/ResonanceBot 触发时写入 block meta "resonance_depth"
## 用于：星涌节点（每层 +2）/ 星脉冲（翻倍 ≈ 每层 +6）/ 群星齐鸣 / 新星

@export var BonusPerDepth: int = 2

func create_action(block, part):
	if block == null:
		return null
	var tree: SceneTree = block.get_tree()
	if tree == null:
		return null
	var depth: int = block.get_meta("resonance_depth", 0)
	var base_damage: int = part.Damage if part != null else 0
	var total_damage: int = base_damage + depth * BonusPerDepth
	GameLog.debug("ChainBonusDamageBehavior: depth=" + str(depth) + ", damage " + str(base_damage) + " -> " + str(total_damage))
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
