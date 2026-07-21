class_name StatBehavior extends Resource

var belonging_stat: Stat

func set_belonging_stat(stat: Stat) -> void:
    belonging_stat = stat

func execute_at(_period: int) -> void:
    pass

func get_execute_periods() -> Array[int]:
    return []
