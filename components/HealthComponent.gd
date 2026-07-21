class_name HealthComponent extends Node

signal died()
signal health_changed(current: int, max_val: int)
signal shield_absorbed(absorbed: int, remaining: int)

@export var MaxHealth: int = 100
@export var CurrentHealth: int
var is_dead: bool:
    get: return CurrentHealth <= 0

func _ready() -> void:
    CurrentHealth = MaxHealth

func take_damage(damage: int) -> void:
    if damage < 0:
        printerr("Damage value cannot be negative")
        return
    if damage == 0:
        return
    var shield: ShieldComponent = _resolve_shield_component()
    if shield != null and shield.CurrentShield > 0:
        var absorbed := mini(shield.CurrentShield, damage)
        shield.reduce_shield(absorbed)
        damage -= absorbed
        shield_absorbed.emit(absorbed, damage)
    if damage > 0:
        CurrentHealth = maxi(0, CurrentHealth - damage)
    health_changed.emit(CurrentHealth, MaxHealth)
    if is_dead:
        died.emit()

func heal(amount: int) -> void:
    if amount < 0:
        printerr("Heal value cannot be negative")
        return
    CurrentHealth = mini(MaxHealth, CurrentHealth + amount)
    health_changed.emit(CurrentHealth, MaxHealth)

func set_max_health(value: int) -> void:
    if value <= 0:
        printerr("Max health must be greater than 0")
        return
    MaxHealth = value
    CurrentHealth = mini(CurrentHealth, MaxHealth)
    health_changed.emit(CurrentHealth, MaxHealth)

func set_current_health(value: int) -> void:
    if value < 0:
        printerr("Current health cannot be negative")
        return
    CurrentHealth = mini(value, MaxHealth)
    health_changed.emit(CurrentHealth, MaxHealth)

func _resolve_shield_component() -> ShieldComponent:
    var shield := get_node_or_null("%ShieldComponent")
    if shield != null:
        return shield
    var parent := get_parent()
    while parent != null:
        shield = parent.get_node_or_null("%ShieldComponent")
        if shield != null:
            return shield
        parent = parent.get_parent()
    return null
