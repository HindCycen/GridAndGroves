class_name ReturnPlacedToHandBehavior extends BlockPartBehavior

## 回手 (Return Placed to Hand) Behavior
## 暗网契约：场上 1 个玩家 Block 回手（代价：场上 Block 回手）
## 用于：生命转换（治疗 10 且场上 1 Block 回手）

func create_action(block, _part):
	if block == null:
		return null
	var block_piles := block.get_parent() as BlockPilesHere
	if block_piles == null:
		return null
	return CallbackAction.new(func():
		if block_piles.return_placed_to_hand():
			GameLog.debug("ReturnPlacedToHandBehavior: 1 placed block returned to hand")
	, Enums.ActionType.Callback)
