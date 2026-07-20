class_name DamageBehavior extends GridPartBehavior
## 伤害行为 — 回合结算时对敌人造成伤害
##
## 伤害数值来自 GridPartSlotDef.damage。
## 依赖战斗系统提供目标获取方法（TODO）。

# preload 确保依赖脚本在 class_name 注册前先被解析
const _GridPart = preload("res://grids/grid_part.gd")
const _GridPartSlotDef = preload("res://resources/grid_defs/grid_part_slot_def.gd")

func on_resolve(grid_part: GridPart) -> void:
	if not is_instance_valid(grid_part):
		return
	var slot_def: GridPartSlotDef = grid_part.slot_def
	if not slot_def or slot_def.damage <= 0:
		return

	var enemy = _get_target_enemy()
	if enemy and enemy.has_method("take_damage"):
		enemy.take_damage(slot_def.damage)

## 获取当前目标敌人
## TODO: 接入战斗系统后实现
func _get_target_enemy() -> Node:
	return null
