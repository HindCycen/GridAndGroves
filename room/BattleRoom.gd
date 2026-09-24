class_name BattleRoom extends Room

var _battle_time: BattleTime
var _block_piles_here: BlockPilesHere
var _bot: Bot
var _end_turn_button: Button
var _enemy_manager: EnemyManager
var _battle_resolved: bool
var _is_game_over: bool
var _player: Player
var _player_health: HealthComponent
var _round_number: int
@export var EnemyChart: EnemyChartDef
## 是否为每层终点 Boss 格战斗（由 StageRoom 注入并随存档恢复）——
## Boss 奖励 / 免费商店 / 换层判定全部以此为准，不再依赖可增减的 RoomCount
@export var IsFinalBossCell: bool = false

func _ready() -> void:
	super()
	_save_load = get_tree().root.get_node("SaveLoad")
	if _save_load != null and _save_load.Data != null:
		_save_load.Data.RoomCount += 1
	_block_piles_here = get_node("BlockPilesHere")
	_bot = get_node("Bot")
	_battle_time = get_tree().root.get_node("BattleTime")
	_end_turn_button = %Button as Button
	_enemy_manager = %EnemyManager as EnemyManager
	var action_manager: ActionManager = get_node_or_null("%ActionManager") as ActionManager
	if action_manager == null:
		action_manager = ActionManager.new()
		action_manager.name = "ActionManager"
		add_child(action_manager)
		action_manager.owner = self
	_player = %Player as Player
	_player_health = _player.get_node("RenderingComponent/HealthComponent") as HealthComponent
	_block_piles_here.PlayerCharacter = _player
	if _player_health != null:
		_player_health.died.connect(_on_player_died)
	_battle_resolved = false
	_is_game_over = false
	# 每场战斗重置网格占格：上一场残留的方块随房间销毁，占格必须一并复位，
	# 否则新战斗会出现“看不见的占用格”
	GridState.init_occupy_state()
	_enemy_manager.initialize(_player, _block_piles_here)
	_enemy_manager.all_enemies_defeated.connect(_on_all_enemies_defeated)
	if EnemyChart != null and EnemyChart.EnemyDefs != null:
		_enemy_manager.spawn_from_chart(EnemyChart)
	var enemy_count := _enemy_manager.count_alive()
	GameLog.debug("Detected " + str(enemy_count) + " enemies")
	if enemy_count == 0:
		GameLog.err("No enemies! Please configure EnemyChart.")
		return
	_persist_current_room()
	_end_turn_button.text = "End Turn"
	_end_turn_button.pressed.connect(_on_end_turn_pressed)
	_battle_time.turn_ended.connect(_on_bot_turn_ended)
	_battle_time.battle_ended.connect(_on_battle_ended_cleanup)
	_initialize_player_deck()
	_block_piles_here.initialize_draw_pile()
	_render_unable_grid_cells()
	_setup_pile_viewer_buttons()
	_round_number = 0
	# 存档恢复出 0 血（例如事件扣血后未判死）时直接判负，避免“0 血无敌”
	if _player_health != null and _player_health.is_dead:
		_on_player_died()
		return
	_start_player_turn()

func _on_all_enemies_defeated() -> void:
	if _is_game_over:
		return
	_bot.stop_patrol()
	_on_victory()

## 写入“当前所在房间”存档信息（Continue 恢复现场用）
func _persist_current_room() -> void:
	if _save_load == null or _save_load.Data == null:
		return
	var data: DataResource = _save_load.Data
	data.CurrentRoomType = Enums.RoomType.Battle
	data.CurrentRoomIsBossCell = IsFinalBossCell
	data.CurrentRoomEnemyNames.clear()
	if EnemyChart != null and EnemyChart.EnemyDefs != null:
		for def in EnemyChart.EnemyDefs:
			var enemy_def := def as EnemyDefinition
			if enemy_def != null:
				data.CurrentRoomEnemyNames.append(enemy_def.EnemyName)

func _exit_tree() -> void:
	# 中途退出战斗（BackToStage / 退出游戏）时也清理战斗内临时 Stat，
	# 防止 RemoveOnBattleEnd 状态被 Room._exit_tree 写档后跨战斗残留
	_cleanup_temp_stats()
	if ActionManager.Instance != null:
		ActionManager.Instance.clear()
	if _battle_time != null:
		if _battle_time.turn_ended.is_connected(_on_bot_turn_ended):
			_battle_time.turn_ended.disconnect(_on_bot_turn_ended)
		if _battle_time.battle_ended.is_connected(_on_battle_ended_cleanup):
			_battle_time.battle_ended.disconnect(_on_battle_ended_cleanup)
	if _player_health != null:
		if _player_health.died.is_connected(_on_player_died):
			_player_health.died.disconnect(_on_player_died)
	if _end_turn_button != null:
		if _end_turn_button.pressed.is_connected(_on_end_turn_pressed):
			_end_turn_button.pressed.disconnect(_on_end_turn_pressed)
	if _enemy_manager != null:
		if _enemy_manager.all_enemies_defeated.is_connected(_on_all_enemies_defeated):
			_enemy_manager.all_enemies_defeated.disconnect(_on_all_enemies_defeated)
	# 战斗未结束时退出，回退 RoomCount 防止存档跳过战斗
	if not _battle_resolved and _save_load != null and _save_load.Data != null:
		_save_load.Data.RoomCount -= 1
	super()

