class_name Block extends Node2D

signal left_grid(block)
signal placed(block)

enum BlockFaction { Player, Enemy }

static var InputLocked: bool

var _parts: Array[BlockPart] = []
var _ghost_sprites: Array[Sprite2D] = []
var _was_on_grid: bool

var BlockName: String
var Description: String
var PartDatas: Array = []  # Array of Dictionaries (raw JSON part data)
var Faction: int = BlockFaction.Player
var IsPlaced: bool
var IsPressed: bool
var OriginalPos: Vector2

func get_parts() -> Array[BlockPart]:
	return _parts.duplicate()

func _ready() -> void:
	OriginalPos = global_position
	_load_parts()
	_create_ghost_sprites()

func _process(_delta: float) -> void:
	if IsPressed and not InputLocked and Faction == BlockFaction.Player:
		global_position = get_global_mouse_position()
		_update_ghost()

func _load_parts() -> void:
	if PartDatas.size() == 0:
		return
	for data in PartDatas:
		var part := _create_part(data)
		_wire_part_press_events(part)

func _create_part(data: Dictionary) -> BlockPart:
	var part := BlockPart.new()
	part.PartId = data.get("partId", "")
	part.Damage = data.get("baseDamage", 0)
	part.MagicNum = data.get("baseMagicNum", 0)
	part.Shield = data.get("baseShield", 0)
	part.Description = data.get("description", "")
	if data.has("movingDirection"):
		part.MovingDirection = data["movingDirection"] as Vector2i
	if data.has("partialPosition"):
		part.PartialPosition = data["partialPosition"] as Vector2
	if data.has("spriteTexture"):
		part.SpriteTexture = data["spriteTexture"] as Texture2D
	if data.has("behaviors"):
		part.Behaviors = data["behaviors"]
	_parts.append(part)
	add_child(part)
	return part

func _wire_part_press_events(part: BlockPart) -> void:
	part.pressed.connect(_on_part_pressed)
	part.released.connect(_on_part_released)

func _on_part_pressed(n: Node) -> void:
	if not _parts.has(n) or InputLocked or Faction != BlockFaction.Player:
		return
	IsPressed = true
	if IsPlaced:
		_was_on_grid = true
		_lift_from_grid()

func _on_part_released(n: Node) -> void:
	if not _parts.has(n) or InputLocked or Faction != BlockFaction.Player:
		return
	IsPressed = false
	_hide_ghost()
	if _check_placement_conditions():
		_finalize_placement()
	elif _was_on_grid:
		_was_on_grid = false
		left_grid.emit(self)
	else:
		global_position = OriginalPos

func _check_placement_conditions() -> bool:
	return _are_all_parts_in_grid_bounds() and _are_all_cells_free() and _is_center_in_grid_bounds()

func _finalize_placement() -> void:
	global_position = GridState.find_nearest_grid_point(global_position)
	_occupy_all_part_grids()
	_was_on_grid = false
	OriginalPos = global_position
	IsPlaced = true
	add_to_group("placed_blocks")
	placed.emit(self)

func _occupy_all_part_grids() -> void:
	for part in _parts:
		var grid_point: Vector2 = GridState.find_nearest_grid_point(part.global_position)
		var grid_index: Vector2i = GridState.get_grid_coords(grid_point)
		if grid_index.x >= 0 and grid_index.y >= 0:
			GridState.set_grid_state(grid_index.x, grid_index.y, Enums.GridStateEnum.Occupied)

func _lift_from_grid() -> void:
	for part in _parts:
		var grid_point: Vector2 = GridState.find_nearest_grid_point(part.global_position)
		var grid_index: Vector2i = GridState.get_grid_coords(grid_point)
		if grid_index.x >= 0 and grid_index.y >= 0:
			GridState.set_grid_state(grid_index.x, grid_index.y, Enums.GridStateEnum.Free)
	IsPlaced = false
	remove_from_group("placed_blocks")

func _are_all_parts_in_grid_bounds() -> bool:
	for part in _parts:
		if not GridState.is_point_in_grid(part.global_position):
			return false
	return true

func _are_all_cells_free() -> bool:
	for part in _parts:
		var nearest: Vector2 = GridState.find_nearest_grid_point(part.global_position)
		if not GridState.is_point_in_grid(nearest):
			return false
		var grid_index: Vector2i = GridState.get_grid_coords(nearest)
		if grid_index.x < 0 or grid_index.x > 6 or grid_index.y < 0 or grid_index.y > 4:
			return false
		if GridState.GridStates[grid_index.x][grid_index.y] != Enums.GridStateEnum.Free:
			return false
	return true

func _is_center_in_grid_bounds() -> bool:
	return GridState.is_point_in_grid(global_position)

func _create_ghost_sprites() -> void:
	for part in _parts:
		var ghost := Sprite2D.new()
		if part.SpriteTexture != null:
			ghost.texture = part.SpriteTexture
		ghost.modulate = Color(1, 1, 1, 0.5)
		ghost.z_index = -1
		ghost.position = part.position
		ghost.visible = false
		add_child(ghost)
		_ghost_sprites.append(ghost)

func _update_ghost() -> void:
	if _check_placement_conditions():
		_show_ghost_at_snapped_position()
	else:
		_hide_ghost()

func _show_ghost_at_snapped_position() -> void:
	var snapped_center := GridState.find_nearest_grid_point(global_position)
	for i in _ghost_sprites.size():
		var ghost := _ghost_sprites[i]
		var part := _parts[i]
		ghost.global_position = snapped_center + part.PartialPosition * 96
		ghost.visible = true

func _hide_ghost() -> void:
	for ghost in _ghost_sprites:
		ghost.visible = false

func place_at_grid(coords: Vector2i) -> void:
	if coords.x < 0 or coords.x >= 7 or coords.y < 0 or coords.y >= 5:
		return
	var center_pos: Vector2 = GridState.get_grid_pos(coords)
	global_position = center_pos
	for part in _parts:
		var grid_point: Vector2 = GridState.find_nearest_grid_point(part.global_position)
		var grid_index: Vector2i = GridState.get_grid_coords(grid_point)
		if grid_index.x >= 0 and grid_index.y >= 0:
			GridState.set_grid_state(grid_index.x, grid_index.y, Enums.GridStateEnum.Occupied)
	OriginalPos = global_position
	IsPlaced = true
	placed.emit(self)
