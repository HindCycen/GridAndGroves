class_name ShieldComponent extends Node

signal shield_changed(current: int, max_val: int)

@export var MaxShield: int = 999
@export var CurrentShield: int

func _ready() -> void:
    CurrentShield = 0
    var battle_time := get_tree().root.get_node("BattleTime")
    if battle_time != null:
        battle_time.turn_ended.connect(_on_turn_ended)

func _exit_tree() -> void:
    var root := get_tree().root if get_tree() != null else null
    if root == null:
        return
    var battle_time := root.get_node_or_null("BattleTime")
    if battle_time != null and battle_time.turn_ended.is_connected(_on_turn_ended):
        battle_time.turn_ended.disconnect(_on_turn_ended)

func _on_turn_ended() -> void:
    CurrentShield = 0

func add_shield(amount: int) -> void:
    if amount < 0:
        printerr("Shield add value cannot be negative")
        return
    CurrentShield = mini(MaxShield, CurrentShield + amount)
    shield_changed.emit(CurrentShield, MaxShield)

func reduce_shield(amount: int) -> void:
    if amount < 0:
        printerr("Shield reduce value cannot be negative")
        return
    CurrentShield = maxi(0, CurrentShield - amount)
    shield_changed.emit(CurrentShield, MaxShield)

func set_max_shield(value: int) -> void:
    if value <= 0:
        printerr("Max shield must be greater than 0")
        return
    MaxShield = value
    CurrentShield = mini(CurrentShield, MaxShield)
    shield_changed.emit(CurrentShield, MaxShield)
