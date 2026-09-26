class_name AbstractGameAction

var duration: float
var start_duration: float
var is_done: bool = false
var action_type: int = Enums.ActionType.Special
var source: Node
var target: Node
var amount: int

func _init(dur: float = 0.0):
	duration = dur
	start_duration = dur

func exhaust_source_block() -> bool:
	return false

## 星涌（Starburst）链加成钩子：共鸣链传播时 Bot/ResonanceBot 会调用此方法，
## 传入链深度。具体加成逻辑由需要链加成的 Action 覆写（参见 planning/card_pack_design/pack_weaver.md）。
## 基类为空实现，保证 has_method("set_chain_bonus") 恒为 true，避免调用点悬空。
func set_chain_bonus(_depth: int) -> void:
	pass

func update(_delta: float) -> void:
	pass

func tick_duration(delta: float) -> void:
	duration -= delta
	if duration <= 0.0:
		duration = 0.0
		is_done = true
