extends Resource

const BLOCK_DEFS_PATH: String = "res://resources/block_defs.json"

static func scan_and_register() -> void:
	var file := FileAccess.open(BLOCK_DEFS_PATH, FileAccess.READ)
	if file == null:
		GameLog.err("JsonBlockScanner: Cannot open " + BLOCK_DEFS_PATH)
		return
	
	var json_text := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var parse_result := json.parse(json_text)
	if parse_result != OK:
		GameLog.err("JsonBlockScanner: JSON parse error at line " + str(json.get_error_line()) + ": " + json.get_error_message())
		return
	
	var data = json.get_data()
	if data == null or not data.has("blocks"):
		GameLog.err("JsonBlockScanner: JSON missing 'blocks' array")
		return
	
	var blocks: Array = data["blocks"]
	for block_entry in blocks:
		var block_def: BlockDef = _create_block_def(block_entry)
		if block_def != null:
			BlockRegistry.subscribe_block_def(block_def)
	
	GameLog.info("JsonBlockScanner: Registered " + str(blocks.size()) + " BlockDefs from JSON")

static func _create_block_def(entry: Dictionary) -> BlockDef:
	if not entry.has("name") or entry.name.is_empty():
		GameLog.err("JsonBlockScanner: Block entry missing 'name'")
		return null
	
	var block_def := BlockDef.new()
	block_def.BlockName = entry.name
	block_def.Description = entry.get("description", "")
	block_def.Faction = entry.get("faction", BlockDef.BlockFactionDef.Player)
	
	if entry.has("parts"):
		var parts: Array = []
		for part_entry in entry["parts"]:
			var part_def := _create_part_def(part_entry)
			if part_def != null:
				parts.append(part_def)
			else:
				GameLog.err("JsonBlockScanner: Failed to create part for block '" + entry.name + "'")
		block_def.PartDefinitions = parts
	
	return block_def

static func _create_part_def(entry: Dictionary) -> BlockPartDef:
	var part_def := BlockPartDef.new()
	part_def.PartId = entry.get("partId", "")
	part_def.BaseDamage = entry.get("baseDamage", 0)
	part_def.BaseMagicNum = entry.get("baseMagicNum", 0)
	part_def.BaseShield = entry.get("baseShield", 0)
	part_def.Description = entry.get("description", "")
	
	if entry.has("movingDirection"):
		var dir: Array = entry["movingDirection"]
		part_def.MovingDirection = Vector2i(dir[0], dir[1] if dir.size() > 1 else 0)
	
	if entry.has("partialPosition"):
		var pos: Array = entry["partialPosition"]
		part_def.PartialPosition = Vector2(pos[0], pos[1] if pos.size() > 1 else 0)
	
	if entry.has("spriteTexture"):
		var tex_path: String = entry["spriteTexture"]
		if ResourceLoader.exists(tex_path):
			part_def.SpriteTexture = load(tex_path)
	
	if entry.has("behaviors"):
		var behaviors: Array = []
		for bhv_entry in entry["behaviors"]:
			var behavior := _create_behavior(bhv_entry)
			if behavior != null:
				behaviors.append(behavior)
		part_def.Behaviors = behaviors
	
	return part_def

static func _create_behavior(entry: Dictionary) -> BlockPartBehavior:
	if not entry.has("script"):
		GameLog.err("JsonBlockScanner: Behavior entry missing 'script'")
		return null
	
	var script_path: String = entry["script"]
	if not ResourceLoader.exists(script_path):
		GameLog.err("JsonBlockScanner: Behavior script not found: " + script_path)
		return null
	
	var script_res = load(script_path)
	if script_res == null:
		return null
	
	var behavior: BlockPartBehavior = script_res.new()
	if behavior == null:
		GameLog.err("JsonBlockScanner: Failed to instantiate behavior: " + script_path)
		return null
	
	# Set custom properties if provided
	if entry.has("params"):
		var params: Dictionary = entry["params"]
		for key in params:
			var value = params[key]
			# If value is a string that looks like a resource path, load it
			if typeof(value) == TYPE_STRING and value.begins_with("res://"):
				if ResourceLoader.exists(value):
					value = load(value)
			behavior.set(key, value)
	
	return behavior
