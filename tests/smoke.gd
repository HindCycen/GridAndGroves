extends Node
## Grid and Groves — 固定冒烟套件
##
## 运行：
##   & "C:\Unpacked\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path . res://tests/smoke.tscn
##
## 约定：
##   - 每条检查独立命名，一一对应一个不变量（见 .dsh/skills/session-handoff）
##   - 输出 PASS/FAIL 每行一条，最后一行汇总
##   - 有失败则退出码非零
##
## 新增守卫：修掉一个 bug，就在这里加一条同名检查。不要删检查。

var _passed := 0
var _failed := 0
var _lines: PackedStringArray = []
var _block_names := {}

const BLOCK_DEFS := "res://resources/block_defs.json"
const ENEMY_DEFS := "res://resources/enemy_defs.json"
const REQUIRED_AUTOLOADS := [
	"GameLog", "GridState", "RngManager", "BlockRegistry",
	"PackManager", "BattleTime", "SaveLoad",
]


func _ready() -> void:
	await get_tree().process_frame

	_check_autoloads()
	_check_block_defs()
	_check_enemy_defs()

	_report()


# ---------------------------------------------------------------- 检查项

func _check_autoloads() -> void:
	var missing: PackedStringArray = []
	for name in REQUIRED_AUTOLOADS:
		if get_node_or_null("/root/" + name) == null:
			missing.append(name)
	_assert("autoloads_present", missing.is_empty(),
		"缺失：%s" % ", ".join(missing) if not missing.is_empty() else "%d 个 Autoload 就位" % REQUIRED_AUTOLOADS.size())


func _check_block_defs() -> void:
	var data: Variant = _load_json(BLOCK_DEFS)
	if not (data is Dictionary) or not (data as Dictionary).has("blocks"):
		_fail("block_defs_parses", "%s 缺失或结构不是 {blocks: [...]}" % BLOCK_DEFS)
		return
	_ok("block_defs_parses")

	var blocks: Array = (data as Dictionary)["blocks"]
	_assert("block_defs_nonempty", blocks.size() > 0, "%d 个 Block" % blocks.size())

	var no_parts: PackedStringArray = []
	var missing_tex: PackedStringArray = []
	var dirty_ids: PackedStringArray = []

	for b in blocks:
		var bname := str((b as Dictionary).get("name", "<unnamed>"))
		_block_names[bname] = true
		var parts: Array = (b as Dictionary).get("parts", [])
		if parts.is_empty():
			no_parts.append(bname)
		for p in parts:
			var pid := str((p as Dictionary).get("partId", ""))
			if pid.strip_edges() == "":
				dirty_ids.append(bname)
			var tex := str((p as Dictionary).get("spriteTexture", ""))
			if tex != "" and not FileAccess.file_exists(tex):
				missing_tex.append("%s -> %s" % [bname, tex])

	_assert("every_block_has_parts", no_parts.is_empty(),
		"%d 个 Block 无 parts：%s" % [no_parts.size(), _head(no_parts)] if not no_parts.is_empty() else "")
	_assert("every_part_has_id", dirty_ids.is_empty(),
		"%d 个 Block 含空 partId：%s" % [dirty_ids.size(), _head(dirty_ids)] if not dirty_ids.is_empty() else "")
	_assert("every_part_texture_exists", missing_tex.is_empty(),
		"%d 个悬空贴图引用：%s" % [missing_tex.size(), _head(missing_tex)] if not missing_tex.is_empty() else "")


func _check_enemy_defs() -> void:
	var data: Variant = _load_json(ENEMY_DEFS)
	if not (data is Dictionary) or not (data as Dictionary).has("enemies"):
		_fail("enemy_defs_parses", "%s 缺失或结构不是 {enemies: [...]}" % ENEMY_DEFS)
		return
	_ok("enemy_defs_parses")

	var enemies: Array = (data as Dictionary)["enemies"]
	_assert("enemy_defs_nonempty", enemies.size() > 0, "%d 个敌人" % enemies.size())

	var missing_img: PackedStringArray = []
	var missing_stat: PackedStringArray = []
	var bad_block: PackedStringArray = []
	var bad_intent: PackedStringArray = []

	for e in enemies:
		var ed := e as Dictionary
		var ename := str(ed.get("enemyName", "<unnamed>"))

		var img := str(ed.get("enemyImage", ""))
		if img != "" and not FileAccess.file_exists(img):
			missing_img.append("%s -> %s" % [ename, img])

		for s in ed.get("initialStats", []):
			var sp := str(s)
			if sp != "" and not FileAccess.file_exists(sp):
				missing_stat.append("%s -> %s" % [ename, sp])

		for intent in ed.get("intentCycle", []):
			var idict := intent as Dictionary
			if str(idict.get("intentName", "")).strip_edges() == "":
				bad_intent.append(ename)
			for pl in idict.get("blockPlacements", []):
				var bn := str((pl as Dictionary).get("blockName", ""))
				if bn != "" and not _block_names.has(bn):
					bad_block.append("%s -> %s" % [ename, bn])

	_assert("every_enemy_image_exists", missing_img.is_empty(),
		"%d 个悬空立绘：%s" % [missing_img.size(), _head(missing_img)] if not missing_img.is_empty() else "")
	_assert("every_enemy_stat_exists", missing_stat.is_empty(),
		"%d 个悬空 Stat：%s" % [missing_stat.size(), _head(missing_stat)] if not missing_stat.is_empty() else "")
	_assert("every_intent_named", bad_intent.is_empty(),
		"%d 个意图缺 intentName：%s" % [bad_intent.size(), _head(bad_intent)] if not bad_intent.is_empty() else "")
	_assert("every_placement_block_defined", bad_block.is_empty(),
		"%d 个未定义 Block 引用：%s" % [bad_block.size(), _head(bad_block)] if not bad_block.is_empty() else "")


# ---------------------------------------------------------------- 工具

func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var txt := FileAccess.get_file_as_string(path)
	if txt.is_empty():
		return null
	return JSON.parse_string(txt)


func _head(items: PackedStringArray, n: int = 5) -> String:
	if items.size() <= n:
		return ", ".join(items)
	return ", ".join(items.slice(0, n)) + " …(+%d)" % (items.size() - n)


func _ok(name: String, detail: String = "") -> void:
	_passed += 1
	var line := "PASS  " + name
	if detail != "":
		line += "  — " + detail
	_lines.append(line)


func _fail(name: String, detail: String) -> void:
	_failed += 1
	var line := "FAIL  " + name + "  — " + detail
	_lines.append(line)
	push_error(line)


func _assert(name: String, cond: bool, detail: String = "") -> void:
	if cond:
		_ok(name, detail)
	else:
		_fail(name, detail if detail != "" else "断言失败")


func _report() -> void:
	print_rich("\n[b]Grid and Groves — smoke suite[/b]")
	for l in _lines:
		print(l)
	print("\n%d passed, %d failed" % [_passed, _failed])
	# 让自动化能读到结果
	get_tree().quit(0 if _failed == 0 else 1)
