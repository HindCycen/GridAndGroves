class_name DrawBlockBehavior extends BlockPartBehavior

## 抽牌 (Draw Block) Behavior
## 触发时从抽牌堆抽 N 张到手牌（能量引流 / 闪烁 / 能量饮料 / 信号弹 / 能量虹吸等）

@export var DrawCount: int = 1

func create_action(block, _part):
	if block == null:
		return null
	# 在创建时捕获 BlockPilesHere
	var block_piles := block.get_parent() as BlockPilesHere
	if block_piles == null:
		return null
	return CallbackAction.new(func():
		block_piles.draw_cards(DrawCount)
		GameLog.debug("DrawBlockBehavior: Drew " + str(DrawCount) + " block(s)")
	, Enums.ActionType.Callback)
