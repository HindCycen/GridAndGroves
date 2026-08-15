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
var Rarity: int = 0  # 0 普通 / 1 稀有 / 2 史诗 / 3 传说
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
	part.Heal = data.get("baseHeal", 0)
	part.Exhaust = data.get("exhaust", false)
	part.Description = data.get("description", "")
	if data.has("movingDirection"):
		part.MovingDirection = data["movingDirection"] as Vector2i
	if data.has("partialPosition"):
		part.PartialPosition = data["partialPosition"] as Vector2
	if data.has("spriteTexture"):
		part.SpriteTexture = data["spriteTexture"] as Texture2D
	if data.has("behaviors"):
		# 复制数组，避免同名 Block 实例共享同一 behaviors 数组（运行时修改会互相污染）
		# 且 Behavior 对象本身也需按实例 duplicate()：JSON 扫描时同名 Block 的所有实例
		# 共享同一批 Behavior Resource（含可变状态，如 SporeBurstBehavior 的触发标记），
		# 不复制会导致多实例状态串台
		part.Behaviors = data["behaviors"].map(func(b):
			return b.duplicate() if b is Resource else b
		)
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
	if not (_are_all_parts_in_grid_bounds() and _are_all_cells_free() and _is_center_in_grid_bounds() and _within_root_glyph_limit()):
		return false
	return _passes_behavior_placement_checks()

## 通用放置限制钩子：遍历所有部件的 Behavior，若有 PlacementRestrictionBehavior
## 则调用 check_placement(block) 做额外条件校验（如"只能放中央"）
func _passes_behavior_placement_checks() -> bool:
	for part in _parts:
		for behavior in part.Behaviors:
			if behavior == null:
				continue
			if not behavior.check_placement(self):
				return false
	return true

## 检查驻留 Block（扎根/法阵）是否未超过数量上限
## 上限：扎根 3 个（variant "root"）、法阵 2 个（variant "glyph"）
func _within_root_glyph_limit() -> bool:
	if Faction != BlockFaction.Player:
		return true
	var tree := get_tree()
	if tree == null:
		return true
	var variant := ""
	for part in _parts:
		for behavior in part.Behaviors:
			if behavior is RootBehavior:
				variant = "root"
			elif behavior is GlyphRootBehavior:
				variant = (behavior as GlyphRootBehavior).IsVariant
			if not variant.is_empty():
				break
		if not variant.is_empty():
			break
	if variant.is_empty():
		return true
	return GlyphRootBehavior.can_place_glyph(tree, variant)

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
