class_name GrantPlayerStatBehavior extends GrantStatBehavior

## 给玩家施加 Stat（GrantStatBehavior 的简化封装）
## 等价于 GrantStatBehavior 设置 TargetGroup = "Players" + 自动从牌组移除 + 耗尽

func _init() -> void:
	TargetGroup = "Players"
	RemoveBlockFromDeck = true
	ShouldExhaust = true
