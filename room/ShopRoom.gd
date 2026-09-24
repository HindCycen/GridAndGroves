class_name ShopRoom extends Room

## 经济与卡组规则常量（对齐 planning/card_pack_design/balance.md 商店章节）：
## - 可购买：从当前卡池按稀有度权重刷 4 件（Boss 战后 5 件、全免费、不可重掷）
## - 重掷：第 1 次 3 金，之后每次 +1
## - 售卖：打击/防御 1 金；其他 = 买入基准价 × 1/2（向下取整）
## - 离店检查：卡组 < DECK_MIN 自动补打击/防御到下限；> DECK_MAX 禁止离店
const BASIC_CARD_NAMES: Array[String] = ["Strike", "Defend"]
const RARITY_NAMES: Array[String] = ["普通", "稀有", "史诗", "传说"]
## 各稀有度买入基准价（用于售价 = 买入价 × 1/2）
const BASE_PRICES: Dictionary = {0: 9, 1: 18, 2: 30, 3: 50}
## 各稀有度买入价区间（商店随机取值）
const PRICE_RANGES: Dictionary = {0: [8, 10], 1: [15, 20], 2: [25, 35], 3: [40, 60]}
const DECK_MIN := 15
const DECK_MAX := 50
const DEFAULT_SLOTS := 4
const BOSS_SLOTS := 5
const REROLL_BASE_COST := 3

## 是否为 Boss 战后商店（balance.md：多 1 件商品、全部 0 金币、不可重掷）
var IsBossShop: bool = false

var _items: Array = []
var _reroll_count: int = 0
var _active_tooltips: Array = []
var _info_label: Label
var _items_container: VBoxContainer
var _deck_container: VBoxContainer
var _leave_btn: Button
var _reroll_btn: Button
var _preview_holder: Node2D
var _preview_title: Label
var _preview_block: Block

func _ready() -> void:
	super()
	# 记录当前房间（Continue 恢复现场用）
	if _save_load != null and _save_load.Data != null:
		_save_load.Data.CurrentRoomType = Enums.RoomType.Shop
		_save_load.Data.CurrentRoomIsBossShop = IsBossShop
	# 商店是战后的必经流程，不提供返回地图按钮（BackToStage 隐藏）
	var back_btn := %BackToStageBtn as TextureButton
	if back_btn != null:
		back_btn.visible = false
	_info_label = %ShopInfoLabel as Label
	_items_container = %ItemsContainer as VBoxContainer
	_deck_container = %DeckContainer as VBoxContainer
	_leave_btn = %LeaveShopBtn as Button
	if _leave_btn != null:
		_leave_btn.pressed.connect(_on_leave_pressed)
	_reroll_btn = %RerollBtn as Button
	if _reroll_btn != null:
		_reroll_btn.pressed.connect(_on_reroll_pressed)
	_preview_holder = get_node_or_null("PreviewPanel/PreviewHolder") as Node2D
	_preview_title = get_node_or_null("PreviewPanel/PreviewTitle") as Label
	_generate_items()
	_refresh_ui()

# ── 商品生成 ──

func _generate_items() -> void:
	_items.clear()
	var pool = PackManager.CurrentCardPool
	if pool == null:
		GameLog.err("ShopRoom: CurrentCardPool is null, cannot generate shop items")
		return
	var slots := BOSS_SLOTS if IsBossShop else DEFAULT_SLOTS
	var used := {}
	for i in slots:
		var rarity: int = BlockRegistry.pick_random_rarity()
		var candidates: Array[String] = []
		for name in pool.AllBlockNames:
			if used.has(name):
				continue
			var def: Dictionary = BlockRegistry.BlockDefs.get(name, {})
			if int(def.get("rarity", 0)) == rarity:
				candidates.append(name)
		if candidates.is_empty():
			# 回退：该稀有度在卡池中无可用内容，取任意未上架块
			for name in pool.AllBlockNames:
				if not used.has(name):
					candidates.append(name)
		if candidates.is_empty():
			break
		var picked: String = candidates[RngManager.get_misc_rand(candidates.size())]
		used[picked] = true
		_items.append({"name": picked, "rarity": rarity, "price": _roll_price(rarity)})

