class_name PileViewer extends ColorRect

var _card_list: VBoxContainer
var _title_label: Label
var _current_title: String

func _init():
    color = Color(0, 0, 0, 0.6)
    size = Vector2i(1920, 1080)
    position = Vector2i.ZERO
    mouse_filter = Control.MOUSE_FILTER_STOP
    var panel := Panel.new()
    panel.set_size(Vector2i(700, 800))
    panel.set_position(Vector2i(610, 140))
    add_child(panel)
    _title_label = Label.new()
    _title_label.set_position(Vector2i(20, 10))
    _title_label.add_theme_font_size_override("font_size", 24)
    panel.add_child(_title_label)
    var close_btn := Button.new()
    close_btn.text = "Close"
    close_btn.set_position(Vector2i(640, 10))
    close_btn.set_size(Vector2i(50, 30))
    close_btn.pressed.connect(queue_free)
    panel.add_child(close_btn)
    var scroll := ScrollContainer.new()
    scroll.set_position(Vector2i(20, 50))
    scroll.set_size(Vector2i(660, 740))
    panel.add_child(scroll)
    _card_list = VBoxContainer.new()
    scroll.add_child(_card_list)

func open(title: String, pile: PileComponent) -> void:
    _current_title = title
    _title_label.text = title
    for child in _card_list.get_children():
        child.queue_free()
    if pile.Count == 0:
        var empty := Label.new()
        empty.text = "(Empty)"
        empty.custom_minimum_size = Vector2i(0, 30)
        _card_list.add_child(empty)
        return
    for block in pile.Pile:
        if not is_instance_valid(block):
            continue
        var card := Panel.new()
        card.custom_minimum_size = Vector2i(640, 36)
        var name_label := Label.new()
        name_label.text = "  " + block.Definition.BlockName + "    (Faction: " + str(block.Faction) + ")"
        name_label.set_position(Vector2i(10, 8))
        card.add_child(name_label)
        _card_list.add_child(card)
