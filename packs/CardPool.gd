class_name CardPool

var MainPack: Resource
var SelectedMiniPacks: Array
var _all_block_defs: Array[BlockDef] = []

var AllBlockDefs: Array[BlockDef]:
    get: return _all_block_defs.duplicate()
var Count: int:
    get: return _all_block_defs.size()

func _init(main_pack, mini_packs: Array):
    MainPack = main_pack
    SelectedMiniPacks = mini_packs
    _build_pool()

func _build_pool() -> void:
    var seen := {}
    _add_block_defs(MainPack.BlockDefs if MainPack != null else [], seen)
    for mini_pack in SelectedMiniPacks:
        if mini_pack != null:
            _add_block_defs(mini_pack.BlockDefs, seen)

func _add_block_defs(defs: Array, seen: Dictionary) -> void:
    for defn in defs:
        if defn == null:
            continue
        if defn.BlockName != null and seen.has(defn.BlockName):
            continue
        if defn.BlockName != null:
            seen[defn.BlockName] = true
        _all_block_defs.append(defn)

func contains_name(block_name: String) -> bool:
    for b in _all_block_defs:
        if b.BlockName == block_name:
            return true
    return false

func contains_def(block_def: BlockDef) -> bool:
    return block_def != null and _all_block_defs.has(block_def)

func get_random_block_def() -> BlockDef:
    if _all_block_defs.size() == 0:
        return null
    var index: int = RngManager.get_misc_rand(_all_block_defs.size())
    return _all_block_defs[index]

func get_random_block_defs(count: int, exclude_names: Dictionary = {}) -> Array[BlockDef]:
    var candidates: Array[BlockDef] = []
    for b in _all_block_defs:
        if not exclude_names.has(b.BlockName):
            candidates.append(b)
    var shuffled := candidates.duplicate()
    var n := shuffled.size()
    while n > 1:
        n -= 1
        var k: int = RngManager.get_misc_rand(n + 1)
        var temp: BlockDef = shuffled[k]
        shuffled[k] = shuffled[n]
        shuffled[n] = temp
    var result: Array[BlockDef] = []
    for i in mini(count, shuffled.size()):
        result.append(shuffled[i])
    return result
