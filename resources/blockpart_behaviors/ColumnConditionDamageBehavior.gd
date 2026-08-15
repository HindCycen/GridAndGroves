class_name ColumnConditionDamageBehavior extends BlockPartBehavior

## 列条件伤害 (Column Condition Damage) Behavior
## 精密传动：Block 放置在第 TargetColumn 列（x 坐标）时追加 BonusDamage 伤害
## 网格 7 列 x=0..6；"第 3 列"即 x=2
## 用于：三角测量（第 3 列时伤害翻倍）

@export var TargetColumn: int = 2
@export var BonusDamage: int = 3

func create_action(block, _part):
	if block == null:
		return null
	var tree: SceneTree = block.get_tree()
	if tree == null:
		return null
	return CallbackAction.new(func():
		_try_bonus(block, tree)
	, Enums.ActionType.Callback)

func _try_bonus(block: Block, tree: SceneTree) -> void:
	if not _is_on_column(block, TargetColumn):
		return
	for node in tree.get_nodes_in_group("Enemies"):
		if node is Node2D:
			var hc: HealthComponent = node.get_node_or_null("RenderingComponent/HealthComponent") as HealthComponent
			if hc != null and not hc.is_dead:
				if ActionManager.Instance != null:
					ActionManager.Instance.add_to_bottom(DamageAction.new(block, node, BonusDamage))
				GameLog.debug("ColumnConditionDamageBehavior: on column " + str(TargetColumn) + ", bonus +" + str(BonusDamage))
				return

func _is_on_column(block: Block, column: int) -> bool:
	for p in block.get_parts():
		var gp: Vector2 = GridState.find_nearest_grid_point(p.global_position)
		var coord: Vector2i = GridState.get_grid_coords(gp)
		if coord.x == column:
			return true
	return false
