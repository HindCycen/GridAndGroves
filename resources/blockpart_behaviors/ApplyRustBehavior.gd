class_name ApplyRustBehavior extends GrantStatBehavior

## 施加锈蚀 (Rust) Behavior
## 给敌人施加 Rust Stat（GrantStatBehavior 的简化封装）
## 等价于 GrantStatBehavior 设置 TargetGroup = "Enemies"，TargetStatDef = Rust.tres
## 层数取部件 MagicNum（若为 0 则用默认 InitialValue）

func _init() -> void:
	TargetGroup = "Enemies"
	TargetStatDef = load("res://resources/stat_defs/Rust.tres") as StatDef
	InitialValue = 1

func create_action(block, part):
	if block == null:
		return null
	# 从部件 MagicNum 取层数（若为 0 则用默认 InitialValue）
	# 注意：不修改共享 behavior 实例的 InitialValue，避免污染其他同名单例
	var layers: int = InitialValue
	if part != null and part.MagicNum > 0:
		layers = part.MagicNum
	var tree: SceneTree = block.get_tree()
	if tree == null:
		return null
	return CallbackAction.new(func():
		_apply_stat_to_group(block, tree, layers)
	, Enums.ActionType.ApplyStatus, ShouldExhaust)
