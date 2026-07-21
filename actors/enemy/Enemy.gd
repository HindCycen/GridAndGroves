class_name Enemy extends Node2D

var _ai_component: AIComponent
@export var AttackDamage: int = 10
@export var Definition: EnemyDefinition

func _ready() -> void:
	add_to_group("Enemies")
	_ai_component = get_node_or_null("AIComponent")
	if Definition != null:
		var health: HealthComponent = get_node("RenderingComponent/HealthComponent") as HealthComponent
		if health != null:
			health.set_max_health(Definition.MaxHealth)
			health.died.connect(_on_die)
		if Definition.EnemyImage != null:
			var sprite := get_node("ActorSprite") as AnimatedSprite2D
			if sprite != null:
				var frames := SpriteFrames.new()
				frames.add_frame("default", Definition.EnemyImage)
				sprite.sprite_frames = frames
				sprite.play("default")
		if Definition.InitialStats != null:
			var rendering = get_node("RenderingComponent")
			if rendering != null:
				var stats_comp: StatsComponent = rendering.StatsComponentRef as StatsComponent
				for stat_def in Definition.InitialStats:
					if stat_def != null:
						var stat := Stat.new()
						stat.Definition = stat_def
						stats_comp.add_status(stat)
						stat.add_value(stat_def.MaxValue)

func setup_ai(block_piles_here) -> void:
	if _ai_component == null:
		_ai_component = AIComponent.new()
		add_child(_ai_component)
	_ai_component.setup(block_piles_here)

func execute_turn() -> void:
	if _ai_component != null and Definition != null:
		_ai_component.execute_intent(Definition)

func clear_blocks() -> void:
	if _ai_component != null:
		_ai_component.clear_existing_blocks()

func _on_die() -> void:
	clear_blocks()
	if is_instance_valid(self) and get_parent() != null:
		get_parent().remove_child(self)
	queue_free()
