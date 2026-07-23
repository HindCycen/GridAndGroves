extends Resource

const ENEMY_DEFS_PATH: String = "res://resources/enemy_defs.json"

## 扫描 enemy_defs.json 并注册所有敌人定义到 BlockRegistry
static func scan_and_register() -> void:
	var file := FileAccess.open(ENEMY_DEFS_PATH, FileAccess.READ)
	if file == null:
		GameLog.err("JsonEnemyScanner: Cannot open " + ENEMY_DEFS_PATH)
		return
	
	var json_text := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var parse_result := json.parse(json_text)
	if parse_result != OK:
		GameLog.err("JsonEnemyScanner: JSON parse error at line " + str(json.get_error_line()) + ": " + json.get_error_message())
		return
	
	var data = json.get_data()
	if data == null or not data.has("enemies"):
		GameLog.err("JsonEnemyScanner: JSON missing 'enemies' array")
		return
	
	# 注册敌人定义
	var enemies: Array = data["enemies"]
	var registered_count := 0
	for enemy_entry in enemies:
		var enemy_def: EnemyDefinition = _create_enemy_def(enemy_entry)
		if enemy_def != null:
			BlockRegistry.subscribe_enemy_def(enemy_def)
			registered_count += 1
	
	GameLog.info("JsonEnemyScanner: Registered " + str(registered_count) + " EnemyDefs from JSON")
	
	# 注册关卡敌人图表配置
	if data.has("stageCharts"):
		var stage_charts: Dictionary = data["stageCharts"]
		for stage_key in stage_charts:
			var chart_config: Dictionary = stage_charts[stage_key]
			BlockRegistry.subscribe_stage_chart(stage_key, chart_config)
		GameLog.info("JsonEnemyScanner: Registered " + str(stage_charts.size()) + " stage chart configs from JSON")

## 从 JSON 字典构建 EnemyDefinition
static func _create_enemy_def(entry: Dictionary) -> EnemyDefinition:
	if not entry.has("enemyName") or entry.enemyName.is_empty():
		GameLog.err("JsonEnemyScanner: Enemy entry missing 'enemyName'")
		return null
	
	var enemy_def := EnemyDefinition.new()
	enemy_def.EnemyName = entry.enemyName
	enemy_def.MaxHealth = entry.get("maxHealth", 50)
	enemy_def.AttackDamage = entry.get("attackDamage", 10)
	
	# 加载敌人图片
	if entry.has("enemyImage"):
		var img_path: String = entry.enemyImage
		if ResourceLoader.exists(img_path):
			enemy_def.EnemyImage = load(img_path)
		else:
			GameLog.err("JsonEnemyScanner: Enemy image not found: " + img_path)
	
	# 加载初始 StatDef
	if entry.has("initialStats"):
		var stats: Array = []
		for stat_path in entry.initialStats:
			if typeof(stat_path) == TYPE_STRING and ResourceLoader.exists(stat_path):
				stats.append(load(stat_path))
			else:
				GameLog.err("JsonEnemyScanner: StatDef not found: " + str(stat_path) + " for enemy '" + entry.enemyName + "'")
		enemy_def.InitialStats = stats
	
	# 构建意图循环
	if entry.has("intentCycle"):
		var intents: Array = []
		for intent_entry in entry.intentCycle:
			var intent_def := _create_intent_def(intent_entry)
			if intent_def != null:
				intents.append(intent_def)
		enemy_def.IntentCycle = intents
	
	return enemy_def

## 从 JSON 字典构建 IntentDefinition
static func _create_intent_def(entry: Dictionary) -> IntentDefinition:
	var intent_def := IntentDefinition.new()
	intent_def.IntentName = entry.get("intentName", "")
	intent_def.RepeatCount = entry.get("repeatCount", 1)
	
	if entry.has("blockPlacements"):
		var placements: Array = []
		for placement_entry in entry.blockPlacements:
			var placement_def := _create_placement_def(placement_entry)
			if placement_def != null:
				placements.append(placement_def)
			else:
				GameLog.err("JsonEnemyScanner: Failed to create BlockPlacementDef for intent '" + intent_def.IntentName + "'")
		intent_def.BlockPlacements = placements
	
	return intent_def

## 从 JSON 字典构建 BlockPlacementDef
##
## blockName 通过名称引用 BlockDef，运行时由 BlockRegistry 按名查找。
static func _create_placement_def(entry: Dictionary) -> BlockPlacementDef:
	var placement_def := BlockPlacementDef.new()
	
	var block_name: String = entry.get("blockName", "")
	if block_name.is_empty():
		GameLog.err("JsonEnemyScanner: BlockPlacementDef missing 'blockName'")
		return null
	placement_def.BlockName = block_name
	
	if entry.has("gridPosition"):
		var pos: Array = entry.gridPosition
		placement_def.GridPosition = Vector2i(pos[0], pos[1] if pos.size() > 1 else 0)
	
	placement_def.RandomOffsetRange = entry.get("randomOffsetRange", 1)
	
	return placement_def
