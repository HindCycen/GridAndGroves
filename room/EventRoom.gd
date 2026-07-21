class_name EventRoom extends Room

var _active_tooltips: Array[TooltipComponent] = []
var _button_container: HBoxContainer
var _desc_label: RichTextLabel
var _phase: int
@export var EventDefRef: EventDef

func _ready() -> void:
	super()
	_save_load = get_tree().root.get_node("SaveLoad")
	if _save_load != null and _save_load.Data != null:
		_save_load.Data.RoomCount += 1
	_show_event_phase1()

func _show_event_phase1() -> void:
	_phase = 1
	_desc_label = %DescLabel as RichTextLabel
	if _desc_label != null:
		_desc_label.visible = true
		_desc_label.text = EventDefRef.EventDesc if EventDefRef != null else ""
	_button_container = %ButtonContainer as HBoxContainer
	if _button_container != null:
		_button_container.visible = true
	if EventDefRef == null or EventDefRef.Choices == null:
		return
	var choice_count := EventDefRef.Choices.size()
	for choice in EventDefRef.Choices:
		var btn := Button.new()
		btn.text = choice.Name
		btn.set_size(Vector2(1320.0 / choice_count - 20, 80))
		btn.add_theme_font_size_override("font_size", 20)
		var captured_desc: String = choice.Description
		btn.mouse_entered.connect(func():
			var tooltip := TooltipComponent.new()
			add_child(tooltip)
			tooltip.show(btn.global_position + Vector2(0, -100), captured_desc)
			_active_tooltips.append(tooltip)
		)
		btn.mouse_exited.connect(func():
			for t in _active_tooltips:
				if is_instance_valid(t):
					t.hide()
					t.queue_free()
			_active_tooltips.clear()
		)
		var captured_choice: EventChoiceDef = choice
		btn.pressed.connect(func(): _on_choice_selected(captured_choice))
		_button_container.add_child(btn)

func _on_choice_selected(choice: EventChoiceDef) -> void:
	if _phase != 1:
		return
	_execute_action(choice.ActionType, choice.ActionValue)
	_phase = 2
	if _desc_label != null:
		_desc_label.text = choice.ResultDescription
	if _button_container != null:
		for child in _button_container.get_children():
			child.queue_free()
		var continue_btn := Button.new()
		continue_btn.text = "Continue"
		continue_btn.set_size(Vector2(200, 80))
		continue_btn.add_theme_font_size_override("font_size", 24)
		continue_btn.pressed.connect(_on_continue)
		_button_container.add_child(continue_btn)

func _execute_action(type: int, value: int) -> void:
	var data: DataResource = _save_load.Data if _save_load != null else null
	if data == null:
		return
	match type:
		Enums.EventActionType.HealPlayer:
			data.PlayerCurrentHealth = mini(data.PlayerCurrentHealth + value, data.PlayerMaxHealth)
		Enums.EventActionType.DamagePlayer:
			data.PlayerCurrentHealth = maxi(data.PlayerCurrentHealth - value, 0)
		Enums.EventActionType.AddBlockToDeck:
			var list: Array[String] = data.PlayerDeckBlockNames.duplicate() if data.PlayerDeckBlockNames != null else []
			for i in value:
				list.append("DamageBlock")
			data.PlayerDeckBlockNames = list
		Enums.EventActionType.RemoveBlockFromDeck:
			if data.PlayerDeckBlockNames != null and data.PlayerDeckBlockNames.size() > 0:
				var list := data.PlayerDeckBlockNames.duplicate()
				var remove_count := mini(value, list.size())
				for i in remove_count:
					list.remove_at(list.size() - 1)
				data.PlayerDeckBlockNames = list

func _on_continue() -> void:
	_go_back_to_stage()

func _go_back_to_stage() -> void:
	if _save_load != null:
		_save_load.save()
	var stage_scene := load("res://room/StageRoom.tscn") as PackedScene
	var stage: StageRoom = stage_scene.instantiate()
	get_tree().root.add_child(stage)
	queue_free()
