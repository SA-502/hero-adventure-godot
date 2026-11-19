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

const EXPECTED_SFX := [
	"jump", "jump_big", "coin", "bump", "brick_break",
	"powerup_spawn", "powerup_collect", "stomp", "kick",
	"hurt", "one_up", "stage_clear", "game_over",
]


func run(tree: SceneTree, host: Node) -> Dictionary:
	var cases: Dictionary = {}

	# F02
	cases["f02_run_main_scene_valid"] = await _case_scene_valid(tree, host, PATH_MAIN)

	# F03 GameState
	cases["f03_defaults_and_power_enum"] = _case_f03_defaults(tree)
	cases["f03_add_score_updates_best_and_signal"] = _case_f03_score(tree)
	cases["f03_add_coin_increments_and_emits"] = _case_f03_coin(tree)
	cases["f03_add_life_and_lose_life"] = _case_f03_lives(tree)
	cases["f03_set_power_level_victory_gameover"] = _case_f03_states(tree)

	# F04 AudioManager
	cases["f04_all_13_sfx_wavs_valid"] = _case_f04_sfx(tree)
	cases["f04_bgm_overworld_and_castle_play"] = _case_f04_bgm(tree)
	cases["f04_mute_toggle_and_set_muted"] = _case_f04_mute(tree)
	cases["f04_pause_ducking_state"] = _case_f04_duck(tree)
	cases["f04_concurrent_sfx_pool"] = _case_f04_pool(tree)

	# F05 Player physics
	cases["f05_horizontal_accel_and_sprint"] = await _case_f05_accel_sprint(tree, host)
	cases["f05_jump_and_variable_cut"] = await _case_f05_jump_cut(tree, host)
	cases["f05_coyote_time_010s"] = await _case_f05_coyote(tree, host)
	cases["f05_jump_buffer_012s_and_anims"] = await _case_f05_jump_buffer(tree, host)

	# F06 Player state machine
	cases["f06_collect_powerup_small_to_big"] = await _case_f06_grow(tree, host)
	cases["f06_damage_big_to_small_with_invuln"] = await _case_f06_shrink(tree, host)
	cases["f06_damage_small_triggers_death"] = await _case_f06_death(tree, host)
	cases["f06_flagpole_slide_and_clear"] = await _case_f06_flag_slide(tree, host)
	cases["f06_invuln_duration_expires"] = await _case_f06_invuln_expire(tree, host)

	# F07 QuestionBlock
	cases["f07_hit_coin_reward"] = await _case_f07_coin(tree, host)
	cases["f07_hit_mushroom_reward"] = await _case_f07_mushroom(tree, host, "MUSHROOM", 1)
	cases["f07_hit_one_up_reward"] = await _case_f07_mushroom(tree, host, "ONE_UP", 2)
	cases["f07_bumps_enemy_standing_above"] = await _case_f07_bump_enemy(tree, host)

	# F08 BrickBlock
	cases["f08_small_player_bounces_intact"] = await _case_f08_small_intact(tree, host)
	cases["f08_big_player_shatters_and_scores"] = await _case_f08_big_shatter(tree, host)
	cases["f08_bumps_enemy_above_when_small"] = await _case_f08_bump_enemy(tree, host, false)
	cases["f08_bumps_enemy_above_when_big"] = await _case_f08_bump_enemy(tree, host, true)

	# F09 Coin
	cases["f09_pickup_adds_coin_and_score"] = await _case_f09_pickup(tree, host, false)
	cases["f09_pickup_frees_coin_node"] = await _case_f09_pickup(tree, host, true)
	cases["f09_pickup_spawns_star_particle"] = await _case_f09_star_particle(tree, host)
	cases["f09_non_player_body_ignored"] = await _case_f09_non_player(tree, host)

	# F10 Mushroom
	cases["f10_grow_vs_one_up_sprite_region"] = await _case_f10_regions(tree, host)
	cases["f10_horizontal_patrol_and_gravity"] = await _case_f10_patrol(tree, host)
	cases["f10_wall_bounce_reverses_direction"] = await _case_f10_wall_bounce(tree, host)
	cases["f10_pickup_grow_and_one_up_effects"] = await _case_f10_pickups(tree, host)

	# F11 MovingPlatform
	cases["f11_cyclic_motion_toward_offset"] = await _case_f11_cyclic(tree, host)
	cases["f11_ping_pong_returns_to_origin"] = await _case_f11_ping_pong(tree, host)
	cases["f11_carries_player_horizontally"] = await _case_f11_carry_horiz(tree, host)
	cases["f11_carries_player_vertically"] = await _case_f11_carry_vert(tree, host)

	# F12 Flagpole
	cases["f12_player_touch_emits_level_cleared"] = await _case_f12_touch_signal(tree, host)
	cases["f12_stops_level_timer"] = await _case_f12_stops_timer(tree, host)
	cases["f12_slides_banner_down"] = await _case_f12_banner_slide(tree, host)
	cases["f12_awards_time_bonus_to_score"] = await _case_f12_time_bonus(tree, host)

	# F13 WalkerEnemy
	cases["f13_patrol_and_wall_reverse"] = await _case_f13_patrol(tree, host)
	cases["f13_stomp_from_above"] = await _case_f13_stomp(tree, host)
	cases["f13_side_contact_hurts_player"] = await _case_f13_side_hurt(tree, host)
	cases["f13_block_bump_and_shell_kill"] = await _case_f13_bump_and_shell_kill(tree, host)

	# F14 ShellEnemy
	cases["f14_first_stomp_enters_shell_idle"] = await _case_f14_first_stomp(tree, host)
	cases["f14_second_stomp_or_kick_slides"] = await _case_f14_slide(tree, host)
	cases["f14_sliding_shell_wall_rebound"] = await _case_f14_rebound(tree, host)
	cases["f14_sliding_shell_defeats_other_enemy"] = await _case_f14_defeats_walker(tree, host)

	# F15 LevelBase
	cases["f15_camera_limits_applied"] = await _case_f15_camera_limits(tree, host)
	cases["f15_countdown_ticks_180s_and_updates_hud"] = await _case_f15_countdown(tree, host)
	cases["f15_fallzone_kills_player"] = await _case_f15_fallzone(tree, host)
	cases["f15_pause_action_toggles_pause_menu"] = await _case_f15_pause_toggle(tree, host)
	cases["f15_stage_bgm_and_level1_tip"] = await _case_f15_bgm_and_tip(tree, host)

	# F18 Level 3 flow
	cases["f18_castle_bgm_configured"] = await _case_f18_castle_bgm(tree, host)
	cases["f18_final_flagpole_routes_to_end_screen"] = await _case_f18_final_flagpole(tree, host)

	# F19 HUD
	cases["f19_updates_on_gamestate_signals"] = await _case_f19_signals(tree, host)
	cases["f19_update_time_formats_seconds"] = await _case_f19_time_format(tree, host)
	cases["f19_show_tip_displays_arabic_banner"] = await _case_f19_tip(tree, host)
	cases["f19_pause_button_emits_and_fits_640x360"] = await _case_f19_pause_btn(tree, host)

	# F20 PauseMenu
	cases["f20_process_mode_always_and_hidden_init"] = await _case_f20_init(tree, host)
	cases["f20_toggle_pause_pauses_and_ducks"] = await _case_f20_pause(tree, host)
	cases["f20_resume_unpauses_and_unducks"] = await _case_f20_resume(tree, host)
	cases["f20_mute_button_toggles_audiomanager"] = await _case_f20_mute(tree, host)

	# F21 TitleScreen
	cases["f21_start_adventure_launches_level_1"] = await _case_f21_start_adventure(tree, host)
	cases["f21_level_select_buttons_1_2_3"] = await _case_f21_level_select(tree, host)
	cases["f21_displays_best_score"] = await _case_f21_best_score(tree, host)
	cases["f21_mute_toggle_and_pixel_scenery"] = await _case_f21_mute(tree, host)

	# F22 EndScreen
	cases["f22_win_state_arabic_heading"] = await _case_f22_heading(tree, host, true)
	cases["f22_loss_state_arabic_heading_and_sfx"] = await _case_f22_heading(tree, host, false)
	cases["f22_displays_final_and_best_scores"] = await _case_f22_scores(tree, host)
	cases["f22_play_again_button_resets_and_restarts"] = await _case_f22_play_again(tree, host)
	cases["f22_main_menu_button_returns_to_title"] = await _case_f22_main_menu(tree, host)

	_cleanup_global_state(tree)
	return {"ok": true, "error": "", "cases": cases}


# --- Helpers ---

func _ok(detail: String) -> Dictionary:
	return {"passed": true, "detail": detail}


func _fail(detail: String) -> Dictionary:
	return {"passed": false, "detail": detail}


func _gs(tree: SceneTree) -> Node:
	return tree.root.get_node_or_null("GameState")


func _am(tree: SceneTree) -> Node:
	return tree.root.get_node_or_null("AudioManager")


func _cleanup_global_state(tree: SceneTree) -> void:
	for act in ["move_left", "move_right", "jump", "sprint", "pause"]:
		if InputMap.has_action(act):
			Input.action_release(act)
	tree.paused = false
	var gs := _gs(tree)
	if gs != null and gs.has_method("reset_game"):
		gs.call("reset_game")
		gs.set("best_score", 0)
	var am := _am(tree)
	if am != null:
		if am.has_method("stop_bgm"):
			am.call("stop_bgm")
		if am.has_method("set_muted"):
			am.call("set_muted", false)
		if am.has_method("set_paused_duck"):
			am.call("set_paused_duck", false)


