class_name CallbackAction extends AbstractGameAction

var _callback: Callable
var _exhaust_source_block: bool

func _init(callback: Callable, act_type: int = Enums.ActionType.Callback, exhaust: bool = false):
	super(0.0)
	_callback = callback
	_exhaust_source_block = exhaust
	action_type = act_type

func exhaust_source_block() -> bool:
	return _exhaust_source_block

func update(_delta: float) -> void:
	if is_done:
		return
	if _callback.is_valid():
		_callback.call()
	is_done = true
