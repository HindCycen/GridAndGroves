class_name VFXAction extends AbstractGameAction

var _parent: Node
var _vfx_node: Node2D

func _init(vfx_node: Node2D, dur: float, parent_node: Node = null):
	super(dur)
	_vfx_node = vfx_node
	_parent = parent_node
	action_type = Enums.ActionType.VFX
	if _vfx_node != null and _vfx_node.get_parent() == null:
		var target_parent := _parent
		if target_parent == null and source != null:
			target_parent = source.get_tree().current_scene
		if target_parent != null:
			target_parent.add_child(_vfx_node)

func update(delta: float) -> void:
	if is_done:
		return
	tick_duration(delta)
	if not is_done:
		return
	if _vfx_node != null and is_instance_valid(_vfx_node):
		if _vfx_node.get_parent() != null:
			_vfx_node.get_parent().remove_child(_vfx_node)
		_vfx_node.queue_free()
