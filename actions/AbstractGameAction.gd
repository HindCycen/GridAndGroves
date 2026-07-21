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

func update(_delta: float) -> void:
	pass

func tick_duration(delta: float) -> void:
	duration -= delta
	if duration <= 0.0:
		duration = 0.0
		is_done = true

func add_to_bot(action: AbstractGameAction) -> void:
	if ActionManager.Instance != null:
		ActionManager.Instance.add_to_bottom(action)

func add_to_top(action: AbstractGameAction) -> void:
	if ActionManager.Instance != null:
		ActionManager.Instance.add_to_top(action)
