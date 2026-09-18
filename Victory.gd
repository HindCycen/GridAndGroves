class_name Victory extends Node2D

## 通关结算画面：显示本局统计（层数/房间/金币/击杀/卡组规模）
## 由 ShopRoom 在最终层 Boss 战后调用；进入时存档已删除（RunEnded = true）

func _ready() -> void:
	var data: DataResource = SaveLoad.Data
	var stage_count: int = data.StageCount if data != null else 0
	var room_count: int = data.RoomCount if data != null else 0
	var gold: int = data.Gold if data != null else 0
	var kills: int = data.KillCount if data != null else 0
	var deck_size: int = data.PlayerDeckBlockNames.size() if data != null and data.PlayerDeckBlockNames != null else 0
	var stats_label := %StatsLabel as Label
	stats_label.text = "抵达层数：Stage " + str(stage_count) + "\n" \
		+ "探索房间：" + str(room_count) + "\n" \
		+ "剩余金币：" + str(gold) + "\n" \
		+ "击败敌人：" + str(kills) + "\n" \
		+ "最终卡组：" + str(deck_size) + " 张"
	var btn := %ReturnButton as Button
	btn.pressed.connect(_on_return_pressed)

func _on_return_pressed() -> void:
	var menu_scene := load("res://MainMenu.tscn") as PackedScene
	var menu: Node = menu_scene.instantiate()
	get_tree().root.add_child(menu)
	queue_free()
