class_name ShieldBehavior extends GridPartBehavior
## 护盾行为 — 回合结算时为玩家增加护盾
##
## 护盾数值来自 GridPartSlotDef.shield。
## 依赖战斗系统提供玩家获取方法（TODO）。

# preload 确保依赖脚本在 class_name 注册前先被解析
const _GridPart = preload("res://grids/grid_part.gd")
const _GridPartSlotDef = preload("res://resources/grid_defs/grid_part_slot_def.gd")

func on_resolve(grid_part: GridPart) -> void:
	if not is_instance_valid(grid_part):
		return
	var slot_def: GridPartSlotDef = grid_part.slot_def
	if not slot_def or slot_def.shield <= 0:
		return

	var player = _get_player()
	if player and player.has_method("add_shield"):
		player.add_shield(slot_def.shield)

## 获取玩家节点
## TODO: 接入战斗系统后实现
func _get_player() -> Node:
	return null
