class_name FullTriggerRewardBehavior extends BlockPartBehavior

## 全部件触发奖励 (Full Trigger Reward) Behavior
## 铁锈游侠：本 Block 的所有部件都触发过后，从弃牌堆回收 1 个 Block
## 通过 block meta 记录已触发的部件 ID（去重），数量达到部件总数时触发奖励
##
## 用法：把本 Behavior 挂到 Block 的**每个部件**上（JSON 每个 part 都配一份），
## 每个实例记录自己的 PartId；最后一个部件触发时计数达标，触发回收。
## 用于：废品巨像（四部件全触发回收 1 个）/ 磁力收束（全部触发后回收松动 Block）

const TRIGGER_META_KEY := "full_trigger_parts"

@export var RequireLoose: bool = false
@export var RecallCount: int = 1

func create_action(block, part):
	if block == null or part == null:
		return null
	# 记录本部件已触发（按 PartId 去重）
	var triggered: Array = block.get_meta(TRIGGER_META_KEY, [])
	if not triggered.has(part.PartId):
		triggered.append(part.PartId)
		block.set_meta(TRIGGER_META_KEY, triggered)
	# 在创建时捕获 BlockPilesHere（回调执行时 Block 可能已被移出场景树）
	var block_piles := block.get_parent() as BlockPilesHere
	if block_piles == null:
		return null
	var total_parts: int = block.get_parts().size()
	return CallbackAction.new(func():
		var recorded: Array = block.get_meta(TRIGGER_META_KEY, [])
		if recorded.size() >= total_parts:
			GameLog.debug("FullTriggerRewardBehavior: all " + str(total_parts) + " parts triggered, recalling from discard")
			for i in RecallCount:
				if not block_piles.recall_from_discard(RequireLoose):
					break
	, Enums.ActionType.Callback)
