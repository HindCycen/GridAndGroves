class_name RootCountVineBehavior extends BlockPartBehavior

## 扎根计数藤蔓 (Root Count Vine) Behavior
## 翠绿哨兵：触发时对敌人施加 场上扎根数 × VinePerRoot 层藤蔓
## 用于：世界树部件 C（设计为回合结束时施加——此处简化为触发时）

@export var VinePerRoot: int = 2

func create_action(block, _part):
	if block == null:
		return null
	var block_piles := block.get_parent() as BlockPilesHere
	if block_piles == null:
		return null
	return CallbackAction.new(func():
		_apply(block, block_piles)
	, Enums.ActionType.ApplyStatus)

func _apply(block: Block, block_piles: BlockPilesHere) -> void:
	var tree := block.get_tree()
	if tree == null:
		return
	var root_count: int = _count_roots(block_piles)
	if root_count <= 0:
		return
	var layers: int = root_count * VinePerRoot
	var vine_def: Resource = load("res://resources/stat_defs/Vine.tres")
	if vine_def == null:
		return
	for node in tree.get_nodes_in_group("Enemies"):
		if node is Node2D:
			var rendering = node.get_node_or_null("RenderingComponent")
			if rendering == null:
				continue
			var stats_comp: StatsComponent = rendering.StatsComponentRef if rendering != null else null
			if stats_comp == null:
				continue
			if not stats_comp.has_status("Vine"):
				var stat: Stat = Stat.new()
				stat.Definition = vine_def
				stats_comp.add_status(stat)
				stat.add_value(layers)
			else:
				stats_comp.get_status("Vine").add_value(layers)
			GameLog.debug("RootCountVineBehavior: " + str(root_count) + " roots x " + str(VinePerRoot) + " = " + str(layers) + " vine")
			return

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
