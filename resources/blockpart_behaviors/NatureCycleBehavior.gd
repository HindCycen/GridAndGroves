class_name NatureCycleBehavior extends BlockPartBehavior

## 自然循环 (Nature's Cycle) Behavior
## 翠绿哨兵：扎根 Block 被清除时触发回收效果
## 可回血/抽 Block/生成临时护盾等

@export var CycleType: String = "heal"  # "heal" / "draw" / "shield" / "overload"
@export var CycleAmount: int = 3

## 注意：此 Behavior 的触发不在 create_action 中
## 而是在 Bot.gd 的 _exhaust_block 或其他清除逻辑中调用
## 通过 Bot 钩子 _on_block_cleared 触发

func create_action(_block, _part):
	# 清除时触发不在此处处理
	return null

## 被外部调用触发回收效果
func trigger_cycle(block: Block) -> void:
	var tree := block.get_tree()
	if tree == null:
		return
	match CycleType:
		"heal":
			_heal_player(tree, block)
		"draw":
			_draw_block(tree)
		"shield":
			_grant_shield(tree, block)
		"overload":
			_add_overload(tree)

func _heal_player(tree: SceneTree, block: Block) -> void:
	for node in tree.get_nodes_in_group("Players"):
		if node is Node2D:
			var player := node as Node2D
			var hc: HealthComponent = player.get_node_or_null("RenderingComponent/HealthComponent") as HealthComponent
			if hc != null:
				hc.heal(CycleAmount)
				GameLog.debug("NatureCycleBehavior: Healed " + str(CycleAmount) + " HP on root removal")
			return

func _draw_block(tree: SceneTree) -> void:
	for node in tree.get_nodes_in_group("Players"):
		if node is Node2D:
			var player := node as Node2D
			var pile_node = player.get_node("%PlayerPile")
			if pile_node != null and pile_node.has_method("draw_block"):
				for _i in range(CycleAmount):
					pile_node.draw_block()
				GameLog.debug("NatureCycleBehavior: Drew " + str(CycleAmount) + " blocks on root removal")
			return

func _grant_shield(tree: SceneTree, block: Block) -> void:
	for node in tree.get_nodes_in_group("Players"):
		if node is Node2D:
			var player := node as Node2D
			var shield_comp: ShieldComponent = _find_shield_component(player)
			if shield_comp != null:
				shield_comp.add_shield(CycleAmount)
				GameLog.debug("NatureCycleBehavior: Gained " + str(CycleAmount) + " shield on root removal")
			return

func _add_overload(tree: SceneTree) -> void:
	for node in tree.get_nodes_in_group("Players"):
		if node is Node2D:
			var player := node as Node2D
			var rendering = player.get_node("RenderingComponent")
			var stats_comp: StatsComponent = rendering.StatsComponentRef if rendering != null else null
			if stats_comp != null:
				if stats_comp.has_status("Overload"):
					stats_comp.get_status("Overload").add_value(CycleAmount)
					GameLog.debug("NatureCycleBehavior: Added " + str(CycleAmount) + " overload on root removal")
				else:
					var overload_def: Resource = load("res://resources/stat_defs/Overload.tres")
					if overload_def != null:
						var stat: Stat = Stat.new()
						stat.Definition = overload_def
						stats_comp.add_status(stat)
						stat.add_value(CycleAmount)
			return

func _find_shield_component(root: Node) -> ShieldComponent:
	if root is ShieldComponent:
		return root
	for child in root.get_children():
		var found: ShieldComponent = _find_shield_component(child)
		if found != null:
			return found
	return null
