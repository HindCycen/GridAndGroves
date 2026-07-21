class_name DamageEnemyBehavior extends BlockPartBehavior

func create_action(block, part):
    var tree: SceneTree = block.get_tree()
    if tree == null:
        return null
    var targets: Array[Node2D] = []
    for e in tree.get_nodes_in_group("Enemies"):
        if e is Node2D:
            var hc: HealthComponent = e.get_node_or_null("RenderingComponent/HealthComponent") as HealthComponent
            if hc != null and not hc.is_dead:
                targets.append(e)
    if targets.size() == 0:
        return null
    for i in range(1, targets.size()):
        var target: Node2D = targets[i]
        if ActionManager.Instance != null:
            ActionManager.Instance.add_to_bottom(DamageAction.new(block, target, part.Damage))
    return DamageAction.new(block, targets[0], part.Damage, 0.4)
