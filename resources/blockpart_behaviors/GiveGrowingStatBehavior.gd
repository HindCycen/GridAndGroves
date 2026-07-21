class_name GiveGrowingStatBehavior extends BlockPartBehavior

func create_action(block, _part):
    return CallbackAction.new(func():
        var tree: SceneTree = block.get_tree()
        if tree == null:
            return
        for node in tree.get_nodes_in_group("Players"):
            if node is Node2D:
                var player: Node2D = node as Node2D
                _try_add_growing_stat(player)
                _try_remove_growing_block(player)
        _destroy_block_on_grid(block)
    , Enums.ActionType.ApplyStatus)

func _try_add_growing_stat(player: Node2D) -> void:
    var rendering = player.get_node("RenderingComponent")
    var stats_comp: StatsComponent = rendering.StatsComponentRef if rendering != null else null
    if stats_comp == null or stats_comp.has_status("Growing"):
        return
    var stat_def: Resource = load("res://resources/stat_defs/Growing.tres")
    if stat_def == null:
        return
    var stat: Stat = Stat.new()
    stat.Definition = stat_def
    stats_comp.add_status(stat)
    stat.add_value(stat_def.MaxValue)

func _try_remove_growing_block(player: Node2D) -> void:
    var player_pile = player.get_node("%PlayerPile")
    if player_pile == null:
        return
    for b in player_pile.Pile:
        if not is_instance_valid(b):
            continue
        if b.Definition != null and b.Definition.BlockName == "Growing":
            player_pile.remove_block(b)
            if is_instance_valid(b) and b.get_parent() != null:
                b.get_parent().remove_child(b)
            b.queue_free()
            return

func _destroy_block_on_grid(block: Block) -> void:
    for p in block.get_parts():
        var grid_point: Vector2 = GridState.find_nearest_grid_point(p.global_position)
        var coords: Vector2i = GridState.get_grid_coords(grid_point)
        if coords.x >= 0 and coords.y >= 0:
            GridState.restore_grid_state(coords.x, coords.y)
    var block_piles_here = block.get_parent()
    if block_piles_here != null and block_piles_here.has_method("PlacedPile"):
        block_piles_here.PlacedPile.remove_block(block)
    if is_instance_valid(block) and block.get_parent() != null:
        block.get_parent().remove_child(block)
    block.queue_free()
