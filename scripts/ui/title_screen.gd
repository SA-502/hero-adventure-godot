extends Control


func _ready() -> void:
	if is_inside_tree():
		get_tree().paused = false
	var am := _audio_manager()
	if am != null:
		if am.has_method("set_paused_duck"):
			am.call("set_paused_duck", false)
		if am.has_method("stop_bgm"):
			am.call("stop_bgm")

	_refresh_best_score()
	_refresh_mute_label()

	var start_btn := get_node_or_null("CenterContainer/Panel/VBox/StartButton") as Button
	if start_btn != null:
		if not start_btn.pressed.is_connected(_on_start_pressed):
			start_btn.pressed.connect(_on_start_pressed)
		start_btn.grab_focus()

	var l1_btn := get_node_or_null("CenterContainer/Panel/VBox/LevelRow/Level1Button") as Button
	if l1_btn != null and not l1_btn.pressed.is_connected(_on_level_pressed.bind(1)):
		l1_btn.pressed.connect(_on_level_pressed.bind(1))

	var l2_btn := get_node_or_null("CenterContainer/Panel/VBox/LevelRow/Level2Button") as Button
	if l2_btn != null and not l2_btn.pressed.is_connected(_on_level_pressed.bind(2)):
		l2_btn.pressed.connect(_on_level_pressed.bind(2))

	var l3_btn := get_node_or_null("CenterContainer/Panel/VBox/LevelRow/Level3Button") as Button
	if l3_btn != null and not l3_btn.pressed.is_connected(_on_level_pressed.bind(3)):
		l3_btn.pressed.connect(_on_level_pressed.bind(3))

	var mute_btn := get_node_or_null("CenterContainer/Panel/VBox/MuteButton") as Button
	if mute_btn != null and not mute_btn.pressed.is_connected(_on_mute_pressed):
		mute_btn.pressed.connect(_on_mute_pressed)

	var bonus_btn := get_node_or_null("CenterContainer/Panel/VBox/BonusButton") as Button
	if bonus_btn != null and not bonus_btn.pressed.is_connected(_on_bonus_pressed):
		bonus_btn.pressed.connect(_on_bonus_pressed)


func _on_start_pressed() -> void:
	_start_at_level(1)


func _on_level_pressed(level_num: int) -> void:
	_start_at_level(level_num)


func _start_at_level(level_num: int) -> void:
	var target := "res://scenes/levels/level_%d.tscn" % clampi(level_num, 1, 3)
	var gs := _game_state()
	if gs != null:
		if gs.has_method("reset_game"):
			gs.call("reset_game")
		if gs.has_method("set_level"):
			gs.call("set_level", level_num)
		if gs.has_method("get_level_scene_path"):
			target = str(gs.call("get_level_scene_path", level_num))
	if is_inside_tree():
		get_tree().change_scene_to_file(target)


func _on_mute_pressed() -> void:
	var am := _audio_manager()
	if am != null and am.has_method("toggle_mute"):
		am.call("toggle_mute")
	_refresh_mute_label()


func _on_bonus_pressed() -> void:
	if is_inside_tree():
		get_tree().change_scene_to_file("res://scenes/bonus_3d.tscn")


func _refresh_best_score() -> void:
	var lbl := get_node_or_null("CenterContainer/Panel/VBox/BestScoreLabel") as Label
	if lbl == null:
		return
	var gs := _game_state()
	var best := int(gs.get("best_score")) if gs != null else 0
	lbl.text = "أعلى نتيجة: %d" % best


func _refresh_mute_label() -> void:
	var mute_btn := get_node_or_null("CenterContainer/Panel/VBox/MuteButton") as Button
	if mute_btn == null:
		return
	var am := _audio_manager()
	var muted := bool(am.get("is_muted")) if am != null else false
	mute_btn.text = "تشغيل الصوت" if muted else "كتم الصوت"


func _game_state() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/GameState")
	return null


func _audio_manager() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/AudioManager")
	return null
