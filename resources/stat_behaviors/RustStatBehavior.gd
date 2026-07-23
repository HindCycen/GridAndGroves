class_name RustStatBehavior extends StatBehavior

## 锈蚀 StatBehavior
## 每层减少敌人造成的伤害 1 点（上限 10 层）
## 触发时机：OnBeforeDamageApply
## 仅在敌人身上生效

func get_execute_periods() -> Array[int]:
	return [Enums.StatExecuteAt.OnBeforeDamageApply]

func execute_at(period: int) -> void:
	if period != Enums.StatExecuteAt.OnBeforeDamageApply:
		return
	if belonging_stat == null:
		return
	var current_layers: int = belonging_stat.CurrentValue
	if current_layers <= 0:
		return
	# DamageAction 在执行前会触发 OnBeforeDamageApply
	# 通过 DamageAction 中的 _trigger_before_damage_hooks 调用到这里
	# 实际减伤逻辑由 DamageAction 在检测到 RustStat 时自行处理
	# 此处 StatBehavior 仅作为数据持有者
	GameLog.debug("RustStatBehavior: " + str(current_layers) + " layers active, reducing incoming damage by " + str(current_layers))
