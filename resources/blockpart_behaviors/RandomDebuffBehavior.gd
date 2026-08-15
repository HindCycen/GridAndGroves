class_name RandomDebuffBehavior extends BlockPartBehavior

## 随机减益 (Random Debuff) Behavior
## 星尘余烬：对敌人随机施加 1 层负面 Stat（锈蚀 Rust 或 藤蔓 Vine）
## 用于：不稳定裂隙

@export var DebuffLayers: int = 1

func create_action(block, _part):
	if block == null:
		return null
	var tree: SceneTree = block.get_tree()
	if tree == null:
		return null
	return CallbackAction.new(func():
		_apply(tree)
	, Enums.ActionType.ApplyStatus)

func _apply(tree: SceneTree) -> void:
	var roll: int = RngManager.get_misc_rand(2)
	var path: String = "res://resources/stat_defs/Rust.tres" if roll == 0 else "res://resources/stat_defs/Vine.tres"
	var def: Resource = load(path)
	if def == null:
		return
	for node in tree.get_nodes_in_group("Enemies"):
		if node is Node2D:
			var rendering = node.get_node_or_null("RenderingComponent")
			if rendering == null:
				continue
			var stats_comp: StatsComponent = rendering.StatsComponentRef if rendering != null else null
			if stats_comp == null:
				continue
			if not stats_comp.has_status(def.StatName):
				var stat: Stat = Stat.new()
				stat.Definition = def
				stats_comp.add_status(stat)
				stat.add_value(DebuffLayers)
			else:
				stats_comp.get_status(def.StatName).add_value(DebuffLayers)
			GameLog.debug("RandomDebuffBehavior: applied [" + str(def.StatName) + "] x" + str(DebuffLayers))
			return
