class_name GridDefLoader extends Resource
## Grid 定义加载器 — 解析 grids.json 并构建运行时数据对象
##
## 使用方法：
##   var data = GridDefLoader.load_grids("res://resources/grid_defs/grids.json")
##   var grid_def = data.grids["strike"]
##   var picture = data.pictures["sword_icon"]

# preload 显式声明依赖，确保类型先被解析
const _GridPartPicture := preload("res://resources/grid_part_pictures/grid_part_picture.gd")
const _GridDef := preload("res://resources/grid_defs/grid_def.gd")
const _GridPartSlotDef := preload("res://resources/grid_defs/grid_part_slot_def.gd")
const _GridPartBehavior := preload("res://resources/grid_part_behaviors/grid_part_behavior.gd")

## 加载结果的数据结构
class LoadResult:
	var grids: Dictionary  # String → GridDef
	var pictures: Dictionary  # String → GridPartPicture

	func _init():
		grids = {}
		pictures = {}

## 从 JSON 文件加载所有 Grid 和贴图定义
static func load_grids(path: String) -> LoadResult:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("GridDefLoader: 无法打开文件: ", path)
		return LoadResult.new()

	var json_str := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_str)
	if error != OK:
		push_error("GridDefLoader: JSON 解析失败在第 ", json.get_error_line(), " 行: ", json.get_error_message())
		return LoadResult.new()

	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		push_error("GridDefLoader: JSON 根节点必须是 Dictionary")
		return LoadResult.new()

	return _parse(data)

## 解析 JSON Dictionary 为运行时对象
static func _parse(data: Dictionary) -> LoadResult:
	var result := LoadResult.new()

	# === 解析贴图 ===
	if data.has("pictures") and typeof(data.pictures) == TYPE_DICTIONARY:
		var pictures_dict: Dictionary = data.pictures
		for pic_id: String in pictures_dict:
			var pic = _GridPartPicture.new()
			pic.id = pic_id
			var tex_path: String = str(pictures_dict[pic_id])
			if tex_path.is_empty():
				continue
			pic.texture = load(tex_path)
			if not pic.texture:
				push_warning("GridDefLoader: 贴图加载失败: ", tex_path)
			result.pictures[pic_id] = pic

	# === 解析 Grid 定义 ===
	if data.has("grids") and typeof(data.grids) == TYPE_ARRAY:
		var grids_array: Array = data.grids
		for grid_entry in grids_array:
			if typeof(grid_entry) != TYPE_DICTIONARY:
				continue

			var grid_def = _GridDef.new()
			grid_def.id = grid_entry.get("id", "")
			grid_def.display_name = grid_entry.get("display_name", "")
			grid_def.special_tag = grid_entry.get("special_tag", "")

			var parts_array: Array = grid_entry.get("parts", [])
			for part_entry in parts_array:
				if typeof(part_entry) != TYPE_DICTIONARY:
					continue

				var slot = _GridPartSlotDef.new()
				var pos_arr: Array = part_entry.get("position", [0, 0])
				slot.position = Vector2i(pos_arr[0], pos_arr[1])
				slot.picture_id = part_entry.get("picture_id", "")
				slot.damage = part_entry.get("damage", 0)
				slot.shield = part_entry.get("shield", 0)
				slot.magic_number = part_entry.get("magic_number", 0)
				slot.behavior_id = part_entry.get("behavior", "")
				grid_def.parts.append(slot)

			result.grids[grid_def.id] = grid_def

	return result

## 根据行为 ID 实例化行为对象
## 返回 GridPartBehavior 实例，如果找不到则返回 null
static func instantiate_behavior(behavior_id: String):
	if behavior_id.is_empty():
		return null

	if not ClassDB.class_exists(behavior_id):
		push_error("GridDefLoader: 行为类不存在: ", behavior_id)
		return null

	var instance = ClassDB.instantiate(behavior_id)
	if instance is _GridPartBehavior:
		return instance
	else:
		push_error("GridDefLoader: 类 \"", behavior_id, "\" 不是 GridPartBehavior 的子类")
		if instance:
			instance.free()
		return null
