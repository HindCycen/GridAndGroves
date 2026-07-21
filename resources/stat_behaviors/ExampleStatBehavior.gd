class_name ExampleStatBehavior extends StatBehavior

func execute_stat() -> void:
    print("Example Status Executed")

func get_execute_periods() -> Array[int]:
    return [Enums.StatExecuteAt.OnTurnEnded]

func execute_at(period: int) -> void:
    if period == Enums.StatExecuteAt.OnTurnEnded:
        execute_stat()
