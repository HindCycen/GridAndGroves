class_name GrowingStatBehavior extends StatBehavior

func heal_player() -> void:
	var stat := belonging_stat
	if stat == null:
		return
	var tree := stat.get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group("Players"):
		if node is Node2D:
			var player := node as Node2D
			var health: HealthComponent = player.get_node("RenderingComponent/HealthComponent")
			if health != null:
				var amount: int = stat.CurrentValue
				if amount <= 0:
					return
				health.heal(amount)
				GameLog.debug("GrowingStatBehavior: Healed " + str(amount) + " HP, current HP: " + str(health.CurrentHealth) + "/" + str(health.MaxHealth))

func get_execute_periods() -> Array[int]:
	return [Enums.StatExecuteAt.OnBattleEnded]

func execute_at(period: int) -> void:
	if period == Enums.StatExecuteAt.OnBattleEnded:
		heal_player()
