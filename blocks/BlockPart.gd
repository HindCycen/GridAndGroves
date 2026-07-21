class_name BlockPart extends Node2D

signal pressed(n)
signal released(n)

var _detecting_area := Area2D.new()
var _detecting_collision_shape := CollisionShape2D.new()
var _sprite2d := Sprite2D.new()
var _tooltip_component: TooltipComponent

@export var PartDefinition: BlockPartDef

var Damage: int
var Shield: int
var MagicNum: int

func _ready() -> void:
	var shape2d := RectangleShape2D.new()
	shape2d.size = Vector2(96, 96)
	_detecting_collision_shape.shape = shape2d
	if PartDefinition != null and PartDefinition.SpriteTexture != null:
		_sprite2d.texture = PartDefinition.SpriteTexture
	_detecting_area.add_child(_detecting_collision_shape)
	_detecting_area.add_child(_sprite2d)
	add_child(_detecting_area)
	_detecting_area.input_event.connect(func(_viewport, event, _shape_idx):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				pressed.emit(self)
			else:
				released.emit(self)
	)
	_detecting_area.mouse_entered.connect(_on_mouse_entered)
	_detecting_area.mouse_exited.connect(_on_mouse_exited)
	_tooltip_component = TooltipComponent.new()
	add_child(_tooltip_component)
	Damage = PartDefinition.BaseDamage if PartDefinition != null else 0
	Shield = PartDefinition.BaseShield if PartDefinition != null else 0
	MagicNum = PartDefinition.BaseMagicNum if PartDefinition != null else 0
	if PartDefinition != null:
		position = PartDefinition.PartialPosition * 96
	set_process_input(true)

func _on_mouse_entered() -> void:
	var parent := get_parent()
	if parent is not Block:
		return
	var block := parent as Block
	if block.Definition == null or block.IsPressed:
		return
	var text := block.Definition.BlockName
	if not block.Definition.Description.is_empty():
		text += "\n" + block.Definition.Description
	if PartDefinition != null and not PartDefinition.Description.is_empty():
		text += "\n" + PartDefinition.Description
	if text.is_empty():
		return
	var placeholders := { "S": str(Shield), "D": str(Damage), "M": str(MagicNum) }
	text = _tooltip_component.process_text(text, placeholders)
	_tooltip_component.show(global_position, text)

func _on_mouse_exited() -> void:
	_tooltip_component.hide()
