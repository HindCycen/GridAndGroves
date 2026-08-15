class_name ConsumeVineDamageBehavior extends BlockPartBehavior

## 消耗藤蔓 (Consume Vine Damage) Behavior
## 翠绿哨兵：触发时消耗敌人全部藤蔓层数，每层造成 1 额外伤害
## 消耗 ≥10 层时额外对所有敌人施加 3 层藤蔓（ToxicBloom 条件）
## 用于：剧毒开花

@export var ReapplyThreshold: int = 10
@export var ReapplyVine: int = 3

func create_action(block, _part):
	if block == null:
		return null
	var tree: SceneTree = block.get_tree()
	if tree == null:
		return null
	return CallbackAction.new(func():
		_consume(block, tree)
	, Enums.ActionType.Callback)

func _consume(block: Block, tree: SceneTree) -> void:
	for node in tree.get_nodes_in_group("Enemies"):
		if node is Node2D:
			var rendering = node.get_node_or_null("RenderingComponent")
			if rendering == null:
				continue
			var stats_comp: StatsComponent = rendering.StatsComponentRef if rendering != null else null
			if stats_comp == null:
				continue
			var vine_layers: int = stats_comp.get_status("Vine").CurrentValue if stats_comp.has_status("Vine") else 0
			if vine_layers <= 0:
				return
			stats_comp.get_status("Vine").set_value(0)
			if ActionManager.Instance != null:
				ActionManager.Instance.add_to_bottom(DamageAction.new(block, node, vine_layers))
			GameLog.debug("ConsumeVineDamageBehavior: consumed " + str(vine_layers) + " vine layers for +" + str(vine_layers) + " damage")
			if vine_layers >= ReapplyThreshold:
				_apply_vine_to_all(tree, ReapplyVine)
			return

func _apply_vine_to_all(tree: SceneTree, layers: int) -> void:
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
	GameLog.debug("ConsumeVineDamageBehavior: re-applied " + str(layers) + " vine to all enemies")
