class_name ApplyStatusAction extends AbstractGameAction

var _initial_value: int
var _stat_def

func _init(target_node: Node, stat_def, initial_value: int, dur: float = 0.3):
	super(dur)
	target = target_node
	_stat_def = stat_def
	_initial_value = initial_value
	amount = initial_value
	action_type = Enums.ActionType.ApplyStatus

func update(delta: float) -> void:
	if is_done:
		return
	tick_duration(delta)
	if not is_done:
		return
	if target is Node2D:
		var target_node: Node2D = target as Node2D
		var rendering = target_node.get_node_or_null("RenderingComponent")
		if rendering != null and rendering.StatsComponentRef != null:
			var stats: StatsComponent = rendering.StatsComponentRef
			if not stats.has_status(_stat_def.StatName):
				var stat: Stat = Stat.new()
				stat.Definition = _stat_def
				stats.add_status(stat)
				stat.add_value(_initial_value)
			else:
				var existing: Stat = stats.get_status(_stat_def.StatName)
				if existing != null:
					existing.add_value(_initial_value)
