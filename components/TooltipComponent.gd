class_name TooltipComponent extends Node

static var ColorMap := { "R": "red", "G": "green", "B": "blue", "Y": "yellow" }

var _tooltip: Node
@export var CanvasLayerOrder: int = 128
@export var MaxWidth: int = 260
@export var PaddingX: int = 12
@export var PaddingY: int = 8

func show(global_position: Vector2, rich_text: String) -> void:
    hide()
    var label := RichTextLabel.new()
    label.bbcode_enabled = true
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.size = Vector2(MaxWidth, 200)
    var panel := Panel.new()
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    panel.size = Vector2(MaxWidth + PaddingX * 2, 216)
    panel.add_child(label)
    var layer := CanvasLayer.new()
    layer.layer = CanvasLayerOrder
    var viewport := get_viewport()
    if viewport != null:
        viewport.add_child(layer)
    layer.add_child(panel)
    _tooltip = layer
    var deferred := func():
        if _tooltip != layer:
            return
        label.position = Vector2(PaddingX, PaddingY)
        label.text = rich_text
        var size := label.get_minimum_size()
        if size.y > 0:
            var panel_h := size.y + PaddingY * 2
            panel.size = Vector2(panel.size.x, panel_h)
        panel.position = Vector2(global_position.x, global_position.y - panel.size.y - 5)
    deferred.call_deferred()

func hide() -> void:
    if _tooltip != null:
        _tooltip.queue_free()
        _tooltip = null

func process_text(input_text: String, placeholders: Dictionary = {}) -> String:
    var result := input_text
    for key in placeholders.keys():
        result = result.replace("%" + key + "%", str(placeholders[key]))
    var regex := RegEx.new()
    regex.compile("\\[([RGBY])\\]\\{([^}]*)\\}")
    var matches := regex.search_all(result)
    for i in range(matches.size() - 1, -1, -1):
        var m := matches[i]
        var color: String = ColorMap.get(m.get_string(1), "white")
        var replacement: String = "[color=" + color + "]" + m.get_string(2) + "[/color]"
        result = result.substr(0, m.get_start()) + replacement + result.substr(m.get_end())
    return result

func _exit_tree() -> void:
    hide()
