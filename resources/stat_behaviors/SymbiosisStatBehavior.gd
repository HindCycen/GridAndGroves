class_name SymbiosisStatBehavior extends StatBehavior

## 共生 StatBehavior（玩家身上）
## OnPostBlockExecute：场上每有 1 个己方 Block（含扎根），获得护盾
## 需要外部传入场上 Block 数量

var _block_count: int = 0

func set_block_count(count: int) -> void:
	_block_count = count

func get_execute_periods() -> Array[int]:
	return [Enums.StatExecuteAt.OnPostBlockExecute]

func execute_at(period: int) -> void:
	if period != Enums.StatExecuteAt.OnPostBlockExecute:
		return
	if belonging_stat == null:
		return
	var current_layers: int = belonging_stat.CurrentValue
	if current_layers <= 0 or _block_count <= 0:
		return
	var tree := belonging_stat.get_tree()
	if tree == null:
		return
	# 获取玩家节点
	for node in tree.get_nodes_in_group("Players"):
		if node is Node2D:
			var player := node as Node2D
			var shield_comp: ShieldComponent = _find_shield_component(player)
			if shield_comp != null:
				var shield_amount: int = _block_count * current_layers
				shield_comp.add_shield(shield_amount)
				GameLog.debug("SymbiosisStatBehavior: Gained " + str(shield_amount) + " shield from " + str(_block_count) + " blocks x " + str(current_layers) + " layers")
			return

func _find_shield_component(root: Node) -> ShieldComponent:
	if root is ShieldComponent:
		return root
	for child in root.get_children():
		var found: ShieldComponent = _find_shield_component(child)
		if found != null:
			return found
	return null
