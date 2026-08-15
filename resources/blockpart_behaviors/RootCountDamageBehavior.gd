class_name RootCountDamageBehavior extends BlockPartBehavior

## 扎根计数伤害 (Root Count Damage) Behavior
## 翠绿哨兵：场上每有 1 个己方扎根 Block，对敌人造成 DamagePerRoot 伤害
## 用于：千年古树部件 D（共生爆发）

@export var DamagePerRoot: int = 5

func create_action(block, _part):
	if block == null:
		return null
	var block_piles := block.get_parent() as BlockPilesHere
	if block_piles == null:
		return null
	return CallbackAction.new(func():
		_burst(block, block_piles)
	, Enums.ActionType.Damage)

func _burst(block: Block, block_piles: BlockPilesHere) -> void:
	var tree := block.get_tree()
	if tree == null:
		return
	var root_count: int = _count_roots(block_piles)
	if root_count <= 0:
		return
	var total: int = root_count * DamagePerRoot
	for node in tree.get_nodes_in_group("Enemies"):
		if node is Node2D:
			var hc: HealthComponent = node.get_node_or_null("RenderingComponent/HealthComponent") as HealthComponent
			if hc != null and not hc.is_dead:
				if ActionManager.Instance != null:
					ActionManager.Instance.add_to_bottom(DamageAction.new(block, node, total))
	GameLog.debug("RootCountDamageBehavior: " + str(root_count) + " roots x " + str(DamagePerRoot) + " = " + str(total))

## 统计场上己方扎根/法阵 Block 数量
func _count_roots(block_piles: BlockPilesHere) -> int:
	var count: int = 0
	var seen := Dictionary()
	for b in block_piles.PlacedPile.Pile:
		if not is_instance_valid(b) or b is not Block:
			continue
		if b.Faction != Block.BlockFaction.Player or seen.has(b):
			continue
		seen[b] = true
		var is_root := false
		for p in b.get_parts():
			if is_root:
				break
			for bh in p.Behaviors:
				if bh is RootBehavior or bh is GlyphRootBehavior:
					count += 1
					is_root = true
					break
	return count
