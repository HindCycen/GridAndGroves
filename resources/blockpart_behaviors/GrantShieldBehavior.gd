class_name GrantShieldBehavior extends BlockPartBehavior

## 通用护盾 Behavior
## 对指定目标群组中的第一个存活单位添加护盾
## 通过 @export TargetGroup 指定目标群组（如 "Players" / "Enemies"）

@export var TargetGroup: String = "Players"

func create_action(block, part):
	if block == null:
		return null
	var tree: SceneTree = block.get_tree()
	if tree == null:
		return null
	var target: Node2D = _find_first_alive_in_group(tree, TargetGroup)
	if target == null:
		return null
	var amount: int = part.Shield
	return CallbackAction.new(func():
		var shield_comp: ShieldComponent = _find_shield_component(target)
		if shield_comp != null:
			shield_comp.add_shield(amount)
			print("GrantShieldBehavior: Added ", amount, " shield to ", target.name, ", current ", shield_comp.CurrentShield)
		else:
			printerr("GrantShieldBehavior: Cannot find ShieldComponent on ", target.name)
	, Enums.ActionType.Block)

func _find_first_alive_in_group(tree: SceneTree, group: String) -> Node2D:
	for node in tree.get_nodes_in_group(group):
		if node is Node2D:
			var hc: HealthComponent = node.get_node_or_null("RenderingComponent/HealthComponent") as HealthComponent
			if hc != null and not hc.is_dead:
				return node
	return null

func _find_shield_component(root: Node) -> ShieldComponent:
	if root is ShieldComponent:
		return root
	for child in root.get_children():
		var found: ShieldComponent = _find_shield_component(child)
		if found != null:
			return found
	return null
