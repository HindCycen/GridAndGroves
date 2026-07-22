class_name OriginalBlockRegisterer extends AbstractBlockRegisterer

func register() -> void:
	var Scanner := preload("res://registerers/JsonBlockScanner.gd")
	Scanner.scan_and_register()
