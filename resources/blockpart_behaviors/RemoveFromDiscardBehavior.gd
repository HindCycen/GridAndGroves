class_name RemoveFromDiscardBehavior extends BlockPartBehavior

## 弃牌堆销毁 (Remove from Discard) Behavior
## 暗网契约：从弃牌堆永久移除 1 个 Block（代价：弃牌堆丢 1）
## 用于：反噬诅咒

func create_action(block, _part):
	if block == null:
		return null
	var block_piles := block.get_parent() as BlockPilesHere
	if block_piles == null:
		return null
	return CallbackAction.new(func():
		_remove(block_piles)
	, Enums.ActionType.Callback)

func _remove(block_piles: BlockPilesHere) -> void:
	var discarded: Array = block_piles.DiscardedPile.Pile
	if discarded.size() == 0:
		return
	var target: Block = discarded[0]
	block_piles.DiscardedPile.remove_block(target)
	if is_instance_valid(target) and target.get_parent() != null:
		target.get_parent().remove_child(target)
	target.queue_free()
	GameLog.debug("RemoveFromDiscardBehavior: destroyed 1 block in discard pile")
