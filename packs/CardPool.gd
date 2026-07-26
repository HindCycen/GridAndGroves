class_name CardPool

var MainPack: Resource
var SelectedMiniPacks: Array
var _all_block_names: Array[String] = []

var AllBlockNames: Array[String]:
    get: return _all_block_names.duplicate()
var Count: int:
    get: return _all_block_names.size()

func _init(main_pack, mini_packs: Array):
    MainPack = main_pack
    SelectedMiniPacks = mini_packs
    _build_pool()

func _build_pool() -> void:
    var seen := {}
    _add_block_names(MainPack.BlockNames if MainPack != null else [], seen)
    for mini_pack in SelectedMiniPacks:
        if mini_pack != null:
            _add_block_names(mini_pack.BlockNames, seen)

func _add_block_names(names: Array, seen: Dictionary) -> void:
    for name in names:
        if not name is String or name.is_empty():
            continue
        if seen.has(name):
            continue
        seen[name] = true
        _all_block_names.append(name)

func contains_name(block_name: String) -> bool:
    return _all_block_names.has(block_name)

func get_random_block_name() -> String:
    if _all_block_names.size() == 0:
        return ""
    var index: int = RngManager.get_misc_rand(_all_block_names.size())
    return _all_block_names[index]

func get_random_block_names(count: int, exclude_names: Dictionary = {}) -> Array[String]:
    var candidates: Array[String] = []
    for name in _all_block_names:
        if not exclude_names.has(name):
            candidates.append(name)
    var shuffled := candidates.duplicate()
    var n := shuffled.size()
    while n > 1:
        n -= 1
        var k: int = RngManager.get_misc_rand(n + 1)
        var temp: String = shuffled[k]
        shuffled[k] = shuffled[n]
        shuffled[n] = temp
    var result: Array[String] = []
    for i in mini(count, shuffled.size()):
        result.append(shuffled[i])
    return result
