extends RefCounted

const EXPECTED_SFX := [
	"jump",
	"jump_big",
	"coin",
	"bump",
	"brick_break",
	"powerup_spawn",
	"powerup_collect",
	"stomp",
	"kick",
	"hurt",
	"one_up",
	"stage_clear",
	"game_over",
]


func run(tree: SceneTree, host: Node) -> Dictionary:
	var cases: Dictionary = {}

	cases["audio_manager_runtime"] = _run_audio_manager_case(tree)
	cases["game_state_initial_and_score"] = _run_game_state_initial_and_score(tree)
	cases["game_state_coin_rollover_100"] = _run_game_state_coin_rollover_100(tree)
	cases["game_state_reset_preserves_best_score"] = _run_game_state_reset_preserves_best_score(tree)
	cases["all_level_paths_resolve"] = _run_all_level_paths_resolve(tree)
	cases["main_scene_runtime"] = await _run_scene_instantiate_case(tree, host, "res://scenes/main.tscn")
	cases["level_1_runtime"] = await _run_scene_instantiate_case(tree, host, "res://scenes/levels/level_1.tscn")
	cases["level_2_runtime"] = await _run_scene_instantiate_case(tree, host, "res://scenes/levels/level_2.tscn")
	cases["level_3_runtime"] = await _run_scene_instantiate_case(tree, host, "res://scenes/levels/level_3.tscn")

	return {
		"ok": true,
		"error": "",
		"cases": cases,
	}


func _make_result(passed: bool, detail: String) -> Dictionary:
	return {
		"passed": passed,
		"detail": detail,
	}


func _run_audio_manager_case(tree: SceneTree) -> Dictionary:
	var am: Node = tree.root.get_node_or_null("AudioManager")
	if am == null:
		return _make_result(false, "Autoload /root/AudioManager not mounted in runtime SceneTree")

	var required_methods := ["play_sfx", "play_bgm", "stop_bgm", "toggle_mute", "set_muted", "set_paused_duck"]
	for m in required_methods:
		if not am.has_method(m):
			return _make_result(false, "AudioManager missing method: " + m)

	if am.get("is_muted") == null or am.get("is_ducked") == null:
		return _make_result(false, "AudioManager missing is_muted or is_ducked property")

	am.call("set_muted", false)
	am.call("set_paused_duck", false)
	if bool(am.get("is_muted")) != false:
		return _make_result(false, "AudioManager.is_muted expected false after set_muted(false)")

	for sfx_key in EXPECTED_SFX:
		am.call("play_sfx", sfx_key)

	am.call("play_bgm", "overworld")
	am.call("stop_bgm")
	am.call("play_bgm", "castle")
	am.call("stop_bgm")

	var toggled: Variant = am.call("toggle_mute")
	if typeof(toggled) != TYPE_BOOL or bool(toggled) != true or bool(am.get("is_muted")) != true:
		am.call("set_muted", false)
		return _make_result(false, "AudioManager.toggle_mute() failed to mute")

	am.call("set_muted", false)
	if bool(am.get("is_muted")) != false:
		return _make_result(false, "AudioManager.set_muted(false) failed")

	am.call("set_paused_duck", true)
	if bool(am.get("is_ducked")) != true:
		am.call("set_paused_duck", false)
		return _make_result(false, "AudioManager.set_paused_duck(true) failed")

	am.call("set_paused_duck", false)
	if bool(am.get("is_ducked")) != false:
		return _make_result(false, "AudioManager.set_paused_duck(false) failed")

	return _make_result(true, "AudioManager runtime API verified")


