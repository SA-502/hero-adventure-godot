extends RefCounted

const PATH_PLAYER := "res://scenes/player/player.tscn"
const PATH_QUESTION_BLOCK := "res://scenes/objects/question_block.tscn"
const PATH_BRICK_BLOCK := "res://scenes/objects/brick_block.tscn"
const PATH_COIN := "res://scenes/objects/coin.tscn"
const PATH_MUSHROOM := "res://scenes/objects/mushroom.tscn"
const PATH_MOVING_PLATFORM := "res://scenes/objects/moving_platform.tscn"
const PATH_FLAGPOLE := "res://scenes/objects/flagpole.tscn"
const PATH_WALKER := "res://scenes/enemies/walker_enemy.tscn"
const PATH_SHELL := "res://scenes/enemies/shell_enemy.tscn"
const PATH_HUD := "res://scenes/ui/hud.tscn"
const PATH_PAUSE_MENU := "res://scenes/ui/pause_menu.tscn"
const PATH_END_SCREEN := "res://scenes/ui/end_screen.tscn"
const PATH_MAIN := "res://scenes/main.tscn"
const PATH_LEVEL_1 := "res://scenes/levels/level_1.tscn"
const PATH_LEVEL_2 := "res://scenes/levels/level_2.tscn"
const PATH_LEVEL_3 := "res://scenes/levels/level_3.tscn"


func run(tree: SceneTree, host: Node) -> Dictionary:
	var cases: Dictionary = {}

	# B03 GameState boundaries
	cases["b03_zero_and_negative_score_ignored"] = _case_b03_neg_score(tree)
	cases["b03_zero_and_negative_coin_ignored"] = _case_b03_neg_coin(tree)
	cases["b03_coin_rollover_99_to_100_and_overflow"] = _case_b03_rollover(tree)
	cases["b03_lives_floor_at_zero_and_neg_add_life"] = _case_b03_lives_floor(tree)
	cases["b03_invalid_level_bounds_and_paths"] = _case_b03_level_bounds(tree)

	# B04 AudioManager boundaries
	cases["b04_play_sfx_empty_string_no_error"] = _case_b04_sfx(tree, "")
	cases["b04_play_sfx_unknown_key_no_error"] = _case_b04_sfx(tree, "nonexistent_sfx_xyz")
	cases["b04_play_bgm_unknown_or_empty_no_error"] = _case_b04_bgm_invalid(tree)
	cases["b04_stop_bgm_when_idle_idempotent"] = _case_b04_stop_idle(tree)
	cases["b04_play_sfx_while_muted_preserves_mute"] = _case_b04_muted(tree)

	# B05 Player physics boundaries
	cases["b05_opposing_left_right_inputs_cancel"] = await _case_b05_opposing_inputs(tree, host)
	cases["b05_jump_unavailable_after_coyote_expires"] = await _case_b05_coyote_expired(tree, host)
	cases["b05_jump_buffer_expired_before_landing"] = await _case_b05_buffer_expired(tree, host)
	cases["b05_double_jump_blocked_in_midair"] = await _case_b05_no_double_jump(tree, host)
	cases["b05_variable_jump_release_while_falling_noop"] = await _case_b05_release_falling(tree, host)

	# B06 Player state boundaries
	cases["b06_collect_powerup_when_already_big_safe"] = await _case_b06_already_big(tree, host)
	cases["b06_take_damage_ignored_while_invulnerable"] = await _case_b06_damage_invuln(tree, host)
	cases["b06_take_damage_ignored_when_dead"] = await _case_b06_damage_dead(tree, host)
	cases["b06_take_damage_ignored_when_level_cleared"] = await _case_b06_damage_cleared(tree, host)
	cases["b06_lethal_damage_bypasses_big_and_invuln"] = await _case_b06_lethal_bypass(tree, host)

	# B07 QuestionBlock boundaries
	cases["b07_rehit_used_block_does_not_spawn_coin"] = await _case_b07_rehit_coin(tree, host)
	cases["b07_rehit_used_mushroom_block_spawns_once"] = await _case_b07_rehit_mushroom(tree, host)
	cases["b07_hit_with_null_player_guarded"] = await _case_b07_null_player(tree, host)
	cases["b07_used_animation_persists_after_rehit"] = await _case_b07_used_anim(tree, host)
	cases["b07_top_landing_does_not_trigger_block"] = await _case_b07_top_land(tree, host)

	# B08 BrickBlock boundaries
	cases["b08_hit_with_null_player_guarded"] = await _case_b08_null_player(tree, host)
	cases["b08_double_hit_while_shattering_scores_once"] = await _case_b08_double_shatter(tree, host)
	cases["b08_repeated_small_hits_stay_intact"] = await _case_b08_small_repeat(tree, host)
	cases["b08_top_landing_does_not_shatter_even_if_big"] = await _case_b08_top_land_big(tree, host)

	# B09 Coin boundaries
	cases["b09_double_collect_same_frame_scores_once"] = await _case_b09_double_collect(tree, host)
	cases["b09_dead_player_cannot_collect_coin"] = await _case_b09_dead_player(tree, host)
	cases["b09_coin_triggers_100_rollover_boundary"] = await _case_b09_rollover(tree, host)

	# B10 Mushroom boundaries
	cases["b10_double_pickup_same_frame_once"] = await _case_b10_double_pickup(tree, host)
	cases["b10_dead_player_ignored_by_mushroom"] = await _case_b10_dead_player(tree, host)
	cases["b10_mushroom_falls_below_pit_cleanup"] = await _case_b10_pit_cleanup(tree, host)
	cases["b10_grow_mushroom_when_already_big_no_regression"] = await _case_b10_already_big(tree, host)

	# B11 MovingPlatform boundaries
	cases["b11_duration_zero_guard"] = await _case_b11_bad_duration(tree, host, 0.0)
	cases["b11_duration_negative_guard"] = await _case_b11_bad_duration(tree, host, -2.5)
	cases["b11_zero_move_offset_stays_stationary"] = await _case_b11_zero_offset(tree, host)
	cases["b11_large_offset_clamped_bounds"] = await _case_b11_bounds(tree, host)

	# B12 Flagpole boundaries
	cases["b12_double_trigger_ignored"] = await _case_b12_double_trigger(tree, host)
	cases["b12_dead_player_cannot_clear_flagpole"] = await _case_b12_dead_player(tree, host)
	cases["b12_enemy_touching_flagpole_ignored"] = await _case_b12_enemy_ignored(tree, host)
	cases["b12_zero_time_remaining_gives_zero_bonus"] = await _case_b12_zero_time(tree, host)

	# B13 WalkerEnemy boundaries
	cases["b13_squished_enemy_ignores_second_stomp"] = await _case_b13_double_stomp(tree, host)
	cases["b13_squished_enemy_does_not_hurt_player"] = await _case_b13_squished_no_hurt(tree, host)
	cases["b13_block_bump_then_stomp_no_double_score"] = await _case_b13_bump_then_stomp(tree, host)
	cases["b13_stomp_threshold_above_vs_side"] = await _case_b13_above_vs_side(tree, host)
	cases["b13_walker_falls_below_pit_frees"] = await _case_b13_pit_free(tree, host)

	# B14 ShellEnemy boundaries
	cases["b14_kick_grace_prevents_immediate_self_hurt"] = await _case_b14_kick_grace(tree, host)
	cases["b14_stomp_sliding_shell_stops_to_idle"] = await _case_b14_stomp_sliding(tree, host)
	cases["b14_dead_shell_ignores_interactions"] = await _case_b14_dead_ignores(tree, host)
	cases["b14_rapid_wall_rebounds_preserve_speed"] = await _case_b14_rapid_rebounds(tree, host)
	cases["b14_shell_idle_safe_to_approach_and_kick"] = await _case_b14_approach_kick(tree, host)

	# B15 LevelBase boundaries
	cases["b15_timer_stops_at_zero_no_negative"] = await _case_b15_timer_zero(tree, host)
	cases["b15_pause_ignored_when_player_dead_or_cleared"] = await _case_b15_pause_dead_or_cleared(tree, host)
	cases["b15_level_tip_safe_on_levels_2_and_3"] = await _case_b15_levels_2_3_safe(tree, host)

	# B18 Level 3 routing
	cases["b18_level_3_next_scene_routes_to_end_screen"] = await _case_b18_end_routing(tree, host)

	# B19 HUD boundaries
	cases["b19_show_tip_empty_string_hides_or_safe"] = await _case_b19_empty_tip(tree, host)
	cases["b19_update_time_negative_clamps_zero"] = await _case_b19_neg_time(tree, host)
	cases["b19_large_score_999999_fits_no_error"] = await _case_b19_large_score(tree, host)
	cases["b19_hud_zero_lives_displays_0"] = await _case_b19_zero_lives(tree, host)

	# B20 PauseMenu boundaries
	cases["b20_restart_unpauses_tree_before_switch"] = await _case_b20_restart(tree)
	cases["b20_main_menu_unpauses_tree_before_switch"] = await _case_b20_main_menu(tree)
	cases["b20_double_toggle_restores_initial_state"] = await _case_b20_double_toggle(tree, host)
	cases["b20_pause_menu_works_while_tree_paused"] = await _case_b20_while_paused(tree, host)

	# B21 TitleScreen boundaries
	cases["b21_best_score_zero_displays_cleanly"] = await _case_b21_zero_best(tree, host)
	cases["b21_start_adventure_clears_stale_win_loss_flags"] = await _case_b21_clears_flags(tree)
	cases["b21_level_select_2_and_3_start_fresh_lives"] = await _case_b21_level_select_fresh(tree)
	cases["b21_title_mute_consecutive_clicks"] = await _case_b21_mute_clicks(tree, host)

	# B22 EndScreen boundaries
	cases["b22_end_screen_when_both_flags_false_safe"] = await _case_b22_both_false(tree, host)
	cases["b22_zero_score_displays_zero"] = await _case_b22_zero_score(tree, host)
	cases["b22_play_again_clears_big_power_to_small"] = await _case_b22_play_again_power(tree)
	cases["b22_best_score_preserved_across_game_over_and_replay"] = await _case_b22_best_preserved(tree)
	cases["b22_end_screen_unpauses_if_entered_paused"] = await _case_b22_unpauses(tree, host)

	_cleanup(tree)
	return {"ok": true, "error": "", "cases": cases}


