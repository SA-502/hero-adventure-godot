extends Control

const TITLE_SCENE_PATH: String = "res://scenes/main.tscn"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	var resume_btn := get_node_or_null("CenterContainer/Panel/VBox/ResumeButton") as Button
	if resume_btn != null and not resume_btn.pressed.is_connected(_on_resume_pressed):
		resume_btn.pressed.connect(_on_resume_pressed)

	var restart_btn := get_node_or_null("CenterContainer/Panel/VBox/RestartButton") as Button
	if restart_btn != null and not restart_btn.pressed.is_connected(_on_restart_pressed):
		restart_btn.pressed.connect(_on_restart_pressed)

	var mute_btn := get_node_or_null("CenterContainer/Panel/VBox/MuteButton") as Button
	if mute_btn != null and not mute_btn.pressed.is_connected(_on_mute_pressed):
		mute_btn.pressed.connect(_on_mute_pressed)

	var menu_btn := get_node_or_null("CenterContainer/Panel/VBox/MainMenuButton") as Button
	if menu_btn != null and not menu_btn.pressed.is_connected(_on_main_menu_pressed):
		menu_btn.pressed.connect(_on_main_menu_pressed)

	_refresh_mute_label()


func toggle_pause() -> void:
	if not is_inside_tree():
		return
	var next_paused := not get_tree().paused
	get_tree().paused = next_paused
	visible = next_paused

	var am := _audio_manager()
	if am != null and am.has_method("set_paused_duck"):
		am.call("set_paused_duck", next_paused)

	if next_paused:
		_refresh_mute_label()
		var resume_btn := get_node_or_null("CenterContainer/Panel/VBox/ResumeButton") as Button
		if resume_btn != null:
			resume_btn.grab_focus()


func _on_resume_pressed() -> void:
	if is_inside_tree() and get_tree().paused:
		toggle_pause()
	else:
		visible = false


func _on_restart_pressed() -> void:
	if not is_inside_tree():
		return
	get_tree().paused = false
	var am := _audio_manager()
	if am != null and am.has_method("set_paused_duck"):
		am.call("set_paused_duck", false)

	var target := "res://scenes/levels/level_1.tscn"
	var gs := _game_state()
	if gs != null and gs.has_method("get_level_scene_path"):
		target = str(gs.call("get_level_scene_path"))
	get_tree().change_scene_to_file(target)


func _on_mute_pressed() -> void:
	var am := _audio_manager()
	if am != null and am.has_method("toggle_mute"):
		am.call("toggle_mute")
	_refresh_mute_label()


func _on_main_menu_pressed() -> void:
	if not is_inside_tree():
		return
	get_tree().paused = false
	var am := _audio_manager()
	if am != null:
		if am.has_method("set_paused_duck"):
			am.call("set_paused_duck", false)
		if am.has_method("stop_bgm"):
			am.call("stop_bgm")
	get_tree().change_scene_to_file(TITLE_SCENE_PATH)


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
