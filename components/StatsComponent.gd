class_name StatsComponent extends Node

signal status_added(status_name: String, current_value: int, max_value: int)
signal status_changed(status_name: String, current_value: int, max_value: int)
signal status_removed(status_name: String)

var _event_handlers: Dictionary = {}
var _status_list: Array[Stat] = []
var _status_map: Dictionary = {}

var StatusCount: int:
    get: return _status_list.size()

func _ready() -> void:
    add_to_group("stats_components")

func _on_stat_value_changed(status_name: String, current: int, max_val: int) -> void:
    status_changed.emit(status_name, current, max_val)

func add_status(stat: Stat) -> void:
    if stat == null:
        GameLog.err("Attempting to add null status")
        return
    var status_name := stat.Definition.StatName
    if _status_map.has(status_name):
        GameLog.err("Status " + status_name + " already exists")
        return
    _status_map[status_name] = stat
    _status_list.append(stat)
    add_child(stat)
    var handler := func(current: int, max_val: int): _on_stat_value_changed(status_name, current, max_val)
    _event_handlers[status_name] = handler
    stat.value_changed.connect(handler)
    status_added.emit(status_name, stat.CurrentValue, stat.Definition.MaxValue)

func remove_status(status_name: String) -> void:
    if not _status_map.has(status_name):
        GameLog.err("Status " + status_name + " not found")
        return
    var stat: Stat = _status_map.get(status_name) as Stat
    if _event_handlers.has(status_name):
        var handler = _event_handlers[status_name]
        if stat.value_changed.is_connected(handler):
            stat.value_changed.disconnect(handler)
        _event_handlers.erase(status_name)
    _status_map.erase(status_name)
    _status_list.erase(stat)
    stat.queue_free()
    status_removed.emit(status_name)

func get_status(status_name: String) -> Stat:
    return _status_map.get(status_name, null) as Stat

func get_all_statuses() -> Array[Stat]:
    return _status_list.duplicate()

func has_status(status_name: String) -> bool:
    return _status_map.has(status_name)

func clear_all_statuses() -> void:
    for status_name in _status_map.keys().duplicate():
        remove_status(status_name)
