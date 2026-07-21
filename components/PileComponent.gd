class_name PileComponent extends Node2D

var _pile: Array[Block] = []

var Pile: Array[Block]:
    get: return _pile.duplicate()
var Count: int:
    get: return _pile.size()

func add_block(block: Block) -> void:
    if block == null:
        printerr("Block is null")
        return
    _pile.append(block)

func add_blocks(blocks: Array[Block]) -> void:
    for block in blocks:
        add_block(block)

func remove_block(block: Block) -> bool:
    if block == null:
        return false
    var had := _pile.has(block)
    _pile.erase(block)
    return had

func get_block_reference(index: int) -> Block:
    if index < 0 or index >= _pile.size():
        printerr("Index out of range")
        return null
    return _pile[index]

func get_random_block_reference() -> Block:
    if _pile.size() == 0:
        printerr("Pile is empty")
        return null
    var random_index: int = RngManager.get_pile_rand(_pile.size())
    return _pile[random_index]

func get_random_block_copy() -> Block:
    if _pile.size() == 0:
        printerr("Pile is empty")
        return null
    var random_index: int = RngManager.get_pile_rand(_pile.size())
    return _create_block_copy(_pile[random_index])

func _create_block_copy(original: Block) -> Block:
    if original.Definition == null:
        return null
    return BlockRegistry.create_block(original.Definition)
