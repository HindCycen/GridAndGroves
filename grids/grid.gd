class_name Grid extends Node2D
## 运行时方块 — 可被拖拽放置到网格上
##
## 由 GridDef 定义其部件组成，运行时动态创建 GridPart 子节点。
## 每个 GridPart 各自管理自己的碰撞和鼠标交互。
## Grid 负责管理部件的生命周期和整体拖拽行为。

## 此方块对应的数据定义
@export var grid_def: GridDef
## 运行时部件列表
var parts: Array = []  # Array[GridPart]
## 当前是否被拖拽中
var is_dragging: bool = false

var _drag_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	# 默认不处理 _process，拖拽时再开启
	set_process(false)

func _process(_delta: float) -> void:
	if is_dragging:
		global_position = get_global_mouse_position() - _drag_offset

func _input(event: InputEvent) -> void:
	# 拖拽中：鼠标在任意位置松开都结束拖拽
	if is_dragging and event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and not event.pressed:
		_end_drag()

## 根据 GridDef 构建方块
func setup_from_def(def: GridDef) -> void:
	grid_def = def

	# 清除旧部件
	for part in parts:
		if is_instance_valid(part):
			part.queue_free()
	parts.clear()

	# 根据定义创建新部件
	var part_scene := preload("res://grids/grid_part.tscn")
	for slot_def in def.parts:
		var part = part_scene.instantiate()
		part.setup_from_slot_def(slot_def)
		add_child(part)
		# 连接拖拽信号（add_child 后 _ready 已执行，信号已就绪）
		if not part.drag_started.is_connected(_on_part_drag_started):
			part.drag_started.connect(_on_part_drag_started)
		if not part.drag_ended.is_connected(_on_part_drag_ended):
			part.drag_ended.connect(_on_part_drag_ended)
		parts.append(part)

## 某个部件上鼠标按下 → 开始拖拽整个 Grid
func _on_part_drag_started() -> void:
	if is_dragging:
		return
	is_dragging = true
	_drag_offset = get_global_mouse_position() - global_position
	set_process(true)

	# 将 Grid 移到兄弟节点的最上层（视觉置顶）
	var parent := get_parent()
	if parent:
		parent.move_child(self, parent.get_child_count() - 1)

## 部件鼠标松开 → 结束拖拽
func _on_part_drag_ended() -> void:
	_end_drag()

## 统一的拖拽结束处理
func _end_drag() -> void:
	if not is_dragging:
		return
	is_dragging = false
	set_process(false)
	# TODO: 吸附到网格位置，或回到手牌区
