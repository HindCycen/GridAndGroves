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
		# 记录当前房间（Continue 恢复现场用）；事件路径为空的内嵌事件已拆分为独立 .tres
		_save_load.Data.CurrentRoomType = Enums.RoomType.Event
		_save_load.Data.CurrentRoomEventPath = EventDefRef.resource_path if EventDefRef != null else ""
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
	_update_health_from_save_load()
	# 事件已结算：禁止再通过地图返回按钮重进本事件
	disable_back_to_stage()
	clear_back_target()
	if _save_load != null and _save_load.Data != null:
		# 当前房间视为已离开：即使此刻退出游戏，Continue 也不会重复触发事件奖励
		_save_load.Data.CurrentRoomType = Enums.RoomType.Stage
		# 事件伤害可能把血量打到 0：必须判死，否则 0 血后 take_damage 直接返回导致无敌
		if _save_load.Data.PlayerCurrentHealth <= 0:
			_on_player_death()
			return
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
		Enums.EventActionType.AddGold:
			data.Gold = maxi(data.Gold + value, 0)
			GameLog.debug("EventRoom: Gold +" + str(value) + " (total: " + str(data.Gold) + ")")
		Enums.EventActionType.RemoveGold:
			data.Gold = maxi(data.Gold - value, 0)
			GameLog.debug("EventRoom: Gold -" + str(value) + " (total: " + str(data.Gold) + ")")
		Enums.EventActionType.AddBlockToDeck:
			var list: Array[String] = data.PlayerDeckBlockNames.duplicate() if data.PlayerDeckBlockNames != null else []
			var pool = PackManager.CurrentCardPool
			for i in value:
				var picked: String = pool.get_random_block_name() if pool != null else ""
				if picked.is_empty() or not BlockRegistry.BlockDefs.has(picked):
					GameLog.warn("EventRoom: AddBlockToDeck skipped (no valid block in current card pool)")
					continue
				list.append(picked)
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

## 事件伤害致死：结束本局并进入 GameOver（与战斗战败一致）
func _on_player_death() -> void:
	SaveLoad.RunEnded = true
	PackManager.clear_card_pool()
	GameLog.info("\n=== Defeat! Player died from an event ===")
	disable_back_to_stage()
	if _button_container != null:
		for child in _button_container.get_children():
			child.queue_free()
	var timer := get_tree().create_timer(1.5)
	timer.timeout.connect(func():
		if not is_instance_valid(self):
			return
		if _save_load != null:
			_save_load.save()
		var game_over_scene := load("res://GameOver.tscn") as PackedScene
		var game_over: Node = game_over_scene.instantiate()
		get_tree().root.add_child(game_over)
		queue_free()
	)

func _go_back_to_stage() -> void:
	clear_back_target()
	if _save_load != null:
		_save_load.save()
	var stage_scene := load("res://room/StageRoom.tscn") as PackedScene
	var stage: StageRoom = stage_scene.instantiate()
	get_tree().root.add_child(stage)
	queue_free()
