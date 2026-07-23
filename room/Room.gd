class_name Room extends Node2D

## 非地图房间类型枚举
enum NonStageType { NONE, BATTLE, EVENT }

var _health_label: Label
var _save_load: SaveLoad
var _stage_room_label: Label
var _back_to_stage_btn: TextureButton
var _is_stage_room: bool
@export var ShowStatusBar: bool = true

func _ready() -> void:
	_save_load = get_tree().root.get_node("SaveLoad") as SaveLoad
	_is_stage_room = self is StageRoom
	_setup_back_to_stage_btn()
	if ShowStatusBar:
		var top_bar := get_node("TopBar") as TextureRect
		if top_bar != null:
			top_bar.visible = true
		var heart := get_node("Heart") as TextureRect
		if heart != null:
			heart.visible = true
		_health_label = %HealthLabel as Label
		if _health_label != null:
			_health_label.visible = true
		_stage_room_label = %StageRoomLabel as Label
		if _stage_room_label != null:
			_stage_room_label.visible = true
		_update_stage_room_label()
	_update_health_from_save_load()
	var player := get_tree().get_first_node_in_group("Players") as Player
	if player != null:
		var health := player.get_node_or_null("RenderingComponent/HealthComponent") as HealthComponent
		if health != null:
			health.health_changed.connect(_on_health_changed)
			_update_health_display(health.CurrentHealth, health.MaxHealth)
	_update_stage_room_label()

func _exit_tree() -> void:
	if is_instance_valid(self):
		var player := get_tree().get_first_node_in_group("Players") as Player
		if player != null:
			var health := player.get_node_or_null("RenderingComponent/HealthComponent") as HealthComponent
			if health != null and health.health_changed.is_connected(_on_health_changed):
				health.health_changed.disconnect(_on_health_changed)
	if _save_load != null:
		_save_load.save()

func _update_stage_room_label() -> void:
	if _stage_room_label == null:
		return
	var player: Player = get_tree().get_first_node_in_group("Players") as Player
	var rc: int = player.RoomCount if player != null else (_save_load.Data.RoomCount if _save_load != null and _save_load.Data != null else 0)
	var sc: int = player.StageCount if player != null else (_save_load.Data.StageCount if _save_load != null and _save_load.Data != null else 0)
	_stage_room_label.text = "Stage: " + str(sc) + "    Room: " + str(rc)

func _on_health_changed(current: int, max_val: int) -> void:
	_update_health_display(current, max_val)

func _update_health_from_save_load() -> void:
	if _health_label != null and _save_load != null and _save_load.Data != null:
		_health_label.text = str(_save_load.Data.PlayerCurrentHealth) + "/" + str(_save_load.Data.PlayerMaxHealth)

func _update_health_display(current: int, max_val: int) -> void:
	if _health_label != null:
		_health_label.text = str(current) + "/" + str(max_val)

## 初始化 BackToStage 按钮
func _setup_back_to_stage_btn() -> void:
	_back_to_stage_btn = %BackToStageBtn as TextureButton
	if _back_to_stage_btn == null:
		return
	if _is_stage_room:
		# 在地图房间中：按钮旋转 180 度
		_back_to_stage_btn.rotation = deg_to_rad(180)
		# 没有之前的房间信息时隐藏按钮
		if _save_load != null and _save_load.Data != null and _save_load.Data.LastNonStageRoomType == NonStageType.NONE:
			_back_to_stage_btn.visible = false
		else:
			_back_to_stage_btn.visible = true
		_back_to_stage_btn.pressed.connect(_on_back_to_stage_from_stage)
	else:
		_back_to_stage_btn.rotation = 0.0
		_back_to_stage_btn.pressed.connect(_on_back_to_stage_from_non_stage)

## 从非地图房间（Battle/Event）点击 BackToStage → 回到地图
func _on_back_to_stage_from_non_stage() -> void:
	# 保存当前房间信息，以便从地图返回
	_save_non_stage_room_info()
	# 导航到 StageRoom
	_navigate_to_stage()

## 从地图房间（StageRoom）点击 BackToStage → 回到之前的非地图房间
func _on_back_to_stage_from_stage() -> void:
	if _save_load == null or _save_load.Data == null:
		return
	var data: DataResource = _save_load.Data
	match data.LastNonStageRoomType:
		NonStageType.BATTLE:
			_navigate_to_previous_battle(data)
		NonStageType.EVENT:
			_navigate_to_previous_event(data)
		_:
			# 没有之前的房间信息，不做任何事
			pass

## 保存当前非地图房间信息到存档
func _save_non_stage_room_info() -> void:
	if _save_load == null or _save_load.Data == null:
		return
	var data: DataResource = _save_load.Data
	if self is BattleRoom:
		data.LastNonStageRoomType = NonStageType.BATTLE
		# 保存敌人名称列表
		var enemy_names: Array[String] = []
		var battle := self as BattleRoom
		if battle.EnemyChart != null and battle.EnemyChart.EnemyDefs != null:
			for def in battle.EnemyChart.EnemyDefs:
				var enemy_def := def as EnemyDefinition
				if enemy_def != null:
					enemy_names.append(enemy_def.EnemyName)
		data.LastNonStageRoomEnemyNames = enemy_names
		data.LastNonStageRoomEventDefPath = ""
	elif self is EventRoom:
		data.LastNonStageRoomType = NonStageType.EVENT
		var event := self as EventRoom
		if event.EventDefRef != null:
			data.LastNonStageRoomEventDefPath = event.EventDefRef.resource_path
		else:
			data.LastNonStageRoomEventDefPath = ""
		data.LastNonStageRoomEnemyNames = []

## 导航到 StageRoom
func _navigate_to_stage() -> void:
	_save_load.save()
	var stage_scene := load("res://room/StageRoom.tscn") as PackedScene
	var stage: StageRoom = stage_scene.instantiate()
	get_tree().root.add_child(stage)
	queue_free()

## 导航回之前的战斗房间
func _navigate_to_previous_battle(data: DataResource) -> void:
	# 从保存的敌人名称重建 EnemyChartDef
	var chart_def := EnemyChartDef.new()
	chart_def.EnemyDefs = []
	for enemy_name in data.LastNonStageRoomEnemyNames:
		var enemy_def: EnemyDefinition = BlockRegistry.get_enemy_def(enemy_name)
		if enemy_def != null:
			chart_def.EnemyDefs.append(enemy_def)
		else:
			GameLog.err("BackToStage: Cannot find enemy def [" + enemy_name + "]")
	var battle_scene := load("res://room/BattleRoom.tscn") as PackedScene
	var battle := battle_scene.instantiate() as BattleRoom
	battle.EnemyChart = chart_def
	get_tree().root.add_child(battle)
	queue_free()

## 导航回之前的事件房间
func _navigate_to_previous_event(data: DataResource) -> void:
	var event_def_path := data.LastNonStageRoomEventDefPath
	var event_def: EventDef = null
	if not event_def_path.is_empty():
		event_def = load(event_def_path) as EventDef
	if event_def == null:
		event_def = load("res://resources/EgHealEvent.tres") as EventDef
	var event_scene := load("res://room/EventRoom.tscn") as PackedScene
	var event_room := event_scene.instantiate() as EventRoom
	event_room.EventDefRef = event_def
	get_tree().root.add_child(event_room)
	queue_free()