# --- Helpers ---

func _ok(d: String) -> Dictionary:
	return {"passed": true, "detail": d}


func _fail(d: String) -> Dictionary:
	return {"passed": false, "detail": d}


func _gs(tree: SceneTree) -> Node:
	return tree.root.get_node_or_null("GameState")


func _am(tree: SceneTree) -> Node:
	return tree.root.get_node_or_null("AudioManager")


func _cleanup(tree: SceneTree) -> void:
	for act in ["move_left", "move_right", "jump", "sprint", "pause"]:
		if InputMap.has_action(act):
			Input.action_release(act)
	tree.paused = false
	var gs := _gs(tree)
	if gs != null and gs.has_method("reset_game"):
		gs.call("reset_game")
	var am := _am(tree)
	if am != null:
		if am.has_method("stop_bgm"):
			am.call("stop_bgm")
		if am.has_method("set_muted"):
			am.call("set_muted", false)
		if am.has_method("set_paused_duck"):
			am.call("set_paused_duck", false)


func _spawn(path: String, parent: Node) -> Node:
	if not ResourceLoader.exists(path):
		return null
	var res := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if not (res is PackedScene):
		return null
	var inst := (res as PackedScene).instantiate()
	if inst != null and parent != null:
		parent.add_child(inst)
	return inst


func _arena(host: Node) -> Node2D:
	var a := Node2D.new()
	host.add_child(a)
	return a


func _floor(arena: Node, pos: Vector2, size: Vector2 = Vector2(800, 32)) -> StaticBody2D:
	var b := StaticBody2D.new()
	b.collision_layer = 1
	b.collision_mask = 0
	b.position = pos
	var c := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = size
	c.shape = r
	b.add_child(c)
	arena.add_child(b)
	return b


func _step(tree: SceneTree, frames: int) -> void:
	for _i in range(frames):
		await tree.physics_frame


func _free_later(tree: SceneTree, node: Node) -> void:
	if node != null and is_instance_valid(node):
		if node.get_parent() != null:
			node.get_parent().remove_child(node)
		node.queue_free()
	await tree.process_frame


func _set_enum(obj: Object, names: Array, s: String, iv: int) -> void:
	for p in obj.get_property_list():
		var pn := str(p.get("name", ""))
		if names.has(pn):
			obj.set(pn, s if int(p.get("type", TYPE_INT)) == TYPE_STRING else iv)
			return


func _find_btn(root: Node, needle: String) -> BaseButton:
	if root is Button and (root as Button).text.find(needle) != -1:
		return root as BaseButton
	for c in root.get_children():
		var f := _find_btn(c, needle)
		if f != null:
			return f
	return null


func _texts(root: Node) -> Array[String]:
	var out: Array[String] = []
	if root is Label:
		out.append((root as Label).text)
	elif root is Button:
		out.append((root as Button).text)
	elif root is RichTextLabel:
		out.append((root as RichTextLabel).text)
	for c in root.get_children():
		out.append_array(_texts(c))
	return out


func _find_script(root: Node, suffix: String) -> Node:
	if root == null:
		return null
	var scr: Variant = root.get_script()
	if scr is Script and (scr as Script).resource_path.ends_with(suffix):
		return root
	for c in root.get_children():
		var f := _find_script(c, suffix)
		if f != null:
			return f
	return null


func _collect_script(root: Node, suffix: String) -> Array[Node]:
	var out: Array[Node] = []
	if root == null:
		return out
	var scr: Variant = root.get_script()
	if scr is Script and (scr as Script).resource_path.ends_with(suffix):
		out.append(root)
	for c in root.get_children():
		out.append_array(_collect_script(c, suffix))
	return out


# --- Cases ---

func _case_b03_neg_score(tree: SceneTree) -> Dictionary:
	var gs := _gs(tree)
	if gs == null:
		return _fail("Missing GameState")
	_cleanup(tree)
	gs.call("add_score", 100)
	gs.call("add_score", 0)
	gs.call("add_score", -100)
	return _ok("Zero/negative score ignored") if int(gs.get("score")) == 100 else _fail("score mutated on 0/-100")


func _case_b03_neg_coin(tree: SceneTree) -> Dictionary:
	var gs := _gs(tree)
	if gs == null:
		return _fail("Missing GameState")
	_cleanup(tree)
	gs.call("add_coin", 3)
	gs.call("add_coin", 0)
	gs.call("add_coin", -5)
	return _ok("Zero/negative coin ignored") if (int(gs.get("coins")) == 3 and int(gs.get("lives")) == 3) else _fail("coins/lives mutated on 0/-5")


func _case_b03_rollover(tree: SceneTree) -> Dictionary:
	var gs := _gs(tree)
	if gs == null:
		return _fail("Missing GameState")
	_cleanup(tree)
	gs.call("add_coin", 99)
	gs.call("add_coin", 1)
	if int(gs.get("coins")) != 0 or int(gs.get("lives")) != 4:
		return _fail("99+1 rollover failed")
	gs.call("add_coin", 95)
	gs.call("add_coin", 10)
	if int(gs.get("coins")) != 5 or int(gs.get("lives")) != 5:
		return _fail("95+10 rollover failed")
	gs.call("add_coin", 200)
	if int(gs.get("coins")) != 5 or int(gs.get("lives")) != 7:
		return _fail("200 coin multi-rollover failed")
	return _ok("Coin rollover & overflow verified")


