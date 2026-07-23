class_name ScrapPayoffBehavior extends BlockPartBehavior

## 废品回收 (Scrap Payoff) Behavior
## 松动 Block 进入弃牌堆时触发额外效果：
## - 增加过载层数
## - 给敌人上锈蚀
## - 获得护盾等
## 是铁锈游侠资源循环的"奖励"端

@export var PayoffType: String = "overload"  # "overload" / "rust" / "shield" / "draw"
@export var PayoffAmount: int = 1

func create_action(block, part):
	if block == null:
		return null
	return CallbackAction.new(func():
		_trigger_payoff(block, part)
	, Enums.ActionType.Callback)

func _trigger_payoff(block: Block, part) -> void:
	var tree := block.get_tree()
	if tree == null:
		return
	match PayoffType:
		"overload":
			_add_player_overload(tree, block)
		"rust":
			_apply_rust_to_enemies(tree, block)
		"shield":
			_grant_shield(tree, block)
		"draw":
			_draw_block(tree)

func _add_player_overload(tree: SceneTree, block: Block) -> void:
	for node in tree.get_nodes_in_group("Players"):
		if node is Node2D:
			var player := node as Node2D
			var rendering = player.get_node("RenderingComponent")
			var stats_comp: StatsComponent = rendering.StatsComponentRef if rendering != null else null
			if stats_comp != null:
				if stats_comp.has_status("Overload"):
					var overload: Stat = stats_comp.get_status("Overload")
					overload.add_value(PayoffAmount)
					GameLog.debug("ScrapPayoffBehavior: Added " + str(PayoffAmount) + " overload from scrap recovery")
				else:
					# 自动创建 Overload Stat
					var overload_def: Resource = load("res://resources/stat_defs/Overload.tres")
					if overload_def != null:
						var stat: Stat = Stat.new()
						stat.Definition = overload_def
						stats_comp.add_status(stat)
						stat.add_value(PayoffAmount)
			return

func _apply_rust_to_enemies(tree: SceneTree, block: Block) -> void:
	var rust_def: Resource = load("res://resources/stat_defs/Rust.tres")
	if rust_def == null:
		return
	for enemy in tree.get_nodes_in_group("Enemies"):
		if enemy is Node2D:
			var rendering = enemy.get_node_or_null("RenderingComponent")
			if rendering == null:
				continue
			var stats_comp: StatsComponent = rendering.StatsComponentRef if rendering != null else null
			if stats_comp == null:
				continue
			if not stats_comp.has_status("Rust"):
				var stat: Stat = Stat.new()
				stat.Definition = rust_def
				stats_comp.add_status(stat)
				stat.add_value(PayoffAmount)
			else:
				var existing: Stat = stats_comp.get_status("Rust")
				if existing != null:
					existing.add_value(PayoffAmount)
			GameLog.debug("ScrapPayoffBehavior: Applied " + str(PayoffAmount) + " Rust from scrap recovery")

func _grant_shield(tree: SceneTree, block: Block) -> void:
	for node in tree.get_nodes_in_group("Players"):
		if node is Node2D:
			var player := node as Node2D
			var shield_comp: ShieldComponent = _find_shield_component(player)
			if shield_comp != null:
				shield_comp.add_shield(PayoffAmount)
				GameLog.debug("ScrapPayoffBehavior: Gained " + str(PayoffAmount) + " shield from scrap recovery")
			return

func _draw_block(tree: SceneTree) -> void:
	for node in tree.get_nodes_in_group("Players"):
		if node is Node2D:
			var player := node as Node2D
			var pile_node = player.get_node("%PlayerPile")
			if pile_node != null and pile_node.has_method("draw_block"):
				pile_node.draw_block()
				GameLog.debug("ScrapPayoffBehavior: Drew a block from scrap recovery")
			return

func _find_shield_component(root: Node) -> ShieldComponent:
	if root is ShieldComponent:
		return root
	for child in root.get_children():
		var found: ShieldComponent = _find_shield_component(child)
		if found != null:
			return found
	return null
