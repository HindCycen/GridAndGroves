class_name SpendOverloadBoostBehavior extends BlockPartBehavior

## 过载爆发 (Spend Overload Boost) Behavior
## 铁锈游侠：触发时同步消费全部过载层数，
## 伤害 = 部件基础伤害 + 消费层数 × BonusPerLayer
## RustAtLayers > 0 时：消费层数 ≥ RustAtLayers 额外施加 1 层锈蚀
## 用于：蒸汽锤部件 A（每层 +2，≥5 层上锈蚀）/ 磁力收束部件 A（每层 +2）
##
## 注意：与 SpendOverloadBehavior（延迟回调消费）不同，本 Behavior 在 create_action
## 同步消费——因为加成必须直接算进本部件的伤害 Action 数值里。
## 消费端位置与设计文档略有差异（设计把消费放部件 B，此处放伤害部件），
## 数值结果一致（本回合内过载清零），且避免"伤害 Action 已入队无法加成"的顺序问题。

@export var BonusPerLayer: int = 2
@export var RustAtLayers: int = 0  # 0 = 不触发锈蚀条件

func create_action(block, part):
	if block == null:
		return null
	var tree: SceneTree = block.get_tree()
	if tree == null:
		return null
	# 同步消费过载层数
	var overload_layers: int = _consume_overload(tree)
	var base_damage: int = part.Damage if part != null else 0
	var total_damage: int = base_damage + overload_layers * BonusPerLayer
	GameLog.debug("SpendOverloadBoostBehavior: Spent " + str(overload_layers) + " overload, damage " + str(base_damage) + " -> " + str(total_damage))
	# 消费达到阈值时施加锈蚀
	if RustAtLayers > 0 and overload_layers >= RustAtLayers:
		_apply_rust(tree, 1)
	var targets: Array[Node2D] = []
	for node in tree.get_nodes_in_group("Enemies"):
		if node is Node2D:
			var hc: HealthComponent = node.get_node_or_null("RenderingComponent/HealthComponent") as HealthComponent
			if hc != null and not hc.is_dead:
				targets.append(node)
	if targets.size() == 0:
		return null
	for i in range(1, targets.size()):
		if ActionManager.Instance != null:
			ActionManager.Instance.add_to_bottom(DamageAction.new(block, targets[i], total_damage))
	return DamageAction.new(block, targets[0], total_damage, 0.4)

## 消费玩家全部过载层数并返回层数
func _consume_overload(tree: SceneTree) -> int:
	for node in tree.get_nodes_in_group("Players"):
		if node is Node2D:
			var player := node as Node2D
			var rendering = player.get_node("RenderingComponent")
			var stats_comp: StatsComponent = rendering.StatsComponentRef if rendering != null else null
			if stats_comp != null and stats_comp.has_status("Overload"):
				var stat: Stat = stats_comp.get_status("Overload")
				var layers: int = stat.CurrentValue
				stat.set_value(0)
				return layers
	return 0

func _apply_rust(tree: SceneTree, layers: int) -> void:
	var rust_def: Resource = load("res://resources/stat_defs/Rust.tres")
	if rust_def == null:
		return
	for node in tree.get_nodes_in_group("Enemies"):
		if node is Node2D:
			var rendering = node.get_node_or_null("RenderingComponent")
			if rendering == null:
				continue
			var stats_comp: StatsComponent = rendering.StatsComponentRef if rendering != null else null
			if stats_comp == null:
				continue
			if not stats_comp.has_status("Rust"):
				var stat: Stat = Stat.new()
				stat.Definition = rust_def
				stats_comp.add_status(stat)
				stat.add_value(layers)
			else:
				stats_comp.get_status("Rust").add_value(layers)
			GameLog.debug("SpendOverloadBoostBehavior: Applied " + str(layers) + " Rust (overload >= threshold)")
			return
