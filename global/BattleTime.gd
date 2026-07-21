extends Node

signal battle_started()
signal battle_ended()
signal turn_started()
signal turn_ended()
signal pre_block_execute()
signal block_execute()
signal post_block_execute()

func _ready() -> void:
    battle_started.connect(_on_battle_started)
    turn_started.connect(_on_turn_started)
    turn_ended.connect(_on_turn_ended)
    battle_ended.connect(_on_battle_ended)
    pre_block_execute.connect(_on_pre_block_execute)
    block_execute.connect(_on_block_execute)
    post_block_execute.connect(_on_post_block_execute)

func _execute_stat_behaviors(period: Enums.StatExecuteAt) -> void:
    var stats := get_tree().get_nodes_in_group("stats")
    for node in stats:
        if node is Stat and node.Definition != null and node.Definition.Behavior != null:
            node.Definition.Behavior.execute_at(period)

func _on_battle_started() -> void: _execute_stat_behaviors(Enums.StatExecuteAt.OnBattleStarted)
func _on_turn_started() -> void: _execute_stat_behaviors(Enums.StatExecuteAt.OnTurnStarted)
func _on_turn_ended() -> void: _execute_stat_behaviors(Enums.StatExecuteAt.OnTurnEnded)
func _on_battle_ended() -> void: _execute_stat_behaviors(Enums.StatExecuteAt.OnBattleEnded)
func _on_pre_block_execute() -> void: _execute_stat_behaviors(Enums.StatExecuteAt.OnPreBlockExecute)
func _on_block_execute() -> void: _execute_stat_behaviors(Enums.StatExecuteAt.OnBlockExecute)
func _on_post_block_execute() -> void: _execute_stat_behaviors(Enums.StatExecuteAt.OnPostBlockExecute)

func say_battle_started() -> void: battle_started.emit()
func say_turn_started() -> void: turn_started.emit()
func say_turn_ended() -> void: turn_ended.emit()
func say_battle_ended() -> void: battle_ended.emit()
func say_pre_block_execute() -> void: pre_block_execute.emit()
func say_block_execute() -> void: block_execute.emit()
func say_post_block_execute() -> void: post_block_execute.emit()