func _run_game_state_initial_and_score(tree: SceneTree) -> Dictionary:
	var gs: Node = tree.root.get_node_or_null("GameState")
	if gs == null:
		return _make_result(false, "Autoload /root/GameState not mounted in runtime SceneTree")

	var required_methods := [
		"reset_game",
		"add_score",
		"add_coin",
		"add_life",
		"lose_life",
		"set_power",
		"set_level",
		"get_level_scene_path",
		"mark_victory",
		"mark_game_over",
	]
	for m in required_methods:
		if not gs.has_method(m):
			return _make_result(false, "GameState missing method: " + m)

	if not gs.has_signal("score_changed"):
		return _make_result(false, "GameState missing signal: score_changed")

	if int(gs.get("score")) != 0:
		return _make_result(false, "Initial GameState.score expected 0, got %s" % str(gs.get("score")))
	if int(gs.get("coins")) != 0:
		return _make_result(false, "Initial GameState.coins expected 0, got %s" % str(gs.get("coins")))
	if int(gs.get("lives")) != 3:
		return _make_result(false, "Initial GameState.lives expected 3, got %s" % str(gs.get("lives")))
	if int(gs.get("current_level")) != 1:
		return _make_result(false, "Initial GameState.current_level expected 1, got %s" % str(gs.get("current_level")))
	if bool(gs.get("game_won")) != false:
		return _make_result(false, "Initial GameState.game_won expected false")
	if bool(gs.get("game_over")) != false:
		return _make_result(false, "Initial GameState.game_over expected false")

	var emitted_scores: Array[int] = []
	var cb := func(new_score: int) -> void:
		emitted_scores.append(new_score)
	gs.connect("score_changed", cb)
	gs.call("add_score", 250)
	gs.disconnect("score_changed", cb)

	if int(gs.get("score")) != 250:
		return _make_result(false, "After add_score(250), score expected 250, got %s" % str(gs.get("score")))
	if int(gs.get("best_score")) < 250:
		return _make_result(false, "After add_score(250), best_score expected >= 250, got %s" % str(gs.get("best_score")))
	if not emitted_scores.has(250):
		return _make_result(false, "score_changed(250) was not emitted; got %s" % str(emitted_scores))

	return _make_result(true, "GameState initial values and add_score verified")


func _run_game_state_coin_rollover_100(tree: SceneTree) -> Dictionary:
	var gs: Node = tree.root.get_node_or_null("GameState")
	if gs == null:
		return _make_result(false, "Autoload /root/GameState not mounted")

	gs.call("reset_game")

	var emitted_coins: Array[int] = []
	var emitted_lives: Array[int] = []
	var coins_cb := func(new_coins: int) -> void:
		emitted_coins.append(new_coins)
	var lives_cb := func(new_lives: int) -> void:
		emitted_lives.append(new_lives)

	if not gs.has_signal("coins_changed") or not gs.has_signal("lives_changed"):
		return _make_result(false, "GameState missing coins_changed or lives_changed signal")

	gs.connect("coins_changed", coins_cb)
	gs.connect("lives_changed", lives_cb)

	gs.call("add_coin", 99)
	if int(gs.get("coins")) != 99 or int(gs.get("lives")) != 3:
		gs.disconnect("coins_changed", coins_cb)
		gs.disconnect("lives_changed", lives_cb)
		return _make_result(false, "After add_coin(99): expected coins=99, lives=3; got coins=%s, lives=%s" % [
			str(gs.get("coins")),
			str(gs.get("lives")),
		])

	gs.call("add_coin", 1)
	gs.disconnect("coins_changed", coins_cb)
	gs.disconnect("lives_changed", lives_cb)

	if int(gs.get("coins")) != 0:
		return _make_result(false, "After rollover add_coin(1): expected coins=0, got %s" % str(gs.get("coins")))
	if int(gs.get("lives")) != 4:
		return _make_result(false, "After rollover add_coin(1): expected lives=4, got %s" % str(gs.get("lives")))
	if not emitted_coins.has(99) or not emitted_coins.has(0):
		return _make_result(false, "coins_changed emissions missing 99 or 0: %s" % str(emitted_coins))
	if not emitted_lives.has(4):
		return _make_result(false, "lives_changed(4) not emitted on rollover: %s" % str(emitted_lives))

	return _make_result(true, "GameState 100-coin rollover verified")