func _initialize_player_deck() -> void:
	var player_pile: PileComponent = get_node("Player/PlayerPile") as PileComponent
	if player_pile.Count > 0:
		GameLog.info("Save exists, keeping saved deck")
		GameLog.debug("Player deck initialized, total " + str(player_pile.Count) + " cards")
		return
	var stage_def: StageDef = _get_stage_def()
	var starting_deck: Array[String] = stage_def.StartingDeck if stage_def != null else []
	if starting_deck != null and starting_deck.size() > 0:
		var pool = PackManager.CurrentCardPool
		for block_name in starting_deck:
			# 基础卡（打击/防御）不属于任何卡包，不做卡池校验
			if pool != null and not _is_basic_card(block_name) and not pool.contains_name(block_name):
				GameLog.err("InitializePlayerDeck: block [" + block_name + "] is not in the current card pool, skipped")
				continue
			var block: Block = BlockRegistry.create_block_by_name(block_name)
			if block != null:
				player_pile.add_block(block)
			else:
				GameLog.err("InitializePlayerDeck: Cannot find block [" + block_name + "]")
	else:
		# 兜底牌组：仅使用真实存在的基础卡（旧的 DamageBlock/ExampleMoveRight 等已不存在）
		for i in 4:
			player_pile.add_block(BlockRegistry.create_block_by_name("Strike"))
		for i in 4:
			player_pile.add_block(BlockRegistry.create_block_by_name("Defend"))
	GameLog.debug("Player deck initialized, total " + str(player_pile.Count) + " cards")

## 基础卡名单：不参与卡池校验（与 ShopRoom.BASIC_CARD_NAMES 保持一致）
const BASIC_CARD_NAMES: Array[String] = ["Strike", "Defend"]

func _is_basic_card(block_name: String) -> bool:
	return BASIC_CARD_NAMES.has(block_name)

func _get_stage_def() -> StageDef:
	var path: String = _save_load.Data.StageDefPath if _save_load != null and _save_load.Data != null else ""
	if not path.is_empty():
		var loaded := load(path) as StageDef
		if loaded != null:
			return loaded
	return load("res://resources/EgStageDef.tres") as StageDef

func _start_player_turn() -> void:
	_round_number += 1
	GameLog.info("\n=== Turn " + str(_round_number) + " ===")
	Block.InputLocked = false
	_enemy_manager.clear_old_blocks()
	_enemy_manager.execute_turn()
	_block_piles_here.clear_player_round()
	_battle_time.say_turn_started()
	_block_piles_here.draw_cards(3)
	_end_turn_button.disabled = false
	_end_turn_button.text = "End Turn"

func _on_end_turn_pressed() -> void:
	_end_turn_button.disabled = true
	_end_turn_button.text = "Bot's Turn..."
	GameLog.debug("\n=== Bot Execution Phase ===")
	Block.InputLocked = true
	_bot.start_patrol()

func _on_bot_turn_ended() -> void:
	GameLog.debug("Bot execution finished")
	_enemy_manager.queue_attacks(self, _on_all_enemy_attacks_resolved)

func _on_victory() -> void:
	_battle_resolved = true
	GameLog.info("\n=== Victory! All enemies defeated! ===")
	_end_turn_button.text = "Victory!"
	_end_turn_button.disabled = true
	# 结算后禁止返回地图：否则可重复进入已结算战斗刷金币
	disable_back_to_stage()
	clear_back_target()
	_battle_time.say_battle_ended()
	var is_boss: bool = IsFinalBossCell
	var reward_gold := 0
	if _save_load != null and _save_load.Data != null:
		var room_count: int = _save_load.Data.RoomCount
		# 战后金币奖励 = 难度基准 + 随机浮动（balance.md：3~5 / 5~7，Boss 10~15）
		# 使用 reward RNG 流，保证存档可复现
		if is_boss:
			reward_gold = 10 + RngManager.get_reward_rand(6)
		elif room_count > 6:
			reward_gold = 5 + RngManager.get_reward_rand(3)
		else:
			reward_gold = 3 + RngManager.get_reward_rand(3)
		_save_load.Data.Gold += reward_gold
		GameLog.info("Victory reward: +" + str(reward_gold) + " gold (total: " + str(_save_load.Data.Gold) + ")")
		# 立即把“当前房间”推进到商店：即使此刻退出游戏，Continue 也进入商店，
		# 不会重打 Boss 重复领奖
		_save_load.Data.CurrentRoomType = Enums.RoomType.Shop
		_save_load.Data.CurrentRoomIsBossShop = is_boss
	if is_boss:
		GameLog.info("Boss killed! Shop will be free, then advancing to next floor")
	_end_turn_button.text = "Victory! +" + str(reward_gold) + " Gold"
	_save_load.save()
	# 每场战后进入商店（balance.md 主循环：胜利 → 金币 → 进入商店）
	var timer := get_tree().create_timer(1.2)
	timer.timeout.connect(func():
		if is_instance_valid(self):
			_enter_shop(is_boss)
	)

