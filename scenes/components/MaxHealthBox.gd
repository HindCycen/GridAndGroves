extends SpinBox

@export var health_component:HealthComponent

func _ready() -> void:
	min_value = 0
	max_value = 500
	value = health_component.MaxHealth
	value_changed.connect(_on_value_changed)
	
func _on_value_changed(val:int) -> void:
	health_component.SetMaxHealth(val)
