class_name HealBehavior extends BlockPartBehavior

## 治疗 (Heal) Behavior
## 治疗玩家：量取部件 Heal 字段（JSON baseHeal），或参数 HealAmount
## 用于：治愈孢子 / 绿叶 / 光合作用 / 吸血藤 / 千年古树 / 急救包 / 绷带等

@export var HealAmount: int = 0  # >0 时覆盖 part.Heal

func create_action(block, part):
	if block == null:
		return null
	var tree: SceneTree = block.get_tree()
	if tree == null:
		return null
	var amount: int = HealAmount if HealAmount > 0 else (part.Heal if part != null else 0)
	if amount <= 0:
		return null
	for node in tree.get_nodes_in_group("Players"):
		if node is Node2D:
			return HealAction.new(node, amount)
	return null
