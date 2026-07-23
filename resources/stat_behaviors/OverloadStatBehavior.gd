class_name OverloadStatBehavior extends StatBehavior

## 过载计数 StatBehavior
## 每触发一个带过载标签的 Block +1，OnTurnEnded 清零
## 可被 SpendOverloadBehavior 消耗换取增益

func get_execute_periods() -> Array[int]:
	return [Enums.StatExecuteAt.OnPostBlockExecute, Enums.StatExecuteAt.OnTurnEnded]

func execute_at(period: int) -> void:
	match period:
		Enums.StatExecuteAt.OnPostBlockExecute:
			# 递增由外部触发（需在触发时调用 belonging_stat.add_value(1)）
			# 此处仅预留钩子，实际递增由 LooseBlockBehavior 等调用
			pass
		Enums.StatExecuteAt.OnTurnEnded:
			# 回合结束未消耗的过载清零
			if belonging_stat != null and belonging_stat.CurrentValue > 0:
				GameLog.debug("OverloadStatBehavior: Resetting overload from " + str(belonging_stat.CurrentValue) + " to 0")
				belonging_stat.set_value(0)
