extends Node

func _ready() -> void:
	init_grids()

var GridLeftUp := Vector2(2, 4) * 120
var GridRightDown := Vector2(7.6, 8) * 120
var UnlockedRows := [false, false, false, false, false]
var UnlockedCols := [false, false, false, false, false, false, false]
var GridPoints: Array[Array] = []
var GridStates: Array[Array] = []

func is_point_in_grid(point: Vector2) -> bool:
	return point.x >= GridLeftUp.x and point.x <= GridRightDown.x and point.y >= GridLeftUp.y and point.y <= GridRightDown.y

func find_nearest_grid_point(target_point: Vector2) -> Vector2:
	if GridPoints.is_empty():
		GameLog.err("GridPoints not initialized")
		return Vector2(-1, -1)
	var nearest: Vector2 = GridPoints[0][0]
	var min_dist: float = nearest.distance_squared_to(target_point)
	for col in 7:
		for row in 5:
			var cur: Vector2 = GridPoints[col][row]
			var dist: float = cur.distance_squared_to(target_point)
			if dist < min_dist:
				min_dist = dist
				nearest = cur
	return nearest

func unlock_row(row: int) -> void:
	if row >= 0 and row < UnlockedRows.size():
		UnlockedRows[row] = true

func unlock_col(col: int) -> void:
	if col >= 0 and col < UnlockedCols.size():
		UnlockedCols[col] = true

func is_row_unlocked(row: int) -> bool:
	return row >= 0 and row < UnlockedRows.size() and UnlockedRows[row]

func is_col_unlocked(col: int) -> bool:
	return col >= 0 and col < UnlockedCols.size() and UnlockedCols[col]

func init_unlocked_state() -> void:
	UnlockedRows = [false, true, true, true, false]
	UnlockedCols = [false, true, true, true, true, true, false]

func init_grids() -> void:
	init_unlocked_state()
	init_occupy_state()

func init_occupy_state() -> void:
	GridPoints.clear()
	GridStates.clear()
	for col in 7:
		GridPoints.append([])
		GridStates.append([])
		for row in 5:
			var pt := Vector2(col * 96, row * 96) + Vector2(2 * 120 + 48, 4 * 120 + 48)
			GridPoints[col].append(pt)
			var state: Enums.GridStateEnum = Enums.GridStateEnum.Free if (is_row_unlocked(row) and is_col_unlocked(col)) else Enums.GridStateEnum.Unable
			GridStates[col].append(state)

func get_grid_coords(point: Vector2) -> Vector2i:
	for col in 7:
		for row in 5:
			if GridPoints[col][row] == point:
				return Vector2i(col, row)
	return Vector2i(-1, -1)

func get_grid_pos(coords: Vector2i) -> Vector2:
	if coords.x >= 0 and coords.x < 7 and coords.y >= 0 and coords.y < 5:
		return GridPoints[coords.x][coords.y]
	GameLog.err("Invalid coordinates")
	return Vector2.ZERO

func set_grid_state(col: int, row: int, state: Enums.GridStateEnum) -> void:
	if col >= 0 and col < 7 and row >= 0 and row < 5:
		GridStates[col][row] = state

func restore_grid_state(col: int, row: int) -> void:
	if col >= 0 and col < 7 and row >= 0 and row < 5:
		GridStates[col][row] = Enums.GridStateEnum.Free if (is_row_unlocked(row) and is_col_unlocked(col)) else Enums.GridStateEnum.Unable

func get_grid_state(col: int, row: int) -> Enums.GridStateEnum:
	if col >= 0 and col < 7 and row >= 0 and row < 5:
		return GridStates[col][row]
	return Enums.GridStateEnum.Unable
