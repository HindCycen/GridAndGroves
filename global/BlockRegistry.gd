extends Node

var BlockDefs: Dictionary = {}
var EnemyDefs: Dictionary = {}
var StageChartConfigs: Dictionary = {}

func _ready() -> void:
    auto_register_blocks()
    auto_register_enemies()

# ── Block 注册 ──

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
    var Scanner := preload("res://registerers/JsonBlockScanner.gd")
    Scanner.scan_and_register()

# ── 敌人注册 ──

func subscribe_enemy_def(enemy_def) -> bool:
    if enemy_def == null:
        GameLog.err("EnemyRegistry: EnemyDefinition is null")
        return false
    if enemy_def.EnemyName.is_empty():
        GameLog.err("EnemyRegistry: EnemyDefinition.EnemyName is empty")
        return false
    if EnemyDefs.has(enemy_def.EnemyName):
        GameLog.err("EnemyRegistry: EnemyDefinition '" + enemy_def.EnemyName + "' already registered")
        return false
    EnemyDefs[enemy_def.EnemyName] = enemy_def
    return true

func get_enemy_def(enemy_name: String) -> EnemyDefinition:
    if not EnemyDefs.has(enemy_name):
        GameLog.err("EnemyRegistry: No EnemyDefinition with name '" + enemy_name + "' found")
        return null
    return EnemyDefs[enemy_name]

func subscribe_stage_chart(stage_key: String, chart_config: Dictionary) -> void:
    if StageChartConfigs.has(stage_key):
        GameLog.warn("EnemyRegistry: Stage chart config '" + stage_key + "' already registered, overwriting")
    StageChartConfigs[stage_key] = chart_config

func get_stage_chart_config(stage_key: String) -> Dictionary:
    return StageChartConfigs.get(stage_key, {})

func auto_register_enemies() -> void:
    var Scanner := preload("res://registerers/JsonEnemyScanner.gd")
    Scanner.scan_and_register()
