extends Node

func debug(message: String) -> void:
    print("[DEBUG] ", message)

func info(message: String) -> void:
    print("[INFO] ", message)

func warn(message: String) -> void:
    print("[WARN] ", message)

func err(message: String) -> void:
    printerr("[ERROR] ", message)
