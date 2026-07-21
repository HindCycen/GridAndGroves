class_name Room extends Node2D

var _health_label: Label
var _save_load: SaveLoad
var _stage_room_label: Label
@export var ShowStatusBar: bool = true

func _ready() -> void:
	_save_load = get_tree().root.get_node("SaveLoad") as SaveLoad
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
