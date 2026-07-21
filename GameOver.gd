class_name GameOver extends Node2D

func _ready() -> void:
    var data: DataResource = SaveLoad.Data
    var stage_count: int = data.StageCount if data != null else 1
    var room_count: int = data.RoomCount if data != null else 0
    var stats_label := %StatsLabel as Label
    stats_label.text = "Stage: " + str(stage_count) + "    Room: " + str(room_count)
    var btn := %ReturnButton as Button
    btn.pressed.connect(func():
        var menu_scene := load("res://MainMenu.tscn") as PackedScene
        var menu: Node = menu_scene.instantiate()
        get_tree().root.add_child(menu)
        queue_free()
    )
