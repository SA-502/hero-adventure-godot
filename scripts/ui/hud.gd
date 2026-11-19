extends CanvasLayer

signal pause_requested

var _tip_timer: SceneTreeTimer = null


func _ready() -> void:
	var gs := _game_state()
	if gs != null:
		if gs.has_signal("score_changed") and not gs.is_connected("score_changed", _on_score_changed):
			gs.connect("score_changed", _on_score_changed)
		if gs.has_signal("coins_changed") and not gs.is_connected("coins_changed", _on_coins_changed):
			gs.connect("coins_changed", _on_coins_changed)
		if gs.has_signal("lives_changed") and not gs.is_connected("lives_changed", _on_lives_changed):
			gs.connect("lives_changed", _on_lives_changed)
		if gs.has_signal("level_changed") and not gs.is_connected("level_changed", _on_level_changed):
			gs.connect("level_changed", _on_level_changed)
		_refresh_from_game_state(gs)

	var pause_btn := get_node_or_null("Root/TopBar/Margin/HBox/PauseButton") as Button
	if pause_btn != null and not pause_btn.pressed.is_connected(_on_pause_button_pressed):
		pause_btn.pressed.connect(_on_pause_button_pressed)


func _exit_tree() -> void:
	var gs := _game_state()
	if gs != null:
		if gs.is_connected("score_changed", _on_score_changed):
			gs.disconnect("score_changed", _on_score_changed)
		if gs.is_connected("coins_changed", _on_coins_changed):
			gs.disconnect("coins_changed", _on_coins_changed)
		if gs.is_connected("lives_changed", _on_lives_changed):
			gs.disconnect("lives_changed", _on_lives_changed)
		if gs.is_connected("level_changed", _on_level_changed):
			gs.disconnect("level_changed", _on_level_changed)


func update_time(seconds: int) -> void:
	var clamped := maxi(0, seconds)
	var lbl := get_node_or_null("Root/TopBar/Margin/HBox/TimeLabel") as Label
	if lbl != null:
		lbl.text = "الوقت: %d" % clamped


func show_tip(text: String, duration: float = 4.0) -> void:
	var panel := get_node_or_null("Root/TipPanel") as Control
	var lbl := get_node_or_null("Root/TipPanel/TipLabel") as Label
	if panel == null or lbl == null:
		return

	if text.strip_edges().is_empty():
		panel.visible = false
		lbl.text = ""
		return

	lbl.text = text
	panel.visible = true

	if duration > 0.0 and is_inside_tree():
		var timer := get_tree().create_timer(duration)
		_tip_timer = timer
		timer.timeout.connect(func() -> void:
			if _tip_timer == timer and is_instance_valid(panel):
				panel.visible = false
		)


func _refresh_from_game_state(gs: Node) -> void:
	_on_score_changed(int(gs.get("score")))
	_on_coins_changed(int(gs.get("coins")))
	_on_lives_changed(int(gs.get("lives")))
	_on_level_changed(int(gs.get("current_level")))


func _on_score_changed(new_score: int) -> void:
	var lbl := get_node_or_null("Root/TopBar/Margin/HBox/ScoreLabel") as Label
	if lbl != null:
		lbl.text = "النقاط: %d" % new_score


func _on_coins_changed(new_coins: int) -> void:
	var lbl := get_node_or_null("Root/TopBar/Margin/HBox/CoinsLabel") as Label
	if lbl != null:
		lbl.text = "العملات: %d" % new_coins


func _on_lives_changed(new_lives: int) -> void:
	var lbl := get_node_or_null("Root/TopBar/Margin/HBox/LivesLabel") as Label
	if lbl != null:
		lbl.text = "المحاولات: %d" % new_lives


func _on_level_changed(new_level: int) -> void:
	var lbl := get_node_or_null("Root/TopBar/Margin/HBox/StageLabel") as Label
	if lbl != null:
		lbl.text = "المرحلة: 1-%d" % new_level


func _on_pause_button_pressed() -> void:
	pause_requested.emit()


func _game_state() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/GameState")
	return null
