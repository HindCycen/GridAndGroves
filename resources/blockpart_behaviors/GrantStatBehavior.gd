class_name GrantStatBehavior extends BlockPartBehavior

## 通用 Stat 施加 Behavior
## 对指定目标群组中的目标施加/叠加 Stat
## 通过 @export 参数控制目标群组、StatDef、初始值等
## 可用于给玩家加增益 Stat，也可给敌人加减益 Stat

@export var TargetGroup: String = "Players"
@export var TargetStatDef: StatDef
@export var InitialValue: int = 1
@export var RemoveBlockFromDeck: bool = false
@export var ShouldExhaust: bool = false

func create_action(block, _part):
	if TargetStatDef == null:
		printerr("GrantStatBehavior: TargetStatDef not set!")
		return null
	if block == null:
		return null
	var tree: SceneTree = block.get_tree()
	if tree == null:
		return null
	return CallbackAction.new(func():
		_apply_stat_to_group(block, tree)
	, Enums.ActionType.ApplyStatus, ShouldExhaust)

func _apply_stat_to_group(block: Block, tree: SceneTree) -> void:
	for node in tree.get_nodes_in_group(TargetGroup):
		if node is Node2D:
			var target: Node2D = node as Node2D
			var stats_comp: StatsComponent = _find_stats_component(target)
			if stats_comp == null:
				continue
			# 施加或叠加 Stat
			if not stats_comp.has_status(TargetStatDef.StatName):
				var stat: Stat = Stat.new()
				stat.Definition = TargetStatDef
				stats_comp.add_status(stat)
				stat.add_value(InitialValue)
				print("GrantStatBehavior: Added Stat [", TargetStatDef.StatName, "] = ", InitialValue, " to ", target.name)
			else:
				var existing: Stat = stats_comp.get_status(TargetStatDef.StatName)
				if existing != null:
					existing.add_value(InitialValue)
					print("GrantStatBehavior: Stacked Stat [", TargetStatDef.StatName, "] +", InitialValue, " on ", target.name, " = ", existing.CurrentValue)
			# 从牌组移除同名 Block（仅对玩家有效）
			if RemoveBlockFromDeck and block.Definition != null:
				_remove_block_from_deck(target, block)
			return  # 只对 Group 中的第一个目标生效

## 查找节点上的 StatsComponent（递归搜索子树）
func _find_stats_component(node: Node2D) -> StatsComponent:
	var rendering = node.get_node_or_null("RenderingComponent")
	if rendering != null and rendering.StatsComponentRef != null:
		return rendering.StatsComponentRef
	return null

## 从玩家牌组中移除同名 Block
func _remove_block_from_deck(target: Node2D, block: Block) -> void:
	var player_pile = target.get_node("%PlayerPile")
	if player_pile == null:
		return
	for b in player_pile.Pile:
		if not is_instance_valid(b):
			continue
		if b.Definition != null and b.Definition.BlockName == block.Definition.BlockName:
			player_pile.remove_block(b)
			if is_instance_valid(b) and b.get_parent() != null:
				b.get_parent().remove_child(b)
			b.queue_free()
			print("GrantStatBehavior: Removed [", block.Definition.BlockName, "] from deck")
			return
