class_name LooseBlockBehavior extends BlockPartBehavior

## 松动 (Loose) Behavior
## Block 被触发后立即释放占用的网格格子，Block 进入弃牌堆而非销毁
## 是铁锈游侠的核心机制：高频腾挪 + 资源循环

func create_action(block, part):
	if block == null:
		return null
	return CallbackAction.new(func():
		_loose_block(block)
	, Enums.ActionType.Callback)

## 将 Block 从网格释放，放入弃牌堆
func _loose_block(block: Block) -> void:
	var tree := block.get_tree()
	if tree == null:
		return
	# 释放所有占用的格子
	for p in block.get_parts():
		var grid_point: Vector2 = GridState.find_nearest_grid_point(p.global_position)
		var coords: Vector2i = GridState.get_grid_coords(grid_point)
		if coords.x >= 0 and coords.y >= 0:
			GridState.restore_grid_state(coords.x, coords.y)
	# 从放置堆中移除
	var block_piles = block.get_parent()
	if block_piles != null and block_piles.has_method("PlacedPile"):
		block_piles.PlacedPile.remove_block(block)
	# 放入玩家弃牌堆
	_enter_discard_pile(block, tree)
	GameLog.debug("LooseBlockBehavior: Block loosened and entered discard pile")

## 将 Block 放入弃牌堆（不销毁节点）
func _enter_discard_pile(block: Block, tree: SceneTree) -> void:
	for node in tree.get_nodes_in_group("Players"):
		if node is Node2D:
			var player := node as Node2D
			var pile_node = player.get_node("%PlayerPile")
			if pile_node != null and pile_node.has_method("DiscardedPile"):
				var discard = pile_node.DiscardedPile
				if discard != null and discard.has_method("add_block"):
					# 重置 Block 状态使其可被再次放置
					block.IsPlaced = false
					block.global_position = block.OriginalPos
					discard.add_block(block)
					return
	# 如果没有找到弃牌堆，将 Block 移到场景外（安全兜底）
	block.global_position = Vector2(9999, 9999)
