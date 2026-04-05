extends SpinBox

@export var health_component:HealthComponent

func _ready() -> void:
	min_value = 0
	max_value = health_component.MaxHealth
	value = health_component.CurrentHealth
	value_changed.connect(_on_value_changed)
	
func _on_value_changed(val:int) -> void:
	health_component.SetCurrentHealth(val)
