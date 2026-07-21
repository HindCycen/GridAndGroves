class_name DamageNumberVFX extends Node2D

var _label: Label
var _alpha: float = 1.0
var _velocity: Vector2

func _init(pos: Vector2, amount: int, color: Color = Color.RED):
    global_position = pos
    _velocity = Vector2(0, -60)
    z_index = 200
    _label = Label.new()
    _label.text = str(amount)
    _label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _label.add_theme_font_size_override("font_size", 36)
    _label.add_theme_color_override("font_color", color)
    _label.set_size(Vector2(80, 40))
    _label.position = Vector2(-40, -20)
    add_child(_label)

func _process(delta: float) -> void:
    var dt := float(delta)
    global_position += _velocity * dt
    _alpha -= dt * 1.5
    modulate = Color(1, 1, 1, maxf(0, _alpha))
    if _alpha <= 0:
        queue_free()
