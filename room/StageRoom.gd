class_name StageRoom extends Room

const Cols := 14
const Rows := 7
const CellSize := 96
static var Current: StageRoom

var Clickable: Array[Array] = []
var Left: Array[Array] = []
var IsBattleCell: Array[Array] = []
var MapGenerated: bool
var _cells: Array[Array] = []
var _flash_tween: Tween
var _grid_container: Node2D
var _initialized: bool
var _pulse_time: float
var _pulsing_cells: Array = []

@export var StageDefRef: StageDef

func _ready() -> void:
	super()
	Current = self
	if not MapGenerated:
		var loaded_from_save := _try_restore_map_from_save()
		if not loaded_from_save:
			Clickable = []
			Left = []
			IsBattleCell = []
			for i in Cols:
				Clickable.append([])
				Left.append([])
				IsBattleCell.append([])
				for j in Rows:
					Clickable[i].append(false)
					Left[i].append(false)
					IsBattleCell[i].append(false)
			_generate_map()
			Clickable[0][Rows - 1] = true
			_rebuild_pulsing_cells()
			MapGenerated = true
	_grid_container = %GridContainer as Node2D
	var total_width := Cols * CellSize
	var total_height := Rows * CellSize
	_grid_container.position = Vector2((1920 - total_width) / 2.0, (1080 - total_height) / 2.0)
	_cells = []
	for i in Cols:
		_cells.append([])
		for j in Rows:
			_cells[i].append(null)
	_build_grid_visuals()
	_initialized = true

func _generate_map() -> void:
	var _battle_tex := load("res://room/room_pictures/BattleRoomBn.png")
	var _event_tex := load("res://room/room_pictures/EventRoomBn.png")
	for col in Cols:
		for row in Rows:
			if (col == 0 and row == Rows - 1) or (col == Cols - 1 and row == 0):
				IsBattleCell[col][row] = true
			else:
				IsBattleCell[col][row] = RngManager.get_map_rand(2) == 0
	if _save_load != null and _save_load.Data != null and (_save_load.Data.GridClickable == null or _save_load.Data.GridClickable.size() == 0):
		_save_load.Data.StageCount += 1

func _try_restore_map_from_save() -> bool:
	var data: DataResource = _save_load.Data if _save_load != null else null
	if data == null or data.GridClickable == null or data.GridClickable.size() == 0:
		return false
	if data.GridLeft == null or data.GridLeft.size() == 0:
		return false
	if data.GridIsBattleCell == null or data.GridIsBattleCell.size() == 0:
		return false
	var total_cells := Cols * Rows
	if data.GridClickable.size() != total_cells:
		return false
	Clickable = []
	Left = []
	IsBattleCell = []
	for i in Cols:
		Clickable.append([])
		Left.append([])
		IsBattleCell.append([])
		for j in Rows:
			Clickable[i].append(false)
			Left[i].append(false)
			IsBattleCell[i].append(false)
	for col in Cols:
		for row in Rows:
			var index := col * Rows + row
			Clickable[col][row] = data.GridClickable[index] != 0
			Left[col][row] = data.GridLeft[index] != 0
			IsBattleCell[col][row] = data.GridIsBattleCell[index] != 0
	MapGenerated = true
	return true

func _build_grid_visuals() -> void:
	var battle_tex := load("res://room/room_pictures/BattleRoomBn.png") as Texture2D
	var event_tex := load("res://room/room_pictures/EventRoomBn.png") as Texture2D
	for col in Cols:
		for row in Rows:
			var tex := battle_tex if IsBattleCell[col][row] else event_tex
			var sprite := Sprite2D.new()
			sprite.texture = tex
			sprite.position = Vector2(col * CellSize + CellSize / 2.0, row * CellSize + CellSize / 2.0)
			if Left[col][row]:
				sprite.modulate = Color(1, 1, 1, 0.5)
			elif Clickable[col][row]:
				sprite.modulate = Color(1, 1, 1, 1)
			else:
				sprite.modulate = Color(1, 1, 1)
			_grid_container.add_child(sprite)
			_cells[col][row] = sprite
			var area := Area2D.new()
			area.name = "Cell_" + str(col) + "_" + str(row)
			var shape := CollisionShape2D.new()
			var rect := RectangleShape2D.new()
			rect.size = Vector2(CellSize, CellSize)
			shape.shape = rect
			area.add_child(shape)
			area.position = sprite.position
			var captured_col := col
			var captured_row := row
			area.input_event.connect(func(_viewport, event, _shape_idx):
				if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
					_on_cell_clicked(captured_col, captured_row)
			)
			_grid_container.add_child(area)

