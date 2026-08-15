class_name DetonatorBehavior extends BlockPartBehavior

## 引爆 (Detonator) Behavior
## 废品爆破：引爆场上所有带一次性标记（Exhaust）的玩家 Block——
## 重新触发它们所有部件的效果（不处理生命周期，防止连环引爆）
## 用于：引爆器

func create_action(block, _part):
	if block == null:
		return null
	var block_piles := block.get_parent() as BlockPilesHere
	if block_piles == null:
		return null
	return CallbackAction.new(func():
		_detonate(block_piles)
	, Enums.ActionType.Callback)

func _detonate(block_piles: BlockPilesHere) -> void:
	var count := 0
	for b in block_piles.get_blocks_on_grid():
		if not is_instance_valid(b) or b is not Block:
			continue
		if b.Faction != Block.BlockFaction.Player:
			continue
		if not _has_exhaust_part(b):
			continue
		for p in b.get_parts():
			for bh in p.Behaviors:
				if bh == null or bh is DetonatorBehavior:
					continue
				var action: AbstractGameAction = bh.create_action(b, p) as AbstractGameAction
				if action != null and ActionManager.Instance != null:
					ActionManager.Instance.add_to_bottom(action)
		count += 1
	GameLog.debug("DetonatorBehavior: detonated " + str(count) + " one-shot block(s)")

func _has_exhaust_part(b: Block) -> bool:
	for p in b.get_parts():
		if p.Exhaust:
			return true
	return false
