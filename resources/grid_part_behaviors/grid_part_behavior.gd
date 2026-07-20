class_name GridPartBehavior extends Resource
## 部件行为基类 — 所有具体行为从此继承
##
## 在部件的不同生命周期阶段被自动调用。
## 子类只需重写需要的方法，其余保持 pass 即可。
## 注意：为避免与 GridPart 的循环依赖，参数不使用类型注解。

## 部件被放置到网格上时触发
func on_place(_grid_part) -> void:
	pass

## 回合结算时触发（如造成伤害、施加护盾等）
func on_resolve(_grid_part) -> void:
	pass

## 部件被弃掉时触发
func on_discard(_grid_part) -> void:
	pass