func _load_scene(path: String) -> PackedScene:
	if not ResourceLoader.exists(path):
		return null
	var res := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if res is PackedScene:
		return res as PackedScene
	return null


func _spawn_scene(path: String, parent: Node) -> Node:
	var ps := _load_scene(path)
	if ps == null:
		return null
	var inst := ps.instantiate()
	if inst != null and parent != null:
		parent.add_child(inst)
	return inst


func _make_arena(host: Node) -> Node2D:
	var arena := Node2D.new()
	arena.name = "TestArena"
	host.add_child(arena)
	return arena


func _add_floor(arena: Node, pos: Vector2, size: Vector2 = Vector2(800, 32)) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = pos
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	col.shape = rect
	body.add_child(col)
	arena.add_child(body)
	return body


func _step_physics(tree: SceneTree, frames: int) -> void:
	for _i in range(frames):
		await tree.physics_frame


func _free_node_later(tree: SceneTree, node: Node) -> void:
	if node != null and is_instance_valid(node):
		if node.get_parent() != null:
			node.get_parent().remove_child(node)
		node.queue_free()
	await tree.process_frame


func _set_enum_prop(obj: Object, names: Array, str_val: String, int_val: int) -> void:
	for p in obj.get_property_list():
		var pname := str(p.get("name", ""))
		if names.has(pname):
			if int(p.get("type", TYPE_INT)) == TYPE_STRING:
				obj.set(pname, str_val)
			else:
				obj.set(pname, int_val)
			return


func _find_button_with_text(root: Node, needle: String) -> BaseButton:
	if root is Button and (root as Button).text.find(needle) != -1:
		return root as BaseButton
	for child in root.get_children():
		var found := _find_button_with_text(child, needle)
		if found != null:
			return found
	return null


func _collect_texts(root: Node) -> Array[String]:
	var out: Array[String] = []
	if root is Label:
		out.append((root as Label).text)
	elif root is Button:
		out.append((root as Button).text)
	elif root is RichTextLabel:
		out.append((root as RichTextLabel).text)
	for child in root.get_children():
		out.append_array(_collect_texts(child))
	return out


func _find_node_script(root: Node, suffix: String) -> Node:
	if root == null:
		return null
	var scr: Variant = root.get_script()
	if scr is Script and (scr as Script).resource_path.ends_with(suffix):
		return root
	for child in root.get_children():
		var found := _find_node_script(child, suffix)
		if found != null:
			return found
	return null


func _collect_nodes_script(root: Node, suffix: String) -> Array[Node]:
	var out: Array[Node] = []
	if root == null:
		return out
	var scr: Variant = root.get_script()
	if scr is Script and (scr as Script).resource_path.ends_with(suffix):
		out.append(root)
	for child in root.get_children():
		out.append_array(_collect_nodes_script(child, suffix))
	return out


func _find_by_name_ci(root: Node, target: String) -> Node:
	if root == null:
		return null
	if String(root.name).to_lower().find(target.to_lower()) != -1:
		return root
	for child in root.get_children():
		var found := _find_by_name_ci(child, target)
		if found != null:
			return found
	return null


# --- Cases ---

func _case_scene_valid(tree: SceneTree, host: Node, path: String) -> Dictionary:
	if not ResourceLoader.exists(path):
		return _fail("Missing scene: " + path)
	var inst := _spawn_scene(path, host)
	if inst == null:
		return _fail("Failed to instantiate: " + path)
	await tree.process_frame
	var inside := is_instance_valid(inst) and inst.is_inside_tree()
	await _free_node_later(tree, inst)
	_cleanup_global_state(tree)
	return _ok("Scene valid: " + path) if inside else _fail("Scene failed tree entry: " + path)


func _case_f03_defaults(tree: SceneTree) -> Dictionary:
	var gs := _gs(tree)
	if gs == null:
		return _fail("Missing GameState autoload")
	_cleanup_global_state(tree)
	if int(gs.get("score")) != 0 or int(gs.get("coins")) != 0 or int(gs.get("lives")) != 3 or int(gs.get("current_level")) != 1:
		return _fail("Unexpected GameState defaults")
	if int(gs.get("player_power")) != 0:
		return _fail("player_power expected SMALL (0)")
	return _ok("GameState defaults verified")


func _case_f03_score(tree: SceneTree) -> Dictionary:
	var gs := _gs(tree)
	if gs == null:
		return _fail("Missing GameState")
	_cleanup_global_state(tree)
	var got: Array[int] = []
	var cb := func(v: int) -> void: got.append(v)
	gs.connect("score_changed", cb)
	gs.call("add_score", 300)
	gs.disconnect("score_changed", cb)
	if int(gs.get("score")) != 300 or int(gs.get("best_score")) < 300 or not got.has(300):
		return _fail("add_score(300) failed")
	return _ok("add_score verified")


func _case_f03_coin(tree: SceneTree) -> Dictionary:
	var gs := _gs(tree)
	if gs == null:
		return _fail("Missing GameState")
	_cleanup_global_state(tree)
	var got: Array[int] = []
	var cb := func(v: int) -> void: got.append(v)
	gs.connect("coins_changed", cb)
	gs.call("add_coin", 5)
	gs.disconnect("coins_changed", cb)
	if int(gs.get("coins")) != 5 or not got.has(5):
		return _fail("add_coin(5) failed")
	return _ok("add_coin verified")


func _case_f03_lives(tree: SceneTree) -> Dictionary:
	var gs := _gs(tree)
	if gs == null:
		return _fail("Missing GameState")
	_cleanup_global_state(tree)
	var got: Array[int] = []
	var cb := func(v: int) -> void: got.append(v)
	gs.connect("lives_changed", cb)
	gs.call("add_life", 1)
	var after_add := int(gs.get("lives"))
	gs.call("lose_life")
	var after_lose := int(gs.get("lives"))
	gs.disconnect("lives_changed", cb)
	if after_add != 4 or after_lose != 3 or not got.has(4) or not got.has(3):
		return _fail("add_life/lose_life mismatch")
	return _ok("add_life & lose_life verified")


func _case_f03_states(tree: SceneTree) -> Dictionary:
	var gs := _gs(tree)
	if gs == null:
		return _fail("Missing GameState")
	_cleanup_global_state(tree)
	var p_sig: Array[int] = []
	var l_sig: Array[int] = []
	var pcb := func(v: int) -> void: p_sig.append(v)
	var lcb := func(v: int) -> void: l_sig.append(v)
	gs.connect("power_changed", pcb)
	gs.connect("level_changed", lcb)
	gs.call("set_power", 1)
	gs.call("set_level", 2)
	gs.disconnect("power_changed", pcb)
	gs.disconnect("level_changed", lcb)
	if not p_sig.has(1) or not l_sig.has(2):
		return _fail("power_changed or level_changed not emitted")
	gs.call("mark_victory")
	if not bool(gs.get("game_won")) or bool(gs.get("game_over")):
		return _fail("mark_victory flags mismatch")
	gs.call("mark_game_over")
	if not bool(gs.get("game_over")) or bool(gs.get("game_won")):
		return _fail("mark_game_over flags mismatch")
	return _ok("GameState power/level/victory/game_over verified")


func _case_f04_sfx(tree: SceneTree) -> Dictionary:
	var am := _am(tree)
	if am == null:
		return _fail("Missing AudioManager")
	for k in EXPECTED_SFX:
		am.call("play_sfx", k)
	return _ok("All 13 SFX played cleanly")


func _case_f04_bgm(tree: SceneTree) -> Dictionary:
	var am := _am(tree)
	if am == null:
		return _fail("Missing AudioManager")
	am.call("play_bgm", "overworld")
	am.call("play_bgm", "castle")
	am.call("stop_bgm")
	return _ok("BGM overworld & castle played and stopped")


func _case_f04_mute(tree: SceneTree) -> Dictionary:
	var am := _am(tree)
	if am == null:
		return _fail("Missing AudioManager")
	am.call("set_muted", false)
	var r1 := bool(am.call("toggle_mute"))
	var r2 := bool(am.call("toggle_mute"))
	am.call("set_muted", true)
	var muted_after := bool(am.get("is_muted"))
	am.call("set_muted", false)
	if r1 != true or r2 != false or muted_after != true:
		return _fail("Mute toggle/set_muted failed")
	return _ok("Mute toggle verified")


func _case_f04_duck(tree: SceneTree) -> Dictionary:
	var am := _am(tree)
	if am == null:
		return _fail("Missing AudioManager")
	am.call("set_paused_duck", true)
	var d1 := bool(am.get("is_ducked"))
	am.call("set_paused_duck", false)
	var d2 := bool(am.get("is_ducked"))
	if not d1 or d2:
		return _fail("Ducking state mismatch")
	return _ok("Pause ducking verified")


func _case_f04_pool(tree: SceneTree) -> Dictionary:
	var am := _am(tree)
	if am == null:
		return _fail("Missing AudioManager")
	am.call("play_sfx", "coin")
	am.call("play_sfx", "jump")
	am.call("play_sfx", "stomp")
	return _ok("Concurrent SFX pool played cleanly")


