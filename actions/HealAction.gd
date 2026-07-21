class_name HealAction extends AbstractGameAction

func _init(target_node: Node, amt: int, dur: float = 0.3):
	super(dur)
	target = target_node
	amount = amt
	action_type = Enums.ActionType.Heal

func update(delta: float) -> void:
	if is_done:
		return
	tick_duration(delta)
	if not is_done:
		return
	if target is Node2D:
		var hc: HealthComponent = target.get_node_or_null("RenderingComponent/HealthComponent") as HealthComponent
		if hc != null:
			hc.heal(amount)
