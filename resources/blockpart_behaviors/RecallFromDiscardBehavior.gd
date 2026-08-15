class_name RecallFromDiscardBehavior extends BlockPartBehavior

## 弃牌堆回收 (Recall from Discard) Behavior
## 铁锈游侠：触发时从弃牌堆回收 1 个 Block 到手牌
## RequireLoose = true 时只回收带松动标记的 Block（"废品回收"语义）
## 用于：信号枪 / 旧引擎 / 废品巨像 / 磁力收束

@export var RequireLoose: bool = true
@export var RequireExhaust: bool = false  # true 时只回收带一次性标记的 Block（余烬重燃用）
@export var RecallCount: int = 1

func create_action(block, _part):
	if block == null:
		return null
	# 在创建时捕获 BlockPilesHere（回调执行时 Block 可能已被移出场景树）
	var block_piles := block.get_parent() as BlockPilesHere
	if block_piles == null:
		return null
	return CallbackAction.new(func():
		for i in RecallCount:
			if not block_piles.recall_from_discard(RequireLoose):
				break
	, Enums.ActionType.Callback)
