extends Node

var BlockPacks: Dictionary = {}
var MiniPacks: Dictionary = {}
var CurrentCardPool = null

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

func build_card_pool(main_pack_name: String) -> bool:
    if not BlockPacks.has(main_pack_name):
        GameLog.err("PackManager: BlockPack '" + main_pack_name + "' not found")
        return false
    var main_pack = BlockPacks[main_pack_name]
    var available = MiniPacks.values()
    var selected = []
    if available.size() <= 4:
        selected = available.duplicate()
    else:
        var pool = available.duplicate()
        for i in 4:
            var swap_idx = RngManager.get_misc_rand(pool.size() - i) + i
            var temp = pool[i]
            pool[i] = pool[swap_idx]
            pool[swap_idx] = temp
            selected.append(pool[i])
    CurrentCardPool = CardPool.new(main_pack, selected)
    GameLog.info("PackManager: CardPool built with main pack '" + main_pack_name + "' and " + str(selected.size()) + " mini pack(s), total " + str(CurrentCardPool.Count) + " BlockDefs")
    return true

func clear_card_pool() -> void:
    CurrentCardPool = null
    GameLog.info("PackManager: CardPool cleared")
