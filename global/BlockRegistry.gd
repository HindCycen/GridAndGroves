extends Node

var BlockDefs: Dictionary = {}

func _ready() -> void:
    auto_register_blocks()

func subscribe_block_def(block_def) -> bool:
    if block_def == null:
        GameLog.err("ParseError: One blockdef is null")
        return false
    if BlockDefs.has(block_def.BlockName):
        GameLog.err("ParseError: Blockdef with name " + block_def.BlockName + " already exists")
        return false
    BlockDefs[block_def.BlockName] = block_def
    return true

func get_block(block_name: String, global_pos: Vector2, parent: Node) -> Block:
    if not BlockDefs.has(block_name):
        GameLog.err("BlockFactory: No blockdef with name " + block_name + " found")
        return null
    var block: Block = create_block(BlockDefs[block_name])
    if block != null:
        block.global_position = global_pos
        parent.add_child(block)
    return block

func create_block(block_def) -> Block:
    if block_def == null:
        GameLog.err("BlockFactory: BlockDef is null")
        return null
    var scene := preload("res://blocks/Block.tscn") as PackedScene
    var block: Block = scene.instantiate()
    block.Definition = block_def
    return block

func create_block_by_name(block_name: String) -> Block:
    if not BlockDefs.has(block_name):
        GameLog.err("BlockFactory: No blockdef with name " + block_name + " found")
        return null
    return create_block(BlockDefs[block_name])

func auto_register_blocks() -> void:
    subscribe_block_def(load("res://resources/blockdefs/ExampleBlock.tres"))
    subscribe_block_def(load("res://resources/blockdefs/ExampleMoveRight.tres"))
    subscribe_block_def(load("res://resources/blockdefs/DamageBlock.tres"))
    subscribe_block_def(load("res://resources/blockdefs/EnemyAttackBlock.tres"))
    subscribe_block_def(load("res://resources/blockdefs/GrowingBlock.tres"))
    subscribe_block_def(load("res://resources/blockdefs/Shield.tres"))
    subscribe_block_def(load("res://resources/blockdefs/Strike.tres"))
