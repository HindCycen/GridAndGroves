class_name BlockPlacementDef extends Resource

## 直接引用的 BlockDef（.tres 方案遗留），优先使用
@export var BlockRef: BlockDef
## JSON 方案：通过名称引用 BlockDef，运行时由 BlockRegistry 查找
@export var BlockName: String
@export var GridPosition: Vector2i
@export var RandomOffsetRange: int = 1
