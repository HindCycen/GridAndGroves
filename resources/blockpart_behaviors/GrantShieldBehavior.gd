class_name GrantShieldBehavior extends BlockPartBehavior

func create_action(block, part):
    var tree: SceneTree = block.get_tree()
    if tree == null:
        return null
    var players: Array[Node] = tree.get_nodes_in_group("Players")
    var player: Node2D = players[0] as Node2D if players.size() > 0 else null
    if player == null:
        return null
    var amount: int = part.Shield
    return CallbackAction.new(func():
        var shield_comp: ShieldComponent = _find_shield_component(player)
        if shield_comp != null:
            shield_comp.add_shield(amount)
            print("GrantShieldBehavior: Added ", amount, " shield, current ", shield_comp.CurrentShield)
        else:
            printerr("GrantShieldBehavior: Cannot find ShieldComponent!")
    , Enums.ActionType.Block)

func _find_shield_component(root: Node) -> ShieldComponent:
    if root is ShieldComponent:
        return root
    for child in root.get_children():
        var found: ShieldComponent = _find_shield_component(child)
        if found != null:
            return found
    return null
