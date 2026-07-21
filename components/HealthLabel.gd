class_name HealthLabel extends Label

@export var _shieldComponent: ShieldComponent
@export var HealthBarRef: TextureProgressBar
@export var HealthComponentRef: HealthComponent

func _ready() -> void:
	_update_text(HealthComponentRef.CurrentHealth, HealthComponentRef.MaxHealth)
	HealthComponentRef.health_changed.connect(_update_text)
	var shield := _shieldComponent
	if shield == null:
		shield = _resolve_shield_component()
	if shield != null:
		_shieldComponent = shield
		shield.shield_changed.connect(func(_c, _m): _update_text(HealthComponentRef.CurrentHealth, HealthComponentRef.MaxHealth))

func _update_text(current: int, max_val: int) -> void:
	if _shieldComponent != null and _shieldComponent.CurrentShield > 0:
		text = str(current) + "/" + str(max_val) + "(+" + str(_shieldComponent.CurrentShield) + ")"
	else:
		text = str(current) + "/" + str(max_val)

func _resolve_shield_component() -> ShieldComponent:
	var shield: ShieldComponent = get_node_or_null("%ShieldComponent") as ShieldComponent
	if shield != null:
		return shield
	var parent := get_parent()
	while parent != null:
		shield = parent.get_node_or_null("%ShieldComponent") as ShieldComponent
		if shield != null:
			return shield
		parent = parent.get_parent()
	return null
