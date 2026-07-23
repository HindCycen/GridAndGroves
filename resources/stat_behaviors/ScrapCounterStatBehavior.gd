class_name ScrapCounterStatBehavior extends StatBehavior

## 废品计数 StatBehavior（玩家身上）
## 本回合松动 Block 触发计数，用于增幅效果
## OnTurnEnded 清零

func get_execute_periods() -> Array[int]:
	return [Enums.StatExecuteAt.OnTurnEnded]

func execute_at(period: int) -> void:
	if period != Enums.StatExecuteAt.OnTurnEnded:
		return
	if belonging_stat == null:
		return
	if belonging_stat.CurrentValue > 0:
		GameLog.debug("ScrapCounterStatBehavior: Resetting scrap count from " + str(belonging_stat.CurrentValue) + " to 0")
		belonging_stat.set_value(0)
