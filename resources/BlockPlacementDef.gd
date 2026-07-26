class_name BlockPlacementDef extends Resource

## 通过名称引用 Block，运行时由 BlockRegistry 查找
@export var BlockName: String
@export var GridPosition: Vector2i
@export var RandomOffsetRange: int = 1