func _rebuild_pulsing_cells() -> void:
	_pulsing_cells.clear()
	for col in Cols:
		for row in Rows:
			if Clickable[col][row] and not Left[col][row]:
				_pulsing_cells.append({"col": col, "row": row})

func _process(delta: float) -> void:
	if not _initialized:
		return
	_pulse_time += delta
	var alpha := 0.3 + 0.7 * (sin(_pulse_time * PI * 2) + 1) / 2
	for cell in _pulsing_cells:
		var c := cell as Dictionary
		var col: int = c["col"]
		var row: int = c["row"]
		var sprite: Sprite2D = _cells[col][row]
		if sprite != null:
			var cur_col := sprite.modulate
			sprite.modulate = Color(cur_col.r, cur_col.g, cur_col.b, alpha)

func _on_cell_clicked(col: int, row: int) -> void:
	if not Clickable[col][row] or Left[col][row]:
		return
	if _flash_tween != null and _flash_tween.is_running():
		return
	_flash_tween = create_tween()
	for i in 3:
		_flash_tween.tween_property(_cells[col][row], "modulate:a", 0.0, 0.15)
		_flash_tween.tween_property(_cells[col][row], "modulate:a", 1.0, 0.15)
	_flash_tween.tween_callback(func(): _enter_room(col, row))

func _enter_room(col: int, row: int) -> void:
	Left[col][row] = true
	_cells[col][row].modulate = Color(1, 1, 1, 0.5)
	for c in Cols:
		for r in Rows:
			Clickable[c][r] = false
	if row > 0:
		Clickable[col][row - 1] = true
	if col < Cols - 1:
		Clickable[col + 1][row] = true
	_rebuild_pulsing_cells()
	var is_battle: bool = IsBattleCell[col][row]
	if _save_load != null and _save_load.Data != null and StageDefRef != null:
		_save_load.Data.StageDefPath = StageDefRef.resource_path
	_save_load.save()
	if is_battle:
		var room_count: int = _save_load.Data.RoomCount if _save_load != null and _save_load.Data != null else 0
		var stage_enemy_chart := load("res://resources/EgStageEnemyChart.tres") as StageEnemyChartDef
		var chart_def: EnemyChartDef
		if room_count == 20:
			chart_def = stage_enemy_chart.BossChart[RngManager.get_monster_rand(stage_enemy_chart.BossChart.size())]
		elif room_count > 6:
			chart_def = stage_enemy_chart.StrongEnemyChart[RngManager.get_monster_rand(stage_enemy_chart.StrongEnemyChart.size())]
		else:
			chart_def = stage_enemy_chart.WeakEnemyChart[RngManager.get_monster_rand(stage_enemy_chart.WeakEnemyChart.size())]
		var battle_scene := load("res://room/BattleRoom.tscn") as PackedScene
		var battle := battle_scene.instantiate() as BattleRoom
		battle.EnemyChart = chart_def
		get_tree().root.add_child(battle)
		queue_free()
	else:
		var picked_event: EventDef = null
		if StageDefRef != null and StageDefRef.StageEventRand != null and StageDefRef.StageEventRand.PossibleEvents != null and StageDefRef.StageEventRand.PossibleEvents.size() > 0:
			var idx: int = RngManager.get_map_rand(StageDefRef.StageEventRand.PossibleEvents.size())
			picked_event = StageDefRef.StageEventRand.PossibleEvents[idx]
		else:
			picked_event = load("res://resources/EgHealEvent.tres") as EventDef
		var event_scene := load("res://room/EventRoom.tscn") as PackedScene
		var event_room := event_scene.instantiate() as EventRoom
		event_room.EventDefRef = picked_event
		get_tree().root.add_child(event_room)
		queue_free()
