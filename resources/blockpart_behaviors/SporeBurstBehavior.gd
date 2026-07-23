class_name SporeBurstBehavior extends BlockPartBehavior

## 孢子蔓延 (Spore Burst) Behavior
## 翠绿哨兵：藤蔓层数达到 5/10/15 层时触发 AOE 爆发
## 每次爆发有独立触发标记，同一阈值只触发一次
## 爆发效果：
##   Lv1 (5 层): 对所有敌人造成 3 伤害
##   Lv2 (10 层): 对所有敌人造成 5 伤害 + 施加 1 层藤蔓
##   Lv3 (15 层): 对所有敌人造成 8 伤害 + 施加 2 层藤蔓 + 治疗玩家 3 HP

## 此 Behavior 直接返回一个 CallbackAction，检查并触发孢子爆发
## 实际使用中建议由触发藤蔓的 Block 携带此 Behavior

var _lv1_triggered: bool = false
var _lv2_triggered: bool = false
var _lv3_triggered: bool = false

func create_action(block, part):
	if block == null:
		return null
	return CallbackAction.new(func():
		_check_and_trigger(block)
	, Enums.ActionType.Callback)

func _check_and_trigger(block: Block) -> void:
	var tree := block.get_tree()
	if tree == null:
		return
	# 检查所有敌人身上的藤蔓层数，取最高值
	var max_vine_layers: int = 0
	for enemy in tree.get_nodes_in_group("Enemies"):
		if enemy is Node2D:
			var rendering = enemy.get_node_or_null("RenderingComponent")
			if rendering == null:
				continue
			var stats_comp: StatsComponent = rendering.StatsComponentRef if rendering != null else null
			if stats_comp != null and stats_comp.has_status("Vine"):
				var vine_stat: Stat = stats_comp.get_status("Vine")
				if vine_stat.CurrentValue > max_vine_layers:
					max_vine_layers = vine_stat.CurrentValue
	# 按顺序检查阈值并触发
	if max_vine_layers >= 15 and not _lv3_triggered:
		_lv3_triggered = true
		_trigger_lv3(block, tree)
		return  # 一次只触发最高等级
	if max_vine_layers >= 10 and not _lv2_triggered:
		_lv2_triggered = true
		_trigger_lv2(block, tree)
		return
	if max_vine_layers >= 5 and not _lv1_triggered:
		_lv1_triggered = true
		_trigger_lv1(block, tree)

func _trigger_lv1(block: Block, tree: SceneTree) -> void:
	GameLog.debug("SporeBurstBehavior: Lv1 triggered! Vine >= 5, AOE 3 damage to all enemies")
	for enemy in tree.get_nodes_in_group("Enemies"):
		if enemy is Node2D:
			var hc: HealthComponent = enemy.get_node_or_null("RenderingComponent/HealthComponent") as HealthComponent
			if hc != null and not hc.is_dead:
				if ActionManager.Instance != null:
					ActionManager.Instance.add_to_bottom(DamageAction.new(block, enemy, 3))

func _trigger_lv2(block: Block, tree: SceneTree) -> void:
	GameLog.debug("SporeBurstBehavior: Lv2 triggered! Vine >= 10, AOE 5 damage + 1 Vine to all enemies")
	var vine_def: Resource = load("res://resources/stat_defs/Vine.tres")
	for enemy in tree.get_nodes_in_group("Enemies"):
		if enemy is Node2D:
			var hc: HealthComponent = enemy.get_node_or_null("RenderingComponent/HealthComponent") as HealthComponent
			if hc != null and not hc.is_dead:
				if ActionManager.Instance != null:
					ActionManager.Instance.add_to_bottom(DamageAction.new(block, enemy, 5))
				# 额外施加 1 层藤蔓
				if vine_def != null:
					var rendering = enemy.get_node_or_null("RenderingComponent")
					if rendering != null:
						var stats_comp: StatsComponent = rendering.StatsComponentRef if rendering != null else null
						if stats_comp != null:
							if not stats_comp.has_status("Vine"):
								var stat: Stat = Stat.new()
								stat.Definition = vine_def
								stats_comp.add_status(stat)
								stat.add_value(1)
							else:
								var existing: Stat = stats_comp.get_status("Vine")
								if existing != null:
									existing.add_value(1)

func _trigger_lv3(block: Block, tree: SceneTree) -> void:
	GameLog.debug("SporeBurstBehavior: Lv3 triggered! Vine >= 15, AOE 8 damage + 2 Vine + heal 3 HP")
	var vine_def: Resource = load("res://resources/stat_defs/Vine.tres")
	for enemy in tree.get_nodes_in_group("Enemies"):
		if enemy is Node2D:
			var hc: HealthComponent = enemy.get_node_or_null("RenderingComponent/HealthComponent") as HealthComponent
			if hc != null and not hc.is_dead:
				if ActionManager.Instance != null:
					ActionManager.Instance.add_to_bottom(DamageAction.new(block, enemy, 8))
				if vine_def != null:
					var rendering = enemy.get_node_or_null("RenderingComponent")
					if rendering != null:
						var stats_comp: StatsComponent = rendering.StatsComponentRef if rendering != null else null
						if stats_comp != null:
							if not stats_comp.has_status("Vine"):
								var stat: Stat = Stat.new()
								stat.Definition = vine_def
								stats_comp.add_status(stat)
								stat.add_value(2)
							else:
								var existing: Stat = stats_comp.get_status("Vine")
								if existing != null:
									existing.add_value(2)
	# 治疗玩家
	for node in tree.get_nodes_in_group("Players"):
		if node is Node2D:
			var player := node as Node2D
			var hc: HealthComponent = player.get_node_or_null("RenderingComponent/HealthComponent") as HealthComponent
			if hc != null:
				hc.heal(3)
				GameLog.debug("SporeBurstBehavior: Lv3 heal 3 HP")
			return
