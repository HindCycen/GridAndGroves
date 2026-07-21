class_name EnemyManager extends Node

signal enemy_died()
signal all_enemies_defeated()

var _block_piles_here
var _enemies: Array[Enemy] = []
var _player: Player

func initialize(player: Player, block_piles_here) -> void:
	_player = player
	_block_piles_here = block_piles_here

func spawn_from_chart(chart: EnemyChartDef) -> void:
	var existing: Array[Node] = get_tree().get_nodes_in_group("Enemies")
	for enemy in existing:
		if enemy is Enemy and is_instance_valid(enemy):
			if enemy.get_parent() != null:
				enemy.get_parent().remove_child(enemy)
			enemy.queue_free()
	if chart == null or chart.EnemyDefs == null:
		_enemies = []
		return
	var index := 0
	for enemy_def in chart.EnemyDefs:
		if enemy_def == null:
			continue
		var enemy_scene := load("res://actors/enemy/Enemy.tscn") as PackedScene
		var enemy := enemy_scene.instantiate() as Enemy
		enemy.Definition = enemy_def
		enemy.position = Vector2(1300 + index * 200, 150 + (index % 2) * 200)
		add_child(enemy)
		GameLog.debug("SpawnFromChart: Spawned enemy " + enemy_def.EnemyName + " at (" + str(enemy.position.x) + ", " + str(enemy.position.y) + ")")
		index += 1
	_refresh_enemy_list()
	for enemy in _enemies:
		enemy.setup_ai(_block_piles_here)
		var hc := enemy.get_node_or_null("RenderingComponent/HealthComponent") as HealthComponent
		if hc != null:
			hc.died.connect(_on_enemy_died)

func clear_old_blocks() -> void:
	_refresh_enemy_list()
	GameLog.debug("Clearing " + str(_enemies.size()) + " enemies' old blocks")
	for enemy in _enemies:
		if not is_instance_valid(enemy):
			continue
		var hc := enemy.get_node_or_null("RenderingComponent/HealthComponent") as HealthComponent
		if hc == null or hc.is_dead:
			continue
		enemy.clear_blocks()

func execute_turn() -> void:
	_refresh_enemy_list()
	GameLog.debug("Executing AI for " + str(_enemies.size()) + " enemies")
	for enemy in _enemies:
		if not is_instance_valid(enemy):
			continue
		var hc := enemy.get_node_or_null("RenderingComponent/HealthComponent") as HealthComponent
		if hc == null or hc.is_dead:
			continue
		enemy.execute_turn()

func queue_attacks(_source: Node, on_all_resolved: Callable) -> void:
	_refresh_enemy_list()
	for enemy in _enemies:
		if not is_instance_valid(enemy):
			continue
		var hc := enemy.get_node_or_null("RenderingComponent/HealthComponent") as HealthComponent
		if hc == null or hc.is_dead:
			continue
		var damage := enemy.AttackDamage
		GameLog.debug("Enemy " + enemy.name + " deals " + str(damage) + " damage to player")
		if ActionManager.Instance != null:
			ActionManager.Instance.add_to_bottom(DamageAction.new(enemy, _player, damage, 0.2))
	if ActionManager.Instance != null:
		ActionManager.Instance.add_to_bottom(CallbackAction.new(on_all_resolved))

func are_all_dead() -> bool:
	_refresh_enemy_list()
	if _enemies.size() == 0:
		return true
	for e in _enemies:
		if not is_instance_valid(e):
			continue
		var hc := e.get_node_or_null("RenderingComponent/HealthComponent") as HealthComponent
		if hc != null and not hc.is_dead:
			return false
	return true

func count_alive() -> int:
	_refresh_enemy_list()
	var count := 0
	for e in _enemies:
		if not is_instance_valid(e):
			continue
		var hc := e.get_node_or_null("RenderingComponent/HealthComponent") as HealthComponent
		if hc != null and not hc.is_dead:
			count += 1
	return count

func _on_enemy_died() -> void:
	enemy_died.emit()
	if are_all_dead():
		all_enemies_defeated.emit()

func _refresh_enemy_list() -> void:
	_enemies = []
	for e in get_tree().get_nodes_in_group("Enemies"):
		if e is Enemy:
			_enemies.append(e as Enemy)
