@tool
extends McpTestSuite

const HELPERS_PATH := "res://tests/helpers/e2e_test_helpers.gd"

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

var _helpers: Script = null
var _batch: Dictionary = {}


func suite_name() -> String:
	return "e2e_tier2_boundaries"


func suite_setup(_ctx: Dictionary) -> void:
	_helpers = _load_helpers()
	if _helpers == null:
		fail_setup("Failed to load helpers script: " + HELPERS_PATH)
		return
	_batch = _helpers.call("run_headless_batch", "e2e_tier2_boundaries")


func _load_helpers() -> Script:
	if _helpers != null:
		return _helpers
	var res := ResourceLoader.load(HELPERS_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	if res is Script:
		_helpers = res as Script
	return _helpers


func _get_helpers() -> Script:
	var h := _load_helpers()
	assert_ne(h, null, "E2E test helpers script must load")
	return h


func _assert_runtime_case(case_id: String) -> void:
	var h := _get_helpers()
	if h == null:
		return
	var res: Dictionary = h.call("get_case_result", _batch, case_id)
	assert_true(bool(res.get("passed", false)), str(res.get("detail", "Runtime case failed: " + case_id)))


func _require_and_instantiate(scene_path: String) -> Node:
	assert_true(ResourceLoader.exists(scene_path), "Missing scene: " + scene_path)
	if not ResourceLoader.exists(scene_path):
		return null
	var h := _get_helpers()
	if h == null:
		return null
	var inst: Node = h.call("instantiate_scene", scene_path)
	assert_ne(inst, null, "Failed to instantiate: " + scene_path)
	if inst != null:
		track(inst)
	return inst


func _descendants(root: Node) -> Array[Node]:
	var out: Array[Node] = []
	for c in root.get_children():
		out.append(c)
		out.append_array(_descendants(c))
	return out


func _uses_theme(root: Node, theme_path: String) -> bool:
	if root is Control and (root as Control).theme != null and (root as Control).theme.resource_path == theme_path:
		return true
	for c in root.get_children():
		if _uses_theme(c, theme_path):
			return true
	return false


func _find_name_prefix(root: Node, prefix: String) -> Node:
	if String(root.name).begins_with(prefix):
		return root
	for c in root.get_children():
		var f := _find_name_prefix(c, prefix)
		if f != null:
			return f
	return null


func _collect_name_prefix(root: Node, prefix: String) -> Array[Node]:
	var out: Array[Node] = []
	if String(root.name).begins_with(prefix):
		out.append(root)
	for c in root.get_children():
		out.append_array(_collect_name_prefix(c, prefix))
	return out


func _shape_rect_in_root(area: Area2D, col: CollisionShape2D) -> Rect2:
	if col.shape is RectangleShape2D:
		var sz := (col.shape as RectangleShape2D).size
		var center := area.position + col.position
		return Rect2(center - sz * 0.5, sz)
	return Rect2()


# --- Feature #1 Boundaries ---

func test_b01_no_duplicate_legacy_autoload_names() -> void:
	var expected := ["_mcp_game_helper", "GameState", "AudioManager"]
	for name_key in expected:
		assert_true(ProjectSettings.has_setting("autoload/" + name_key), "Missing autoload: " + name_key)
	for prop in ProjectSettings.get_property_list():
		var pname := str(prop.get("name", ""))
		if pname.begins_with("autoload/"):
			var short_name := pname.substr("autoload/".length())
			assert_contains(expected, short_name, "Unexpected autoload entry: " + short_name)


func test_b01_stretch_mode_not_disabled() -> void:
	var mode := str(ProjectSettings.get_setting("display/window/stretch/mode", ""))
	assert_ne(mode, "disabled")
	assert_ne(mode, "ignore")
	assert_eq(mode, "canvas_items")


func test_b01_texture_filter_exact_nearest_zero() -> void:
	var tf := int(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter", -1))
	assert_eq(tf, 0)


func test_b01_physics_layers_unique_names() -> void:
	var seen: Array[String] = []
	for i in range(1, 6):
		var lname := str(ProjectSettings.get_setting("layer_names/2d_physics/layer_%d" % i, ""))
		assert_ne(lname, "", "Layer %d name empty" % i)
		assert_false(seen.has(lname), "Duplicate layer name: " + lname)
		seen.append(lname)


func test_b01_input_actions_have_nonzero_deadzone() -> void:
	for act in ["move_left", "move_right", "jump", "sprint", "pause"]:
		if not Engine.is_editor_hint() and InputMap.has_action(act):
			assert_true(InputMap.has_action(act))
			assert_gt(InputMap.action_get_deadzone(act), 0.0)
		else:
			assert_true(ProjectSettings.has_setting("input/" + act))
			var cfg: Variant = ProjectSettings.get_setting("input/" + act, {})
			var dz: float = float((cfg as Dictionary).get("deadzone", 0.0)) if cfg is Dictionary else 0.0
			assert_gt(dz, 0.0)


# --- Feature #2 Boundaries ---

func test_b02_main_tscn_no_legacy_dependencies() -> void:
	assert_true(ResourceLoader.exists(PATH_MAIN))
	var deps := Array(ResourceLoader.get_dependencies(PATH_MAIN))
	for d in deps:
		var s := str(d)
		assert_eq(s.find("scripts/main.gd"), -1)
		assert_eq(s.find("scripts/player.gd"), -1)


func test_b02_no_broken_ext_resources_in_scenes() -> void:
	for p in [PATH_MAIN, PATH_LEVEL_1, PATH_LEVEL_2, PATH_LEVEL_3, PATH_PLAYER]:
		assert_true(ResourceLoader.exists(p), "Missing scene: " + p)
		if ResourceLoader.exists(p):
			var inst := _require_and_instantiate(p)
			assert_ne(inst, null)


func test_b02_no_stray_prototype_coin_spawner_method() -> void:
	var root := _require_and_instantiate(PATH_MAIN)
	if root == null:
		return
	var h := _get_helpers()
	var scr: Variant = root.get_script()
	assert_ne(scr, null)
	if scr is Script and h != null:
		assert_false(bool(h.call("script_has_method", scr, "_move_coin")))


func test_b02_no_stray_topdown_player_script() -> void:
	var p := _require_and_instantiate(PATH_PLAYER)
	if p == null:
		return
	var scr: Variant = p.get_script()
	assert_ne(scr, null)
	if scr is Script:
		assert_eq((scr as Script).resource_path, "res://scripts/player/player.gd")


func test_b02_scripts_root_has_no_loose_prototypes() -> void:
	var dir := DirAccess.open("res://scripts")
	assert_ne(dir, null)
	if dir == null:
		return
	dir.list_dir_begin()
	var fname := dir.get_next()
	while not fname.is_empty():
		if not dir.current_is_dir():
			assert_false(fname.ends_with(".gd"), "Unexpected root script in res://scripts/: " + fname)
		fname = dir.get_next()
	dir.list_dir_end()


# --- Feature #3 Boundaries ---

func test_b03_zero_and_negative_score_ignored() -> void:
	_assert_runtime_case("b03_zero_and_negative_score_ignored")


func test_b03_zero_and_negative_coin_ignored() -> void:
	_assert_runtime_case("b03_zero_and_negative_coin_ignored")


func test_b03_coin_rollover_99_to_100_and_overflow() -> void:
	_assert_runtime_case("b03_coin_rollover_99_to_100_and_overflow")


func test_b03_lives_floor_at_zero_and_neg_add_life() -> void:
	_assert_runtime_case("b03_lives_floor_at_zero_and_neg_add_life")


func test_b03_invalid_level_bounds_and_paths() -> void:
	_assert_runtime_case("b03_invalid_level_bounds_and_paths")


# --- Feature #4 Boundaries ---

func test_b04_play_sfx_empty_string_no_error() -> void:
	_assert_runtime_case("b04_play_sfx_empty_string_no_error")


func test_b04_play_sfx_unknown_key_no_error() -> void:
	_assert_runtime_case("b04_play_sfx_unknown_key_no_error")


func test_b04_play_bgm_unknown_or_empty_no_error() -> void:
	_assert_runtime_case("b04_play_bgm_unknown_or_empty_no_error")


func test_b04_stop_bgm_when_idle_idempotent() -> void:
	_assert_runtime_case("b04_stop_bgm_when_idle_idempotent")


func test_b04_play_sfx_while_muted_preserves_mute() -> void:
	_assert_runtime_case("b04_play_sfx_while_muted_preserves_mute")


# --- Feature #5 Boundaries ---

func test_b05_opposing_left_right_inputs_cancel() -> void:
	_assert_runtime_case("b05_opposing_left_right_inputs_cancel")


func test_b05_jump_unavailable_after_coyote_expires() -> void:
	_assert_runtime_case("b05_jump_unavailable_after_coyote_expires")


func test_b05_jump_buffer_expired_before_landing() -> void:
	_assert_runtime_case("b05_jump_buffer_expired_before_landing")


func test_b05_double_jump_blocked_in_midair() -> void:
	_assert_runtime_case("b05_double_jump_blocked_in_midair")


func test_b05_variable_jump_release_while_falling_noop() -> void:
	_assert_runtime_case("b05_variable_jump_release_while_falling_noop")


# --- Feature #6 Boundaries ---

func test_b06_collect_powerup_when_already_big_safe() -> void:
	_assert_runtime_case("b06_collect_powerup_when_already_big_safe")


func test_b06_take_damage_ignored_while_invulnerable() -> void:
	_assert_runtime_case("b06_take_damage_ignored_while_invulnerable")


func test_b06_take_damage_ignored_when_dead() -> void:
	_assert_runtime_case("b06_take_damage_ignored_when_dead")


func test_b06_take_damage_ignored_when_level_cleared() -> void:
	_assert_runtime_case("b06_take_damage_ignored_when_level_cleared")


func test_b06_lethal_damage_bypasses_big_and_invuln() -> void:
	_assert_runtime_case("b06_lethal_damage_bypasses_big_and_invuln")


# --- Feature #7 Boundaries ---

func test_b07_rehit_used_block_does_not_spawn_coin() -> void:
	_assert_runtime_case("b07_rehit_used_block_does_not_spawn_coin")


func test_b07_rehit_used_mushroom_block_spawns_once() -> void:
	_assert_runtime_case("b07_rehit_used_mushroom_block_spawns_once")


func test_b07_hit_with_null_player_guarded() -> void:
	_assert_runtime_case("b07_hit_with_null_player_guarded")


func test_b07_used_animation_persists_after_rehit() -> void:
	_assert_runtime_case("b07_used_animation_persists_after_rehit")


func test_b07_top_landing_does_not_trigger_block() -> void:
	_assert_runtime_case("b07_top_landing_does_not_trigger_block")


# --- Feature #8 Boundaries ---

func test_b08_hit_with_null_player_guarded() -> void:
	_assert_runtime_case("b08_hit_with_null_player_guarded")


func test_b08_double_hit_while_shattering_scores_once() -> void:
	_assert_runtime_case("b08_double_hit_while_shattering_scores_once")


func test_b08_repeated_small_hits_stay_intact() -> void:
	_assert_runtime_case("b08_repeated_small_hits_stay_intact")


func test_b08_top_landing_does_not_shatter_even_if_big() -> void:
	_assert_runtime_case("b08_top_landing_does_not_shatter_even_if_big")


func test_b08_brick_layer_is_world_only() -> void:
	var bb := _require_and_instantiate(PATH_BRICK_BLOCK)
	if bb == null:
		return
	assert_true(bb is CollisionObject2D)
	if bb is CollisionObject2D:
		assert_eq((bb as CollisionObject2D).collision_layer, 1)


# --- Feature #9 Boundaries ---

func test_b09_double_collect_same_frame_scores_once() -> void:
	_assert_runtime_case("b09_double_collect_same_frame_scores_once")


func test_b09_dead_player_cannot_collect_coin() -> void:
	_assert_runtime_case("b09_dead_player_cannot_collect_coin")


func test_b09_coin_does_not_block_player_physics() -> void:
	var c := _require_and_instantiate(PATH_COIN)
	var p := _require_and_instantiate(PATH_PLAYER)
	if c == null or p == null:
		return
	assert_eq((c as Area2D).collision_layer, 8)
	assert_eq((p as CharacterBody2D).collision_mask & (c as Area2D).collision_layer, 0)


func test_b09_coin_triggers_100_rollover_boundary() -> void:
	_assert_runtime_case("b09_coin_triggers_100_rollover_boundary")


func test_b09_coin_animation_loops_and_non_empty() -> void:
	var h := _get_helpers()
	var sf: Resource = h.call("load_resource_ignore_cache", "res://assets/sprites/coin_frames.tres")
	assert_true(sf is SpriteFrames)
	if sf is SpriteFrames:
		var frames := sf as SpriteFrames
		assert_true(frames.has_animation(&"spin"))
		assert_eq(frames.get_frame_count(&"spin"), 4)
		assert_true(frames.get_animation_loop(&"spin"))


# --- Feature #10 Boundaries ---

func test_b10_double_pickup_same_frame_once() -> void:
	_assert_runtime_case("b10_double_pickup_same_frame_once")


func test_b10_dead_player_ignored_by_mushroom() -> void:
	_assert_runtime_case("b10_dead_player_ignored_by_mushroom")


func test_b10_mushroom_collision_mask_world_only() -> void:
	var m := _require_and_instantiate(PATH_MUSHROOM)
	if m == null:
		return
	assert_eq((m as CharacterBody2D).collision_mask, 1)
	var pa := m.get_node_or_null("PickupArea") as Area2D
	assert_ne(pa, null)
	if pa != null:
		assert_eq(pa.collision_mask, 2)


func test_b10_mushroom_falls_below_pit_cleanup() -> void:
	_assert_runtime_case("b10_mushroom_falls_below_pit_cleanup")


func test_b10_grow_mushroom_when_already_big_no_regression() -> void:
	_assert_runtime_case("b10_grow_mushroom_when_already_big_no_regression")


# --- Feature #11 Boundaries ---

func test_b11_duration_zero_guard() -> void:
	_assert_runtime_case("b11_duration_zero_guard")


func test_b11_duration_negative_guard() -> void:
	_assert_runtime_case("b11_duration_negative_guard")


func test_b11_zero_move_offset_stays_stationary() -> void:
	_assert_runtime_case("b11_zero_move_offset_stays_stationary")


func test_b11_large_offset_clamped_bounds() -> void:
	_assert_runtime_case("b11_large_offset_clamped_bounds")


func test_b11_sync_to_physics_always_enabled() -> void:
	var mp := _require_and_instantiate(PATH_MOVING_PLATFORM)
	if mp == null:
		return
	assert_true(mp is AnimatableBody2D)
	if mp is AnimatableBody2D:
		assert_true((mp as AnimatableBody2D).sync_to_physics)


# --- Feature #12 Boundaries ---

func test_b12_double_trigger_ignored() -> void:
	_assert_runtime_case("b12_double_trigger_ignored")


func test_b12_dead_player_cannot_clear_flagpole() -> void:
	_assert_runtime_case("b12_dead_player_cannot_clear_flagpole")


func test_b12_enemy_touching_flagpole_ignored() -> void:
	_assert_runtime_case("b12_enemy_touching_flagpole_ignored")


func test_b12_zero_time_remaining_gives_zero_bonus() -> void:
	_assert_runtime_case("b12_zero_time_remaining_gives_zero_bonus")


func test_b12_flagpole_layer_hazards_mask_player() -> void:
	var fp := _require_and_instantiate(PATH_FLAGPOLE)
	if fp == null:
		return
	assert_true(fp is Area2D)
	if fp is Area2D:
		assert_eq((fp as Area2D).collision_layer, 16)
		assert_eq((fp as Area2D).collision_mask, 2)


# --- Feature #13 Boundaries ---

func test_b13_squished_enemy_ignores_second_stomp() -> void:
	_assert_runtime_case("b13_squished_enemy_ignores_second_stomp")


func test_b13_squished_enemy_does_not_hurt_player() -> void:
	_assert_runtime_case("b13_squished_enemy_does_not_hurt_player")


func test_b13_block_bump_then_stomp_no_double_score() -> void:
	_assert_runtime_case("b13_block_bump_then_stomp_no_double_score")


func test_b13_stomp_threshold_above_vs_side() -> void:
	_assert_runtime_case("b13_stomp_threshold_above_vs_side")


func test_b13_walker_falls_below_pit_frees() -> void:
	_assert_runtime_case("b13_walker_falls_below_pit_frees")


# --- Feature #14 Boundaries ---

func test_b14_kick_grace_prevents_immediate_self_hurt() -> void:
	_assert_runtime_case("b14_kick_grace_prevents_immediate_self_hurt")


func test_b14_stomp_sliding_shell_stops_to_idle() -> void:
	_assert_runtime_case("b14_stomp_sliding_shell_stops_to_idle")


func test_b14_dead_shell_ignores_interactions() -> void:
	_assert_runtime_case("b14_dead_shell_ignores_interactions")


func test_b14_rapid_wall_rebounds_preserve_speed() -> void:
	_assert_runtime_case("b14_rapid_wall_rebounds_preserve_speed")


func test_b14_shell_idle_safe_to_approach_and_kick() -> void:
	_assert_runtime_case("b14_shell_idle_safe_to_approach_and_kick")


# --- Feature #15 Boundaries ---

func test_b15_timer_stops_at_zero_no_negative() -> void:
	_assert_runtime_case("b15_timer_stops_at_zero_no_negative")


func test_b15_fallzone_layer_16_mask_2() -> void:
	var lvl := _require_and_instantiate(PATH_LEVEL_1)
	if lvl == null:
		return
	var fz := _find_name_prefix(lvl, "FallZone")
	assert_true(fz is Area2D, "level_1 missing FallZone Area2D")
	if fz is Area2D:
		assert_eq((fz as Area2D).collision_layer, 16)
		assert_eq((fz as Area2D).collision_mask, 2)


func test_b15_camera_limits_left_top_valid() -> void:
	var lvl := _require_and_instantiate(PATH_LEVEL_1)
	if lvl == null:
		return
	var lim_r: Variant = lvl.get("camera_limit_right")
	var lim_l: Variant = lvl.get("camera_limit_left") if lvl.get("camera_limit_left") != null else 0
	var lim_b: Variant = lvl.get("camera_limit_bottom")
	var lim_t: Variant = lvl.get("camera_limit_top") if lvl.get("camera_limit_top") != null else 0
	assert_ne(lim_r, null)
	if lim_r != null:
		assert_gt(int(lim_r), int(lim_l))
	if lim_b != null:
		assert_gt(int(lim_b), int(lim_t))


func test_b15_pause_ignored_when_player_dead_or_cleared() -> void:
	_assert_runtime_case("b15_pause_ignored_when_player_dead_or_cleared")


func test_b15_level_tip_safe_on_levels_2_and_3() -> void:
	_assert_runtime_case("b15_level_tip_safe_on_levels_2_and_3")


# --- Feature #16 Boundaries ---

func test_b16_player_spawn_above_solid_ground() -> void:
	var h := _get_helpers()
	var lvl := _require_and_instantiate(PATH_LEVEL_1)
	if lvl == null or h == null:
		return
	var p := h.call("find_node_by_name_or_script", lvl, "Player", "player.gd") as Node2D
	var g := lvl.get_node_or_null("GroundLayer") as TileMapLayer
	assert_ne(p, null)
	assert_ne(g, null)
	if p != null and g != null:
		var cell := g.local_to_map(g.to_local(p.position + Vector2(0, 16)))
		var found_below := false
		for dy in range(0, 5):
			if g.get_cell_source_id(cell + Vector2i(0, dy)) != -1:
				found_below = true
				break
		assert_true(found_below, "level_1 Player spawn must sit over solid ground")


func test_b16_fallzone_covers_entire_level_width() -> void:
	var h := _get_helpers()
	var lvl := _require_and_instantiate(PATH_LEVEL_1)
	if lvl == null or h == null:
		return
	var fp := h.call("find_node_by_name_or_script", lvl, "Flagpole", "flagpole.gd") as Node2D
	var fz := _find_name_prefix(lvl, "FallZone") as Area2D
	assert_ne(fp, null)
	assert_ne(fz, null)
	if fp != null and fz != null:
		var max_x := fz.position.x
		for c in fz.get_children():
			if c is CollisionShape2D and (c as CollisionShape2D).shape is RectangleShape2D:
				var r := _shape_rect_in_root(fz, c as CollisionShape2D)
				max_x = maxf(max_x, r.end.x)
		assert_gt(max_x, fp.position.x)


func test_b16_no_unintended_lava_in_level_1() -> void:
	var lvl := _require_and_instantiate(PATH_LEVEL_1)
	if lvl == null:
		return
	var g := lvl.get_node_or_null("GroundLayer") as TileMapLayer
	assert_ne(g, null)
	if g != null:
		for cell in g.get_used_cells():
			var ac := g.get_cell_atlas_coords(cell)
			assert_false(ac == Vector2i(0, 1) or ac == Vector2i(1, 1), "level_1 must not have lava tiles")


func test_b16_all_entities_within_camera_bounds() -> void:
	var h := _get_helpers()
	var lvl := _require_and_instantiate(PATH_LEVEL_1)
	if lvl == null or h == null:
		return
	var fp := h.call("find_node_by_name_or_script", lvl, "Flagpole", "flagpole.gd") as Node2D
	var lim_r := int(lvl.get("camera_limit_right")) if lvl.get("camera_limit_right") != null else 3500
	assert_ne(fp, null)
	if fp != null:
		assert_true(fp.position.x <= float(lim_r), "Flagpole exceeds camera_limit_right")
	for suffix in ["question_block.gd", "brick_block.gd", "coin.gd", "walker_enemy.gd"]:
		for n in h.call("collect_nodes_with_script_suffix", lvl, suffix):
			var n2d := n as Node2D
			assert_true(n2d.position.x >= 0.0 and n2d.position.x <= float(lim_r), "Entity outside camera bounds: " + suffix)


func test_b16_level_1_bgm_not_castle() -> void:
	var lvl := _require_and_instantiate(PATH_LEVEL_1)
	if lvl == null:
		return
	assert_ne(str(lvl.get("bgm_track")), "castle")


# --- Feature #17 Boundaries ---

func test_b17_player_spawn_above_solid_ground() -> void:
	var h := _get_helpers()
	var lvl := _require_and_instantiate(PATH_LEVEL_2)
	if lvl == null or h == null:
		return
	var p := h.call("find_node_by_name_or_script", lvl, "Player", "player.gd") as Node2D
	var g := lvl.get_node_or_null("GroundLayer") as TileMapLayer
	assert_ne(p, null)
	assert_ne(g, null)
	if p != null and g != null:
		var cell := g.local_to_map(g.to_local(p.position + Vector2(0, 16)))
		var found := false
		for dy in range(0, 5):
			if g.get_cell_source_id(cell + Vector2i(0, dy)) != -1:
				found = true
				break
		assert_true(found, "level_2 Player spawn must sit over solid ground")


func test_b17_moving_platforms_have_positive_duration() -> void:
	var h := _get_helpers()
	var lvl := _require_and_instantiate(PATH_LEVEL_2)
	if lvl == null or h == null:
		return
	var mps: Array = h.call("collect_nodes_with_script_suffix", lvl, "moving_platform.gd")
	assert_gt(mps.size(), 0)
	for mp in mps:
		assert_gt(float(mp.get("duration")), 0.0)
		assert_ne(mp.get("move_offset"), Vector2.ZERO)


func test_b17_fallzone_below_lowest_gap() -> void:
	var lvl := _require_and_instantiate(PATH_LEVEL_2)
	if lvl == null:
		return
	var fz := _find_name_prefix(lvl, "FallZone") as Area2D
	var g := lvl.get_node_or_null("GroundLayer") as TileMapLayer
	assert_ne(fz, null)
	assert_ne(g, null)
	if fz != null and g != null:
		var max_tile_y := -9999.0
		for cell in g.get_used_cells():
			var wy := g.to_global(g.map_to_local(cell)).y
			max_tile_y = maxf(max_tile_y, wy)
		assert_gt(fz.position.y, max_tile_y - 16.0)


func test_b17_enemies_within_level_bounds() -> void:
	var h := _get_helpers()
	var lvl := _require_and_instantiate(PATH_LEVEL_2)
	if lvl == null or h == null:
		return
	var lim_r := int(lvl.get("camera_limit_right")) if lvl.get("camera_limit_right") != null else 4000
	for suffix in ["walker_enemy.gd", "shell_enemy.gd"]:
		for e in h.call("collect_nodes_with_script_suffix", lvl, suffix):
			var pos := (e as Node2D).position
			assert_true(pos.x >= 0.0 and pos.x <= float(lim_r), "Enemy out of bounds")


func test_b17_level_2_next_scene_valid() -> void:
	var lvl := _require_and_instantiate(PATH_LEVEL_2)
	if lvl == null:
		return
	var next_p := str(lvl.get("next_scene_path"))
	assert_eq(next_p, PATH_LEVEL_3)
	assert_true(ResourceLoader.exists(next_p))


# --- Feature #18 Boundaries ---

func test_b18_every_lava_tile_covered_by_hazard_zone() -> void:
	var lvl := _require_and_instantiate(PATH_LEVEL_3)
	if lvl == null:
		return
	var g := lvl.get_node_or_null("GroundLayer") as TileMapLayer
	var zones := _collect_name_prefix(lvl, "HazardZone")
	assert_ne(g, null)
	assert_gt(zones.size(), 0)
	if g != null and zones.size() > 0:
		var rects: Array[Rect2] = []
		for z in zones:
			if z is Area2D:
				for c in z.get_children():
					if c is CollisionShape2D:
						rects.append(_shape_rect_in_root(z as Area2D, c as CollisionShape2D))
		for cell in g.get_used_cells():
			var ac := g.get_cell_atlas_coords(cell)
			if ac == Vector2i(0, 1) or ac == Vector2i(1, 1):
				var pt := g.position + g.map_to_local(cell)
				var covered := false
				for r in rects:
					if r.grow(4.0).has_point(pt):
						covered = true
						break
				assert_true(covered, "Uncovered lava tile at " + str(cell))


func test_b18_player_spawn_safe_on_castle_stone() -> void:
	var h := _get_helpers()
	var lvl := _require_and_instantiate(PATH_LEVEL_3)
	if lvl == null or h == null:
		return
	var p := h.call("find_node_by_name_or_script", lvl, "Player", "player.gd") as Node2D
	var g := lvl.get_node_or_null("GroundLayer") as TileMapLayer
	assert_ne(p, null)
	assert_ne(g, null)
	if p != null and g != null:
		var cell := g.local_to_map(g.to_local(p.position + Vector2(0, 16)))
		var found := false
		for dy in range(0, 5):
			if g.get_cell_source_id(cell + Vector2i(0, dy)) != -1:
				found = true
				break
		assert_true(found, "level_3 Player spawn must sit over solid stone")


func test_b18_moving_platforms_valid_durations() -> void:
	var h := _get_helpers()
	var lvl := _require_and_instantiate(PATH_LEVEL_3)
	if lvl == null or h == null:
		return
	var mps: Array = h.call("collect_nodes_with_script_suffix", lvl, "moving_platform.gd")
	assert_gt(mps.size(), 0)
	for mp in mps:
		assert_gt(float(mp.get("duration")), 0.0)


func test_b18_level_3_camera_bounds_cover_flagpole() -> void:
	var h := _get_helpers()
	var lvl := _require_and_instantiate(PATH_LEVEL_3)
	if lvl == null or h == null:
		return
	var fp := h.call("find_node_by_name_or_script", lvl, "Flagpole", "flagpole.gd") as Node2D
	var lim_r := int(lvl.get("camera_limit_right")) if lvl.get("camera_limit_right") != null else 0
	assert_ne(fp, null)
	if fp != null:
		assert_true(fp.position.x <= float(lim_r), "level_3 Flagpole exceeds camera_limit_right")


func test_b18_level_3_next_scene_routes_to_end_screen() -> void:
	_assert_runtime_case("b18_level_3_next_scene_routes_to_end_screen")


# --- Feature #19 Boundaries ---

func test_b19_show_tip_empty_string_hides_or_safe() -> void:
	_assert_runtime_case("b19_show_tip_empty_string_hides_or_safe")


func test_b19_update_time_negative_clamps_zero() -> void:
	_assert_runtime_case("b19_update_time_negative_clamps_zero")


func test_b19_large_score_999999_fits_no_error() -> void:
	_assert_runtime_case("b19_large_score_999999_fits_no_error")


func test_b19_hud_top_strip_anchors_valid() -> void:
	var hud := _require_and_instantiate(PATH_HUD)
	if hud == null:
		return
	assert_true(hud is CanvasLayer or hud is Control)
	for n in _descendants(hud):
		if n is Control and (n as Control).size.x > 0:
			assert_true((n as Control).size.x <= 640.0)


func test_b19_hud_zero_lives_displays_0() -> void:
	_assert_runtime_case("b19_hud_zero_lives_displays_0")


# --- Feature #20 Boundaries ---

func test_b20_restart_unpauses_tree_before_switch() -> void:
	_assert_runtime_case("b20_restart_unpauses_tree_before_switch")


func test_b20_main_menu_unpauses_tree_before_switch() -> void:
	_assert_runtime_case("b20_main_menu_unpauses_tree_before_switch")


func test_b20_double_toggle_restores_initial_state() -> void:
	_assert_runtime_case("b20_double_toggle_restores_initial_state")


func test_b20_pause_menu_works_while_tree_paused() -> void:
	_assert_runtime_case("b20_pause_menu_works_while_tree_paused")


func test_b20_pause_menu_theme_arabic_applied() -> void:
	var pm := _require_and_instantiate(PATH_PAUSE_MENU)
	if pm == null:
		return
	assert_true(_uses_theme(pm, "res://assets/ui/arabic_theme.tres"))


# --- Feature #21 Boundaries ---

func test_b21_best_score_zero_displays_cleanly() -> void:
	_assert_runtime_case("b21_best_score_zero_displays_cleanly")


func test_b21_start_adventure_clears_stale_win_loss_flags() -> void:
	_assert_runtime_case("b21_start_adventure_clears_stale_win_loss_flags")


func test_b21_level_select_2_and_3_start_fresh_lives() -> void:
	_assert_runtime_case("b21_level_select_2_and_3_start_fresh_lives")


func test_b21_title_mute_consecutive_clicks() -> void:
	_assert_runtime_case("b21_title_mute_consecutive_clicks")


func test_b21_title_fits_640x360_viewport() -> void:
	var ts := _require_and_instantiate(PATH_MAIN)
	if ts == null:
		return
	assert_true(ts is Control)
	if ts is Control:
		var sz := (ts as Control).size
		assert_true(sz.x <= 640.0 and sz.y <= 360.0)


# --- Feature #22 Boundaries ---

func test_b22_end_screen_when_both_flags_false_safe() -> void:
	_assert_runtime_case("b22_end_screen_when_both_flags_false_safe")


func test_b22_zero_score_displays_zero() -> void:
	_assert_runtime_case("b22_zero_score_displays_zero")


func test_b22_play_again_clears_big_power_to_small() -> void:
	_assert_runtime_case("b22_play_again_clears_big_power_to_small")


func test_b22_best_score_preserved_across_game_over_and_replay() -> void:
	_assert_runtime_case("b22_best_score_preserved_across_game_over_and_replay")


func test_b22_end_screen_unpauses_if_entered_paused() -> void:
	_assert_runtime_case("b22_end_screen_unpauses_if_entered_paused")
