extends Node2D
## Grid 系统测试脚本
##
## 程序化创建多个不同形状的 Grid，测试：
## - 部件渲染（贴图 + 数值标签）
## - 碰撞区域（每个部件独立）
## - 鼠标拖拽（点击任意部件拖拽整个 Grid）
## - 行为系统（DamageBehavior / ShieldBehavior）

func _ready() -> void:
	# 诊断：检查 GridLibrary 图片加载情况
	for id in ["attack_g", "shield_b", "shield_g", "blank_g"]:
		var pic = GridLibrary.get_picture(id)
		if pic:
			print("  [诊断] 图片 '", id, "': ", "有纹理" if pic.texture else "无纹理")
		else:
			print("  [诊断] 图片 '", id, "': 未找到")
	
	_run_test()

func _run_test() -> void:
	print("=== Grid 系统测试开始 ===")

	# ── 测试 1：L 形（2×2 缺一角） ──
	_create_test_grid("L 形 Grid", [
		{ "pos": Vector2i(0, 0), "damage": 6, "shield": 0, "behavior": "DamageBehavior" },
		{ "pos": Vector2i(1, 0), "damage": 6, "shield": 0, "behavior": "DamageBehavior" },
		{ "pos": Vector2i(0, 1), "damage": 0, "shield": 5, "behavior": "ShieldBehavior" },
	], Vector2(200, 250))

	# ── 测试 2：直线 3 格 ──
	_create_test_grid("直线 Grid", [
		{ "pos": Vector2i(0, 0), "damage": 3, "shield": 0, "behavior": "DamageBehavior" },
		{ "pos": Vector2i(1, 0), "damage": 3, "shield": 0, "behavior": "DamageBehavior" },
		{ "pos": Vector2i(2, 0), "damage": 3, "shield": 0, "behavior": "DamageBehavior" },
	], Vector2(200, 450))

	# ── 测试 3：2×2 方块 ──
	_create_test_grid("2×2 方块 Grid", [
		{ "pos": Vector2i(0, 0), "damage": 4, "shield": 0, "behavior": "DamageBehavior" },
		{ "pos": Vector2i(1, 0), "damage": 4, "shield": 0, "behavior": "DamageBehavior" },
		{ "pos": Vector2i(0, 1), "damage": 0, "shield": 4, "behavior": "ShieldBehavior" },
		{ "pos": Vector2i(1, 1), "damage": 0, "shield": 4, "behavior": "ShieldBehavior" },
	], Vector2(550, 250))

	# ── 测试 4：单格（1×1） ──
	_create_test_grid("单格 Grid", [
		{ "pos": Vector2i(0, 0), "damage": 10, "shield": 0, "behavior": "DamageBehavior" },
	], Vector2(550, 450))

	print("=== Grid 系统测试完成 ===")
	print("提示：尝试拖拽任意 Grid，观察是否跟随鼠标。")

func _create_test_grid(grid_name: String, parts_data: Array, pos: Vector2) -> void:
	var def := GridDef.new()
	def.id = "test_" + grid_name
	def.display_name = grid_name

	var slots: Array[GridPartSlotDef] = []
	for data in parts_data:
		var slot := GridPartSlotDef.new()
		slot.position = data["pos"] if data.has("pos") else Vector2i(0, 0)
		slot.damage = data.get("damage", 0)
		slot.shield = data.get("shield", 0)
		slot.magic_number = data.get("magic_number", 0)
		slot.behavior_id = data.get("behavior", "")
		# 根据行为选择贴图（使用有颜色分类的图片）
		if slot.behavior_id == "DamageBehavior":
			slot.picture_id = "attack_g"
		elif slot.behavior_id == "ShieldBehavior":
			slot.picture_id = "shield_b"
		else:
			slot.picture_id = "blank_g"
		slots.append(slot)

	def.parts = slots

	# 实例化 Grid 并设置
	var grid_scene := preload("res://grids/grid.tscn")
	var grid: Grid = grid_scene.instantiate()
	grid.setup_from_def(def)
	add_child(grid)
	grid.position = pos

	print("  ✓ ", grid_name, " (", slots.size(), " 个部件, 位置 ", pos, ")")
