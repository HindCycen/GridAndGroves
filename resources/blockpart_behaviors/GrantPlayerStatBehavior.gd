class_name GrantPlayerStatBehavior extends BlockPartBehavior

@export var TargetStatDef: StatDef
@export var InitialValue: int = 1
@export var RemoveBlockFromDeck: bool = true
@export var ShouldExhaust: bool = true

func prevents_clear() -> bool:
    return false

func create_action(block, _part):
    if TargetStatDef == null:
        printerr("GrantPlayerStatBehavior: TargetStatDef not set!")
        return null
    var tree: SceneTree = block.get_tree()
    if tree == null:
        return null
    var players: Array[Node] = tree.get_nodes_in_group("Players")
    if players.size() == 0:
        return null
    var player: Node2D = players[0] as Node2D
    if player == null:
        return null
    return CallbackAction.new(func():
        var rendering = player.get_node("RenderingComponent")
        var stats_comp: StatsComponent = rendering.StatsComponentRef if rendering != null else null
        if stats_comp != null:
            if not stats_comp.has_status(TargetStatDef.StatName):
                var stat: Stat = Stat.new()
                stat.Definition = TargetStatDef
                stats_comp.add_status(stat)
                stat.add_value(InitialValue)
                print("GrantPlayerStatBehavior: Added Stat [", TargetStatDef.StatName, "] = ", InitialValue)
            else:
                var existing: Stat = stats_comp.get_status(TargetStatDef.StatName)
                if existing != null:
                    existing.add_value(InitialValue)
                    print("GrantPlayerStatBehavior: Stacked Stat [", TargetStatDef.StatName, "] +", InitialValue, " = ", existing.CurrentValue)
        if RemoveBlockFromDeck and block.Definition != null:
            var player_pile = player.get_node("%PlayerPile")
            if player_pile != null:
                for b in player_pile.Pile:
                    if not is_instance_valid(b):
                        continue
                    if b.Definition != null and b.Definition.BlockName == block.Definition.BlockName:
                        player_pile.remove_block(b)
                        if is_instance_valid(b) and b.get_parent() != null:
                            b.get_parent().remove_child(b)
                        b.queue_free()
                        print("GrantPlayerStatBehavior: Removed [", block.Definition.BlockName, "] from deck")
                        return
    , Enums.ActionType.ApplyStatus, ShouldExhaust)
