class_name DamagePlayerBehavior extends DamageBehavior

## 对玩家造成伤害（DamageBehavior 的简化封装）
## 等价于 DamageBehavior 设置 TargetGroup = "Players"

func _init() -> void:
	TargetGroup = "Players"
