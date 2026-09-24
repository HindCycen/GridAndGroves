class_name BlockPart extends Node2D

signal pressed(n)
signal released(n)

var _detecting_area := Area2D.new()
var _detecting_collision_shape := CollisionShape2D.new()
var _sprite2d := Sprite2D.new()
var _tooltip_component: TooltipComponent

var PartId: String
var Description: String
var MovingDirection: Vector2i
var PartialPosition: Vector2
var Behaviors: Array = []
var SpriteTexture: Texture2D
var Damage: int
var Shield: int
var Heal: int
var MagicNum: int
var Exhaust: bool = false  # 一次性：触发后立即移出战斗（Bot 检测此标记）
var IsSpent: bool = false  # 已离场（松动落场）：隐藏且不再被 Bot 触发/占格

func _ready() -> void:
	var shape2d := RectangleShape2D.new()
	shape2d.size = Vector2(96, 96)
	_detecting_collision_shape.shape = shape2d
	if SpriteTexture != null:
		_sprite2d.texture = SpriteTexture
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
	position = PartialPosition * 96
	set_process_input(true)

func _on_mouse_entered() -> void:
	var parent := get_parent()
	if parent is not Block:
		return
	var block := parent as Block
	if block.BlockName.is_empty() or block.IsPressed:
		return
	var text := block.BlockName
	if not block.Description.is_empty():
		text += "\n" + block.Description
	if not Description.is_empty():
		text += "\n" + Description
	if text.is_empty():
		return
	var placeholders := { "S": str(Shield), "D": str(Damage), "M": str(MagicNum) }
	text = _tooltip_component.process_text(text, placeholders)
	_tooltip_component.show(global_position, text)

func _on_mouse_exited() -> void:
	_tooltip_component.hide()

## 标记该部件离场（松动落场）：隐藏自身并禁用交互与检测
func mark_spent() -> void:
	IsSpent = true
	visible = false
	_detecting_area.input_pickable = false
	if _tooltip_component != null:
		_tooltip_component.hide()

## 复位离场状态（Block 回到手牌重新可用时调用）
func reset_spent() -> void:
	IsSpent = false
	visible = true
	_detecting_area.input_pickable = true
