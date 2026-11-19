extends Node2D

const END_SCREEN_PATH: String = "res://scenes/ui/end_screen.tscn"

@export var level_number: int = 1
@export var bgm_track: String = "overworld"
@export var next_scene_path: String = ""
@export var time_limit: float = 180.0
@export var camera_limit_left: int = 0
@export var camera_limit_top: int = 0
@export var camera_limit_right: int = 3200
@export var camera_limit_bottom: int = 368
@export var intro_tip: String = ""

var time_remaining: float = 180.0

var _timer_stopped: bool = false
var _level_cleared: bool = false
var _handling_death: bool = false
var _last_displayed_time: int = -1


func _ready() -> void:
	time_remaining = time_limit

	var gs := _game_state()
	if gs != null and gs.has_method("set_level"):
		gs.call("set_level", level_number)

	var am := _audio_manager()
	if am != null:
		if am.has_method("set_paused_duck"):
			am.call("set_paused_duck", false)
		if am.has_method("play_bgm"):
			am.call("play_bgm", bgm_track)

	var player := _find_player()
	if player != null:
		var cam := player.get_node_or_null("Camera2D") as Camera2D
		if cam != null:
			cam.limit_left = camera_limit_left
			cam.limit_top = camera_limit_top
			cam.limit_right = camera_limit_right
			cam.limit_bottom = camera_limit_bottom
		if player.has_signal("died") and not player.is_connected("died", _on_player_died):
			player.connect("died", _on_player_died)

	var flagpole := _find_flagpole()
	if flagpole != null and flagpole.has_signal("level_cleared"):
		if not flagpole.is_connected("level_cleared", _on_flagpole_cleared):
			flagpole.connect("level_cleared", _on_flagpole_cleared)

	for hazard in _find_hazard_areas():
		if not hazard.body_entered.is_connected(_on_hazard_body_entered):
			hazard.body_entered.connect(_on_hazard_body_entered)

	var hud := _find_hud()
	if hud != null:
		if hud.has_signal("pause_requested") and not hud.is_connected("pause_requested", _on_hud_pause_requested):
			hud.connect("pause_requested", _on_hud_pause_requested)
		_sync_hud_time(hud)
		if not intro_tip.strip_edges().is_empty() and hud.has_method("show_tip"):
			hud.call("show_tip", intro_tip, 5.0)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		if not _level_cleared and not _is_player_dead():
			_toggle_pause_menu()


func _physics_process(delta: float) -> void:
	for hazard in _find_hazard_areas():
		for body in hazard.get_overlapping_bodies():
			_on_hazard_body_entered(body)

	if _timer_stopped or _level_cleared or _is_player_dead():
		return

	time_remaining = maxf(0.0, time_remaining - delta)
	_sync_hud_time(_find_hud())

	if time_remaining <= 0.0:
		_timer_stopped = true
		var player := _find_player()
		if player != null and player.has_method("take_damage"):
			player.call("take_damage", true)


func _sync_hud_time(hud: Node) -> void:
	if hud == null or not hud.has_method("update_time"):
		return
	var secs := maxi(0, int(ceil(time_remaining)))
	if secs != _last_displayed_time:
		_last_displayed_time = secs
		hud.call("update_time", secs)


func _on_hud_pause_requested() -> void:
	if not _level_cleared and not _is_player_dead():
		_toggle_pause_menu()


func _toggle_pause_menu() -> void:
	var pm := _find_pause_menu()
	if pm != null and pm.has_method("toggle_pause"):
		pm.call("toggle_pause")


func _on_hazard_body_entered(body: Node) -> void:
	if _level_cleared or body == null:
		return
	if body.is_in_group("player"):
		if body.has_method("is_dead") and bool(body.call("is_dead")):
			return
		if body.has_method("take_damage"):
			body.call("take_damage", true)