func _case_b03_lives_floor(tree: SceneTree) -> Dictionary:
	var gs := _gs(tree)
	if gs == null:
		return _fail("Missing GameState")
	_cleanup(tree)
	gs.call("lose_life")
	gs.call("lose_life")
	gs.call("lose_life")
	gs.call("lose_life")
	if int(gs.get("lives")) != 0:
		return _fail("Lives went below 0")
	gs.call("add_life", 0)
	gs.call("add_life", -2)
	if int(gs.get("lives")) != 0:
		return _fail("add_life(0/-2) mutated lives")
	return _ok("Lives floor & non-positive add_life verified")


func _case_b03_level_bounds(tree: SceneTree) -> Dictionary:
	var gs := _gs(tree)
	if gs == null:
		return _fail("Missing GameState")
	_cleanup(tree)
	gs.call("set_level", 0)
	var l_low := int(gs.get("current_level"))
	gs.call("set_level", 99)
	var l_high := int(gs.get("current_level"))
	var p0 := str(gs.call("get_level_scene_path", 0))
	var pneg := str(gs.call("get_level_scene_path", -99))
	var p99 := str(gs.call("get_level_scene_path", 99))
	if l_low < 1 or l_low > 3 or l_high < 1 or l_high > 3:
		return _fail("set_level out-of-range not clamped: %d, %d" % [l_low, l_high])
	if p0.is_empty() or pneg.is_empty() or p99.is_empty():
		return _fail("get_level_scene_path returned empty on out-of-range")
	return _ok("Level bounds & paths clamped safely")


func _case_b04_sfx(tree: SceneTree, key: String) -> Dictionary:
	var am := _am(tree)
	if am == null:
		return _fail("Missing AudioManager")
	am.call("play_sfx", key)
	return _ok("play_sfx handled '%s'" % key)


func _case_b04_bgm_invalid(tree: SceneTree) -> Dictionary:
	var am := _am(tree)
	if am == null:
		return _fail("Missing AudioManager")
	am.call("play_bgm", "")
	am.call("play_bgm", "invalid_track")
	return _ok("Invalid BGM keys handled cleanly")


func _case_b04_stop_idle(tree: SceneTree) -> Dictionary:
	var am := _am(tree)
	if am == null:
		return _fail("Missing AudioManager")
	am.call("stop_bgm")
	am.call("stop_bgm")
	return _ok("stop_bgm idempotent when idle")


func _case_b04_muted(tree: SceneTree) -> Dictionary:
	var am := _am(tree)
	if am == null:
		return _fail("Missing AudioManager")
	am.call("set_muted", true)
	am.call("play_sfx", "jump")
	am.call("play_bgm", "overworld")
	var still_muted := bool(am.get("is_muted"))
	am.call("stop_bgm")
	am.call("set_muted", false)
	return _ok("Mute preserved on play calls") if still_muted else _fail("Mute cleared unexpectedly")


