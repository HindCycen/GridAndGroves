class_name Enemy extends Node2D

var _ai_component: AIComponent
@export var AttackDamage: int = 10
@export var Definition: EnemyDefinition
## 楼层缩放系数（由 EnemyManager 按 StageCount 注入，1.0 = 基准）
@export var ScalingMultiplier: float = 1.0

func _ready() -> void:
	add_to_group("Enemies")
	_ai_component = get_node_or_null("AIComponent")
	if Definition != null:
		# 应用定义中的攻击力（enemy_defs.json 的 attackDamage）并按楼层缩放，
		# 否则 AttackDamage 永远停留在默认值 10
		AttackDamage = roundi(Definition.AttackDamage * ScalingMultiplier)
		var health: HealthComponent = get_node("RenderingComponent/HealthComponent") as HealthComponent
		if health != null:
			health.set_max_health(roundi(Definition.MaxHealth * ScalingMultiplier))
			health.died.connect(_on_die)
		if Definition.EnemyImage != null:
			var sprite := get_node("ActorSprite") as AnimatedSprite2D
			if sprite != null:
				sprite.sprite_frames = _build_sprite_frames(Definition.EnemyImage)
				sprite.play("default")
		if Definition.InitialStats != null:
			var rendering = get_node("RenderingComponent")
			if rendering != null:
				var stats_comp: StatsComponent = rendering.StatsComponentRef as StatsComponent
				var index := 0
				for stat_def in Definition.InitialStats:
					if stat_def != null:
						var stat := Stat.new()
						stat.Definition = stat_def
						stats_comp.add_status(stat)
						# 数值优先取 initialStatValues（与 initialStats 平行），缺省用 StatDef.MaxValue
						var value: int = stat_def.MaxValue
						if index < Definition.InitialStatValues.size():
							value = Definition.InitialStatValues[index]
						stat.add_value(value)
					index += 1
	_update_intent_display()

## 构建敌人 SpriteFrames：
## - 192×192 单帧图 → 单帧动画
## - 384×192（宽 = 高 × 2）→ 左右两张 192×192 组成 2 帧 idle 动画
func _build_sprite_frames(texture: Texture2D) -> SpriteFrames:
	var frames := SpriteFrames.new()
	var w := texture.get_width()
	var h := texture.get_height()
	if w == h * 2:
		for i in 2:
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(i * h, 0, h, h)
			frames.add_frame("default", atlas)
		frames.set_animation_speed("default", 3.0)
	else:
		frames.add_frame("default", texture)
	return frames

## 刷新头顶意图图标（数据来自 JSON 注册的 IntentDefinition.Icon）
func _update_intent_display() -> void:
	var icon_node := get_node_or_null("IntentIcon") as Sprite2D
	if icon_node == null or _ai_component == null or Definition == null:
		return
	var intent: IntentDefinition = _ai_component.get_current_intent(Definition)
	if intent != null and intent.Icon != null:
		icon_node.texture = intent.Icon
		icon_node.visible = true
	else:
		icon_node.visible = false

func setup_ai(block_piles_here) -> void:
	if _ai_component == null:
		_ai_component = AIComponent.new()
		add_child(_ai_component)
	_ai_component.setup(block_piles_here)

func execute_turn() -> void:
	if _ai_component != null and Definition != null:
		_update_intent_display()
		_ai_component.execute_intent(Definition)

func clear_blocks() -> void:
	if _ai_component != null:
		_ai_component.clear_existing_blocks()

func _on_die() -> void:
	clear_blocks()
	if is_instance_valid(self) and get_parent() != null:
		get_parent().remove_child(self)
	queue_free()