func _roll_price(rarity: int) -> int:
	if IsBossShop:
		return 0
	var r: Array = PRICE_RANGES[rarity]
	return int(r[0]) + RngManager.get_reward_rand(int(r[1]) - int(r[0]) + 1)

# ── UI 刷新 ──

func _refresh_ui() -> void:
	_refresh_items_ui()
	_refresh_deck_ui()
	_update_gold_label()

func _refresh_items_ui() -> void:
	if _items_container == null:
		return
	for child in _items_container.get_children():
		child.queue_free()
	var gold: int = _save_load.Data.Gold if _save_load != null and _save_load.Data != null else 0
	for item in _items:
		var rarity: int = item["rarity"]
		var price: int = item["price"]
		var btn := Button.new()
		btn.text = item["name"] + "（" + RARITY_NAMES[rarity] + "）— " + str(price) + " G"
		btn.custom_minimum_size = Vector2(500, 54)
		btn.add_theme_font_size_override("font_size", 20)
		if price > gold:
			btn.disabled = true
		var block_name: String = item["name"]
		btn.mouse_entered.connect(func():
			_show_tooltip(btn, _describe_block(block_name))
			_show_preview(block_name)
		)
		btn.mouse_exited.connect(_hide_tooltips)
		var captured_item: Dictionary = item
		btn.pressed.connect(func(): _on_buy_pressed(captured_item))
		_items_container.add_child(btn)
	if _reroll_btn != null:
		var cost := _reroll_cost()
		_reroll_btn.text = "重掷商品（" + str(cost) + " G）"
		_reroll_btn.disabled = IsBossShop or cost > gold

func _refresh_deck_ui() -> void:
	if _deck_container == null:
		return
	for child in _deck_container.get_children():
		child.queue_free()
	var data: DataResource = _save_load.Data if _save_load != null else null
	var deck: Array = data.PlayerDeckBlockNames if data != null else []
	var counts := {}
	for name in deck:
		counts[name] = counts.get(name, 0) + 1
	var title := Label.new()
	title.text = "当前卡组（" + str(deck.size()) + " 张，点击卖出）"
	title.add_theme_font_size_override("font_size", 22)
	title.custom_minimum_size = Vector2(560, 36)
	_deck_container.add_child(title)
	for block_name in counts.keys():
		var count: int = counts[block_name]
		var sell_price := _sell_price_of(block_name)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var label := Label.new()
		label.text = block_name + " ×" + str(count)
		label.custom_minimum_size = Vector2(320, 44)
		label.add_theme_font_size_override("font_size", 19)
		row.add_child(label)
		var sell_btn := Button.new()
		sell_btn.text = "卖出 +" + str(sell_price) + " G"
		sell_btn.custom_minimum_size = Vector2(180, 44)
		sell_btn.add_theme_font_size_override("font_size", 18)
		var captured_name: String = block_name
		sell_btn.pressed.connect(func(): _on_sell_pressed(captured_name))
		row.add_child(sell_btn)
		# 悬停卡组条目 / 卖出按钮时预览该 Block 的完整形状
		row.mouse_entered.connect(func(): _show_preview(captured_name))
		sell_btn.mouse_entered.connect(func(): _show_preview(captured_name))
		label.mouse_entered.connect(func(): _show_preview(captured_name))
		_deck_container.add_child(row)

# ── 购买 / 重掷 / 售卖 ──

