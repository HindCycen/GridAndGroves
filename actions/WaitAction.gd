class_name WaitAction extends AbstractGameAction

func _init(dur: float):
	super(dur)
	action_type = Enums.ActionType.Wait

func update(delta: float) -> void:
	tick_duration(delta)
