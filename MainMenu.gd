class_name MainMenu extends Node2D

const TITLE_LABEL_TEXT := "Grid and Groves"
const SUBTITLE_LABEL_TEXT := "A Roguelike Deckbuilder"

var _continue_btn: Button
var _main_menu_container: VBoxContainer
var _pack_select_panel: VBoxContainer
var _pack_info_label: Label
var _mini_pack_label: Label
var _start_btn: Button
var _selected_main_pack: String = ""

func _ready() -> void:
	var btn_container := %ButtonContainer as VBoxContainer
	_main_menu_container = btn_container
	_continue_btn = _make_button("Continue", _on_continue_pressed)
	btn_container.add_child(_continue_btn)
	btn_container.add_child(_make_button("New Game", _on_new_game_pressed))
	btn_container.add_child(_make_button("Quit", get_tree().quit))
	_continue_btn.disabled = not ResourceLoader.exists("user://savegame.tres")
	_setup_pack_select()

## 卡包选择面板：主卡包 3 选 1 → 系统随机 4 个小卡包 → 开始冒险
## （balance.md：选择 1 个主卡包 + 系统随机抽 4 个小卡包）
func _setup_pack_select() -> void:
	_pack_select_panel = %PackSelectPanel as VBoxContainer
	if _pack_select_panel == null:
		return
	_pack_select_panel.visible = false
	_pack_info_label = %PackInfoLabel as Label
	_mini_pack_label = %MiniPackLabel as Label
	_start_btn = %StartGameBtn as Button
	if _start_btn != null:
		_start_btn.pressed.connect(_on_start_game_pressed)
		_start_btn.disabled = true
	# 主包按钮（PackManager._ready 已自动注册全部卡包）
	for pack_name in PackManager.BlockPacks.keys():
		var btn := _make_button(pack_name, func(): _on_pack_selected(pack_name))
		_pack_select_panel.add_child(btn)

func _make_button(text: String, action: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.size = Vector2(300, 60)
	btn.custom_minimum_size = Vector2(300, 60)
	btn.add_theme_font_size_override("font_size", 22)
	btn.pressed.connect(action)
	return btn

func _on_new_game_pressed() -> void:
	SaveLoad.reset_for_new_game()
	_show_pack_select()

func _show_pack_select() -> void:
	if _main_menu_container != null:
		_main_menu_container.visible = false
	if _pack_select_panel != null:
		_pack_select_panel.visible = true

func _on_continue_pressed() -> void:
	SaveLoad.load()
	if not PackManager.restore_card_pool_from_save():
		# 旧存档缺少卡池信息时回退：注册第一个主包，保证老存档可继续
		GameLog.warn("MainMenu: Save has no card pool info, falling back to first block pack")
		var first_pack: String = PackManager.BlockPacks.keys()[0] if not PackManager.BlockPacks.is_empty() else ""
		if not first_pack.is_empty():
			PackManager.build_card_pool(first_pack)
	_enter_stage()

func _on_pack_selected(pack_name: String) -> void:
	if SaveLoad.Data == null:
		return
	if not PackManager.build_card_pool(pack_name):
		GameLog.err("MainMenu: Failed to build card pool for pack '" + pack_name + "'")
		return
	_selected_main_pack = pack_name
	if _pack_info_label != null:
		_pack_info_label.text = "主卡包：" + pack_name
	if _mini_pack_label != null:
		var mini_names: Array[String] = []
		for p in PackManager.CurrentCardPool.SelectedMiniPacks:
			if p != null:
				mini_names.append(p.PackName)
		_mini_pack_label.text = "小卡包：" + "、".join(mini_names) + "\n卡池规模：" + str(PackManager.CurrentCardPool.Count) + " 个 Block"
	if _start_btn != null:
		_start_btn.disabled = false

func _on_start_game_pressed() -> void:
	if _selected_main_pack.is_empty():
		return
	_enter_stage()

func _enter_stage() -> void:
	var stage_scene := load("res://room/StageRoom.tscn") as PackedScene
	var stage: StageRoom = stage_scene.instantiate()
	get_tree().root.add_child(stage)
	queue_free()