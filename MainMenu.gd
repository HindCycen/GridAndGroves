class_name MainMenu extends Node2D

var _continue_btn: Button

func _ready() -> void:
    var btn_container := %ButtonContainer as VBoxContainer
    _continue_btn = _make_button("Continue", _on_continue_pressed)
    btn_container.add_child(_continue_btn)
    btn_container.add_child(_make_button("New Game", _on_new_game_pressed))
    btn_container.add_child(_make_button("Quit", get_tree().quit))
    _continue_btn.disabled = not ResourceLoader.exists("user://savegame.tres")

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
    var stage_scene := load("res://room/StageRoom.tscn") as PackedScene
    var stage: StageRoom = stage_scene.instantiate()
    get_tree().root.add_child(stage)
    queue_free()

func _on_continue_pressed() -> void:
    SaveLoad.load()
    var stage_scene := load("res://room/StageRoom.tscn") as PackedScene
    var stage: StageRoom = stage_scene.instantiate()
    get_tree().root.add_child(stage)
    queue_free()
