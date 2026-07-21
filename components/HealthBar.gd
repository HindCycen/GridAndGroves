class_name HealthBar extends TextureProgressBar

var _health_bar_mid: Texture2D
@export var _healthComponent: HealthComponent
var _shield_bar_mid: Texture2D
@export var _shieldComponent: ShieldComponent

func _ready() -> void:
    _health_bar_mid = load("res://components/healthbar/HealthBarMid.png")
    _shield_bar_mid = load("res://components/healthbar/ShieldBarMid.png")
    min_value = 0
    max_value = _healthComponent.MaxHealth
    value = _healthComponent.CurrentHealth
    _healthComponent.health_changed.connect(func(current, max_val):
        value = current
        max_value = max_val
    )
    var shield := _shieldComponent
    if shield == null:
        shield = _resolve_shield_component()
    if shield != null:
        _shieldComponent = shield
        _update_mid_texture(shield.CurrentShield)
        shield.shield_changed.connect(func(current, _max): _update_mid_texture(current))

func _update_mid_texture(shield_val: int) -> void:
    texture_progress = _shield_bar_mid if shield_val > 0 else _health_bar_mid

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
