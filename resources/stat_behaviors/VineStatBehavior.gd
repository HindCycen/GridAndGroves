class_name VineStatBehavior extends StatBehavior

## 藤蔓 StatBehavior
## OnTurnEnded 时每层对敌人造成 1 伤害，层数 -1
## 上限 20 层

func get_execute_periods() -> Array[int]:
	return [Enums.StatExecuteAt.OnTurnEnded]

func execute_at(period: int) -> void:
	if period != Enums.StatExecuteAt.OnTurnEnded:
		return
	if belonging_stat == null:
		return
	var current_layers: int = belonging_stat.CurrentValue
	if current_layers <= 0:
		return
	var tree := belonging_stat.get_tree()
	if tree == null:
		return
	# 获取拥有此 Stat 的敌人节点
	var owner_node := belonging_stat.get_parent()  # StatsComponent
	if owner_node == null:
		return
	var enemy_node := owner_node.get_parent()  # RenderingComponent
	if enemy_node == null:
		return
	var enemy_actor := enemy_node.get_parent()  # Enemy Actor
	if enemy_actor == null:
		return
	# 对敌人自身造成伤害
	var health: HealthComponent = enemy_node.get_node_or_null("HealthComponent") as HealthComponent
	if health != null:
		var vine_damage: int = current_layers
		health.take_damage(vine_damage)
		GameLog.debug("VineStatBehavior: Dealt " + str(vine_damage) + " vine damage, " + str(current_layers) + " layers consumed")
	# 层数 -1
	belonging_stat.reduce_value(1)
