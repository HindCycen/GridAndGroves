extends Node

func _ready() -> void:
	if not Glob.IsDebug:
		queue_free() # 三军听令，自刎归天