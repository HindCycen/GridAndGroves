class_name DamageAction extends AbstractGameAction

func _init(source_node: Node, target_node: Node, damage: int, dur: float = 0.3):
	super(dur)
	source = source_node
	target = target_node
	amount = damage
	action_type = Enums.ActionType.Damage

var DamageAmount: int:
	get: return amount
	set(v): amount = v

func update(delta: float) -> void:
	if is_done:
		return
	tick_duration(delta)
	if not is_done:
		return
	_trigger_before_damage_hooks()
	var final_damage: int = _apply_damage_modifiers(amount)
	_play_damage_vfx()
	var target_health: HealthComponent = _find_target_health()
	if target_health != null:
		target_health.take_damage(final_damage)
	_trigger_after_damage_hooks()

func _play_damage_vfx() -> void:
	var target_node := target as Node2D
	if target_node == null and source != null:
		var enemies := source.get_tree().get_nodes_in_group("Enemies")
		if enemies.size() > 0:
			target_node = enemies[0] as Node2D
	if target_node != null and is_instance_valid(target_node):
		var vfx := DamageNumberVFX.new(target_node.global_position, amount)
		var tree := target_node.get_tree()
		if tree != null and tree.current_scene != null:
			tree.current_scene.add_child(vfx)

## 应用伤害修正（锈蚀减伤等）
func _apply_damage_modifiers(base_damage: int) -> int:
	var modified: int = base_damage
	# 检查目标是否有 RustStat
	if target is Node2D:
		var rendering = target.get_node_or_null("RenderingComponent")
		if rendering != null:
			var stats_comp: StatsComponent = rendering.StatsComponentRef if rendering != null else null
			if stats_comp != null and stats_comp.has_status("Rust"):
				var rust_stat: Stat = stats_comp.get_status("Rust")
				var rust_layers: int = rust_stat.CurrentValue
				modified = maxi(1, modified - rust_layers)
				GameLog.debug("DamageAction: RustStat reduced damage from " + str(base_damage) + " to " + str(modified))
	return modified

func _trigger_before_damage_hooks() -> void:
	_trigger_damage_hooks(Enums.StatExecuteAt.OnBeforeDamageApply)

func _trigger_after_damage_hooks() -> void:
	_trigger_damage_hooks(Enums.StatExecuteAt.OnAfterDamageApply)

func _trigger_damage_hooks(period: int) -> void:
	var tree := source.get_tree() if source != null else null
	if tree == null:
		return
	var stats_components := tree.get_nodes_in_group("stats_components")
	for node in stats_components:
		if node is StatsComponent:
			var sc: StatsComponent = node as StatsComponent
			for stat in sc.get_all_statuses():
				if stat.Definition != null and stat.Definition.Behavior != null:
					stat.Definition.Behavior.execute_at(period)

func _find_target_health() -> HealthComponent:
	if target is Node2D:
		var hc := _get_health_component(target)
		if hc != null:
			return hc
	return _find_first_alive_enemy_health()

static func _get_health_component(node: Node2D) -> HealthComponent:
	return node.get_node_or_null("RenderingComponent/HealthComponent") as HealthComponent

func _find_first_alive_enemy_health() -> HealthComponent:
	if source == null:
		return null
	var tree := source.get_tree()
	if tree == null:
		return null
	for enemy in tree.get_nodes_in_group("Enemies"):
		if enemy is Node2D:
			var hc: HealthComponent = _get_health_component(enemy)
			if hc != null and not hc.is_dead:
				return hc
	return null
