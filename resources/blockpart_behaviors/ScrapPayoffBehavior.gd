class_name ScrapPayoffBehavior extends BlockPartBehavior

## 废品回收 (Scrap Payoff) Behavior
## 松动 Block 进入弃牌堆时触发额外效果：
## - 增加过载层数
## - 给敌人上锈蚀
## - 获得护盾
## - 抽 Block
## 是铁锈游侠资源循环的"奖励"端
##
## 注意：create_action 返回 null（标记类，普通触发时不产生 Action），
## 松动入弃牌堆时由 Bot / ResonanceBot 调用 create_payoff_action 显式触发，
## 避免与普通触发路径重复执行。

@export var PayoffType: String = "overload"  # "overload" / "rust" / "shield" / "draw"
@export var PayoffAmount: int = 1

func create_action(_block, _part):
	# 回收效果由松动路径（Bot._trigger_scrap_payoff）显式触发
	return null

## 创建回收效果 Action（由 Bot / ResonanceBot 在松动入弃牌堆时调用）
func create_payoff_action(block: Block, part, block_piles: BlockPilesHere) -> AbstractGameAction:
	if block == null:
		return null
	return CallbackAction.new(func():
		_trigger_payoff(block, part, block_piles)
	, Enums.ActionType.Callback)

func _trigger_payoff(block: Block, part, block_piles: BlockPilesHere) -> void:
	if block_piles == null or not is_instance_valid(block_piles):
		return
	var tree := block_piles.get_tree()
	if tree == null:
		return
	match PayoffType:
		"overload":
			block_piles.add_player_stat("Overload", PayoffAmount)
		"rust":
			_apply_rust_to_enemies(tree, block)
		"shield":
			_grant_shield(tree, block)
		"draw":
			_draw_block(block_piles)

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

func _draw_block(block_piles: BlockPilesHere) -> void:
	if block_piles == null:
		return
	block_piles.draw_cards(PayoffAmount)
	GameLog.debug("ScrapPayoffBehavior: Drew " + str(PayoffAmount) + " block(s) from scrap recovery")

func _find_shield_component(root: Node) -> ShieldComponent:
	if root is ShieldComponent:
		return root
	for child in root.get_children():
		var found: ShieldComponent = _find_shield_component(child)
		if found != null:
			return found
	return null
