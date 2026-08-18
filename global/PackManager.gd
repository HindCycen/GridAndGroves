extends Node

const BLOCK_PACKS_DIR: String = "res://resources/block_packs"
const MINI_PACKS_DIR: String = "res://resources/mini_packs"
## 随机抽取的小卡包数量（balance.md：系统随机抽 4 个小卡包）
const DEFAULT_MINI_PACK_COUNT := 4

var BlockPacks: Dictionary = {}
var MiniPacks: Dictionary = {}
var CurrentCardPool = null

func _ready() -> void:
	register_all_packs()

## 扫描 resources/block_packs 与 resources/mini_packs 目录，自动注册全部卡包。
## 数据驱动：新增 .tres 卡包文件后无需改代码即被收录。
func register_all_packs() -> void:
	_register_packs_from_dir(BLOCK_PACKS_DIR, true)
	_register_packs_from_dir(MINI_PACKS_DIR, false)
	GameLog.info("PackManager: Registered " + str(BlockPacks.size()) + " block pack(s), " + str(MiniPacks.size()) + " mini pack(s)")

func _register_packs_from_dir(dir_path: String, is_main: bool) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		GameLog.err("PackManager: Cannot open directory " + dir_path)
		return
	for file_name in dir.get_files():
		if not file_name.ends_with(".tres"):
			continue
		var pack = load(dir_path + "/" + file_name)
		if pack == null:
			GameLog.err("PackManager: Failed to load pack " + dir_path + "/" + file_name)
			continue
		if is_main:
			if not BlockPacks.has(pack.PackName):
				subscribe_block_pack(pack)
		else:
			if not MiniPacks.has(pack.PackName):
				subscribe_mini_pack(pack)

func subscribe_block_pack(pack) -> bool:
	if pack == null:
		GameLog.err("PackManager: BlockPack is null")
		return false
	if pack.PackName.is_empty():
		GameLog.err("PackManager: BlockPack.PackName is null or empty")
		return false
	if BlockPacks.has(pack.PackName):
		GameLog.err("PackManager: BlockPack '" + pack.PackName + "' already registered")
		return false
	BlockPacks[pack.PackName] = pack
	return true

func subscribe_mini_pack(pack) -> bool:
	if pack == null:
		GameLog.err("PackManager: MiniPack is null")
		return false
	if pack.PackName.is_empty():
		GameLog.err("PackManager: MiniPack.PackName is null or empty")
		return false
	if MiniPacks.has(pack.PackName):
		GameLog.err("PackManager: MiniPack '" + pack.PackName + "' already registered")
		return false
	MiniPacks[pack.PackName] = pack
	return true

## 构建运行时卡池（主包 + 小包）。
## selected_mini_names 为空时按 balance.md 从全部小包中随机抽 4 个；
## 非空时使用指定小包（用于 Continue 从存档恢复）。
func build_card_pool(main_pack_name: String, selected_mini_names: Array = []) -> bool:
	if not BlockPacks.has(main_pack_name):
		GameLog.err("PackManager: BlockPack '" + main_pack_name + "' not found")
		return false
	var main_pack = BlockPacks[main_pack_name]
	var selected = []
	if selected_mini_names.size() > 0:
		for name in selected_mini_names:
			if MiniPacks.has(name) and not selected.has(MiniPacks[name]):
				selected.append(MiniPacks[name])
	if selected.is_empty():
		var available = MiniPacks.values()
		if available.size() <= DEFAULT_MINI_PACK_COUNT:
			selected = available.duplicate()
		else:
			var pool = available.duplicate()
			for i in DEFAULT_MINI_PACK_COUNT:
				var swap_idx = RngManager.get_misc_rand(pool.size() - i) + i
				var temp = pool[i]
				pool[i] = pool[swap_idx]
				pool[swap_idx] = temp
				selected.append(pool[i])
	CurrentCardPool = CardPool.new(main_pack, selected)
	# 回写存档字段（New Game 选择后 / Continue 恢复后均一致）
	if SaveLoad != null and SaveLoad.Data != null:
		SaveLoad.Data.MainPackName = main_pack_name
		var mini_names: Array[String] = []
		for p in selected:
			mini_names.append(p.PackName)
		SaveLoad.Data.SelectedMiniPackNames = mini_names
	GameLog.info("PackManager: CardPool built with main pack '" + main_pack_name + "' and " + str(selected.size()) + " mini pack(s), total " + str(CurrentCardPool.Count) + " BlockDefs")
	return true

## 从存档中的 MainPackName / SelectedMiniPackNames 恢复卡池（Continue 流程）。
func restore_card_pool_from_save() -> bool:
	if SaveLoad == null or SaveLoad.Data == null:
		GameLog.err("PackManager: restore_card_pool_from_save failed, SaveLoad not ready")
		return false
	var main_name: String = SaveLoad.Data.MainPackName
	if main_name.is_empty() or not BlockPacks.has(main_name):
		GameLog.err("PackManager: restore_card_pool_from_save failed, MainPackName '" + main_name + "' invalid")
		return false
	var mini_names: Array = SaveLoad.Data.SelectedMiniPackNames.duplicate() if SaveLoad.Data.SelectedMiniPackNames != null else []
	return build_card_pool(main_name, mini_names)

func clear_card_pool() -> void:
	CurrentCardPool = null
	GameLog.info("PackManager: CardPool cleared")