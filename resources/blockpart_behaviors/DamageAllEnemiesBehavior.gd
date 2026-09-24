class_name DamageAllEnemiesBehavior extends BlockPartBehavior

## 对敌方全体造成伤害 Behavior
## 翠绿哨兵/小卡包：与 DamageBehavior 不同，这里显式对每个存活敌人各排一个 DamageAction，
## 用于“造成 X 伤害。对敌全体 Y 伤害。”这类复合效果（如 破片手雷 FragGrenade）。
##
## 用法：params DamageAmount 指定全体伤害；部件 MagicNum > 0 时优先取 MagicNum。

@export var DamageAmount: int = 3

func create_action(block, part):
	if block == null:
		return null
	var tree: SceneTree = block.get_tree()
	if tree == null:
		return null
	var amount: int = DamageAmount
	if part != null and part.MagicNum > 0:
		amount = part.MagicNum
	return CallbackAction.new(func():
		_damage_all(tree, block, amount)
	, Enums.ActionType.Damage)

func _damage_all(tree: SceneTree, block: Block, amount: int) -> void:
	if amount <= 0 or tree == null or not is_instance_valid(tree):
		return
	for node in tree.get_nodes_in_group("Enemies"):
		if not is_instance_valid(node) or not (node is Node2D):
			continue
		var health: HealthComponent = node.get_node_or_null("RenderingComponent/HealthComponent") as HealthComponent
		if health == null or health.is_dead:
			continue
		if ActionManager.Instance != null:
			ActionManager.Instance.add_to_bottom(DamageAction.new(block, node, amount))
	GameLog.debug("DamageAllEnemiesBehavior: dealt " + str(amount) + " damage to all enemies")
