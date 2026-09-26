class_name ShieldComponent extends Node

signal shield_changed(current: int, max_val: int)

@export var MaxShield: int = 999
@export var CurrentShield: int

func _ready() -> void:
	CurrentShield = 0
	var battle_time := get_tree().root.get_node("BattleTime")
	if battle_time != null:
		# 护盾在 turn_started（新回合开始时）清零，而不是 turn_ended：
		# turn_ended 时敌人攻击（DamageAction 入队）尚未执行，
		# 若在 turn_ended 清零，护盾将完全无法抵挡敌人回合末直伤。
		battle_time.turn_started.connect(_on_turn_started)

func _exit_tree() -> void:
	var root := get_tree().root if get_tree() != null else null
	if root == null:
		return
	var battle_time := root.get_node_or_null("BattleTime")
	if battle_time != null and battle_time.turn_started.is_connected(_on_turn_started):
		battle_time.turn_started.disconnect(_on_turn_started)

func _on_turn_started() -> void:
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
