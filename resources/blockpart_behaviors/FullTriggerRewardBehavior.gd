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
@export var EchoReward: int = 0  # >0 时全部件触发额外给玩家回响 +N（超新星前兆用）

func create_action(block, part):
	if block == null or part == null:
		return null
	# 在创建时捕获 BlockPilesHere（回调执行时 Block 可能已被移出场景树）
	var block_piles := block.get_parent() as BlockPilesHere
	if block_piles == null:
		return null
	var total_parts: int = block.get_parts().size()
	return CallbackAction.new(func():
		if not is_instance_valid(block_piles) or not is_instance_valid(block):
			return
		# 在 Action 真正执行时才记录本次触发（避免未执行的 Action 污染计数）
		var recorded: Array = block.get_meta(TRIGGER_META_KEY, [])
		if not recorded.has(part.PartId):
			recorded.append(part.PartId)
			block.set_meta(TRIGGER_META_KEY, recorded)
		if recorded.size() >= total_parts:
			GameLog.debug("FullTriggerRewardBehavior: all " + str(total_parts) + " parts triggered, recalling from discard")
			for i in RecallCount:
				if not block_piles.recall_from_discard(RequireLoose):
					break
			if EchoReward > 0:
				_add_echo(block, EchoReward)
			# 结算后清空记录：下一次“全部件触发”需重新累计，避免每次部件触发都重复奖励
			block.remove_meta(TRIGGER_META_KEY)
	, Enums.ActionType.Callback)

## 给玩家回响 +N（EchoStat，星语术士资源）
func _add_echo(block: Block, layers: int) -> void:
	var tree := block.get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group("Players"):
		if node is Node2D:
			var player := node as Node2D
			var rendering = player.get_node("RenderingComponent")
			var stats_comp: StatsComponent = rendering.StatsComponentRef if rendering != null else null
			if stats_comp == null:
				return
			if not stats_comp.has_status("Echo"):
				var echo_def: Resource = load("res://resources/stat_defs/Echo.tres")
				if echo_def == null:
					printerr("FullTriggerRewardBehavior: Echo.tres not found!")
					return
				var stat: Stat = Stat.new()
				stat.Definition = echo_def
				stats_comp.add_status(stat)
				stat.add_value(layers)
			else:
				stats_comp.get_status("Echo").add_value(layers)
			GameLog.debug("FullTriggerRewardBehavior: Echo +" + str(layers))
			return
