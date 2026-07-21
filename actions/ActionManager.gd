class_name ActionManager extends Node

enum QueuePhase { Idle, Executing }

var _actions: Array[AbstractGameAction] = []
static var Instance: ActionManager
var CurrentAction: AbstractGameAction
var PreviousAction: AbstractGameAction
var Phase: int = QueuePhase.Idle
var is_busy: bool:
	get:
		return Phase == QueuePhase.Executing

func _ready() -> void:
	Instance = self
	Phase = QueuePhase.Idle

func _exit_tree() -> void:
	if Instance == self:
		Instance = null

func _process(delta: float) -> void:
	if Phase != QueuePhase.Executing:
		return
	if CurrentAction != null and not CurrentAction.is_done:
		CurrentAction.update(delta)
	if CurrentAction != null and CurrentAction.is_done:
		PreviousAction = CurrentAction
		CurrentAction = null
		_pop_next_action()
	elif CurrentAction == null:
		_pop_next_action()

func _pop_next_action() -> void:
	if _actions.size() > 0:
		CurrentAction = _actions[0]
		_actions.remove_at(0)
		Phase = QueuePhase.Executing
		return
	CurrentAction = null
	Phase = QueuePhase.Idle

func add_to_bottom(action: AbstractGameAction) -> void:
	_actions.append(action)
	if Phase == QueuePhase.Idle:
		_pop_next_action()

func add_to_top(action: AbstractGameAction) -> void:
	if _actions.size() == 0:
		_actions.append(action)
	else:
		_actions.insert(0, action)
	if Phase == QueuePhase.Idle:
		_pop_next_action()

func clear() -> void:
	_actions.clear()
	CurrentAction = null
	PreviousAction = null
	Phase = QueuePhase.Idle

func is_empty() -> bool:
	return _actions.size() == 0
