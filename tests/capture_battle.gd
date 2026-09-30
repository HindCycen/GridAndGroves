extends Node
## 战斗画面截图工具 —— 供视觉复核使用（不是回归守卫）。
##
## 用法（**必须非 headless**，headless 没有渲染设备）：
##   & "C:\Unpacked\Godot\Godot_v4.7.2-stable_win64_console.exe" --path . `
##       res://tests/capture_battle.tscn -- --stage=2 --out=C:/tmp/battle2.png
##
## 它会：设定楼层 → 加载 BattleRoom → 等若干帧 → 把根视口存成 PNG → 退出。
## BattleRoom 在没有 EnemyChart 时会提前 return（"No enemies!"），
## 但楼层背景在 _ready 最前面就已挂上，因此截图依然有效。

const BATTLE_SCENE := "res://room/BattleRoom.tscn"
const CAPTURE_SIZE := Vector2i(1920, 1080)


func _ready() -> void:
	var stage := 1
	var out := "res://demo_generated/battle_capture.png"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--stage="):
			stage = int(a.trim_prefix("--stage="))
		elif a.begins_with("--out="):
			out = a.trim_prefix("--out=")

	DisplayServer.window_set_size(CAPTURE_SIZE)

	var save_load := get_node_or_null("/root/SaveLoad")
	if save_load != null:
		if save_load.Data == null:
			save_load.Data = DataResource.new()
		save_load.Data.StageCount = stage

	var ps := load(BATTLE_SCENE) as PackedScene
	if ps == null:
		push_error("capture: 无法加载 " + BATTLE_SCENE)
		get_tree().quit(1)
		return
	add_child(ps.instantiate())

	# 等背景与首帧渲染完成
	for i in 10:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw

	var img := get_viewport().get_texture().get_image()
	if img == null:
		push_error("capture: 拿不到视口图像")
		get_tree().quit(1)
		return

	# 截图落在 res:// 下的 demo_generated（已被 .gitignore 忽略）
	var dir := out.get_base_dir()
	if dir != "" and not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	var err := img.save_png(out)
	print("capture: stage=%d size=%s -> %s (err=%d)" % [stage, str(img.get_size()), out, err])
	get_tree().quit(0 if err == OK else 1)