func _on_buy_pressed(item: Dictionary) -> void:
	var data: DataResource = _save_load.Data if _save_load != null else null
	if data == null:
		return
	var block_name: String = item["name"]
	var price: int = item["price"]
	if price > data.Gold:
		_show_info("金币不足，无法购买 " + block_name)
		return
	if data.PlayerDeckBlockNames.size() >= DECK_MAX:
		_show_info("卡组已达上限 " + str(DECK_MAX) + " 张，无法购买")
		return
	_items.erase(item)
	data.Gold -= price
	_add_block_to_deck(block_name)
	_show_info("购买了 " + block_name + "（-" + str(price) + " G）")
	_refresh_ui()

func _on_reroll_pressed() -> void:
	var data: DataResource = _save_load.Data if _save_load != null else null
	if data == null:
		return
	if IsBossShop:
		_show_info("Boss 战后商店不可重掷")
		return
	var cost := _reroll_cost()
	if data.Gold < cost:
		_show_info("金币不足，重掷需要 " + str(cost) + " G")
		return
	data.Gold -= cost
	_reroll_count += 1
	_generate_items()
	_show_info("已重掷商品（-"+ str(cost) + " G），下次重掷 " + str(_reroll_cost()) + " G")
	_refresh_ui()

func _on_sell_pressed(block_name: String) -> void:
	var data: DataResource = _save_load.Data if _save_load != null else null
	if data == null:
		return
	var price := _sell_price_of(block_name)
	if _remove_block_from_deck(block_name):
		data.Gold += price
		_show_info("卖出了 " + block_name + "（+" + str(price) + " G）")
	_refresh_ui()

func _reroll_cost() -> int:
	return REROLL_BASE_COST + _reroll_count

func _sell_price_of(block_name: String) -> int:
	if BASIC_CARD_NAMES.has(block_name):
		return 1
	var def: Dictionary = BlockRegistry.BlockDefs.get(block_name, {})
	var rarity: int = int(def.get("rarity", 0))
	return int(BASE_PRICES[rarity] / 2.0)

# ── 卡组操作（与存档 & 玩家卡组保持同步） ──

func _player_pile() -> PileComponent:
	var player := get_tree().get_first_node_in_group("Players")
	if player == null:
		return null
	return player.get_node_or_null("%PlayerPile") as PileComponent

func _add_block_to_deck(block_name: String) -> void:
	var pile := _player_pile()
	var block: Block = BlockRegistry.create_block_by_name(block_name)
	if block != null and pile != null:
		pile.add_block(block)
	if _save_load != null and _save_load.Data != null:
		_save_load.Data.PlayerDeckBlockNames.append(block_name)

func _remove_block_from_deck(block_name: String) -> bool:
	var pile := _player_pile()
	if pile != null:
		for b in pile.Pile:
			if is_instance_valid(b) and b.BlockName == block_name:
				pile.remove_block(b)
				b.queue_free()
				break
	if _save_load != null and _save_load.Data != null:
		# 注意：Array[String].erase() 返回 void，须先 find 再 remove_at
		var deck: Array[String] = _save_load.Data.PlayerDeckBlockNames
		var index := deck.find(block_name)
		if index >= 0:
			deck.remove_at(index)
			return true
	return false

# ── 离店 ──

func _on_leave_pressed() -> void:
	var data: DataResource = _save_load.Data if _save_load != null else null
	if data == null:
		return
	var deck: Array = data.PlayerDeckBlockNames
	if deck.size() > DECK_MAX:
		_show_info("卡组超过 " + str(DECK_MAX) + " 张，请先售卖到 " + str(DECK_MAX) + " 张以内")
		return
	if _leave_btn != null:
		_leave_btn.disabled = true
	if deck.size() < DECK_MIN:
		var need := DECK_MIN - deck.size()
		_auto_top_up(need)
		GameLog.info("ShopRoom: 卡组不足 " + str(DECK_MIN) + " 张，已自动补入 " + str(need) + " 张打击/防御并离店")
	# 补牌后立即离店（不再停留），避免"卖出打防 → 离店补牌 → 再卖出"的刷金币循环
	_leave_shop()