func _run_game_state_reset_preserves_best_score(tree: SceneTree) -> Dictionary:
	var gs: Node = tree.root.get_node_or_null("GameState")
	if gs == null:
		return _make_result(false, "Autoload /root/GameState not mounted")

	gs.call("reset_game")
	gs.call("add_score", 1200)
	gs.call("add_coin", 45)
	gs.call("lose_life")
	gs.call("lose_life")
	gs.call("set_power", 1)
	gs.call("set_level", 3)
	gs.call("mark_victory")

	if int(gs.get("score")) != 1200 or int(gs.get("coins")) != 45 or int(gs.get("lives")) != 1:
		return _make_result(false, "Failed to stage GameState prior to reset_game()")

	gs.call("reset_game")

	if int(gs.get("score")) != 0:
		return _make_result(false, "score not reset to 0")
	if int(gs.get("coins")) != 0:
		return _make_result(false, "coins not reset to 0")
	if int(gs.get("lives")) != 3:
		return _make_result(false, "lives not reset to 3")
	if int(gs.get("player_power")) != 0:
		return _make_result(false, "player_power not reset to SMALL (0)")
	if int(gs.get("current_level")) != 1:
		return _make_result(false, "current_level not reset to 1")
	if bool(gs.get("game_won")) != false:
		return _make_result(false, "game_won not reset to false")
	if bool(gs.get("game_over")) != false:
		return _make_result(false, "game_over not reset to false")
	if int(gs.get("best_score")) < 1200:
		return _make_result(false, "best_score was not preserved (>=1200), got %s" % str(gs.get("best_score")))

	return _make_result(true, "GameState.reset_game() preserves best_score verified")


func _run_all_level_paths_resolve(tree: SceneTree) -> Dictionary:
	var gs: Node = tree.root.get_node_or_null("GameState")
	if gs == null:
		return _make_result(false, "Autoload /root/GameState not mounted")
	if not gs.has_method("get_level_scene_path"):
		return _make_result(false, "GameState missing get_level_scene_path()")

	var expected := {
		1: "res://scenes/levels/level_1.tscn",
		2: "res://scenes/levels/level_2.tscn",
		3: "res://scenes/levels/level_3.tscn",
	}
	for lvl in expected.keys():
		var actual_path := str(gs.call("get_level_scene_path", lvl))
		if actual_path != expected[lvl]:
			return _make_result(false, "get_level_scene_path(%d) expected '%s', got '%s'" % [lvl, expected[lvl], actual_path])
		if not ResourceLoader.exists(actual_path):
			return _make_result(false, "Level scene does not exist on disk: " + actual_path)

	return _make_result(true, "All 3 level scene paths resolve and exist")


func _run_scene_instantiate_case(tree: SceneTree, host: Node, scene_path: String) -> Dictionary:
	if not ResourceLoader.exists(scene_path):
		return _make_result(false, "Scene does not exist: " + scene_path)

	var gs: Node = tree.root.get_node_or_null("GameState")
	if gs != null and gs.has_method("reset_game"):
		gs.call("reset_game")

	var res := ResourceLoader.load(scene_path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if res == null or not (res is PackedScene):
		return _make_result(false, "Failed to load PackedScene: " + scene_path)

	var inst := (res as PackedScene).instantiate()
	if inst == null:
		return _make_result(false, "PackedScene.instantiate() returned null: " + scene_path)

	host.add_child(inst)
	await tree.process_frame

	var valid_in_tree := is_instance_valid(inst) and inst.is_inside_tree()

	var am: Node = tree.root.get_node_or_null("AudioManager")
	if am != null and am.has_method("stop_bgm"):
		am.call("stop_bgm")

	if is_instance_valid(inst):
		if inst.get_parent() == host:
			host.remove_child(inst)
		inst.queue_free()
	await tree.process_frame

	if not valid_in_tree:
		return _make_result(false, "Instantiated scene failed to enter tree cleanly: " + scene_path)
	return _make_result(true, "Scene instantiated and ran 1 frame cleanly: " + scene_path)
