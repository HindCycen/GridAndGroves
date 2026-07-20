class_name GridPart extends Node2D
## 运行时部件 — Grid 中的单个格子
##
## 由 Grid.setup_from_def() 根据 GridPartSlotDef 自动创建。
## 每个部件包含 Sprite2D（贴图）、Label（数值）、Area2D（碰撞/交互）。
## 碰撞和鼠标交互由每个部件独立管理，以支持不规则形状的 Grid。

const _GridPartBehavior = preload("res://resources/grid_part_behaviors/grid_part_behavior.gd")
const _GridDefLoader = preload("res://resources/grid_defs/grid_def_loader.gd")

## 每个格子的像素大小（后续可参数化到全局常量）
const CELL_SIZE: float = 96.0

## 此部件对应的槽位定义
var slot_def: GridPartSlotDef

## 拖拽信号 — 由 Area2D 的鼠标事件触发，Grid 父节点监听
signal drag_started
signal drag_ended

## 缓存的行为实例（延迟创建）
var _behavior = null

func _ready() -> void:
	# 连接 Area2D 的鼠标输入事件
	var area: Area2D = $Area2D
	if area and not area.input_event.is_connected(_on_area_input):
		area.input_event.connect(_on_area_input)
		area.mouse_entered.connect(_on_mouse_entered)
		area.mouse_exited.connect(_on_mouse_exited)

## 根据槽位定义设置部件外观、数据和碰撞
func setup_from_slot_def(def: GridPartSlotDef) -> void:
	slot_def = def

	# 设置位置（相对于父节点 Grid，按格子坐标换算）
	position = Vector2(def.position) * CELL_SIZE

	# 设置贴图
	var sprite: Sprite2D = $Sprite
	if sprite:
		var picture = GridLibrary.get_picture(def.picture_id)
		if picture and picture.texture:
			sprite.texture = picture.texture

	# 设置数值标签
	var label: Label = $Label
	if label:
		var text_parts := []
		if def.damage > 0:
			text_parts.append(str(def.damage))
		if def.shield > 0:
			text_parts.append("[" + str(def.shield) + "]")
		label.text = " ".join(text_parts)

	# 设置碰撞形状尺寸（每格占满一个 CELL_SIZE × CELL_SIZE）
	_setup_collision()

func _on_area_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			drag_started.emit()
		else:
			drag_ended.emit()

func _on_mouse_entered() -> void:
	# 鼠标进入部件区域时的悬停效果（后续可加高亮等）
	pass

func _on_mouse_exited() -> void:
	# 鼠标离开部件区域
	pass

## 设置碰撞区域的形状和尺寸
func _setup_collision() -> void:
	var area: Area2D = $Area2D
	if not area:
		return

	var shape_node: CollisionShape2D = area.get_node("CollisionShape2D")
	if not shape_node:
		return

	# 确保形状是 RectangleShape2D 并设置尺寸
	var rect: RectangleShape2D
	if shape_node.shape is RectangleShape2D:
		rect = shape_node.shape
	else:
		rect = RectangleShape2D.new()
		shape_node.shape = rect

	rect.size = Vector2(CELL_SIZE, CELL_SIZE)

## 获取行为实例（懒加载）
func get_behavior():
	if _behavior == null and slot_def and not slot_def.behavior_id.is_empty():
		_behavior = _GridDefLoader.instantiate_behavior(slot_def.behavior_id)
	return _behavior

## 触发放置回调
func notify_place() -> void:
	var b = get_behavior()
	if b:
		b.on_place(self)

## 触发射击回调
func notify_resolve() -> void:
	var b = get_behavior()
	if b:
		b.on_resolve(self)

## 触发弃掉回调
func notify_discard() -> void:
	var b = get_behavior()
	if b:
		b.on_discard(self)
