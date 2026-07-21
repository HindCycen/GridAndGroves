extends Node

const DEFAULT_SAVE_PATH := "user://savegame.tres"

var Data = null

func _ready() -> void:
    Data = DataResource.new()

func save(path := DEFAULT_SAVE_PATH) -> void:
    sync_from_game_state()
    var result := ResourceSaver.save(Data, path)
    if result != OK:
        GameLog.err("SaveLoad: Save failed (" + str(result) + ")")

func load(path := DEFAULT_SAVE_PATH) -> void:
    if not ResourceLoader.exists(path):
        GameLog.info("SaveLoad: Save file not found (" + path + "), using default data")
        return
    var loaded := ResourceLoader.load(path)
    if loaded == null:
        GameLog.err("SaveLoad: Failed to load save")
        return
    Data = loaded
    sync_to_game_state()

func sync_from_game_state() -> void:
    Data.Seed = RngManager.get_current_seed()
    Data.MapRandUsage = RngManager.get_map_rand_usage()
    Data.MonsterRandUsage = RngManager.get_monster_rand_usage()
    Data.RewardRandUsage = RngManager.get_reward_rand_usage()
    Data.ChestRandUsage = RngManager.get_chest_rand_usage()
    Data.MiscRandUsage = RngManager.get_misc_rand_usage()
    Data.PileRandUsage = RngManager.get_pile_rand_usage()
    save_stage_map()
    var player := get_tree().get_first_node_in_group("Players")
    if player == null:
        return
    var health := player.get_node("RenderingComponent/HealthComponent")
    if health != null:
        Data.PlayerCurrentHealth = health.CurrentHealth
        Data.PlayerMaxHealth = health.MaxHealth
    var pile := player.get_node("%PlayerPile")
    if pile != null:
        var names: Array[String] = []
        for b in pile.Pile:
            if not is_instance_valid(b):
                continue
            if b.Definition != null and b.Definition.BlockName != null:
                names.append(b.Definition.BlockName)
        Data.PlayerDeckBlockNames = names
    var rend := player.get_node("RenderingComponent")
    if rend != null and rend.StatsComponentRef != null:
        var stats: Array = rend.StatsComponentRef.get_all_statuses()
        var stat_names: Array[String] = []
        var stat_values: Array[int] = []
        for s in stats:
            if s.Definition != null and s.Definition.StatName != null:
                stat_names.append(s.Definition.StatName)
                stat_values.append(s.CurrentValue)
        Data.PlayerStatNames = stat_names
        Data.PlayerStatValues = stat_values

func sync_to_game_state() -> void:
    RngManager.restore_rng_from_usage(Data.Seed, Data.MapRandUsage, Data.MonsterRandUsage, Data.RewardRandUsage, Data.ChestRandUsage, Data.MiscRandUsage, Data.PileRandUsage)
    restore_stage_map()
    var player := get_tree().get_first_node_in_group("Players")
    if player == null:
        return
    player.StageCount = Data.StageCount
    player.RoomCount = Data.RoomCount
    var health := player.get_node("RenderingComponent/HealthComponent")
    if health != null and Data.PlayerMaxHealth > 0:
        health.set_max_health(Data.PlayerMaxHealth)
        health.set_current_health(Data.PlayerCurrentHealth)
    var pile := player.get_node("%PlayerPile")
    if pile != null and Data.PlayerDeckBlockNames != null:
        var existing = pile.Pile.duplicate()
        for b in existing:
            pile.remove_block(b)
            b.queue_free()
        for block_name in Data.PlayerDeckBlockNames:
            var block: Block = BlockRegistry.create_block_by_name(block_name)
            if block != null:
                pile.add_block(block)
    var rend = player.get_node("RenderingComponent")
    if rend != null and rend.StatsComponentRef != null and Data.PlayerStatNames != null and Data.PlayerStatValues != null:
        var stats_comp: StatsComponent = rend.StatsComponentRef
        var count = mini(Data.PlayerStatNames.size(), Data.PlayerStatValues.size())
        for i in count:
            var stat = stats_comp.get_status(Data.PlayerStatNames[i])
            if stat != null:
                stat.set_value(Data.PlayerStatValues[i])
            else:
                var stat_def := load("res://resources/stat_defs/" + Data.PlayerStatNames[i] + ".tres")
                if stat_def != null:
                    stat = Stat.new()
                    stat.Definition = stat_def
                    stats_comp.add_status(stat)
                    stat.set_value(Data.PlayerStatValues[i])

func save_stage_map() -> void:
    var stage: StageRoom = StageRoom.Current if has_node("/root/StageRoom") else null
    if stage == null or stage.Clickable == null:
        return
    var cols = StageRoom.Cols
    var rows = StageRoom.Rows
    var _total = cols * rows
    var clickable: Array[int] = []
    var left: Array[int] = []
    var is_battle: Array[int] = []
    for col in cols:
        for row in rows:
            clickable.append(1 if stage.Clickable[col][row] else 0)
            left.append(1 if stage.Left[col][row] else 0)
            is_battle.append(1 if stage.IsBattleCell[col][row] else 0)
    Data.GridClickable = clickable
    Data.GridLeft = left
    Data.GridIsBattleCell = is_battle

static func restore_stage_map() -> void:
    GameLog.debug("SaveLoad.restoreStageMap: Map restoration handled by StageRoom.tryRestoreMapFromSave()")

func reset_for_new_game() -> void:
    Data = DataResource.new()
    Data.StageCount = 1
    Data.RoomCount = 0
    Data.PlayerCurrentHealth = 100
    Data.PlayerMaxHealth = 100
    Data.StageDefPath = "res://resources/EgStageDef.tres"
    RngManager.init_seed(0)
    RngManager.init_rng()
    GridState.init_grids()

func advance_to_next_floor() -> void:
    Data.StageCount += 1
    Data.RoomCount = 0
    Data.GridClickable = []
    Data.GridLeft = []
    Data.GridIsBattleCell = []
    GridState.init_grids()
    RngManager.init_seed(Data.Seed + Data.StageCount * 7919)
    RngManager.init_rng()
    save()