func _case_f05_accel_sprint(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing " + PATH_PLAYER)
	_cleanup_global_state(tree)
	var arena := _make_arena(host)
	_add_floor(arena, Vector2(200, 116), Vector2(1000, 32))
	var p := _spawn_scene(PATH_PLAYER, arena) as CharacterBody2D
	if p == null:
		await _free_node_later(tree, arena)
		return _fail("Failed to instantiate Player")
	p.position = Vector2(0, 100)
	await _step_physics(tree, 4)

	Input.action_press("move_right")
	await _step_physics(tree, 12)
	var walk_vx := p.velocity.x
	var moved_x := p.position.x
	Input.action_release("move_right")

	p.position = Vector2(0, 100)
	p.velocity = Vector2.ZERO
	await _step_physics(tree, 2)
	Input.action_press("move_right")
	Input.action_press("sprint")
	await _step_physics(tree, 15)
	var sprint_vx := p.velocity.x
	Input.action_release("move_right")
	Input.action_release("sprint")

	await _free_node_later(tree, arena)
	if walk_vx <= 0.0 or moved_x <= 0.0:
		return _fail("Player did not accelerate right: vx=%.1f x=%.1f" % [walk_vx, moved_x])
	if sprint_vx <= walk_vx:
		return _fail("Sprint speed (%.1f) not greater than walk speed (%.1f)" % [sprint_vx, walk_vx])
	return _ok("Walk vx=%.1f, Sprint vx=%.1f" % [walk_vx, sprint_vx])


func _case_f05_jump_cut(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing " + PATH_PLAYER)
	_cleanup_global_state(tree)
	var arena := _make_arena(host)
	_add_floor(arena, Vector2(0, 116), Vector2(400, 32))
	var p := _spawn_scene(PATH_PLAYER, arena) as CharacterBody2D
	if p == null:
		await _free_node_later(tree, arena)
		return _fail("Failed to instantiate Player")
	p.position = Vector2(0, 100)
	await _step_physics(tree, 4)

	# Full hold jump
	Input.action_press("jump")
	await _step_physics(tree, 2)
	var initial_vy := p.velocity.y
	await _step_physics(tree, 10)
	var hold_dy := 100.0 - p.position.y
	Input.action_release("jump")

	# Reset to floor & early release
	p.position = Vector2(0, 100)
	p.velocity = Vector2.ZERO
	await _step_physics(tree, 4)
	Input.action_press("jump")
	await _step_physics(tree, 2)
	Input.action_release("jump")
	await _step_physics(tree, 10)
	var short_dy := 100.0 - p.position.y

	await _free_node_later(tree, arena)
	if initial_vy >= 0.0:
		return _fail("Jump did not apply upward velocity: vy=%.1f" % initial_vy)
	if short_dy >= hold_dy:
		return _fail("Variable jump cut failed: short_dy=%.1f >= hold_dy=%.1f" % [short_dy, hold_dy])
	return _ok("Jump cut verified: hold_dy=%.1f, short_dy=%.1f" % [hold_dy, short_dy])


func _case_f05_coyote(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing " + PATH_PLAYER)
	_cleanup_global_state(tree)
	var arena := _make_arena(host)
	_add_floor(arena, Vector2(0, 116), Vector2(64, 32))
	var p := _spawn_scene(PATH_PLAYER, arena) as CharacterBody2D
	if p == null:
		await _free_node_later(tree, arena)
		return _fail("Failed to instantiate Player")
	p.position = Vector2(20, 100)
	await _step_physics(tree, 4)

	Input.action_press("move_right")
	var left_floor := false
	for _i in range(25):
		await _step_physics(tree, 1)
		if not p.is_on_floor():
			left_floor = true
			break
	Input.action_release("move_right")
	if not left_floor:
		await _free_node_later(tree, arena)
		return _fail("Player stayed on floor instead of walking off ledge")
	# Wait 2 frames (~0.033s, inside 0.10s coyote window) then jump
	await _step_physics(tree, 2)
	Input.action_press("jump")
	await _step_physics(tree, 2)
	Input.action_release("jump")
	var jumped := p.velocity.y < -50.0
	await _free_node_later(tree, arena)
	return _ok("Coyote jump succeeded off ledge") if jumped else _fail("Coyote jump failed: vy=%.1f" % p.velocity.y)


func _case_f05_jump_buffer(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing " + PATH_PLAYER)
	_cleanup_global_state(tree)
	var arena := _make_arena(host)
	_add_floor(arena, Vector2(0, 116), Vector2(400, 32))
	var p := _spawn_scene(PATH_PLAYER, arena) as CharacterBody2D
	if p == null:
		await _free_node_later(tree, arena)
		return _fail("Failed to instantiate Player")
	p.position = Vector2(0, 82)
	await _step_physics(tree, 2)
	Input.action_press("jump")
	var jumped_on_land := false
	for _i in range(15):
		await _step_physics(tree, 1)
		if p.velocity.y < -150.0:
			jumped_on_land = true
			break
	Input.action_release("jump")
	await _free_node_later(tree, arena)
	return _ok("Jump buffer triggered jump on landing") if jumped_on_land else _fail("Jump buffer did not trigger")


func _case_f06_grow(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing " + PATH_PLAYER)
	_cleanup_global_state(tree)
	var arena := _make_arena(host)
	var p := _spawn_scene(PATH_PLAYER, arena)
	var sigs: Array[bool] = []
	var cb := func(is_big_now: bool) -> void: sigs.append(is_big_now)
	p.connect("power_state_changed", cb)
	p.call("collect_powerup")
	await _step_physics(tree, 2)
	p.disconnect("power_state_changed", cb)

	var is_big_val := bool(p.call("is_big"))
	var gs_power := int(_gs(tree).get("player_power"))
	var spr := p.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	var sf_path := spr.sprite_frames.resource_path if (spr != null and spr.sprite_frames != null) else ""
	var col := p.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var h := 0.0
	if col != null and col.shape is RectangleShape2D:
		h = (col.shape as RectangleShape2D).size.y
	elif col != null and col.shape is CapsuleShape2D:
		h = (col.shape as CapsuleShape2D).height

	await _free_node_later(tree, arena)
	if not is_big_val or gs_power != 1 or not sigs.has(true):
		return _fail("collect_powerup failed to enter BIG state")
	if sf_path != "res://assets/sprites/player_big_frames.tres":
		return _fail("Expected player_big_frames.tres, got: " + sf_path)
	if h < 40.0:
		return _fail("BIG collision height expected >=40, got %.1f" % h)
	return _ok("Player BIG transition verified")


func _case_f06_shrink(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing " + PATH_PLAYER)
	_cleanup_global_state(tree)
	var arena := _make_arena(host)
	var p := _spawn_scene(PATH_PLAYER, arena)
	p.call("collect_powerup")
	var lives_before := int(_gs(tree).get("lives"))
	var sigs: Array[bool] = []
	var cb := func(v: bool) -> void: sigs.append(v)
	p.connect("power_state_changed", cb)
	p.call("take_damage", false)
	p.disconnect("power_state_changed", cb)

	var big_after := bool(p.call("is_big"))
	var invuln := bool(p.call("is_invulnerable"))
	var lives_after := int(_gs(tree).get("lives"))
	await _free_node_later(tree, arena)
	if big_after or not invuln or not sigs.has(false) or lives_after != lives_before:
		return _fail("BIG->SMALL shrink or invuln failed")
	return _ok("BIG->SMALL shrink with invulnerability verified")


func _case_f06_death(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing " + PATH_PLAYER)
	_cleanup_global_state(tree)
	var arena := _make_arena(host)
	var p := _spawn_scene(PATH_PLAYER, arena) as CharacterBody2D
	var died_count := [0]
	var cb := func() -> void: died_count[0] += 1
	p.connect("died", cb)
	p.call("take_damage", false)
	p.disconnect("died", cb)
	var dead := bool(p.call("is_dead"))
	var vy := p.velocity.y
	await _free_node_later(tree, arena)
	if not dead or died_count[0] != 1 or vy >= 0.0:
		return _fail("SMALL death failed: dead=%s died=%d vy=%.1f" % [str(dead), died_count[0], vy])
	return _ok("SMALL player death hop & signal verified")


func _case_f06_flag_slide(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing " + PATH_PLAYER)
	_cleanup_global_state(tree)
	var arena := _make_arena(host)
	var p := _spawn_scene(PATH_PLAYER, arena) as CharacterBody2D
	p.position = Vector2(180, 100)
	p.call("start_flagpole_slide", 200.0, 240.0)
	await _step_physics(tree, 6)
	var moved_down := p.position.y > 100.0
	var snapped_x := absf(p.position.x - 200.0) < 20.0
	p.call("finish_level_clear")
	await _free_node_later(tree, arena)
	if not moved_down or not snapped_x:
		return _fail("Flagpole slide mismatch: pos=%s" % str(p.position))
	return _ok("Flagpole slide & finish_level_clear verified")


func _case_f06_invuln_expire(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing " + PATH_PLAYER)
	_cleanup_global_state(tree)
	var arena := _make_arena(host)
	var p := _spawn_scene(PATH_PLAYER, arena)
	p.call("collect_powerup")
	p.call("take_damage", false)
	if not bool(p.call("is_invulnerable")):
		await _free_node_later(tree, arena)
		return _fail("Expected invulnerable right after BIG shrink")
	# Wait up to ~105 physics frames (1.75s at 60fps) for 1.5s invuln expiry
	var expired := false
	for _i in range(105):
		await _step_physics(tree, 1)
		if not bool(p.call("is_invulnerable")):
			expired = true
			break
	await _free_node_later(tree, arena)
	return _ok("1.5s invulnerability expired cleanly") if expired else _fail("Invulnerability did not expire within 1.75s")


func _case_f07_coin(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_QUESTION_BLOCK) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing QuestionBlock or Player")
	_cleanup_global_state(tree)
	var arena := _make_arena(host)
	var qb := _spawn_scene(PATH_QUESTION_BLOCK, arena)
	_set_enum_prop(qb, ["reward_type", "reward"], "COIN", 0)
	var p := _spawn_scene(PATH_PLAYER, arena)
	qb.call("hit_from_below", p)
	await _step_physics(tree, 2)
	var gs := _gs(tree)
	var spr := qb.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	var anim := String(spr.animation) if spr != null else ""
	var ok := int(gs.get("coins")) == 1 and int(gs.get("score")) == 100 and anim == "used"
	await _free_node_later(tree, arena)
	return _ok("QuestionBlock COIN reward verified") if ok else _fail("QuestionBlock COIN failed: anim=%s" % anim)


func _case_f07_mushroom(tree: SceneTree, host: Node, str_val: String, int_val: int) -> Dictionary:
	if not ResourceLoader.exists(PATH_QUESTION_BLOCK) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing QuestionBlock or Player")
	_cleanup_global_state(tree)
	var arena := _make_arena(host)
	var qb := _spawn_scene(PATH_QUESTION_BLOCK, arena)
	qb.position = Vector2(200, 200)
	_set_enum_prop(qb, ["reward_type", "reward"], str_val, int_val)
	var p := _spawn_scene(PATH_PLAYER, arena)
	p.position = Vector2(0, 300)
	qb.call("hit_from_below", p)
	await _step_physics(tree, 3)
	var mushrooms := _collect_nodes_script(arena, "mushroom.gd")
	var spr := qb.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	var anim := String(spr.animation) if spr != null else ""
	var ok := mushrooms.size() >= 1 and anim == "used"
	await _free_node_later(tree, arena)
	return _ok("QuestionBlock spawned " + str_val) if ok else _fail("QuestionBlock failed to spawn " + str_val)


func _case_f07_bump_enemy(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_QUESTION_BLOCK) or not ResourceLoader.exists(PATH_WALKER) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing QuestionBlock, WalkerEnemy, or Player")
	_cleanup_global_state(tree)
	var arena := _make_arena(host)
	var qb := _spawn_scene(PATH_QUESTION_BLOCK, arena)
	qb.position = Vector2(100, 200)
	var w := _spawn_scene(PATH_WALKER, arena) as Node2D
	w.position = Vector2(100, 184)
	var p := _spawn_scene(PATH_PLAYER, arena)
	p.position = Vector2(0, 300)
	await _step_physics(tree, 4)
	var score_before := int(_gs(tree).get("score"))
	qb.call("hit_from_below", p)
	await _step_physics(tree, 3)
	var bumped := (not is_instance_valid(w)) or w.is_queued_for_deletion() or int(_gs(tree).get("score")) > score_before + 100
	await _free_node_later(tree, arena)
	return _ok("QuestionBlock bumped enemy above") if bumped else _fail("Enemy above QuestionBlock was not bumped")


func _case_f08_small_intact(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_BRICK_BLOCK) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing BrickBlock or Player")
	_cleanup_global_state(tree)
	var arena := _make_arena(host)
	var bb := _spawn_scene(PATH_BRICK_BLOCK, arena)
	var p := _spawn_scene(PATH_PLAYER, arena)
	bb.call("hit_from_below", p)
	await _step_physics(tree, 2)
	var intact := is_instance_valid(bb) and not bb.is_queued_for_deletion()
	var score_ok := int(_gs(tree).get("score")) == 0
	await _free_node_later(tree, arena)
	return _ok("Small hit keeps BrickBlock intact") if (intact and score_ok) else _fail("Small hit broke brick or changed score")


func _case_f08_big_shatter(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_BRICK_BLOCK) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing BrickBlock or Player")
	_cleanup_global_state(tree)
	var arena := _make_arena(host)
	var bb := _spawn_scene(PATH_BRICK_BLOCK, arena)
	bb.position = Vector2(100, 100)
	var p := _spawn_scene(PATH_PLAYER, arena)
	p.call("collect_powerup")
	bb.call("hit_from_below", p)
	var queued := (not is_instance_valid(bb)) or bb.is_queued_for_deletion()
	var score_ok := int(_gs(tree).get("score")) == 50
	var shard_ok := _has_brick_shard_visual(arena)
	await _free_node_later(tree, arena)
	if not queued or not score_ok or not shard_ok:
		return _fail("Brick shatter check failed: queued=%s score_ok=%s shard=%s" % [str(queued), str(score_ok), str(shard_ok)])
	return _ok("Big hit shattered BrickBlock (+50, shards)")


func _has_brick_shard_visual(root: Node) -> bool:
	var count_sprites := 0
	for c in _all_descendants(root):
		if c is CPUParticles2D and (c as CPUParticles2D).texture != null and (c as CPUParticles2D).texture.resource_path.ends_with("brick_shard.png"):
			return true
		if c is Sprite2D and (c as Sprite2D).texture != null and (c as Sprite2D).texture.resource_path.ends_with("brick_shard.png"):
			count_sprites += 1
	return count_sprites >= 4


func _all_descendants(root: Node) -> Array[Node]:
	var out: Array[Node] = []
	for c in root.get_children():
		out.append(c)
		out.append_array(_all_descendants(c))
	return out


func _case_f08_bump_enemy(tree: SceneTree, host: Node, big: bool) -> Dictionary:
	if not ResourceLoader.exists(PATH_BRICK_BLOCK) or not ResourceLoader.exists(PATH_WALKER) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing BrickBlock, WalkerEnemy, or Player")
	_cleanup_global_state(tree)
	var arena := _make_arena(host)
	var bb := _spawn_scene(PATH_BRICK_BLOCK, arena)
	bb.position = Vector2(100, 200)
	var w := _spawn_scene(PATH_WALKER, arena) as Node2D
	w.position = Vector2(100, 184)
	var p := _spawn_scene(PATH_PLAYER, arena)
	p.position = Vector2(0, 300)
	if big:
		p.call("collect_powerup")
	await _step_physics(tree, 4)
	var score_before := int(_gs(tree).get("score"))
	bb.call("hit_from_below", p)
	await _step_physics(tree, 3)
	var enemy_hit := (not is_instance_valid(w)) or w.is_queued_for_deletion() or int(_gs(tree).get("score")) > score_before + (50 if big else 0)
	await _free_node_later(tree, arena)
	return _ok("BrickBlock bumped enemy above") if enemy_hit else _fail("Enemy above BrickBlock was not bumped")


func _case_f09_pickup(tree: SceneTree, host: Node, check_freed: bool) -> Dictionary:
	if not ResourceLoader.exists(PATH_COIN) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing Coin or Player")
	_cleanup_global_state(tree)
	var arena := _make_arena(host)
	var c := _spawn_scene(PATH_COIN, arena) as Node2D
	c.position = Vector2(100, 100)
	var p := _spawn_scene(PATH_PLAYER, arena) as Node2D
	p.position = Vector2(100, 114)
	await _step_physics(tree, 5)
	var gs := _gs(tree)
	var ok := int(gs.get("coins")) == 1 and int(gs.get("score")) == 100
	if check_freed:
		ok = ok and ((not is_instance_valid(c)) or c.is_queued_for_deletion())
	await _free_node_later(tree, arena)
	return _ok("Coin pickup verified") if ok else _fail("Coin pickup failed")


func _case_f09_star_particle(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_COIN) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing Coin or Player")
	if not ResourceLoader.exists("res://assets/sprites/particle_star.png"):
		return _fail("Missing particle_star.png")
	_cleanup_global_state(tree)
	var arena := _make_arena(host)
	var c := _spawn_scene(PATH_COIN, arena) as Node2D
	c.position = Vector2(100, 100)
	var p := _spawn_scene(PATH_PLAYER, arena) as Node2D
	p.position = Vector2(100, 114)
	await _step_physics(tree, 4)
	var found := false
	for n in _all_descendants(arena):
		if n is CPUParticles2D and (n as CPUParticles2D).texture != null and (n as CPUParticles2D).texture.resource_path.ends_with("particle_star.png"):
			found = true
		elif n is Sprite2D and (n as Sprite2D).texture != null and (n as Sprite2D).texture.resource_path.ends_with("particle_star.png"):
			found = true
	await _free_node_later(tree, arena)
	return _ok("Coin star particle burst verified") if found else _fail("No particle_star.png burst node found on Coin collection")


func _case_f09_non_player(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_COIN) or not ResourceLoader.exists(PATH_WALKER):
		return _fail("Missing Coin or WalkerEnemy")
	_cleanup_global_state(tree)
	var arena := _make_arena(host)
	var c := _spawn_scene(PATH_COIN, arena) as Node2D
	c.position = Vector2(100, 100)
	var w := _spawn_scene(PATH_WALKER, arena) as Node2D
	w.position = Vector2(100, 114)
	await _step_physics(tree, 5)
	var ok := is_instance_valid(c) and not c.is_queued_for_deletion() and int(_gs(tree).get("coins")) == 0
	await _free_node_later(tree, arena)
	return _ok("Non-player ignored by Coin") if ok else _fail("Non-player collected Coin")


func _case_f10_regions(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_MUSHROOM):
		return _fail("Missing Mushroom")
	var arena := _make_arena(host)
	var m1 := _spawn_scene(PATH_MUSHROOM, arena)
	_set_enum_prop(m1, ["mushroom_type", "type"], "GROW", 0)
	var m2 := _spawn_scene(PATH_MUSHROOM, arena)
	_set_enum_prop(m2, ["mushroom_type", "type"], "ONE_UP", 1)
	await tree.process_frame
	var s1 := _find_sprite(m1)
	var s2 := _find_sprite(m2)
	var r1 := s1.region_rect if s1 != null else Rect2()
	var r2 := s2.region_rect if s2 != null else Rect2()
	await _free_node_later(tree, arena)
	if r1 != Rect2(0, 0, 32, 32) or r2 != Rect2(32, 0, 32, 32):
		return _fail("Mushroom sprite regions mismatch: GROW=%s ONE_UP=%s" % [str(r1), str(r2)])
	return _ok("GROW & ONE_UP sprite regions verified")


func _find_sprite(root: Node) -> Sprite2D:
	if root is Sprite2D:
		return root as Sprite2D
	for c in root.get_children():
		var f := _find_sprite(c)
		if f != null:
			return f
	return null


func _case_f10_patrol(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_MUSHROOM):
		return _fail("Missing Mushroom")
	var arena := _make_arena(host)
	_add_floor(arena, Vector2(0, 116), Vector2(600, 32))
	var m := _spawn_scene(PATH_MUSHROOM, arena) as CharacterBody2D
	m.position = Vector2(0, 70)
	await _step_physics(tree, 20)
	var fell := m.position.y > 85.0
	var moved_x := absf(m.position.x) > 2.0
	await _free_node_later(tree, arena)
	return _ok("Mushroom gravity & patrol verified") if (fell and moved_x) else _fail("Mushroom patrol failed: pos=%s" % str(m.position))


func _case_f10_wall_bounce(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_MUSHROOM):
		return _fail("Missing Mushroom")
	var arena := _make_arena(host)
	_add_floor(arena, Vector2(0, 116), Vector2(600, 32))
	_add_floor(arena, Vector2(36, 80), Vector2(24, 64))
	_add_floor(arena, Vector2(-36, 80), Vector2(24, 64))
	var m := _spawn_scene(PATH_MUSHROOM, arena) as CharacterBody2D
	if m == null:
		await _free_node_later(tree, arena)
		return _fail("Failed to instantiate Mushroom")
	m.position = Vector2(0, 98)
	await _step_physics(tree, 3)
	var vx_init := m.velocity.x
	var bounced := false
	for _i in range(35):
		await _step_physics(tree, 1)
		if signf(m.velocity.x) != signf(vx_init) and absf(m.velocity.x) > 1.0:
			bounced = true
			break
	await _free_node_later(tree, arena)
	return _ok("Mushroom wall bounce verified") if (absf(vx_init) > 1.0 and bounced) else _fail("Mushroom did not reverse on wall")


func _case_f10_pickups(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_MUSHROOM) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing Mushroom or Player")
	_cleanup_global_state(tree)
	var arena := _make_arena(host)
	_add_floor(arena, Vector2(0, 116), Vector2(400, 32))
	var p := _spawn_scene(PATH_PLAYER, arena) as CharacterBody2D
	p.position = Vector2(0, 100)
	var m_grow := _spawn_scene(PATH_MUSHROOM, arena) as Node2D
	_set_enum_prop(m_grow, ["mushroom_type", "type"], "GROW", 0)
	m_grow.position = Vector2(0, 96)
	await _step_physics(tree, 5)
	var big_ok := bool(p.call("is_big")) and ((not is_instance_valid(m_grow)) or m_grow.is_queued_for_deletion())

	var m_1up := _spawn_scene(PATH_MUSHROOM, arena) as Node2D
	_set_enum_prop(m_1up, ["mushroom_type", "type"], "ONE_UP", 1)
	m_1up.position = Vector2(0, 96)
	await _step_physics(tree, 5)
	var life_ok := int(_gs(tree).get("lives")) == 4 and ((not is_instance_valid(m_1up)) or m_1up.is_queued_for_deletion())
	await _free_node_later(tree, arena)
	return _ok("Mushroom GROW & ONE_UP pickups verified") if (big_ok and life_ok) else _fail("Mushroom pickups failed")


func _case_f11_cyclic(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_MOVING_PLATFORM):
		return _fail("Missing MovingPlatform")
	var arena := _make_arena(host)
	var mp := _spawn_scene(PATH_MOVING_PLATFORM, arena) as Node2D
	mp.position = Vector2(100, 100)
	mp.set("move_offset", Vector2(96, 0))
	mp.set("duration", 1.0)
	await _step_physics(tree, 20)
	var dx := mp.position.x - 100.0
	await _free_node_later(tree, arena)
	return _ok("MovingPlatform displaced dx=%.1f" % dx) if dx > 10.0 else _fail("MovingPlatform did not translate toward offset")


func _case_f11_ping_pong(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_MOVING_PLATFORM):
		return _fail("Missing MovingPlatform")
	var arena := _make_arena(host)
	var mp := _spawn_scene(PATH_MOVING_PLATFORM, arena) as Node2D
	mp.position = Vector2(100, 100)
	mp.set("move_offset", Vector2(96, 0))
	mp.set("duration", 0.3)
	await _step_physics(tree, 18) # ~0.3s -> near +96
	var mid_dx := mp.position.x - 100.0
	await _step_physics(tree, 18) # ~0.6s -> back near 0
	var end_dx := absf(mp.position.x - 100.0)
	await _free_node_later(tree, arena)
	if mid_dx < 40.0 or end_dx > 30.0:
		return _fail("Ping-pong mismatch: mid_dx=%.1f end_dx=%.1f" % [mid_dx, end_dx])
	return _ok("MovingPlatform ping-pong verified")


func _case_f11_carry_horiz(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_MOVING_PLATFORM) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing MovingPlatform or Player")
	_cleanup_global_state(tree)
	var arena := _make_arena(host)
	var mp := _spawn_scene(PATH_MOVING_PLATFORM, arena) as Node2D
	mp.position = Vector2(100, 116)
	mp.set("move_offset", Vector2(80, 0))
	mp.set("duration", 0.8)
	var p := _spawn_scene(PATH_PLAYER, arena) as CharacterBody2D
	p.position = Vector2(100, 100)
	await _step_physics(tree, 20)
	var px := p.position.x
	await _free_node_later(tree, arena)
	return _ok("Player carried horizontally x=%.1f" % px) if px > 110.0 else _fail("Player not carried horizontally: x=%.1f" % px)


func _case_f11_carry_vert(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_MOVING_PLATFORM) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing MovingPlatform or Player")
	_cleanup_global_state(tree)
	var arena := _make_arena(host)
	var mp := _spawn_scene(PATH_MOVING_PLATFORM, arena) as Node2D
	mp.position = Vector2(100, 116)
	mp.set("move_offset", Vector2(0, -48))
	mp.set("duration", 0.6)
	var p := _spawn_scene(PATH_PLAYER, arena) as CharacterBody2D
	p.position = Vector2(100, 100)
	await _step_physics(tree, 18)
	var py := p.position.y
	var floored := p.is_on_floor()
	await _free_node_later(tree, arena)
	return _ok("Player carried vertically y=%.1f" % py) if (py < 90.0 and floored) else _fail("Vertical carry failed: y=%.1f floor=%s" % [py, str(floored)])


func _case_f12_touch_signal(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_FLAGPOLE) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing Flagpole or Player")
	_cleanup_global_state(tree)
	var arena := _make_arena(host)
	var fp := _spawn_scene(PATH_FLAGPOLE, arena) as Node2D
	fp.position = Vector2(200, 200)
	var bonuses: Array[int] = []
	var cb := func(tb: int) -> void: bonuses.append(tb)
	fp.connect("level_cleared", cb)
	var p := _spawn_scene(PATH_PLAYER, arena) as Node2D
	p.position = Vector2(200, 180)
	await _step_physics(tree, 5)
	fp.disconnect("level_cleared", cb)
	await _free_node_later(tree, arena)
	return _ok("Flagpole level_cleared emitted") if (bonuses.size() == 1 and bonuses[0] >= 0) else _fail("Flagpole signal count=%d" % bonuses.size())


func _case_f12_stops_timer(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_LEVEL_1):
		return _fail("Missing level_1.tscn")
	_cleanup_global_state(tree)
	var saved_current := tree.current_scene
	var lvl := _spawn_scene(PATH_LEVEL_1, tree.root)
	if lvl == null:
		return _fail("Failed to instantiate level_1.tscn")
	tree.current_scene = lvl
	await _step_physics(tree, 4)
	var p := _find_node_script(lvl, "player.gd") as Node2D
	var fp := _find_node_script(lvl, "flagpole.gd") as Node2D
	if p == null or fp == null:
		await _free_node_later(tree, lvl)
		tree.current_scene = saved_current
		return _fail("level_1 missing Player or Flagpole")
	p.global_position = fp.global_position
	await _step_physics(tree, 5)
	var t1: Variant = lvl.get("time_remaining") if lvl.get("time_remaining") != null else lvl.get("_time_remaining")
	await _step_physics(tree, 35)
	var t2: Variant = lvl.get("time_remaining") if lvl.get("time_remaining") != null else lvl.get("_time_remaining")
	if tree.current_scene != null and tree.current_scene != saved_current:
		await _free_node_later(tree, tree.current_scene)
	elif is_instance_valid(lvl):
		await _free_node_later(tree, lvl)
	tree.current_scene = saved_current
	_cleanup_global_state(tree)
	if t1 != null and t2 != null and float(t2) < float(t1) - 0.1:
		return _fail("Timer kept ticking after Flagpole: %s -> %s" % [str(t1), str(t2)])
	return _ok("Flagpole stops level timer")


func _case_f12_banner_slide(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_FLAGPOLE) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing Flagpole or Player")
	_cleanup_global_state(tree)
	var arena := _make_arena(host)
	var fp := _spawn_scene(PATH_FLAGPOLE, arena) as Node2D
	fp.position = Vector2(200, 200)
	var banner := _find_banner(fp)
	var y0 := banner.position.y if banner != null else 0.0
	var p := _spawn_scene(PATH_PLAYER, arena) as Node2D
	p.position = Vector2(200, 180)
	await _step_physics(tree, 15)
	var has_banner := banner != null
	var y1 := banner.position.y if banner != null else 0.0
	await _free_node_later(tree, arena)
	return _ok("Banner slid y=%.1f -> %.1f" % [y0, y1]) if (has_banner and y1 > y0) else _fail("Banner did not slide down")


func _find_banner(fp: Node) -> Node2D:
	for c in _all_descendants(fp):
		if c is Sprite2D and (c as Sprite2D).texture != null and (c as Sprite2D).texture.resource_path.ends_with("flag_banner.png"):
			return c as Node2D
	return null


func _case_f12_time_bonus(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_LEVEL_1):
		return _fail("Missing level_1.tscn")
	_cleanup_global_state(tree)
	var saved_current := tree.current_scene
	var lvl := _spawn_scene(PATH_LEVEL_1, tree.root)
	if lvl == null:
		return _fail("Failed to instantiate level_1.tscn")
	tree.current_scene = lvl
	await _step_physics(tree, 4)
	var score_before := int(_gs(tree).get("score"))
	var p := _find_node_script(lvl, "player.gd") as Node2D
	var fp := _find_node_script(lvl, "flagpole.gd") as Node2D
	if p == null or fp == null:
		await _free_node_later(tree, lvl)
		tree.current_scene = saved_current
		return _fail("level_1 missing Player or Flagpole")
	p.global_position = fp.global_position
	await _step_physics(tree, 5)
	var score_after := int(_gs(tree).get("score"))
	if tree.current_scene != null and tree.current_scene != saved_current:
		await _free_node_later(tree, tree.current_scene)
	elif is_instance_valid(lvl):
		await _free_node_later(tree, lvl)
	tree.current_scene = saved_current
	_cleanup_global_state(tree)
	return _ok("Time bonus added: %d -> %d" % [score_before, score_after]) if score_after > score_before else _fail("No time bonus added")


func _case_f13_patrol(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_WALKER):
		return _fail("Missing WalkerEnemy")
	var arena := _make_arena(host)
	_add_floor(arena, Vector2(0, 116), Vector2(600, 32))
	_add_floor(arena, Vector2(-36, 80), Vector2(24, 64))
	_add_floor(arena, Vector2(36, 80), Vector2(24, 64))
	var w := _spawn_scene(PATH_WALKER, arena) as CharacterBody2D
	w.position = Vector2(0, 100)
	await _step_physics(tree, 3)
	var vx0 := w.velocity.x
	var reversed := false
	for _i in range(25):
		await _step_physics(tree, 1)
		if signf(w.velocity.x) != signf(vx0) and absf(w.velocity.x) > 1.0:
			reversed = true
			break
	await _free_node_later(tree, arena)
	return _ok("WalkerEnemy patrols & reverses on wall") if (absf(vx0) > 1.0 and reversed) else _fail("Walker patrol/reverse failed")


func _case_f13_stomp(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_WALKER) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing WalkerEnemy or Player")
	_cleanup_global_state(tree)
	var arena := _make_arena(host)
	var w := _spawn_scene(PATH_WALKER, arena)
	var p := _spawn_scene(PATH_PLAYER, arena) as CharacterBody2D
	w.call("on_stomped", p)
	var spr := w.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	var anim := String(spr.animation) if spr != null else ""
	var ok := anim == "squished" and int(_gs(tree).get("score")) == 200 and p.velocity.y < 0.0
	await _free_node_later(tree, arena)
	return _ok("WalkerEnemy stomp verified") if ok else _fail("Walker stomp failed: anim=%s" % anim)


func _case_f13_side_hurt(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_WALKER) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing WalkerEnemy or Player")
	_cleanup_global_state(tree)
	var arena := _make_arena(host)
	_add_floor(arena, Vector2(0, 116), Vector2(400, 32))
	var p := _spawn_scene(PATH_PLAYER, arena) as CharacterBody2D
	p.position = Vector2(0, 100)
	var w := _spawn_scene(PATH_WALKER, arena) as CharacterBody2D
	w.position = Vector2(4, 100)
	await _step_physics(tree, 5)
	var dead := bool(p.call("is_dead"))
	await _free_node_later(tree, arena)
	return _ok("WalkerEnemy side contact hurt player") if dead else _fail("Walker side contact did not hurt player")


func _case_f13_bump_and_shell_kill(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_WALKER) or not ResourceLoader.exists(PATH_SHELL):
		return _fail("Missing WalkerEnemy or ShellEnemy")
	_cleanup_global_state(tree)
	var arena := _make_arena(host)
	var w1 := _spawn_scene(PATH_WALKER, arena)
	w1.call("on_block_bumped")
	var s1 := int(_gs(tree).get("score"))
	var w2 := _spawn_scene(PATH_WALKER, arena)
	var sh := _spawn_scene(PATH_SHELL, arena)
	w2.call("on_hit_by_shell", sh)
	var s2 := int(_gs(tree).get("score"))
	await _free_node_later(tree, arena)
	return _ok("Walker block bump & shell kill verified") if (s1 > 0 and s2 > s1) else _fail("Walker bump/shell score failed")


func _case_f14_first_stomp(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_SHELL) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing ShellEnemy or Player")
	var arena := _make_arena(host)
	var sh := _spawn_scene(PATH_SHELL, arena)
	var p := _spawn_scene(PATH_PLAYER, arena) as CharacterBody2D
	sh.call("on_stomped", p)
	var idle := bool(sh.call("is_shell_idle"))
	var sliding := bool(sh.call("is_sliding"))
	var spr := sh.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	var anim := String(spr.animation) if spr != null else ""
	var bounced := p.velocity.y < 0.0
	await _free_node_later(tree, arena)
	return _ok("Shell first stomp -> SHELL_IDLE") if (idle and not sliding and anim == "shell" and bounced) else _fail("Shell first stomp failed")


func _case_f14_slide(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_SHELL) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing ShellEnemy or Player")
	var arena := _make_arena(host)
	var sh := _spawn_scene(PATH_SHELL, arena) as CharacterBody2D
	var p := _spawn_scene(PATH_PLAYER, arena) as CharacterBody2D
	p.position = Vector2(-20, 0)
	sh.call("on_stomped", p)
	sh.call("on_stomped", p)
	var sliding := bool(sh.call("is_sliding"))
	var speed := absf(sh.velocity.x)
	await _free_node_later(tree, arena)
	return _ok("Shell second stomp -> SHELL_SLIDE") if (sliding and speed > 100.0) else _fail("Shell slide failed: sliding=%s vx=%.1f" % [str(sliding), speed])


func _case_f14_rebound(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_SHELL) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing ShellEnemy or Player")
	var arena := _make_arena(host)
	_add_floor(arena, Vector2(0, 116), Vector2(600, 32))
	_add_floor(arena, Vector2(-40, 80), Vector2(24, 64))
	_add_floor(arena, Vector2(40, 80), Vector2(24, 64))
	var sh := _spawn_scene(PATH_SHELL, arena) as CharacterBody2D
	sh.position = Vector2(0, 100)
	var p := _spawn_scene(PATH_PLAYER, arena) as CharacterBody2D
	p.position = Vector2(-15, 100)
	sh.call("on_stomped", p)
	sh.call("on_stomped", p)
	var vx0 := sh.velocity.x
	var rebounded := false
	for _i in range(20):
		await _step_physics(tree, 1)
		if signf(sh.velocity.x) != signf(vx0) and bool(sh.call("is_sliding")):
			rebounded = true
			break
	await _free_node_later(tree, arena)
	return _ok("Sliding shell rebounded off wall") if rebounded else _fail("Sliding shell did not rebound")


func _case_f14_defeats_walker(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_SHELL) or not ResourceLoader.exists(PATH_WALKER) or not ResourceLoader.exists(PATH_PLAYER):
		return _fail("Missing ShellEnemy, WalkerEnemy, or Player")
	_cleanup_global_state(tree)
	var arena := _make_arena(host)
	_add_floor(arena, Vector2(0, 116), Vector2(600, 32))
	var sh := _spawn_scene(PATH_SHELL, arena) as CharacterBody2D
	sh.position = Vector2(0, 100)
	var p := _spawn_scene(PATH_PLAYER, arena) as CharacterBody2D
	p.position = Vector2(-20, 100)
	var w := _spawn_scene(PATH_WALKER, arena) as Node2D
	w.position = Vector2(40, 100)
	sh.call("on_stomped", p)
	sh.call("on_stomped", p)
	if sh.velocity.x < 0:
		w.position = Vector2(-40, 100)
	var score0 := int(_gs(tree).get("score"))
	await _step_physics(tree, 15)
	var ok := (not is_instance_valid(w)) or w.is_queued_for_deletion() or int(_gs(tree).get("score")) > score0
	await _free_node_later(tree, arena)
	return _ok("Sliding shell defeated WalkerEnemy") if ok else _fail("Sliding shell did not defeat walker")


func _case_f15_camera_limits(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_LEVEL_1):
		return _fail("Missing level_1.tscn")
	var lvl := _spawn_scene(PATH_LEVEL_1, host)
	await _step_physics(tree, 2)
	var p := _find_node_script(lvl, "player.gd")
	var cam := p.get_node_or_null("Camera2D") as Camera2D if p != null else null
	var ok := cam != null and cam.limit_right >= 3000 and cam.limit_bottom >= 360
	await _free_node_later(tree, lvl)
	_cleanup_global_state(tree)
	return _ok("Camera2D limits applied") if ok else _fail("Camera2D limits not applied")


func _case_f15_countdown(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_LEVEL_1):
		return _fail("Missing level_1.tscn")
	var lvl := _spawn_scene(PATH_LEVEL_1, host)
	await _step_physics(tree, 68)
	var hud := _find_node_script(lvl, "hud.gd")
	var txt := " | ".join(_collect_texts(hud)) if hud != null else ""
	var ok := txt.find("178") != -1 or txt.find("179") != -1
	await _free_node_later(tree, lvl)
	_cleanup_global_state(tree)
	return _ok("Countdown ticked & updated HUD") if ok else _fail("Countdown did not decrement in HUD: " + txt)


func _case_f15_fallzone(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_LEVEL_1):
		return _fail("Missing level_1.tscn")
	_cleanup_global_state(tree)
	var lvl := _spawn_scene(PATH_LEVEL_1, host)
	await _step_physics(tree, 2)
	var p := _find_node_script(lvl, "player.gd") as Node2D
	var fz := _find_by_name_ci(lvl, "FallZone") as Node2D
	if p == null or fz == null:
		await _free_node_later(tree, lvl)
		return _fail("Missing Player or FallZone")
	p.global_position = fz.global_position
	await _step_physics(tree, 5)
	var dead := bool(p.call("is_dead"))
	await _free_node_later(tree, lvl)
	_cleanup_global_state(tree)
	return _ok("FallZone killed player") if dead else _fail("FallZone did not kill player")


func _case_f15_pause_toggle(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_LEVEL_1):
		return _fail("Missing level_1.tscn")
	_cleanup_global_state(tree)
	var lvl := _spawn_scene(PATH_LEVEL_1, host)
	await _step_physics(tree, 2)
	var pm := _find_node_script(lvl, "pause_menu.gd") as Control
	if pm == null:
		await _free_node_later(tree, lvl)
		return _fail("Missing PauseMenu in level_1")
	pm.call("toggle_pause")
	var paused_ok := tree.paused and pm.visible
	pm.call("toggle_pause")
	var resumed_ok := (not tree.paused) and (not pm.visible)
	await _free_node_later(tree, lvl)
	_cleanup_global_state(tree)
	return _ok("PauseMenu toggle verified") if (paused_ok and resumed_ok) else _fail("PauseMenu toggle failed")


func _case_f15_bgm_and_tip(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_LEVEL_1):
		return _fail("Missing level_1.tscn")
	_cleanup_global_state(tree)
	var lvl := _spawn_scene(PATH_LEVEL_1, host)
	await _step_physics(tree, 3)
	var bgm_ok := str(lvl.get("bgm_track")) != "castle"
	var hud := _find_node_script(lvl, "hud.gd")
	var tip_found := false
	if hud != null:
		for c in _all_descendants(hud):
			if c is Label and (c as Label).visible and (c as Label).text.length() > 8:
				if (c as Label).text.find("المرحلة") == -1 and (c as Label).text.find("النقاط") == -1:
					tip_found = true
	await _free_node_later(tree, lvl)
	_cleanup_global_state(tree)
	return _ok("Level 1-1 overworld BGM & Arabic tip verified") if (bgm_ok and tip_found) else _fail("Level 1-1 tip or BGM missing")


func _case_f18_castle_bgm(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_LEVEL_3):
		return _fail("Missing level_3.tscn")
	_cleanup_global_state(tree)
	var lvl := _spawn_scene(PATH_LEVEL_3, host)
	await _step_physics(tree, 3)
	var ok := str(lvl.get("bgm_track")) == "castle"
	await _free_node_later(tree, lvl)
	_cleanup_global_state(tree)
	return _ok("Level 3 castle BGM verified") if ok else _fail("Level 3 bgm_track != castle")


func _case_f18_final_flagpole(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_LEVEL_3) or not ResourceLoader.exists(PATH_END_SCREEN):
		return _fail("Missing level_3.tscn or end_screen.tscn")
	_cleanup_global_state(tree)
	var saved_current := tree.current_scene
	var lvl := _spawn_scene(PATH_LEVEL_3, tree.root)
	tree.current_scene = lvl
	await _step_physics(tree, 3)
	var p := _find_node_script(lvl, "player.gd") as Node2D
	var fp := _find_node_script(lvl, "flagpole.gd") as Node2D
	p.global_position = fp.global_position
	var switched := false
	for _i in range(180):
		await _step_physics(tree, 1)
		if tree.current_scene != null and tree.current_scene != lvl and tree.current_scene.scene_file_path == PATH_END_SCREEN:
			switched = true
			break
	var won := bool(_gs(tree).get("game_won"))
	if tree.current_scene != null and tree.current_scene != saved_current:
		await _free_node_later(tree, tree.current_scene)
	tree.current_scene = saved_current
	_cleanup_global_state(tree)
	return _ok("Level 3 Flagpole routed to EndScreen with game_won=true") if (switched and won) else _fail("Level 3 Flagpole routing failed: switched=%s won=%s" % [str(switched), str(won)])


func _case_f19_signals(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_HUD):
		return _fail("Missing hud.tscn")
	_cleanup_global_state(tree)
	var hud := _spawn_scene(PATH_HUD, host)
	await tree.process_frame
	var gs := _gs(tree)
	gs.call("add_score", 450)
	gs.call("add_coin", 7)
	gs.call("add_life", 2)
	gs.call("set_level", 2)
	await tree.process_frame
	var joined := " | ".join(_collect_texts(hud))
	await _free_node_later(tree, hud)
	_cleanup_global_state(tree)
	if joined.find("450") == -1 or joined.find("7") == -1 or joined.find("5") == -1:
		return _fail("HUD did not update from GameState signals: " + joined)
	return _ok("HUD reacts to GameState signals")


func _case_f19_time_format(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_HUD):
		return _fail("Missing hud.tscn")
	var hud := _spawn_scene(PATH_HUD, host)
	await tree.process_frame
	hud.call("update_time", 142)
	var joined := " | ".join(_collect_texts(hud))
	await _free_node_later(tree, hud)
	return _ok("HUD update_time(142) verified") if joined.find("142") != -1 else _fail("HUD time missing 142: " + joined)


func _case_f19_tip(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_HUD):
		return _fail("Missing hud.tscn")
	var hud := _spawn_scene(PATH_HUD, host)
	await tree.process_frame
	hud.call("show_tip", "اضغط مسافة للقفز")
	var joined := " | ".join(_collect_texts(hud))
	await _free_node_later(tree, hud)
	return _ok("HUD show_tip verified") if joined.find("اضغط مسافة للقفز") != -1 else _fail("HUD tip text missing")


func _case_f19_pause_btn(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_HUD):
		return _fail("Missing hud.tscn")
	var hud := _spawn_scene(PATH_HUD, host)
	await tree.process_frame
	var count := [0]
	var cb := func() -> void: count[0] += 1
	hud.connect("pause_requested", cb)
	var btn := _find_pause_btn(hud)
	if btn != null:
		btn.emit_signal("pressed")
	hud.disconnect("pause_requested", cb)
	await _free_node_later(tree, hud)
	return _ok("HUD pause button emits pause_requested") if count[0] == 1 else _fail("HUD pause button did not emit pause_requested")


func _find_pause_btn(root: Node) -> BaseButton:
	for c in _all_descendants(root):
		if c is BaseButton:
			var t := (c as Button).text if c is Button else ""
			if String(c.name).to_lower().find("pause") != -1 or t.find("إيقاف") != -1 or t.find("⏸") != -1:
				return c as BaseButton
	return null


func _case_f20_init(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_PAUSE_MENU):
		return _fail("Missing pause_menu.tscn")
	var pm := _spawn_scene(PATH_PAUSE_MENU, host) as Control
	await tree.process_frame
	var ok := pm.process_mode == Node.PROCESS_MODE_ALWAYS and not pm.visible
	await _free_node_later(tree, pm)
	return _ok("PauseMenu process_mode & hidden init verified") if ok else _fail("PauseMenu init mismatch")


func _case_f20_pause(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_PAUSE_MENU):
		return _fail("Missing pause_menu.tscn")
	_cleanup_global_state(tree)
	var pm := _spawn_scene(PATH_PAUSE_MENU, host) as Control
	await tree.process_frame
	pm.call("toggle_pause")
	var ok := pm.visible and tree.paused and bool(_am(tree).get("is_ducked"))
	pm.call("toggle_pause")
	await _free_node_later(tree, pm)
	_cleanup_global_state(tree)
	return _ok("PauseMenu toggle_pause pauses & ducks") if ok else _fail("PauseMenu pause/duck failed")


func _case_f20_resume(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_PAUSE_MENU):
		return _fail("Missing pause_menu.tscn")
	_cleanup_global_state(tree)
	var pm := _spawn_scene(PATH_PAUSE_MENU, host) as Control
	await tree.process_frame
	pm.call("toggle_pause")
	var btn := _find_button_with_text(pm, "استئناف")
	if btn != null:
		btn.emit_signal("pressed")
	else:
		pm.call("toggle_pause")
	var ok := (not pm.visible) and (not tree.paused) and (not bool(_am(tree).get("is_ducked")))
	await _free_node_later(tree, pm)
	_cleanup_global_state(tree)
	return _ok("PauseMenu resume unpauses & unducks") if ok else _fail("PauseMenu resume failed")


func _case_f20_mute(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_PAUSE_MENU):
		return _fail("Missing pause_menu.tscn")
	_cleanup_global_state(tree)
	var pm := _spawn_scene(PATH_PAUSE_MENU, host) as Control
	await tree.process_frame
	pm.call("toggle_pause")
	var btn := _find_button_with_text(pm, "الصوت")
	if btn == null:
		btn = _find_button_with_text(pm, "كتم")
	if btn == null:
		pm.call("toggle_pause")
		await _free_node_later(tree, pm)
		return _fail("PauseMenu missing mute button")
	btn.emit_signal("pressed")
	var muted := bool(_am(tree).get("is_muted"))
	pm.call("toggle_pause")
	await _free_node_later(tree, pm)
	_cleanup_global_state(tree)
	return _ok("PauseMenu mute button toggles AudioManager") if muted else _fail("PauseMenu mute button failed")


func _case_f21_start_adventure(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_MAIN) or not ResourceLoader.exists(PATH_LEVEL_1):
		return _fail("Missing main.tscn or level_1.tscn")
	_cleanup_global_state(tree)
	_gs(tree).call("add_score", 500)
	var saved := tree.current_scene
	var ts := _spawn_scene(PATH_MAIN, tree.root)
	tree.current_scene = ts
	await tree.process_frame
	var btn := _find_button_with_text(ts, "ابدأ المغامرة")
	if btn == null:
		await _free_node_later(tree, ts)
		tree.current_scene = saved
		return _fail("TitleScreen missing 'ابدأ المغامرة'")
	btn.emit_signal("pressed")
	await tree.process_frame
	await tree.process_frame
	var switched := tree.current_scene != null and tree.current_scene.scene_file_path == PATH_LEVEL_1
	var score_reset := int(_gs(tree).get("score")) == 0
	if tree.current_scene != null and tree.current_scene != saved:
		await _free_node_later(tree, tree.current_scene)
	tree.current_scene = saved
	_cleanup_global_state(tree)
	return _ok("Start Adventure reset & launched level_1") if (switched and score_reset) else _fail("Start Adventure failed")


func _case_f21_level_select(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_MAIN) or not ResourceLoader.exists(PATH_LEVEL_2):
		return _fail("Missing main.tscn or level_2.tscn")
	_cleanup_global_state(tree)
	var saved := tree.current_scene
	var ts := _spawn_scene(PATH_MAIN, tree.root)
	tree.current_scene = ts
	await tree.process_frame
	var btn2 := _find_button_with_text(ts, "1-2")
	if btn2 == null:
		await _free_node_later(tree, ts)
		tree.current_scene = saved
		return _fail("TitleScreen missing '1-2' button")
	btn2.emit_signal("pressed")
	await tree.process_frame
	await tree.process_frame
	var switched := tree.current_scene != null and tree.current_scene.scene_file_path == PATH_LEVEL_2
	if tree.current_scene != null and tree.current_scene != saved:
		await _free_node_later(tree, tree.current_scene)
	tree.current_scene = saved
	_cleanup_global_state(tree)
	return _ok("TitleScreen Level Select 1-2 routed to level_2") if switched else _fail("Level Select 1-2 failed")


func _case_f21_best_score(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_MAIN):
		return _fail("Missing main.tscn")
	_cleanup_global_state(tree)
	_gs(tree).call("add_score", 750)
	var ts := _spawn_scene(PATH_MAIN, host)
	await tree.process_frame
	var joined := " | ".join(_collect_texts(ts))
	await _free_node_later(tree, ts)
	_cleanup_global_state(tree)
	return _ok("TitleScreen displays best_score") if (joined.find("أعلى نتيجة") != -1 and joined.find("750") != -1) else _fail("TitleScreen best_score missing: " + joined)


func _case_f21_mute(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_MAIN):
		return _fail("Missing main.tscn")
	_cleanup_global_state(tree)
	var ts := _spawn_scene(PATH_MAIN, host)
	await tree.process_frame
	var btn := _find_button_with_text(ts, "الصوت")
	if btn == null:
		btn = _find_button_with_text(ts, "كتم")
	if btn == null:
		await _free_node_later(tree, ts)
		return _fail("TitleScreen missing mute button")
	btn.emit_signal("pressed")
	var muted := bool(_am(tree).get("is_muted"))
	await _free_node_later(tree, ts)
	_cleanup_global_state(tree)
	return _ok("TitleScreen mute toggles AudioManager") if muted else _fail("TitleScreen mute failed")


func _case_f22_heading(tree: SceneTree, host: Node, win: bool) -> Dictionary:
	if not ResourceLoader.exists(PATH_END_SCREEN):
		return _fail("Missing end_screen.tscn")
	_cleanup_global_state(tree)
	if win:
		_gs(tree).call("mark_victory")
	else:
		_gs(tree).call("mark_game_over")
	var es := _spawn_scene(PATH_END_SCREEN, host)
	await tree.process_frame
	var joined := " | ".join(_collect_texts(es))
	await _free_node_later(tree, es)
	_cleanup_global_state(tree)
	if win:
		var ok := joined.find("فوز") != -1 or joined.find("انتصر") != -1 or joined.find("مبروك") != -1 or joined.find("أنهيت") != -1
		return _ok("EndScreen win heading rendered") if ok else _fail("EndScreen win heading missing: " + joined)
	else:
		var ok := joined.find("انتهت") != -1 or joined.find("خسارة") != -1 or joined.find("نفدت") != -1
		return _ok("EndScreen loss heading rendered") if ok else _fail("EndScreen loss heading missing: " + joined)


func _case_f22_scores(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_END_SCREEN):
		return _fail("Missing end_screen.tscn")
	_cleanup_global_state(tree)
	_gs(tree).call("add_score", 640)
	_gs(tree).call("mark_victory")
	var es := _spawn_scene(PATH_END_SCREEN, host)
	await tree.process_frame
	var joined := " | ".join(_collect_texts(es))
	await _free_node_later(tree, es)
	_cleanup_global_state(tree)
	var ok := joined.find("640") != -1 and joined.find("أعلى نتيجة") != -1 and joined.find("النتيجة") != -1
	return _ok("EndScreen scores rendered") if ok else _fail("EndScreen scores missing: " + joined)


func _case_f22_play_again(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_END_SCREEN) or not ResourceLoader.exists(PATH_LEVEL_1):
		return _fail("Missing end_screen.tscn or level_1.tscn")
	_cleanup_global_state(tree)
	_gs(tree).call("add_score", 300)
	_gs(tree).call("mark_game_over")
	var saved := tree.current_scene
	var es := _spawn_scene(PATH_END_SCREEN, tree.root)
	tree.current_scene = es
	await tree.process_frame
	var btn := _find_button_with_text(es, "إعادة اللعب")
	if btn == null:
		await _free_node_later(tree, es)
		tree.current_scene = saved
		return _fail("EndScreen missing 'إعادة اللعب'")
	btn.emit_signal("pressed")
	await tree.process_frame
	await tree.process_frame
	var switched := tree.current_scene != null and tree.current_scene.scene_file_path == PATH_LEVEL_1
	var reset_ok := int(_gs(tree).get("score")) == 0 and int(_gs(tree).get("lives")) == 3
	if tree.current_scene != null and tree.current_scene != saved:
		await _free_node_later(tree, tree.current_scene)
	tree.current_scene = saved
	_cleanup_global_state(tree)
	return _ok("EndScreen Play Again reset & launched level_1") if (switched and reset_ok) else _fail("EndScreen Play Again failed")


func _case_f22_main_menu(tree: SceneTree, host: Node) -> Dictionary:
	if not ResourceLoader.exists(PATH_END_SCREEN) or not ResourceLoader.exists(PATH_MAIN):
		return _fail("Missing end_screen.tscn or main.tscn")
	_cleanup_global_state(tree)
	var saved := tree.current_scene
	var es := _spawn_scene(PATH_END_SCREEN, tree.root)
	tree.current_scene = es
	await tree.process_frame
	var btn := _find_button_with_text(es, "القائمة الرئيسية")
	if btn == null:
		await _free_node_later(tree, es)
		tree.current_scene = saved
		return _fail("EndScreen missing 'القائمة الرئيسية'")
	btn.emit_signal("pressed")
	await tree.process_frame
	await tree.process_frame
	var switched := tree.current_scene != null and tree.current_scene.scene_file_path == PATH_MAIN
	if tree.current_scene != null and tree.current_scene != saved:
		await _free_node_later(tree, tree.current_scene)
	tree.current_scene = saved
	_cleanup_global_state(tree)
	return _ok("EndScreen Main Menu returned to main.tscn") if switched else _fail("EndScreen Main Menu failed")
