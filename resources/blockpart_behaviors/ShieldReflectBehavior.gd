class_name ShieldReflectBehavior extends BlockPartBehavior

## 护盾反伤 (Shield Reflect) Behavior
## 翠绿哨兵/废品爆破：获得护盾时对敌人造成 N 伤害
## 与 GrantShieldBehavior 同部件配合（护盾先入队，反伤后入队）
## 用于：荆棘反甲（+3）/ 荆棘之墙（每部件 +3）

@export var ReflectDamage: int = 3

func create_action(block, _part):
	if block == null:
		return null
	var tree: SceneTree = block.get_tree()
	if tree == null:
		return null
	return CallbackAction.new(func():
		_reflect(block, tree)
	, Enums.ActionType.Damage)

func _reflect(block: Block, tree: SceneTree) -> void:
	for node in tree.get_nodes_in_group("Enemies"):
		if node is Node2D:
			var hc: HealthComponent = node.get_node_or_null("RenderingComponent/HealthComponent") as HealthComponent
			if hc != null and not hc.is_dead:
				if ActionManager.Instance != null:
					ActionManager.Instance.add_to_bottom(DamageAction.new(block, node, ReflectDamage))
				GameLog.debug("ShieldReflectBehavior: reflected " + str(ReflectDamage) + " damage")
				return
