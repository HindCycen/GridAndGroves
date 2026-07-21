class_name ShootingStatBehavior extends StatBehavior

func shoot_player() -> void:
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
                health.take_damage(10)
                print("ShootingStatBehavior: Dealt 10 damage to player, remaining HP: ", health.CurrentHealth, "/", health.MaxHealth)

func get_execute_periods() -> Array[int]:
    return [Enums.StatExecuteAt.OnTurnEnded]

func execute_at(period: int) -> void:
    if period == Enums.StatExecuteAt.OnTurnEnded:
        shoot_player()