func _enter_shop(is_boss: bool) -> void:
	var shop_scene := load("res://room/ShopRoom.tscn") as PackedScene
	var shop: ShopRoom = shop_scene.instantiate()
	shop.IsBossShop = is_boss
	get_tree().root.add_child(shop)
	queue_free()

func _on_player_died() -> void:
	if _is_game_over:
		return
	_is_game_over = true
	_on_defeat()

func _on_defeat() -> void:
	_battle_resolved = true
	SaveLoad.RunEnded = true
	GameLog.info("\n=== Defeat! Player has been defeated! ===")
	_end_turn_button.text = "Defeat..."
	_end_turn_button.disabled = true
	disable_back_to_stage()
	_bot.stop_patrol()
	_battle_time.say_battle_ended()
	# 本局结束：清理运行时卡池
	PackManager.clear_card_pool()
	var timer := get_tree().create_timer(1.5)
	timer.timeout.connect(func():
		var game_over_scene := load("res://GameOver.tscn") as PackedScene
		var game_over: Node = game_over_scene.instantiate()
		get_tree().root.add_child(game_over)
		queue_free()
	)

func _on_battle_ended_cleanup() -> void:
	_cleanup_temp_stats()

## 移除战斗内临时 Stat（RemoveOnBattleEnd）
func _cleanup_temp_stats() -> void:
	if not is_instance_valid(_player):
		return
	var rend = _player.get_node_or_null("RenderingComponent")
	var stats_comp: StatsComponent = rend.StatsComponentRef if rend != null else null
	if stats_comp == null:
		return
	var temp_stats: Array[Stat] = []
	for s in stats_comp.get_all_statuses():
		if s.Definition != null and s.Definition.RemoveOnBattleEnd:
			temp_stats.append(s)
	for stat in temp_stats:
		if stats_comp.has_status(stat.Definition.StatName):
			GameLog.info("Battle ended, removing temp status [" + stat.Definition.StatName + "]")
			stats_comp.remove_status(stat.Definition.StatName)

func _on_all_enemy_attacks_resolved() -> void:
	if _is_game_over:
		return
	if _enemy_manager.are_all_dead():
		return
	GameLog.debug("Remaining enemies: " + str(_enemy_manager.count_alive()))
	_start_player_turn()

func _setup_pile_viewer_buttons() -> void:
	var draw_btn := Button.new()
	draw_btn.text = "Draw Pile"
	draw_btn.set_position(Vector2i(20, 1030))
	draw_btn.set_size(Vector2i(120, 40))
	draw_btn.pressed.connect(func(): _show_pile_viewer("Draw Pile", _block_piles_here.DrawPile))
	add_child(draw_btn)
	var discard_btn := Button.new()
	discard_btn.text = "Discard Pile"
	discard_btn.set_position(Vector2i(1780, 1030))
	discard_btn.set_size(Vector2i(120, 40))
	discard_btn.pressed.connect(func(): _show_pile_viewer("Discard Pile", _block_piles_here.DiscardedPile))
	add_child(discard_btn)

func _show_pile_viewer(title: String, pile: PileComponent) -> void:
	var viewer_scene := load("res://components/PileViewer.tscn") as PackedScene
	var viewer := viewer_scene.instantiate() as PileViewer
	viewer.open(title, pile)
	add_child(viewer)

func _render_unable_grid_cells() -> void:
	var texture := load("res://room/battle_background/UnableGrid.png") as Texture2D
	var tex_size := texture.get_size()
	var sprite_scale := Vector2(96 / tex_size.x, 96 / tex_size.y)
	var bg_node := get_node("BackgroundAnimator") as Node2D
	for col in 7:
		for row in 5:
			if GridState.get_grid_state(col, row) != Enums.GridStateEnum.Unable:
				continue
			var sprite := Sprite2D.new()
			sprite.texture = texture
			sprite.scale = sprite_scale
			sprite.z_index = 0
			sprite.global_position = GridState.get_grid_pos(Vector2i(col, row))
			bg_node.add_child(sprite)