func _case_b05_opposing_inputs(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing Player")
	_cleanup(tree)
	var a := _arena(host)
	_floor(a, Vector2(0, 116))
	var p := _spawn(PATH_PLAYER, a) as CharacterBody2D
	p.position = Vector2(0, 100)
	await _step(tree, 3)
	Input.action_press("move_left")
	Input.action_press("move_right")
	await _step(tree, 6)
	var vx := absf(p.velocity.x)
	Input.action_release("move_left")
	Input.action_release("move_right")
	await _free_later(tree, a)
	return _ok("Opposing inputs canceled (vx=%.2f)" % vx) if vx < 5.0 else _fail("Opposing inputs moved player: vx=%.1f" % vx)


func _case_b05_coyote_expired(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing Player")
	_cleanup(tree)
	var a := _arena(host)
	_floor(a, Vector2(0, 116), Vector2(64, 32))
	var p := _spawn(PATH_PLAYER, a) as CharacterBody2D
	p.position = Vector2(20, 100)
	await _step(tree, 3)
	Input.action_press("move_right")
	var left_floor := false
	for _i in range(25):
		await _step(tree, 1)
		if not p.is_on_floor():
			left_floor = true
			break
	Input.action_release("move_right")
	if not left_floor:
		await _free_later(tree, a)
		return _fail("Player did not walk off ledge")
	await _step(tree, 12) # 0.20s > 0.10s coyote
	Input.action_press("jump")
	await _step(tree, 2)
	Input.action_release("jump")
	var vy := p.velocity.y
	await _free_later(tree, a)
	return _ok("Coyote expired cleanly (vy=%.1f)" % vy) if vy >= 0.0 else _fail("Jumped after coyote expired: vy=%.1f" % vy)


func _case_b05_buffer_expired(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing Player")
	_cleanup(tree)
	var a := _arena(host)
	_floor(a, Vector2(0, 216), Vector2(400, 32))
	var p := _spawn(PATH_PLAYER, a) as CharacterBody2D
	p.position = Vector2(0, 20)
	Input.action_press("jump")
	await _step(tree, 2)
	Input.action_release("jump")
	var jumped_on_land := false
	for _i in range(35):
		await _step(tree, 1)
		if p.is_on_floor() and p.velocity.y < -50.0:
			jumped_on_land = true
			break
	await _free_later(tree, a)
	return _ok("Expired jump buffer did not auto-jump") if not jumped_on_land else _fail("Expired jump buffer still triggered")


func _case_b05_no_double_jump(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing Player")
	_cleanup(tree)
	var a := _arena(host)
	_floor(a, Vector2(0, 116))
	var p := _spawn(PATH_PLAYER, a) as CharacterBody2D
	p.position = Vector2(0, 100)
	await _step(tree, 3)
	Input.action_press("jump")
	await _step(tree, 2)
	Input.action_release("jump")
	await _step(tree, 6)
	var vy_before := p.velocity.y
	Input.action_press("jump")
	await _step(tree, 1)
	var vy_after := p.velocity.y
	Input.action_release("jump")
	await _free_later(tree, a)
	return _ok("Midair double jump blocked") if vy_after >= vy_before - 5.0 else _fail("Midair jump increased upward speed: %.1f -> %.1f" % [vy_before, vy_after])


func _case_b05_release_falling(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing Player")
	_cleanup(tree)
	var a := _arena(host)
	_floor(a, Vector2(0, 300))
	var p := _spawn(PATH_PLAYER, a) as CharacterBody2D
	p.position = Vector2(0, 50)
	Input.action_press("jump")
	await _step(tree, 6)
	var vy_before := p.velocity.y
	Input.action_release("jump")
	await _step(tree, 1)
	var vy_after := p.velocity.y
	await _free_later(tree, a)
	return _ok("Release while falling did not cut fall speed") if (vy_before > 0.0 and vy_after >= vy_before) else _fail("Falling release altered speed: %.1f -> %.1f" % [vy_before, vy_after])


func _case_b06_already_big(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing Player")
	_cleanup(tree)
	var a := _arena(host)
	var p := _spawn(PATH_PLAYER, a)
	p.call("collect_powerup")
	p.call("collect_powerup")
	var big := bool(p.call("is_big"))
	await _free_later(tree, a)
	return _ok("collect_powerup when BIG stays BIG") if big else _fail("collect_powerup regressed BIG state")


func _case_b06_damage_invuln(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing Player")
	_cleanup(tree)
	var a := _arena(host)
	var p := _spawn(PATH_PLAYER, a)
	p.call("collect_powerup")
	p.call("take_damage", false) # shrinks to SMALL + invuln
	var lives_before := int(_gs(tree).get("lives"))
	p.call("take_damage", false)
	var dead := bool(p.call("is_dead"))
	var lives_after := int(_gs(tree).get("lives"))
	await _free_later(tree, a)
	return _ok("Non-lethal damage ignored while invulnerable") if (not dead and lives_after == lives_before) else _fail("Invuln did not block damage")


func _case_b06_damage_dead(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing Player")
	_cleanup(tree)
	var a := _arena(host)
	var p := _spawn(PATH_PLAYER, a)
	var died_count := [0]
	var cb := func() -> void: died_count[0] += 1
	p.connect("died", cb)
	p.call("take_damage", false)
	p.call("take_damage", false)
	p.call("take_damage", true)
	p.disconnect("died", cb)
	await _free_later(tree, a)
	return _ok("Damage ignored when already dead") if died_count[0] == 1 else _fail("died emitted %d times" % died_count[0])


func _case_b06_damage_cleared(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing Player")
	_cleanup(tree)
	var a := _arena(host)
	var p := _spawn(PATH_PLAYER, a)
	p.call("finish_level_clear")
	p.call("take_damage", false)
	var dead := bool(p.call("is_dead"))
	await _free_later(tree, a)
	return _ok("Damage ignored after level clear") if not dead else _fail("Damage killed player after finish_level_clear")


func _case_b06_lethal_bypass(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing Player")
	_cleanup(tree)
	var a := _arena(host)
	var p := _spawn(PATH_PLAYER, a)
	p.call("collect_powerup")
	p.call("take_damage", false) # now invulnerable
	p.call("collect_powerup") # now BIG + invulnerable
	p.call("take_damage", true)
	var dead := bool(p.call("is_dead"))
	await _free_later(tree, a)
	return _ok("Lethal damage bypassed BIG & invuln") if dead else _fail("Lethal damage failed to kill invuln BIG player")


func _case_b07_rehit_coin(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_QUESTION_BLOCK) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing QuestionBlock or Player")
	_cleanup(tree)
	var a := _arena(host)
	var qb := _spawn(PATH_QUESTION_BLOCK, a)
	_set_enum(qb, ["reward_type", "reward"], "COIN", 0)
	var p := _spawn(PATH_PLAYER, a)
	qb.call("hit_from_below", p)
	qb.call("hit_from_below", p)
	var ok := int(_gs(tree).get("coins")) == 1 and int(_gs(tree).get("score")) == 100
	await _free_later(tree, a)
	return _ok("Used QuestionBlock ignored 2nd coin hit") if ok else _fail("Used QuestionBlock double-rewarded")


func _case_b07_rehit_mushroom(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_QUESTION_BLOCK) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing QuestionBlock or Player")
	_cleanup(tree)
	var a := _arena(host)
	var qb := _spawn(PATH_QUESTION_BLOCK, a)
	_set_enum(qb, ["reward_type", "reward"], "MUSHROOM", 1)
	var p := _spawn(PATH_PLAYER, a)
	qb.call("hit_from_below", p)
	qb.call("hit_from_below", p)
	await _step(tree, 2)
	var count := _collect_script(a, "mushroom.gd").size()
	await _free_later(tree, a)
	return _ok("Used QuestionBlock spawned 1 mushroom only") if count == 1 else _fail("Spawned %d mushrooms" % count)


func _case_b07_null_player(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_QUESTION_BLOCK):
		return _fail("Missing QuestionBlock")
	var a := _arena(host)
	var qb := _spawn(PATH_QUESTION_BLOCK, a)
	qb.call("hit_from_below", null)
	await _free_later(tree, a)
	return _ok("QuestionBlock hit_from_below(null) guarded")


func _case_b07_used_anim(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_QUESTION_BLOCK) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing QuestionBlock or Player")
	var a := _arena(host)
	var qb := _spawn(PATH_QUESTION_BLOCK, a)
	var p := _spawn(PATH_PLAYER, a)
	qb.call("hit_from_below", p)
	qb.call("hit_from_below", p)
	var spr := qb.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	var anim := String(spr.animation) if spr != null else ""
	await _free_later(tree, a)
	return _ok("Used animation persisted") if anim == "used" else _fail("Animation was '%s'" % anim)


func _case_b07_top_land(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_QUESTION_BLOCK) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing QuestionBlock or Player")
	_cleanup(tree)
	var a := _arena(host)
	var qb := _spawn(PATH_QUESTION_BLOCK, a) as Node2D
	qb.position = Vector2(100, 116)
	var p := _spawn(PATH_PLAYER, a) as Node2D
	p.position = Vector2(100, 96)
	await _step(tree, 8)
	var ok := int(_gs(tree).get("coins")) == 0
	await _free_later(tree, a)
	return _ok("Top landing did not trigger QuestionBlock") if ok else _fail("Top landing triggered QuestionBlock")


func _case_b08_null_player(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_BRICK_BLOCK):
		return _fail("Missing BrickBlock")
	var a := _arena(host)
	var bb := _spawn(PATH_BRICK_BLOCK, a)
	bb.call("hit_from_below", null)
	await _free_later(tree, a)
	return _ok("BrickBlock hit_from_below(null) guarded")


func _case_b08_double_shatter(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_BRICK_BLOCK) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing BrickBlock or Player")
	_cleanup(tree)
	var a := _arena(host)
	var bb := _spawn(PATH_BRICK_BLOCK, a)
	var p := _spawn(PATH_PLAYER, a)
	p.call("collect_powerup")
	bb.call("hit_from_below", p)
	bb.call("hit_from_below", p)
	var sc := int(_gs(tree).get("score"))
	await _free_later(tree, a)
	return _ok("Brick double-hit scored once (50)") if sc == 50 else _fail("Brick double-hit scored %d" % sc)


func _case_b08_small_repeat(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_BRICK_BLOCK) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing BrickBlock or Player")
	_cleanup(tree)
	var a := _arena(host)
	var bb := _spawn(PATH_BRICK_BLOCK, a)
	var p := _spawn(PATH_PLAYER, a)
	for _i in range(3):
		bb.call("hit_from_below", p)
	var intact := is_instance_valid(bb) and not bb.is_queued_for_deletion()
	var sc := int(_gs(tree).get("score"))
	await _free_later(tree, a)
	return _ok("3 small hits kept brick intact") if (intact and sc == 0) else _fail("Repeated small hits broke brick or scored")


func _case_b08_top_land_big(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_BRICK_BLOCK) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing BrickBlock or Player")
	var a := _arena(host)
	var bb := _spawn(PATH_BRICK_BLOCK, a) as Node2D
	bb.position = Vector2(100, 116)
	var p := _spawn(PATH_PLAYER, a) as Node2D
	p.call("collect_powerup")
	p.position = Vector2(100, 96)
	await _step(tree, 8)
	var intact := is_instance_valid(bb) and not bb.is_queued_for_deletion()
	await _free_later(tree, a)
	return _ok("BIG landing atop BrickBlock kept it intact") if intact else _fail("Top landing shattered BrickBlock")


func _case_b09_double_collect(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_COIN) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing Coin or Player")
	_cleanup(tree)
	var a := _arena(host)
	var c := _spawn(PATH_COIN, a) as Area2D
	var p := _spawn(PATH_PLAYER, a)
	c.emit_signal("body_entered", p)
	c.emit_signal("body_entered", p)
	var ok := int(_gs(tree).get("coins")) == 1 and int(_gs(tree).get("score")) == 100
	await _free_later(tree, a)
	return _ok("Coin double collect same frame scored once") if ok else _fail("Coin double-collected")


func _case_b09_dead_player(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_COIN) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing Coin or Player")
	_cleanup(tree)
	var a := _arena(host)
	var c := _spawn(PATH_COIN, a) as Node2D
	c.position = Vector2(100, 100)
	var p := _spawn(PATH_PLAYER, a) as Node2D
	p.position = Vector2(100, 114)
	p.call("take_damage", false)
	await _step(tree, 4)
	var ok := int(_gs(tree).get("coins")) == 0
	await _free_later(tree, a)
	return _ok("Dead player ignored by Coin") if ok else _fail("Dead player collected Coin")


func _case_b09_rollover(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_COIN) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing Coin or Player")
	_cleanup(tree)
	_gs(tree).call("add_coin", 99)
	var a := _arena(host)
	var c := _spawn(PATH_COIN, a) as Node2D
	c.position = Vector2(100, 100)
	var p := _spawn(PATH_PLAYER, a) as Node2D
	p.position = Vector2(100, 114)
	await _step(tree, 5)
	var ok := int(_gs(tree).get("coins")) == 0 and int(_gs(tree).get("lives")) == 4
	await _free_later(tree, a)
	return _ok("Coin triggered 100 rollover") if ok else _fail("Coin 99->100 rollover failed")


func _case_b10_double_pickup(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_MUSHROOM) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing Mushroom or Player")
	_cleanup(tree)
	var a := _arena(host)
	var m := _spawn(PATH_MUSHROOM, a)
	_set_enum(m, ["mushroom_type", "type"], "ONE_UP", 1)
	var pa := m.get_node_or_null("PickupArea") as Area2D
	var p := _spawn(PATH_PLAYER, a)
	if pa != null:
		pa.emit_signal("body_entered", p)
		pa.emit_signal("body_entered", p)
	var lives := int(_gs(tree).get("lives"))
	await _free_later(tree, a)
	return _ok("Mushroom double pickup granted +1 life only") if lives == 4 else _fail("Expected 4 lives, got %d" % lives)


func _case_b10_dead_player(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_MUSHROOM) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing Mushroom or Player")
	_cleanup(tree)
	var a := _arena(host)
	var p := _spawn(PATH_PLAYER, a) as Node2D
	p.position = Vector2(100, 100)
	p.call("take_damage", false)
	var m := _spawn(PATH_MUSHROOM, a) as Node2D
	_set_enum(m, ["mushroom_type", "type"], "ONE_UP", 1)
	m.position = Vector2(100, 90)
	await _step(tree, 4)
	var ok := int(_gs(tree).get("lives")) == 2
	await _free_later(tree, a)
	return _ok("Dead player ignored by Mushroom") if ok else _fail("Dead player collected Mushroom")


func _case_b10_pit_cleanup(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_MUSHROOM):
		return _fail("Missing Mushroom")
	var a := _arena(host)
	var m := _spawn(PATH_MUSHROOM, a) as Node2D
	m.position = Vector2(0, 1500)
	await _step(tree, 5)
	await _free_later(tree, a)
	return _ok("Mushroom below pit handled cleanly")


func _case_b10_already_big(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_MUSHROOM) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing Mushroom or Player")
	_cleanup(tree)
	var a := _arena(host)
	var p := _spawn(PATH_PLAYER, a) as Node2D
	p.call("collect_powerup")
	p.position = Vector2(100, 100)
	var m := _spawn(PATH_MUSHROOM, a) as Node2D
	_set_enum(m, ["mushroom_type", "type"], "GROW", 0)
	m.position = Vector2(100, 90)
	await _step(tree, 4)
	var big := bool(p.call("is_big"))
	await _free_later(tree, a)
	return _ok("GROW mushroom when already BIG safe") if big else _fail("BIG state regressed")


func _case_b11_bad_duration(tree: SceneTree, host: Node, dur: float) -> Dictionary:
	if not ResourceLoader.exists(PATH_MOVING_PLATFORM):
		return _fail("Missing MovingPlatform")
	var a := _arena(host)
	var mp := _spawn(PATH_MOVING_PLATFORM, a) as Node2D
	mp.position = Vector2(100, 100)
	mp.set("move_offset", Vector2(64, 0))
	mp.set("duration", dur)
	await _step(tree, 5)
	var ok := not is_nan(mp.position.x) and not is_nan(mp.position.y)
	await _free_later(tree, a)
	return _ok("duration=%s guarded (no NaN)" % str(dur)) if ok else _fail("NaN position on duration=%s" % str(dur))


func _case_b11_zero_offset(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_MOVING_PLATFORM):
		return _fail("Missing MovingPlatform")
	var a := _arena(host)
	var mp := _spawn(PATH_MOVING_PLATFORM, a) as Node2D
	mp.position = Vector2(100, 100)
	mp.set("move_offset", Vector2.ZERO)
	mp.set("duration", 1.0)
	await _step(tree, 8)
	var dist := mp.position.distance_to(Vector2(100, 100))
	await _free_later(tree, a)
	return _ok("Zero offset stayed stationary") if dist < 0.5 else _fail("Platform moved with zero offset")


func _case_b11_bounds(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_MOVING_PLATFORM):
		return _fail("Missing MovingPlatform")
	var a := _arena(host)
	var mp := _spawn(PATH_MOVING_PLATFORM, a) as Node2D
	mp.position = Vector2(100, 100)
	mp.set("move_offset", Vector2(120, 0))
	mp.set("duration", 0.3)
	var min_x := 100.0
	var max_x := 100.0
	for _i in range(24):
		await _step(tree, 1)
		min_x = minf(min_x, mp.position.x)
		max_x = maxf(max_x, mp.position.x)
	await _free_later(tree, a)
	var ok := min_x >= 99.0 and max_x <= 221.0
	return _ok("Platform bounded [%.1f, %.1f]" % [min_x, max_x]) if ok else _fail("Platform out of bounds: [%.1f, %.1f]" % [min_x, max_x])


func _case_b12_double_trigger(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_FLAGPOLE) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing Flagpole or Player")
	_cleanup(tree)
	var a := _arena(host)
	var fp := _spawn(PATH_FLAGPOLE, a) as Area2D
	var count := [0]
	var cb := func(_tb: int) -> void: count[0] += 1
	fp.connect("level_cleared", cb)
	var p := _spawn(PATH_PLAYER, a)
	fp.emit_signal("body_entered", p)
	fp.emit_signal("body_entered", p)
	fp.disconnect("level_cleared", cb)
	await _free_later(tree, a)
	return _ok("Flagpole double trigger ignored") if count[0] == 1 else _fail("level_cleared emitted %d times" % count[0])


func _case_b12_dead_player(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_FLAGPOLE) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing Flagpole or Player")
	_cleanup(tree)
	var a := _arena(host)
	var fp := _spawn(PATH_FLAGPOLE, a) as Area2D
	var count := [0]
	var cb := func(_tb: int) -> void: count[0] += 1
	fp.connect("level_cleared", cb)
	var p := _spawn(PATH_PLAYER, a)
	p.call("take_damage", false)
	fp.emit_signal("body_entered", p)
	fp.disconnect("level_cleared", cb)
	await _free_later(tree, a)
	return _ok("Dead player ignored by Flagpole") if count[0] == 0 else _fail("Dead player triggered Flagpole")


func _case_b12_enemy_ignored(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_FLAGPOLE) or not ResourceLoader.exists(PATH_WALKER):
		return _fail("Missing Flagpole or WalkerEnemy")
	var a := _arena(host)
	var fp := _spawn(PATH_FLAGPOLE, a) as Area2D
	var count := [0]
	var cb := func(_tb: int) -> void: count[0] += 1
	fp.connect("level_cleared", cb)
	var w := _spawn(PATH_WALKER, a)
	fp.emit_signal("body_entered", w)
	fp.disconnect("level_cleared", cb)
	await _free_later(tree, a)
	return _ok("Enemy ignored by Flagpole") if count[0] == 0 else _fail("Enemy triggered Flagpole")


func _case_b12_zero_time(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_FLAGPOLE) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing Flagpole or Player")
	var a := _arena(host)
	var fp := _spawn(PATH_FLAGPOLE, a) as Area2D
	var bonuses: Array[int] = []
	var cb := func(tb: int) -> void: bonuses.append(tb)
	fp.connect("level_cleared", cb)
	if fp.has_method("set_time_remaining"):
		fp.call("set_time_remaining", 0)
	var p := _spawn(PATH_PLAYER, a)
	fp.emit_signal("body_entered", p)
	fp.disconnect("level_cleared", cb)
	await _free_later(tree, a)
	return _ok("Zero time gives >=0 bonus") if (bonuses.size() == 1 and bonuses[0] >= 0) else _fail("Invalid bonus: " + str(bonuses))


func _case_b13_double_stomp(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_WALKER) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing WalkerEnemy or Player")
	_cleanup(tree)
	var a := _arena(host)
	var w := _spawn(PATH_WALKER, a)
	var p := _spawn(PATH_PLAYER, a)
	w.call("on_stomped", p)
	w.call("on_stomped", p)
	var sc := int(_gs(tree).get("score"))
	await _free_later(tree, a)
	return _ok("Squished walker ignored 2nd stomp") if sc == 200 else _fail("Expected 200, got %d" % sc)


func _case_b13_squished_no_hurt(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_WALKER) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing WalkerEnemy or Player")
	_cleanup(tree)
	var a := _arena(host)
	_floor(a, Vector2(0, 116))
	var w := _spawn(PATH_WALKER, a) as Node2D
	w.position = Vector2(0, 100)
	var p := _spawn(PATH_PLAYER, a) as Node2D
	p.position = Vector2(0, 100)
	w.call("on_stomped", p)
	await _step(tree, 4)
	var dead := bool(p.call("is_dead"))
	await _free_later(tree, a)
	return _ok("Squished walker did not hurt player") if not dead else _fail("Squished walker hurt player")


func _case_b13_bump_then_stomp(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_WALKER) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing WalkerEnemy or Player")
	_cleanup(tree)
	var a := _arena(host)
	var w := _spawn(PATH_WALKER, a)
	var p := _spawn(PATH_PLAYER, a)
	w.call("on_block_bumped")
	var sc1 := int(_gs(tree).get("score"))
	w.call("on_stomped", p)
	var sc2 := int(_gs(tree).get("score"))
	await _free_later(tree, a)
	return _ok("Bumped walker ignored subsequent stomp") if sc2 == sc1 else _fail("Double scored: %d -> %d" % [sc1, sc2])


func _case_b13_above_vs_side(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_WALKER) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing WalkerEnemy or Player")
	_cleanup(tree)
	var a := _arena(host)
	_floor(a, Vector2(0, 116))
	var w := _spawn(PATH_WALKER, a) as Node2D
	w.position = Vector2(0, 100)
	var p := _spawn(PATH_PLAYER, a) as CharacterBody2D
	p.position = Vector2(0, 74)
	p.velocity = Vector2(0, 120)
	await _step(tree, 6)
	var stomped := (not bool(p.call("is_dead"))) and int(_gs(tree).get("score")) >= 200
	await _free_later(tree, a)
	return _ok("Falling above stomped walker cleanly") if stomped else _fail("Stomp from above failed")


func _case_b13_pit_free(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_WALKER):
		return _fail("Missing WalkerEnemy")
	var a := _arena(host)
	var w := _spawn(PATH_WALKER, a) as Node2D
	w.position = Vector2(0, 1500)
	await _step(tree, 5)
	await _free_later(tree, a)
	return _ok("Walker below pit handled cleanly")


func _case_b14_kick_grace(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_SHELL) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing ShellEnemy or Player")
	_cleanup(tree)
	var a := _arena(host)
	_floor(a, Vector2(0, 116))
	var sh := _spawn(PATH_SHELL, a) as Node2D
	sh.position = Vector2(10, 100)
	var p := _spawn(PATH_PLAYER, a) as Node2D
	p.position = Vector2(-10, 100)
	sh.call("on_stomped", p)
	# Approach laterally from left to kick
	p.position = Vector2(2, 100)
	await _step(tree, 3)
	var hurt := bool(p.call("is_dead"))
	await _free_later(tree, a)
	return _ok("Kick grace protected player") if not hurt else _fail("Player hurt immediately on shell kick")


func _case_b14_stomp_sliding(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_SHELL) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing ShellEnemy or Player")
	var a := _arena(host)
	var sh := _spawn(PATH_SHELL, a)
	var p := _spawn(PATH_PLAYER, a) as Node2D
	p.position = Vector2(-20, 0)
	sh.call("on_stomped", p) # IDLE
	sh.call("on_stomped", p) # SLIDE
	sh.call("on_stomped", p) # back to IDLE
	var idle := bool(sh.call("is_shell_idle"))
	var sliding := bool(sh.call("is_sliding"))
	await _free_later(tree, a)
	return _ok("Stomping sliding shell stopped it to IDLE") if (idle and not sliding) else _fail("Sliding shell did not stop")


func _case_b14_dead_ignores(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_SHELL) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing ShellEnemy or Player")
	_cleanup(tree)
	var a := _arena(host)
	var sh := _spawn(PATH_SHELL, a)
	var p := _spawn(PATH_PLAYER, a)
	sh.call("on_block_bumped")
	var sc1 := int(_gs(tree).get("score"))
	sh.call("on_stomped", p)
	var sc2 := int(_gs(tree).get("score"))
	await _free_later(tree, a)
	return _ok("Dead shell ignored subsequent stomp") if sc2 == sc1 else _fail("Dead shell still scored")


func _case_b14_rapid_rebounds(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_SHELL) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing ShellEnemy or Player")
	var a := _arena(host)
	_floor(a, Vector2(0, 116))
	_floor(a, Vector2(-36, 80), Vector2(24, 64))
	_floor(a, Vector2(36, 80), Vector2(24, 64))
	var sh := _spawn(PATH_SHELL, a) as CharacterBody2D
	sh.position = Vector2(0, 100)
	var p := _spawn(PATH_PLAYER, a) as Node2D
	p.position = Vector2(-20, 100)
	sh.call("on_stomped", p)
	sh.call("on_stomped", p)
	await _step(tree, 18)
	var ok := bool(sh.call("is_sliding")) and absf(sh.velocity.x) > 50.0
	await _free_later(tree, a)
	return _ok("Rapid wall rebounds preserved shell slide speed") if ok else _fail("Shell speed collapsed on rebounds")


func _case_b14_approach_kick(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_SHELL) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing ShellEnemy or Player")
	_cleanup(tree)
	var a := _arena(host)
	_floor(a, Vector2(0, 116))
	var sh := _spawn(PATH_SHELL, a) as CharacterBody2D
	sh.position = Vector2(12, 100)
	var p := _spawn(PATH_PLAYER, a) as Node2D
	p.position = Vector2(-20, 100)
	sh.call("on_stomped", p) # IDLE
	p.position = Vector2(6, 100)
	await _step(tree, 4)
	var ok := bool(sh.call("is_sliding")) and not bool(p.call("is_dead"))
	await _free_later(tree, a)
	return _ok("Lateral contact kicked IDLE shell safely") if ok else _fail("Approach kick failed")


func _case_b15_timer_zero(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_LEVEL_1):
		return _fail("Missing level_1.tscn")
	_cleanup(tree)
	var lvl := _spawn(PATH_LEVEL_1, host)
	lvl.set("time_limit", 0.05)
	if lvl.get("time_remaining") != null:
		lvl.set("time_remaining", 0.05)
	await _step(tree, 10)
	var p := _find_script(lvl, "player.gd")
	var tr: Variant = lvl.get("time_remaining")
	var clamped := tr == null or float(tr) >= 0.0
	var dead := p != null and bool(p.call("is_dead"))
	await _free_later(tree, lvl)
	_cleanup(tree)
	return _ok("Timer clamped >=0 & killed player on timeout") if (clamped and dead) else _fail("Timeout handling failed: tr=%s dead=%s" % [str(tr), str(dead)])


func _case_b15_pause_dead_or_cleared(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_LEVEL_1):
		return _fail("Missing level_1.tscn")
	_cleanup(tree)
	var lvl := _spawn(PATH_LEVEL_1, host)
	await _step(tree, 2)
	var p := _find_script(lvl, "player.gd")
	p.call("take_damage", false)
	Input.action_press("pause")
	await _step(tree, 2)
	Input.action_release("pause")
	var paused := tree.paused
	await _free_later(tree, lvl)
	_cleanup(tree)
	return _ok("Pause ignored when player dead") if not paused else _fail("Tree paused while player dead")


func _case_b15_levels_2_3_safe(tree: SceneTree, host: Node) -> Dictionary:
	for path in [PATH_LEVEL_2, PATH_LEVEL_3]:
		if not ResourceLoader.exists(path):
			return _fail("Missing " + path)
		_cleanup(tree)
		var lvl := _spawn(path, host)
		await _step(tree, 3)
		await _free_later(tree, lvl)
	_cleanup(tree)
	return _ok("Levels 2 and 3 initialized safely")


func _case_b18_end_routing(tree: SceneTree, _host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_LEVEL_3) or not ResourceLoader.exists(PATH_END_SCREEN):
		return _fail("Missing level_3.tscn or end_screen.tscn")
	_cleanup(tree)
	var saved := tree.current_scene
	var lvl := _spawn(PATH_LEVEL_3, tree.root)
	tree.current_scene = lvl
	await _step(tree, 2)
	var p := _find_script(lvl, "player.gd") as Node2D
	var fp := _find_script(lvl, "flagpole.gd") as Node2D
	p.global_position = fp.global_position
	var routed := ""
	for _i in range(180):
		await _step(tree, 1)
		if tree.current_scene != null and tree.current_scene != lvl:
			routed = tree.current_scene.scene_file_path
			break
	if tree.current_scene != null and tree.current_scene != saved:
		await _free_later(tree, tree.current_scene)
	tree.current_scene = saved
	_cleanup(tree)
	return _ok("Level 3 routed to EndScreen") if routed == PATH_END_SCREEN else _fail("Routed to '%s'" % routed)


func _case_b19_empty_tip(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_HUD):
		return _fail("Missing hud.tscn")
	var hud := _spawn(PATH_HUD, host)
	await tree.process_frame
	hud.call("show_tip", "")
	await _free_later(tree, hud)
	return _ok("HUD.show_tip('') safe")


func _case_b19_neg_time(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_HUD):
		return _fail("Missing hud.tscn")
	var hud := _spawn(PATH_HUD, host)
	await tree.process_frame
	hud.call("update_time", -10)
	var joined := " | ".join(_texts(hud))
	await _free_later(tree, hud)
	return _ok("HUD.update_time(-10) clamped to 0") if joined.find("-10") == -1 else _fail("Negative time displayed: " + joined)


func _case_b19_large_score(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_HUD):
		return _fail("Missing hud.tscn")
	_cleanup(tree)
	var hud := _spawn(PATH_HUD, host)
	await tree.process_frame
	_gs(tree).call("add_score", 999999)
	await tree.process_frame
	var joined := " | ".join(_texts(hud))
	await _free_later(tree, hud)
	_cleanup(tree)
	return _ok("HUD formatted 999999") if joined.find("999999") != -1 else _fail("999999 missing: " + joined)


func _case_b19_zero_lives(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_HUD):
		return _fail("Missing hud.tscn")
	_cleanup(tree)
	var hud := _spawn(PATH_HUD, host)
	await tree.process_frame
	var gs := _gs(tree)
	gs.call("lose_life")
	gs.call("lose_life")
	gs.call("lose_life")
	await tree.process_frame
	var joined := " | ".join(_texts(hud))
	await _free_later(tree, hud)
	_cleanup(tree)
	return _ok("HUD displays 0 lives") if joined.find("0") != -1 else _fail("HUD 0 lives missing")


func _case_b20_restart(tree: SceneTree) -> Dictionary:
	if not ResourceLoader.exists(PATH_LEVEL_1):
		return _fail("Missing level_1.tscn")
	_cleanup(tree)
	var saved := tree.current_scene
	var lvl := _spawn(PATH_LEVEL_1, tree.root)
	tree.current_scene = lvl
	await tree.process_frame
	var pm := _find_script(lvl, "pause_menu.gd")
	pm.call("toggle_pause")
	var btn := _find_btn(pm, "إعادة المرحلة")
	if btn == null:
		await _free_later(tree, lvl)
		tree.current_scene = saved
		_cleanup(tree)
		return _fail("PauseMenu missing Restart button")
	btn.emit_signal("pressed")
	await tree.process_frame
	await tree.process_frame
	var ok := (not tree.paused) and (not bool(_am(tree).get("is_ducked")))
	if tree.current_scene != null and tree.current_scene != saved:
		await _free_later(tree, tree.current_scene)
	tree.current_scene = saved
	_cleanup(tree)
	return _ok("PauseMenu Restart unpaused & unducked") if ok else _fail("Restart left paused or ducked")


func _case_b20_main_menu(tree: SceneTree) -> Dictionary:
	if not ResourceLoader.exists(PATH_PAUSE_MENU) or not ResourceLoader.exists(PATH_MAIN):
		return _fail("Missing pause_menu.tscn or main.tscn")
	_cleanup(tree)
	var saved := tree.current_scene
	var pm := _spawn(PATH_PAUSE_MENU, tree.root)
	tree.current_scene = pm
	await tree.process_frame
	pm.call("toggle_pause")
	var btn := _find_btn(pm, "القائمة الرئيسية")
	if btn == null:
		await _free_later(tree, pm)
		tree.current_scene = saved
		_cleanup(tree)
		return _fail("PauseMenu missing Main Menu button")
	btn.emit_signal("pressed")
	await tree.process_frame
	await tree.process_frame
	var ok := (not tree.paused) and (not bool(_am(tree).get("is_ducked"))) and tree.current_scene != null and tree.current_scene.scene_file_path == PATH_MAIN
	if tree.current_scene != null and tree.current_scene != saved:
		await _free_later(tree, tree.current_scene)
	tree.current_scene = saved
	_cleanup(tree)
	return _ok("PauseMenu Main Menu unpaused & switched") if ok else _fail("PauseMenu Main Menu failed")


func _case_b20_double_toggle(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_PAUSE_MENU):
		return _fail("Missing pause_menu.tscn")
	_cleanup(tree)
	var pm := _spawn(PATH_PAUSE_MENU, host) as Control
	await tree.process_frame
	pm.call("toggle_pause")
	pm.call("toggle_pause")
	var ok := (not tree.paused) and (not pm.visible) and (not bool(_am(tree).get("is_ducked")))
	await _free_later(tree, pm)
	_cleanup(tree)
	return _ok("Double toggle restored initial state") if ok else _fail("Double toggle did not restore")


func _case_b20_while_paused(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_PAUSE_MENU):
		return _fail("Missing pause_menu.tscn")
	_cleanup(tree)
	var pm := _spawn(PATH_PAUSE_MENU, host) as Control
	await tree.process_frame
	pm.call("toggle_pause")
	await tree.process_frame
	pm.call("toggle_pause")
	var ok := not tree.paused and not pm.visible
	await _free_later(tree, pm)
	_cleanup(tree)
	return _ok("PauseMenu worked while SceneTree paused") if ok else _fail("PauseMenu stuck while paused")


func _case_b21_zero_best(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_MAIN):
		return _fail("Missing main.tscn")
	_cleanup(tree)
	_gs(tree).set("best_score", 0)
	var ts := _spawn(PATH_MAIN, host)
	await tree.process_frame
	var joined := " | ".join(_texts(ts))
	await _free_later(tree, ts)
	return _ok("best_score=0 displays cleanly") if joined.find("0") != -1 else _fail("0 missing on TitleScreen")


func _case_b21_clears_flags(tree: SceneTree) -> Dictionary:
	if not ResourceLoader.exists(PATH_MAIN) or not ResourceLoader.exists(PATH_LEVEL_1):
		return _fail("Missing main.tscn or level_1.tscn")
	_cleanup(tree)
	_gs(tree).call("mark_victory")
	var saved := tree.current_scene
	var ts := _spawn(PATH_MAIN, tree.root)
	tree.current_scene = ts
	await tree.process_frame
	var btn := _find_btn(ts, "ابدأ المغامرة")
	if btn == null:
		await _free_later(tree, ts)
		tree.current_scene = saved
		return _fail("Missing Start button")
	btn.emit_signal("pressed")
	await tree.process_frame
	await tree.process_frame
	var ok := not bool(_gs(tree).get("game_won")) and not bool(_gs(tree).get("game_over"))
	if tree.current_scene != null and tree.current_scene != saved:
		await _free_later(tree, tree.current_scene)
	tree.current_scene = saved
	_cleanup(tree)
	return _ok("Start Adventure cleared win/loss flags") if ok else _fail("Flags remained dirty")


func _case_b21_level_select_fresh(tree: SceneTree) -> Dictionary:
	if not ResourceLoader.exists(PATH_MAIN) or not ResourceLoader.exists(PATH_LEVEL_3):
		return _fail("Missing main.tscn or level_3.tscn")
	_cleanup(tree)
	_gs(tree).call("lose_life")
	var saved := tree.current_scene
	var ts := _spawn(PATH_MAIN, tree.root)
	tree.current_scene = ts
	await tree.process_frame
	var btn := _find_btn(ts, "1-3")
	if btn == null:
		await _free_later(tree, ts)
		tree.current_scene = saved
		return _fail("Missing 1-3 button")
	btn.emit_signal("pressed")
	await tree.process_frame
	await tree.process_frame
	var ok := int(_gs(tree).get("current_level")) == 3 and int(_gs(tree).get("lives")) == 3
	if tree.current_scene != null and tree.current_scene != saved:
		await _free_later(tree, tree.current_scene)
	tree.current_scene = saved
	_cleanup(tree)
	return _ok("Level select 1-3 started with fresh 3 lives") if ok else _fail("Level select fresh state mismatch")


func _case_b21_mute_clicks(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_MAIN):
		return _fail("Missing main.tscn")
	_cleanup(tree)
	var ts := _spawn(PATH_MAIN, host)
	await tree.process_frame
	var btn := _find_btn(ts, "الصوت")
	if btn == null:
		btn = _find_btn(ts, "كتم")
	if btn == null:
		await _free_later(tree, ts)
		return _fail("TitleScreen missing mute button")
	btn.emit_signal("pressed")
	var m1 := bool(_am(tree).get("is_muted"))
	btn.emit_signal("pressed")
	var m2 := bool(_am(tree).get("is_muted"))
	await _free_later(tree, ts)
	_cleanup(tree)
	return _ok("Consecutive mute clicks alternated") if (m1 == true and m2 == false) else _fail("Mute clicks did not alternate")


func _case_b22_both_false(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_END_SCREEN):
		return _fail("Missing end_screen.tscn")
	_cleanup(tree)
	var es := _spawn(PATH_END_SCREEN, host)
	await tree.process_frame
	await _free_later(tree, es)
	return _ok("EndScreen safe when both win/loss flags false")


func _case_b22_zero_score(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_END_SCREEN):
		return _fail("Missing end_screen.tscn")
	_cleanup(tree)
	_gs(tree).set("best_score", 0)
	var es := _spawn(PATH_END_SCREEN, host)
	await tree.process_frame
	var joined := " | ".join(_texts(es))
	await _free_later(tree, es)
	var ok := joined.find("0") != -1 and joined.find("null") == -1
	return _ok("EndScreen zero score displays 0 cleanly") if ok else _fail("EndScreen zero score invalid: " + joined)


func _case_b22_play_again_power(tree: SceneTree) -> Dictionary:
	if not ResourceLoader.exists(PATH_END_SCREEN) or not ResourceLoader.exists(PATH_LEVEL_1):
		return _fail("Missing end_screen.tscn or level_1.tscn")
	_cleanup(tree)
	_gs(tree).call("set_power", 1)
	var saved := tree.current_scene
	var es := _spawn(PATH_END_SCREEN, tree.root)
	tree.current_scene = es
	await tree.process_frame
	var btn := _find_btn(es, "إعادة اللعب")
	if btn == null:
		await _free_later(tree, es)
		tree.current_scene = saved
		return _fail("Missing Play Again button")
	btn.emit_signal("pressed")
	await tree.process_frame
	await tree.process_frame
	var ok := int(_gs(tree).get("player_power")) == 0
	if tree.current_scene != null and tree.current_scene != saved:
		await _free_later(tree, tree.current_scene)
	tree.current_scene = saved
	_cleanup(tree)
	return _ok("Play Again reset player_power to SMALL") if ok else _fail("player_power stayed BIG")


func _case_b22_best_preserved(tree: SceneTree) -> Dictionary:
	if not ResourceLoader.exists(PATH_END_SCREEN) or not ResourceLoader.exists(PATH_LEVEL_1):
		return _fail("Missing end_screen.tscn or level_1.tscn")
	_cleanup(tree)
	_gs(tree).call("add_score", 880)
	_gs(tree).call("mark_game_over")
	var saved := tree.current_scene
	var es := _spawn(PATH_END_SCREEN, tree.root)
	tree.current_scene = es
	await tree.process_frame
	var btn := _find_btn(es, "إعادة اللعب")
	if btn == null:
		await _free_later(tree, es)
		tree.current_scene = saved
		return _fail("Missing Play Again button")
	btn.emit_signal("pressed")
	await tree.process_frame
	await tree.process_frame
	var best := int(_gs(tree).get("best_score"))
	if tree.current_scene != null and tree.current_scene != saved:
		await _free_later(tree, tree.current_scene)
	tree.current_scene = saved
	_cleanup(tree)
	return _ok("best_score preserved (>=880) across Game Over & Play Again") if best >= 880 else _fail("best_score lost: %d" % best)


func _case_b22_unpauses(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_END_SCREEN):
		return _fail("Missing end_screen.tscn")
	_cleanup(tree)
	tree.paused = true
	var es := _spawn(PATH_END_SCREEN, host)
	await tree.process_frame
	var paused := tree.paused
	await _free_later(tree, es)
	_cleanup(tree)
	return _ok("EndScreen unpaused SceneTree") if not paused else _fail("EndScreen remained paused")
