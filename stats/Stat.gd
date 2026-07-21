class_name Stat extends Node

signal value_changed(current: int, max_val: int)

@export var Definition: StatDef
@export var CurrentValue: int

var is_full: bool:
    get: return CurrentValue >= Definition.MaxValue
var is_empty: bool:
    get: return (not Definition.CanGoNegative) and CurrentValue <= 0

func _ready() -> void:
    CurrentValue = 0
    if Definition != null and Definition.Behavior != null:
        Definition.Behavior.belonging_stat = self
    add_to_group("stats")

func add_value(amount: int) -> void:
    if amount < 0:
        printerr("Add value cannot be negative")
        return
    CurrentValue = mini(Definition.MaxValue, CurrentValue + amount)
    value_changed.emit(CurrentValue, Definition.MaxValue)

func reduce_value(amount: int) -> void:
    if amount < 0:
        printerr("Reduce value cannot be negative")
        return
    CurrentValue = CurrentValue - amount if Definition.CanGoNegative else maxi(0, CurrentValue - amount)
    value_changed.emit(CurrentValue, Definition.MaxValue)

func set_value(value: int) -> void:
    if not Definition.CanGoNegative and value < 0:
        printerr("Value cannot be negative")
        return
    CurrentValue = mini(Definition.MaxValue, value) if Definition.CanGoNegative else mini(Definition.MaxValue, maxi(0, value))
    value_changed.emit(CurrentValue, Definition.MaxValue)
