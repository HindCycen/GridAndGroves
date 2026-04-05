extends Node

func _ready() -> void:
	if not Glob.IsDebug: # Glob是Autoload，找不到你的母牛
		queue_free() # 三军听令，自刎归天