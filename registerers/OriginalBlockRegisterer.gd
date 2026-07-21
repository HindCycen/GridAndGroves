class_name OriginalBlockRegisterer extends AbstractBlockRegisterer

func register() -> void:
	BlockRegistry.subscribe_block_def(load("res://resources/blockdefs/ExampleBlock.tres"))
	BlockRegistry.subscribe_block_def(load("res://resources/blockdefs/ExampleMoveRight.tres"))
	BlockRegistry.subscribe_block_def(load("res://resources/blockdefs/DamageBlock.tres"))
	BlockRegistry.subscribe_block_def(load("res://resources/blockdefs/EnemyAttackBlock.tres"))
	BlockRegistry.subscribe_block_def(load("res://resources/blockdefs/GrowingBlock.tres"))
	BlockRegistry.subscribe_block_def(load("res://resources/blockdefs/Shield.tres"))
