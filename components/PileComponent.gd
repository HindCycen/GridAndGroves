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

func remove_block(block: Block) -> bool:
	if block == null:
		return false
	var had := _pile.has(block)
	_pile.erase(block)
	return had

func get_random_block_reference() -> Block:
	if _pile.size() == 0:
		printerr("Pile is empty")
		return null
	var random_index: int = RngManager.get_pile_rand(_pile.size())
	return _pile[random_index]
