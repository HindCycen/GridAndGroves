class_name EchoStatBehavior extends StatBehavior

## 回响 StatBehavior（玩家身上）
## 共鸣链每成功传播 1 个 Block +1 层
## 可被 SpendEchoBehavior 消费换取增益
## OnTurnEnded 清零

func get_execute_periods() -> Array[int]:
	return [Enums.StatExecuteAt.OnTurnEnded]

func execute_at(period: int) -> void:
	if period != Enums.StatExecuteAt.OnTurnEnded:
		return
	if belonging_stat == null:
		return
	if belonging_stat.CurrentValue > 0:
		GameLog.debug("EchoStatBehavior: Resetting echo from " + str(belonging_stat.CurrentValue) + " to 0")
		belonging_stat.set_value(0)
