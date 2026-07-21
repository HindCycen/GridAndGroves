class_name RenderingComponent extends Control

var _stat_icons: Dictionary = {}
var _stats_container: HBoxContainer
@export var BarLength: int
@export var StatIconPx: int = 45

var StatsComponentRef: StatsComponent

func _ready() -> void:
    StatsComponentRef = %StatsComponent as StatsComponent
    _stats_container = %StatsContainer as HBoxContainer
    StatsComponentRef.status_added.connect(_on_status_added)
    StatsComponentRef.status_removed.connect(_on_status_removed)

func _on_status_added(status_name: String, _current: int, _max: int) -> void:
    var stat: Stat = StatsComponentRef.get_status(status_name)
    if stat == null:
        return
    var icon := StatIcon.new()
    icon.setup(stat, StatIconPx)
    _stat_icons[status_name] = icon
    _stats_container.add_child(icon)

func _on_status_removed(status_name: String) -> void:
    if _stat_icons.has(status_name):
        var icon := _stat_icons[status_name] as StatIcon
        icon.detach()
        _stat_icons.erase(name)
        icon.queue_free()

func get_health() -> int:
    var hc := get_node("HealthComponent") as HealthComponent
    return hc.CurrentHealth if hc != null else 0

func get_shield() -> int:
    var sc := get_node("ShieldComponent") as ShieldComponent
    return sc.CurrentShield if sc != null else 0

func get_stat() -> Array:
    return StatsComponentRef.get_all_statuses()
