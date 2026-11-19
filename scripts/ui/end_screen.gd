extends Control

const LEVEL_1_SCENE_PATH: String = "res://scenes/levels/level_1.tscn"
const TITLE_SCENE_PATH: String = "res://scenes/main.tscn"


func _ready() -> void:
	if is_inside_tree():
		get_tree().paused = false
	var am := _audio_manager()
	if am != null:
		if am.has_method("set_paused_duck"):
			am.call("set_paused_duck", false)
		if am.has_method("stop_bgm"):
			am.call("stop_bgm")

	var gs := _game_state()
	var won := bool(gs.get("game_won")) if gs != null else false
	var lost := bool(gs.get("game_over")) if gs != null else false
	var score_val := int(gs.get("score")) if gs != null else 0
	var best_val := int(gs.get("best_score")) if gs != null else 0

	var heading := get_node_or_null("CenterContainer/Panel/VBox/HeadingLabel") as Label
	if heading != null:
		if won:
			heading.text = "مبروك! فوز رائع!"
			heading.add_theme_color_override("font_color", Color(1.0, 0.831373, 0.231373, 1.0))
		else:
			heading.text = "انتهت اللعبة!"
			heading.add_theme_color_override("font_color", Color(1.0, 0.42, 0.42, 1.0))

	if am != null and am.has_method("play_sfx"):
		if won:
			am.call("play_sfx", "stage_clear")
		elif lost:
			am.call("play_sfx", "game_over")

	var final_lbl := get_node_or_null("CenterContainer/Panel/VBox/FinalScoreLabel") as Label
	if final_lbl != null:
		final_lbl.text = "النتيجة النهائية: %d" % score_val

	var best_lbl := get_node_or_null("CenterContainer/Panel/VBox/BestScoreLabel") as Label
	if best_lbl != null:
		best_lbl.text = "أعلى نتيجة: %d" % best_val

	var play_again_btn := get_node_or_null("CenterContainer/Panel/VBox/PlayAgainButton") as Button
	if play_again_btn != null:
		if not play_again_btn.pressed.is_connected(_on_play_again_pressed):
			play_again_btn.pressed.connect(_on_play_again_pressed)
		play_again_btn.grab_focus()

	var menu_btn := get_node_or_null("CenterContainer/Panel/VBox/MainMenuButton") as Button
	if menu_btn != null and not menu_btn.pressed.is_connected(_on_main_menu_pressed):
		menu_btn.pressed.connect(_on_main_menu_pressed)


func _on_play_again_pressed() -> void:
	var gs := _game_state()
	if gs != null:
		if gs.has_method("reset_game"):
			gs.call("reset_game")
		if gs.has_method("set_level"):
			gs.call("set_level", 1)
	if is_inside_tree():
		get_tree().change_scene_to_file(LEVEL_1_SCENE_PATH)


func _on_main_menu_pressed() -> void:
	if is_inside_tree():
		get_tree().change_scene_to_file(TITLE_SCENE_PATH)


func _game_state() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/GameState")
	return null


func _audio_manager() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/AudioManager")
	return null
