class_name DamagePlayerBehavior extends BlockPartBehavior

func create_action(block, part):
    var tree: SceneTree = block.get_tree()
    if tree == null:
        return null
    var players: Array[Node] = tree.get_nodes_in_group("Players")
    var target: Node2D = players[0] as Node2D if players.size() > 0 else null
    if target != null and part.Damage > 0:
        return DamageAction.new(block, target, part.Damage, 0.4)
    return null