func _on_flagpole_cleared(bonus: int) -> void:
	if _level_cleared:
		return
	_level_cleared = true
	_timer_stopped = true

	var am := _audio_manager()
	if am != null and am.has_method("stop_bgm"):
		am.call("stop_bgm")

	var awarded := bonus if bonus > 0 else maxi(0, int(ceil(time_remaining))) * 10
	var gs := _game_state()
	if gs != null and awarded > 0 and gs.has_method("add_score"):
		gs.call("add_score", awarded)

	if not is_inside_tree():
		return
	var timer := get_tree().create_timer(1.2)
	timer.timeout.connect(_finish_stage_transition)


func _finish_stage_transition() -> void:
	if not is_inside_tree():
		return
	var player := _find_player()
	if player != null and player.has_method("finish_level_clear"):
		player.call("finish_level_clear")

	var gs := _game_state()
	var is_final := level_number >= 3 or next_scene_path.is_empty() or next_scene_path == END_SCREEN_PATH
	if is_final:
		if gs != null and gs.has_method("mark_victory"):
			gs.call("mark_victory")
		get_tree().change_scene_to_file(END_SCREEN_PATH)
	else:
		if gs != null and gs.has_method("set_level"):
			gs.call("set_level", level_number + 1)
		get_tree().change_scene_to_file(next_scene_path)


func _on_player_died() -> void:
	if _handling_death or _level_cleared:
		return
	_handling_death = true
	_timer_stopped = true

	var am := _audio_manager()
	if am != null and am.has_method("stop_bgm"):
		am.call("stop_bgm")

	if not is_inside_tree():
		return
	var timer := get_tree().create_timer(0.8)
	timer.timeout.connect(_finish_death_transition)


func _finish_death_transition() -> void:
	if not is_inside_tree():
		return
	var gs := _game_state()
	var lives_left := int(gs.get("lives")) if gs != null else 0
	var is_over := bool(gs.get("game_over")) if gs != null else true
	if lives_left <= 0 or is_over:
		if gs != null and gs.has_method("mark_game_over"):
			gs.call("mark_game_over")
		get_tree().change_scene_to_file(END_SCREEN_PATH)
	else:
		var reload_path := "res://scenes/levels/level_%d.tscn" % level_number
		if gs != null and gs.has_method("get_level_scene_path"):
			reload_path = str(gs.call("get_level_scene_path", level_number))
		get_tree().change_scene_to_file(reload_path)


func _is_player_dead() -> bool:
	var p := _find_player()
	if p != null and p.has_method("is_dead"):
		return bool(p.call("is_dead"))
	return false


func _find_player() -> Node:
	return _find_by_name_or_script("Player", "player.gd")


func _find_flagpole() -> Node:
	return _find_by_name_or_script("Flagpole", "flagpole.gd")


func _find_hud() -> Node:
	return _find_by_name_or_script("HUD", "hud.gd")


func _find_pause_menu() -> Node:
	return _find_by_name_or_script("PauseMenu", "pause_menu.gd")


func _find_hazard_areas() -> Array[Area2D]:
	var out: Array[Area2D] = []
	_collect_hazards_rec(self, out)
	return out


func _collect_hazards_rec(node: Node, out: Array[Area2D]) -> void:
	if node is Area2D and (String(node.name).begins_with("FallZone") or String(node.name).begins_with("HazardZone")):
		out.append(node as Area2D)
	for c in node.get_children():
		_collect_hazards_rec(c, out)


func _find_by_name_or_script(target_name: String, script_suffix: String) -> Node:
	return _find_rec(self, target_name, script_suffix)


func _find_rec(node: Node, target_name: String, script_suffix: String) -> Node:
	if node != self:
		if String(node.name) == target_name:
			return node
		var scr: Variant = node.get_script()
		if scr is Script and (scr as Script).resource_path.ends_with(script_suffix):
			return node
	for c in node.get_children():
		var found := _find_rec(c, target_name, script_suffix)
		if found != null:
			return found
	return null


func _game_state() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/GameState")
	return null


func _audio_manager() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/AudioManager")
	return null
