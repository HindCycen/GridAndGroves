class_name ApplyRustBehavior extends GrantStatBehavior

## 施加锈蚀 (Rust) Behavior
## 给敌人施加 Rust Stat（GrantStatBehavior 的简化封装）
## 等价于 GrantStatBehavior 设置 TargetGroup = "Enemies"，TargetStatDef = Rust.tres

func _init() -> void:
	TargetGroup = "Enemies"
	TargetStatDef = load("res://resources/stat_defs/Rust.tres") as StatDef
	InitialValue = 1

func create_action(block, part):
	if block == null:
		return null
	# 从部件 MagicNum 取层数（若为 0 则用默认 InitialValue）
	if part.MagicNum > 0:
		InitialValue = part.MagicNum
	return super.create_action(block, part)