## 自动补打击/防御到下限：尽量均衡，不能均衡时防御更多
func _auto_top_up(need: int) -> void:
	var strikes_to_add := int(need / 2)
	var defends_to_add := need - strikes_to_add
	for i in strikes_to_add:
		_add_block_to_deck("Strike")
	for i in defends_to_add:
		_add_block_to_deck("Defend")

func _leave_shop() -> void:
	if _save_load == null:
		return
	# 商店已结算：清空返回目标，防止地图返回按钮重进已结算战斗/事件
	clear_back_target()
	# Boss 战后商店离店 → 通关判定 / 进入下一层
	if IsBossShop:
		if _save_load.Data != null and _save_load.Data.StageCount >= SaveLoad.FINAL_STAGE:
			_go_victory()
			return
		_save_load.advance_to_next_floor()
	_save_load.save()
	var stage_scene := load("res://room/StageRoom.tscn") as PackedScene
	var stage: StageRoom = stage_scene.instantiate()
	get_tree().root.add_child(stage)
	queue_free()

## 通关结算：结束本局（删档）、清理卡池、进入 Victory 画面
func _go_victory() -> void:
	PackManager.clear_card_pool()
	SaveLoad.RunEnded = true
	if _save_load != null:
		_save_load.save()  # RunEnded = true 时内部会删除存档文件
	GameLog.info("\n=== Victory! Run completed at stage " + str(_save_load.Data.StageCount) + " ===")
	var victory_scene := load("res://Victory.tscn") as PackedScene
	var victory: Node = victory_scene.instantiate()
	get_tree().root.add_child(victory)
	queue_free()

# ── 辅助 ──

func _show_info(text: String) -> void:
	if _info_label != null:
		_info_label.text = text

func _describe_block(block_name: String) -> String:
	var def: Dictionary = BlockRegistry.BlockDefs.get(block_name, {})
	var desc: String = def.get("description", "")
	if desc.is_empty():
		desc = "（无描述）"
	var rarity: int = int(def.get("rarity", 0))
	return block_name + " [" + RARITY_NAMES[rarity] + "]\n" + desc

func _show_tooltip(target: Control, text: String) -> void:
	var tooltip := TooltipComponent.new()
	add_child(tooltip)
	tooltip.show(target.global_position + Vector2(0, -90), text)
	_active_tooltips.append(tooltip)

func _hide_tooltips() -> void:
	for t in _active_tooltips:
		if is_instance_valid(t):
			t.hide()
			t.queue_free()
	_active_tooltips.clear()

# ── 卡牌预览 ──

## 在右侧预览面板中展示 Block 的完整形状；悬停各个部件可查看部件提示
func _show_preview(block_name: String) -> void:
	if _preview_holder == null:
		return
	_clear_preview()
	var def: Dictionary = BlockRegistry.BlockDefs.get(block_name, {})
	var rarity: int = int(def.get("rarity", 0))
	if _preview_title != null:
		_preview_title.text = block_name + "  [" + RARITY_NAMES[rarity] + "]"
	var block: Block = BlockRegistry.create_block_by_name(block_name)
	if block == null:
		return
	_preview_holder.add_child(block)
	# Block 原点在部件 (0,0) 处，用部件包围盒中心对齐预览区中心
	block.position = -_block_bounds_center(block)
	_preview_block = block

func _clear_preview() -> void:
	if is_instance_valid(_preview_block):
		# 立即隐藏，避免 queue_free 到帧末前与新旧预览同屏
		_preview_block.visible = false
		_preview_block.queue_free()
	_preview_block = null

func _block_bounds_center(block: Block) -> Vector2:
	var bounds := Rect2()
	var first := true
	for part in block.get_parts():
		var part_rect := Rect2(part.position - Vector2(48, 48), Vector2(96, 96))
		if first:
			bounds = part_rect
			first = false
		else:
			bounds = bounds.merge(part_rect)
	return bounds.get_center() if not first else Vector2.ZERO