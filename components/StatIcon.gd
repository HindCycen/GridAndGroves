class_name StatIcon extends Control

var _count_label: Label
var _stat: Stat
var _tooltip_component: TooltipComponent

func setup(stat: Stat, icon_size: int) -> void:
    _stat = stat
    custom_minimum_size = Vector2(icon_size, icon_size)
    size = Vector2(icon_size, icon_size)
    var icon_rect := TextureRect.new()
    icon_rect.texture = stat.Definition.Icon
    icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
    icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon_rect.size = Vector2(icon_size, icon_size)
    icon_rect.position = Vector2.ZERO
    icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(icon_rect)
    _count_label = Label.new()
    _count_label.text = str(stat.CurrentValue)
    _count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    _count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
    _count_label.size = Vector2(icon_size, icon_size)
    _count_label.position = Vector2.ZERO
    _count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _count_label.add_theme_color_override("font_color", Color.WHITE)
    add_child(_count_label)
    _tooltip_component = TooltipComponent.new()
    add_child(_tooltip_component)
    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)
    stat.value_changed.connect(_on_value_changed)

func _on_mouse_entered() -> void:
    if _stat == null or _stat.Definition == null:
        return
    var placeholders := { "N": str(_stat.CurrentValue) }
    var text := ""
    if not _stat.Definition.StatName.is_empty():
        text = _stat.Definition.StatName
    if not _stat.Definition.Description.is_empty():
        text += "\n" + _stat.Definition.Description
    text = _tooltip_component.process_text(text, placeholders)
    _tooltip_component.show(global_position, text)

func _on_mouse_exited() -> void:
    _tooltip_component.hide()

func _on_value_changed(current: int, _max: int) -> void:
    _count_label.text = str(current)

func detach() -> void:
    if _stat != null and _stat.value_changed.is_connected(_on_value_changed):
        _stat.value_changed.disconnect(_on_value_changed)
    if mouse_entered.is_connected(_on_mouse_entered):
        mouse_entered.disconnect(_on_mouse_entered)
    if mouse_exited.is_connected(_on_mouse_exited):
        mouse_exited.disconnect(_on_mouse_exited)
