class_name PlacementRestrictionBehavior extends BlockPartBehavior

## 放置限制 (Placement Restriction) Behavior
## 通用放置钩子：Block 只能放在指定格子（按中心格判定）
## Block._check_placement_conditions 会调用 check_placement
## 用于：奇点（只能放网格正中央 (3,2)）

@export var TargetX: int = 3  # 目标列（网格 7 列，x=0..6）
@export var TargetY: int = 2  # 目标行（网格 5 行，y=0..4）

func check_placement(block: Block) -> bool:
	if block == null:
		return false
	# 用 Block 的原点（左上角部件位置）判定
	var gp: Vector2 = GridState.find_nearest_grid_point(block.global_position)
	var coord: Vector2i = GridState.get_grid_coords(gp)
	return coord == Vector2i(TargetX, TargetY)
