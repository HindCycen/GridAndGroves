class_name DamageEnemyBehavior extends DamageBehavior

## 对敌人造成伤害（DamageBehavior 的简化封装）
## 等价于 DamageBehavior 设置 TargetGroup = "Enemies"

func _init() -> void:
	TargetGroup = "Enemies"
