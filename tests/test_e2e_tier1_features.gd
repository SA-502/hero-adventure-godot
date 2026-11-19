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

const SFX_KEYS := [
	"jump", "jump_big", "coin", "bump", "brick_break",
	"powerup_spawn", "powerup_collect", "stomp", "kick",
	"hurt", "one_up", "stage_clear", "game_over",
]

var _helpers: Script = null
var _batch: Dictionary = {}


func suite_name() -> String:
	return "e2e_tier1_features"


func suite_setup(_ctx: Dictionary) -> void:
	_helpers = _load_helpers()
	if _helpers == null:
		fail_setup("Failed to load helpers script: " + HELPERS_PATH)
		return
	_batch = _helpers.call("run_headless_batch", "e2e_tier1_features")


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


func _collect_texts(root: Node) -> Array[String]:
	var out: Array[String] = []
	if root is Label:
		out.append((root as Label).text)
	elif root is Button:
		out.append((root as Button).text)
	elif root is RichTextLabel:
		out.append((root as RichTextLabel).text)
	for c in root.get_children():
		out.append_array(_collect_texts(c))
	return out


func _uses_theme(root: Node, theme_path: String) -> bool:
	if root is Control and (root as Control).theme != null and (root as Control).theme.resource_path == theme_path:
		return true
	for c in root.get_children():
		if _uses_theme(c, theme_path):
			return true
	return false


func _has_texture_suffix(root: Node, suffix: String) -> bool:
	for n in _descendants(root):
		if n is Sprite2D and (n as Sprite2D).texture != null and (n as Sprite2D).texture.resource_path.ends_with(suffix):
			return true
		if n is TextureRect and (n as TextureRect).texture != null and (n as TextureRect).texture.resource_path.ends_with(suffix):
			return true
	return false


func _tilemap_has_atlas_coords(tml: TileMapLayer, targets: Array) -> bool:
	for cell in tml.get_used_cells():
		var ac := tml.get_cell_atlas_coords(cell)
		if targets.has(ac):
			return true
	return false


# --- Feature #1: project.godot Autoloads & Stretch ---

func test_f01_autoload_gamestate_enabled() -> void:
	var val := str(ProjectSettings.get_setting("autoload/GameState", ""))
	assert_true(val.begins_with("*"), "GameState autoload must be enabled (*)")
	assert_contains(val, "res://scripts/autoload/game_state.gd")


func test_f01_autoload_audiomanager_enabled() -> void:
	var val := str(ProjectSettings.get_setting("autoload/AudioManager", ""))
	assert_true(val.begins_with("*"), "AudioManager autoload must be enabled (*)")
	assert_contains(val, "res://scripts/autoload/audio_manager.gd")


func test_f01_viewport_640x360_2x_window() -> void:
	assert_eq(int(ProjectSettings.get_setting("display/window/size/viewport_width", 0)), 640)
	assert_eq(int(ProjectSettings.get_setting("display/window/size/viewport_height", 0)), 360)
	assert_eq(int(ProjectSettings.get_setting("display/window/size/window_width_override", 0)), 1280)
	assert_eq(int(ProjectSettings.get_setting("display/window/size/window_height_override", 0)), 720)


func test_f01_stretch_canvas_items_keep_nearest() -> void:
	assert_eq(str(ProjectSettings.get_setting("display/window/stretch/mode", "")), "canvas_items")
	assert_eq(str(ProjectSettings.get_setting("display/window/stretch/aspect", "")), "keep")
	assert_eq(int(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter", -1)), 0)


func test_f01_five_physics_layers_and_five_inputs() -> void:
	var expected_layers := ["World", "Player", "Enemies", "Items", "Hazards"]
	for i in range(5):
		assert_eq(str(ProjectSettings.get_setting("layer_names/2d_physics/layer_%d" % (i + 1), "")), expected_layers[i])
	for act in ["move_left", "move_right", "jump", "sprint", "pause"]:
		if not Engine.is_editor_hint() and InputMap.has_action(act):
			assert_true(InputMap.has_action(act), "Missing action: " + act)
			assert_gt(InputMap.action_get_events(act).size(), 0, "Empty events for action: " + act)
		else:
			assert_true(ProjectSettings.has_setting("input/" + act), "Missing action: " + act)
			var cfg: Variant = ProjectSettings.get_setting("input/" + act, {})
			var evs: Array = Array((cfg as Dictionary).get("events", [])) if cfg is Dictionary else []
			assert_gt(evs.size(), 0, "Empty events for action: " + act)


# --- Feature #2: Legacy Prototype Removal ---

func test_f02_legacy_main_gd_absent() -> void:
	assert_false(FileAccess.file_exists("res://scripts/main.gd"))
	assert_false(FileAccess.file_exists("res://scripts/main.gd.uid"))


func test_f02_legacy_player_gd_absent() -> void:
	assert_false(FileAccess.file_exists("res://scripts/player.gd"))
	assert_false(FileAccess.file_exists("res://scripts/player.gd.uid"))


func test_f02_main_tscn_not_prototype_script() -> void:
	var root := _require_and_instantiate(PATH_MAIN)
	if root == null:
		return
	assert_true(root is Control, "main.tscn root must be Control")
	var scr: Variant = root.get_script()
	assert_ne(scr, null, "main.tscn must have title_screen script")
	if scr is Script:
		assert_contains((scr as Script).resource_path, "title_screen.gd")


func test_f02_main_tscn_no_legacy_coin_rect() -> void:
	var root := _require_and_instantiate(PATH_MAIN)
	if root == null:
		return
	var joined := " | ".join(_collect_texts(root))
	assert_eq(joined.find("Collect the yellow coins!"), -1)
	assert_eq(joined.find("Score: 0"), -1)


func test_f02_run_main_scene_valid() -> void:
	assert_eq(str(ProjectSettings.get_setting("application/run/main_scene", "")), PATH_MAIN)
	_assert_runtime_case("f02_run_main_scene_valid")


# --- Feature #3: GameState Autoload ---

func test_f03_defaults_and_power_enum() -> void:
	var h := _get_helpers()
	if h == null:
		return
	assert_true(ResourceLoader.exists("res://scripts/autoload/game_state.gd"))
	var scr: Resource = h.call("load_resource_ignore_cache", "res://scripts/autoload/game_state.gd")
	assert_true(scr is Script)
	if scr is Script:
		var cmap: Dictionary = (scr as Script).get_script_constant_map()
		assert_has_key(cmap, "PowerState")
	_assert_runtime_case("f03_defaults_and_power_enum")


func test_f03_add_score_updates_best_and_signal() -> void:
	_assert_runtime_case("f03_add_score_updates_best_and_signal")


func test_f03_add_coin_increments_and_emits() -> void:
	_assert_runtime_case("f03_add_coin_increments_and_emits")


func test_f03_add_life_and_lose_life() -> void:
	_assert_runtime_case("f03_add_life_and_lose_life")


func test_f03_set_power_level_victory_gameover() -> void:
	_assert_runtime_case("f03_set_power_level_victory_gameover")


# --- Feature #4: AudioManager Autoload ---

func test_f04_all_13_sfx_wavs_valid() -> void:
	var h := _get_helpers()
	if h == null:
		return
	for k in SFX_KEYS:
		var p := "res://assets/audio/%s.wav" % k
		assert_true(ResourceLoader.exists(p), "Missing WAV: " + p)
		var res: Resource = h.call("load_resource_ignore_cache", p)
		assert_true(res is AudioStreamWAV, "Expected AudioStreamWAV: " + p)
	_assert_runtime_case("f04_all_13_sfx_wavs_valid")


func test_f04_bgm_overworld_and_castle_play() -> void:
	var h := _get_helpers()
	if h == null:
		return
	for b in ["bgm_overworld", "bgm_castle"]:
		var p := "res://assets/audio/%s.wav" % b
		assert_true(ResourceLoader.exists(p))
		var res: Resource = h.call("load_resource_ignore_cache", p)
		assert_true(res is AudioStreamWAV)
		if res is AudioStreamWAV:
			assert_eq((res as AudioStreamWAV).loop_mode, AudioStreamWAV.LOOP_FORWARD)
	_assert_runtime_case("f04_bgm_overworld_and_castle_play")


func test_f04_mute_toggle_and_set_muted() -> void:
	_assert_runtime_case("f04_mute_toggle_and_set_muted")


func test_f04_pause_ducking_state() -> void:
	_assert_runtime_case("f04_pause_ducking_state")


func test_f04_concurrent_sfx_pool() -> void:
	_assert_runtime_case("f04_concurrent_sfx_pool")


# --- Feature #5: Player Scene & Physics ---

func test_f05_scene_structure_and_layers() -> void:
	var p := _require_and_instantiate(PATH_PLAYER)
	if p == null:
		return
	assert_true(p is CharacterBody2D, "Player root must be CharacterBody2D")
	assert_true(p.is_in_group("player"), "Player must be in group 'player'")
	if p is CollisionObject2D:
		assert_eq((p as CollisionObject2D).collision_layer, 2)
		assert_eq((p as CollisionObject2D).collision_mask, 1)
	assert_ne(p.get_node_or_null("AnimatedSprite2D"), null)
	assert_ne(p.get_node_or_null("CollisionShape2D"), null)
	assert_ne(p.get_node_or_null("Camera2D"), null)
	var hb := p.get_node_or_null("Hitbox")
	assert_true(hb is Area2D, "Player must have Hitbox Area2D")
	assert_ne(p.get_node_or_null("HeadChecker"), null)


func test_f05_horizontal_accel_and_sprint() -> void:
	_assert_runtime_case("f05_horizontal_accel_and_sprint")


func test_f05_jump_and_variable_cut() -> void:
	_assert_runtime_case("f05_jump_and_variable_cut")


func test_f05_coyote_time_010s() -> void:
	_assert_runtime_case("f05_coyote_time_010s")


func test_f05_jump_buffer_012s_and_anims() -> void:
	var p := _require_and_instantiate(PATH_PLAYER)
	if p == null:
		return
	var spr := p.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	assert_ne(spr, null)
	if spr != null and spr.sprite_frames != null:
		assert_eq(spr.sprite_frames.resource_path, "res://assets/sprites/player_small_frames.tres")
		for anim_name in [&"idle", &"run", &"jump", &"hurt"]:
			assert_true(spr.sprite_frames.has_animation(anim_name))
	_assert_runtime_case("f05_jump_buffer_012s_and_anims")


# --- Feature #6: Player State Machine ---

func test_f06_collect_powerup_small_to_big() -> void:
	_assert_runtime_case("f06_collect_powerup_small_to_big")


func test_f06_damage_big_to_small_with_invuln() -> void:
	_assert_runtime_case("f06_damage_big_to_small_with_invuln")


func test_f06_damage_small_triggers_death() -> void:
	_assert_runtime_case("f06_damage_small_triggers_death")


func test_f06_flagpole_slide_and_clear() -> void:
	_assert_runtime_case("f06_flagpole_slide_and_clear")


func test_f06_invuln_duration_expires() -> void:
	_assert_runtime_case("f06_invuln_duration_expires")


# --- Feature #7: QuestionBlock ---

func test_f07_scene_structure_and_frames() -> void:
	var qb := _require_and_instantiate(PATH_QUESTION_BLOCK)
	if qb == null:
		return
	assert_true(qb is StaticBody2D)
	assert_eq((qb as StaticBody2D).collision_layer, 1)
	var spr := qb.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	assert_ne(spr, null)
	if spr != null and spr.sprite_frames != null:
		assert_eq(spr.sprite_frames.resource_path, "res://assets/sprites/question_block_frames.tres")
		assert_eq(spr.animation, &"active")


func test_f07_hit_coin_reward() -> void:
	_assert_runtime_case("f07_hit_coin_reward")


func test_f07_hit_mushroom_reward() -> void:
	_assert_runtime_case("f07_hit_mushroom_reward")


func test_f07_hit_one_up_reward() -> void:
	_assert_runtime_case("f07_hit_one_up_reward")


func test_f07_bumps_enemy_standing_above() -> void:
	_assert_runtime_case("f07_bumps_enemy_standing_above")


# --- Feature #8: BrickBlock ---

func test_f08_scene_structure_and_texture() -> void:
	var bb := _require_and_instantiate(PATH_BRICK_BLOCK)
	if bb == null:
		return
	assert_true(bb is StaticBody2D)
	assert_eq((bb as StaticBody2D).collision_layer, 1)
	assert_true(_has_texture_suffix(bb, "brick_block.png"), "BrickBlock must use brick_block.png")


func test_f08_small_player_bounces_intact() -> void:
	_assert_runtime_case("f08_small_player_bounces_intact")


func test_f08_big_player_shatters_and_scores() -> void:
	_assert_runtime_case("f08_big_player_shatters_and_scores")


func test_f08_bumps_enemy_above_when_small() -> void:
	_assert_runtime_case("f08_bumps_enemy_above_when_small")


func test_f08_bumps_enemy_above_when_big() -> void:
	_assert_runtime_case("f08_bumps_enemy_above_when_big")


# --- Feature #9: Coin ---

func test_f09_scene_structure_and_layers() -> void:
	var c := _require_and_instantiate(PATH_COIN)
	if c == null:
		return
	assert_true(c is Area2D)
	if c is Area2D:
		assert_eq((c as Area2D).collision_layer, 8)
		assert_eq((c as Area2D).collision_mask, 2)
	var spr := c.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	assert_ne(spr, null)
	if spr != null and spr.sprite_frames != null:
		assert_eq(spr.sprite_frames.resource_path, "res://assets/sprites/coin_frames.tres")
		assert_eq(spr.animation, &"spin")


func test_f09_pickup_adds_coin_and_score() -> void:
	_assert_runtime_case("f09_pickup_adds_coin_and_score")


func test_f09_pickup_frees_coin_node() -> void:
	_assert_runtime_case("f09_pickup_frees_coin_node")


func test_f09_pickup_spawns_star_particle() -> void:
	_assert_runtime_case("f09_pickup_spawns_star_particle")


func test_f09_non_player_body_ignored() -> void:
	_assert_runtime_case("f09_non_player_body_ignored")


# --- Feature #10: Mushroom ---

func test_f10_scene_structure_and_layers() -> void:
	var m := _require_and_instantiate(PATH_MUSHROOM)
	if m == null:
		return
	assert_true(m is CharacterBody2D)
	if m is CharacterBody2D:
		assert_eq((m as CharacterBody2D).collision_layer, 8)
		assert_eq((m as CharacterBody2D).collision_mask, 1)
	var pa := m.get_node_or_null("PickupArea")
	assert_true(pa is Area2D, "Mushroom must have PickupArea Area2D")
	if pa is Area2D:
		assert_eq((pa as Area2D).collision_layer, 8)
		assert_eq((pa as Area2D).collision_mask, 2)
	assert_true(_has_texture_suffix(m, "mushroom.png"))


func test_f10_grow_vs_one_up_sprite_region() -> void:
	_assert_runtime_case("f10_grow_vs_one_up_sprite_region")


func test_f10_horizontal_patrol_and_gravity() -> void:
	_assert_runtime_case("f10_horizontal_patrol_and_gravity")


func test_f10_wall_bounce_reverses_direction() -> void:
	_assert_runtime_case("f10_wall_bounce_reverses_direction")


func test_f10_pickup_grow_and_one_up_effects() -> void:
	_assert_runtime_case("f10_pickup_grow_and_one_up_effects")


# --- Feature #11: MovingPlatform ---

func test_f11_scene_structure_and_sync() -> void:
	var mp := _require_and_instantiate(PATH_MOVING_PLATFORM)
	if mp == null:
		return
	assert_true(mp is AnimatableBody2D)
	if mp is AnimatableBody2D:
		assert_eq((mp as AnimatableBody2D).collision_layer, 1)
		assert_true((mp as AnimatableBody2D).sync_to_physics)
	assert_ne(mp.get("move_offset"), null)
	assert_ne(mp.get("duration"), null)


func test_f11_cyclic_motion_toward_offset() -> void:
	_assert_runtime_case("f11_cyclic_motion_toward_offset")


func test_f11_ping_pong_returns_to_origin() -> void:
	_assert_runtime_case("f11_ping_pong_returns_to_origin")


func test_f11_carries_player_horizontally() -> void:
	_assert_runtime_case("f11_carries_player_horizontally")


func test_f11_carries_player_vertically() -> void:
	_assert_runtime_case("f11_carries_player_vertically")


# --- Feature #12: Flagpole ---

func test_f12_scene_structure_and_assets() -> void:
	var fp := _require_and_instantiate(PATH_FLAGPOLE)
	if fp == null:
		return
	assert_true(fp is Area2D)
	if fp is Area2D:
		assert_eq((fp as Area2D).collision_layer, 16)
		assert_eq((fp as Area2D).collision_mask, 2)
	assert_true(_has_texture_suffix(fp, "flag_pole.png"))
	assert_true(_has_texture_suffix(fp, "flag_banner.png"))
	var h := _get_helpers()
	var scr: Variant = fp.get_script()
	assert_true(scr is Script and bool(h.call("script_has_signal", scr, "level_cleared")))


func test_f12_player_touch_emits_level_cleared() -> void:
	_assert_runtime_case("f12_player_touch_emits_level_cleared")


func test_f12_stops_level_timer() -> void:
	_assert_runtime_case("f12_stops_level_timer")


func test_f12_slides_banner_down() -> void:
	_assert_runtime_case("f12_slides_banner_down")


func test_f12_awards_time_bonus_to_score() -> void:
	_assert_runtime_case("f12_awards_time_bonus_to_score")


# --- Feature #13: WalkerEnemy ---

func test_f13_scene_structure_and_frames() -> void:
	var w := _require_and_instantiate(PATH_WALKER)
	if w == null:
		return
	assert_true(w is CharacterBody2D)
	assert_true(w.is_in_group("enemies"))
	if w is CharacterBody2D:
		assert_eq((w as CharacterBody2D).collision_layer, 4)
		assert_eq((w as CharacterBody2D).collision_mask, 1)
	var hb := w.get_node_or_null("Hitbox")
	assert_true(hb is Area2D)
	if hb is Area2D:
		assert_eq((hb as Area2D).collision_layer, 4)
		assert_eq((hb as Area2D).collision_mask, 6)
	var spr := w.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	assert_ne(spr, null)
	if spr != null and spr.sprite_frames != null:
		assert_eq(spr.sprite_frames.resource_path, "res://assets/sprites/enemy_walker_frames.tres")
		assert_true(spr.sprite_frames.has_animation(&"walk"))
		assert_true(spr.sprite_frames.has_animation(&"squished"))


func test_f13_patrol_and_wall_reverse() -> void:
	_assert_runtime_case("f13_patrol_and_wall_reverse")


func test_f13_stomp_from_above() -> void:
	_assert_runtime_case("f13_stomp_from_above")


func test_f13_side_contact_hurts_player() -> void:
	_assert_runtime_case("f13_side_contact_hurts_player")


func test_f13_block_bump_and_shell_kill() -> void:
	_assert_runtime_case("f13_block_bump_and_shell_kill")


# --- Feature #14: ShellEnemy ---

func test_f14_scene_structure_and_frames() -> void:
	var sh := _require_and_instantiate(PATH_SHELL)
	if sh == null:
		return
	assert_true(sh is CharacterBody2D)
	assert_true(sh.is_in_group("enemies"))
	if sh is CharacterBody2D:
		assert_eq((sh as CharacterBody2D).collision_layer, 4)
		assert_eq((sh as CharacterBody2D).collision_mask, 1)
	var spr := sh.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	assert_ne(spr, null)
	if spr != null and spr.sprite_frames != null:
		assert_eq(spr.sprite_frames.resource_path, "res://assets/sprites/enemy_shell_frames.tres")
		assert_true(spr.sprite_frames.has_animation(&"walk"))
		assert_true(spr.sprite_frames.has_animation(&"shell"))
	var h := _get_helpers()
	var scr: Variant = sh.get_script()
	assert_true(scr is Script and bool(h.call("script_has_method", scr, "is_sliding")))
	assert_true(scr is Script and bool(h.call("script_has_method", scr, "is_shell_idle")))


func test_f14_first_stomp_enters_shell_idle() -> void:
	_assert_runtime_case("f14_first_stomp_enters_shell_idle")


func test_f14_second_stomp_or_kick_slides() -> void:
	_assert_runtime_case("f14_second_stomp_or_kick_slides")


func test_f14_sliding_shell_wall_rebound() -> void:
	_assert_runtime_case("f14_sliding_shell_wall_rebound")


func test_f14_sliding_shell_defeats_other_enemy() -> void:
	_assert_runtime_case("f14_sliding_shell_defeats_other_enemy")


# --- Feature #15: LevelBase ---

func test_f15_camera_limits_applied() -> void:
	_assert_runtime_case("f15_camera_limits_applied")


func test_f15_countdown_ticks_180s_and_updates_hud() -> void:
	_assert_runtime_case("f15_countdown_ticks_180s_and_updates_hud")


func test_f15_fallzone_kills_player() -> void:
	_assert_runtime_case("f15_fallzone_kills_player")


func test_f15_pause_action_toggles_pause_menu() -> void:
	_assert_runtime_case("f15_pause_action_toggles_pause_menu")


func test_f15_stage_bgm_and_level1_tip() -> void:
	_assert_runtime_case("f15_stage_bgm_and_level1_tip")


# --- Feature #16: Level 1-1 ---

func test_f16_tilemap_and_width_approx_3200() -> void:
	var lvl := _require_and_instantiate(PATH_LEVEL_1)
	if lvl == null:
		return
	var g := lvl.get_node_or_null("GroundLayer") as TileMapLayer
	assert_ne(g, null)
	if g != null:
		assert_ne(g.tile_set, null)
		if g.tile_set != null:
			assert_eq(g.tile_set.resource_path, "res://assets/tilesets/world_tileset.tres")
		assert_true(_tilemap_has_atlas_coords(g, [Vector2i(0, 0), Vector2i(1, 0)]))
	var lim: Variant = lvl.get("camera_limit_right")
	if lim != null:
		assert_gt(int(lim), 2999)


func test_f16_parallax_clouds_and_bushes() -> void:
	var lvl := _require_and_instantiate(PATH_LEVEL_1)
	if lvl == null:
		return
	assert_true(_has_texture_suffix(lvl, "bg_cloud.png"), "level_1 missing bg_cloud.png")
	assert_true(_has_texture_suffix(lvl, "bg_bush.png"), "level_1 missing bg_bush.png")


func test_f16_question_and_brick_blocks_present() -> void:
	var h := _get_helpers()
	var lvl := _require_and_instantiate(PATH_LEVEL_1)
	if lvl == null or h == null:
		return
	var qbs: Array = h.call("collect_nodes_with_script_suffix", lvl, "question_block.gd")
	var bbs: Array = h.call("collect_nodes_with_script_suffix", lvl, "brick_block.gd")
	assert_gt(qbs.size(), 1, "level_1 must have >=2 QuestionBlocks")
	assert_gt(bbs.size(), 1, "level_1 must have >=2 BrickBlocks")


func test_f16_coins_and_walker_enemies_present() -> void:
	var h := _get_helpers()
	var lvl := _require_and_instantiate(PATH_LEVEL_1)
	if lvl == null or h == null:
		return
	var coins: Array = h.call("collect_nodes_with_script_suffix", lvl, "coin.gd")
	var walkers: Array = h.call("collect_nodes_with_script_suffix", lvl, "walker_enemy.gd")
	assert_gt(coins.size(), 0, "level_1 must have Coins")
	assert_gt(walkers.size(), 1, "level_1 must have >=2 WalkerEnemies")


func test_f16_flagpole_castle_and_next_level() -> void:
	var h := _get_helpers()
	var lvl := _require_and_instantiate(PATH_LEVEL_1)
	if lvl == null or h == null:
		return
	assert_ne(h.call("find_node_by_name_or_script", lvl, "Flagpole", "flagpole.gd"), null)
	assert_true(_has_texture_suffix(lvl, "castle.png"), "level_1 missing castle.png")
	assert_ne(h.call("find_node_by_name_or_script", lvl, "FallZone", ""), null)
	assert_eq(str(lvl.get("next_scene_path")), PATH_LEVEL_2)


# --- Feature #17: Level 1-2 ---

func test_f17_sunset_tiles_and_gaps() -> void:
	var lvl := _require_and_instantiate(PATH_LEVEL_2)
	if lvl == null:
		return
	var g := lvl.get_node_or_null("GroundLayer") as TileMapLayer
	assert_ne(g, null)
	if g != null:
		assert_true(_tilemap_has_atlas_coords(g, [Vector2i(2, 1), Vector2i(3, 1)]), "level_2 must use sunset tiles (2,1)/(3,1)")


func test_f17_moving_platforms_present() -> void:
	var h := _get_helpers()
	var lvl := _require_and_instantiate(PATH_LEVEL_2)
	if lvl == null or h == null:
		return
	var mps: Array = h.call("collect_nodes_with_script_suffix", lvl, "moving_platform.gd")
	assert_gt(mps.size(), 1, "level_2 must have >=2 MovingPlatforms")


func test_f17_walker_and_shell_enemies_present() -> void:
	var h := _get_helpers()
	var lvl := _require_and_instantiate(PATH_LEVEL_2)
	if lvl == null or h == null:
		return
	var walkers: Array = h.call("collect_nodes_with_script_suffix", lvl, "walker_enemy.gd")
	var shells: Array = h.call("collect_nodes_with_script_suffix", lvl, "shell_enemy.gd")
	assert_gt(walkers.size(), 0)
	assert_gt(shells.size(), 0)


func test_f17_secret_one_up_reward_present() -> void:
	var h := _get_helpers()
	var lvl := _require_and_instantiate(PATH_LEVEL_2)
	if lvl == null or h == null:
		return
	var found := false
	for qb in h.call("collect_nodes_with_script_suffix", lvl, "question_block.gd"):
		var rt: Variant = qb.get("reward_type")
		if str(rt) == "ONE_UP" or (rt is int and int(rt) == 2):
			found = true
	for m in h.call("collect_nodes_with_script_suffix", lvl, "mushroom.gd"):
		var mt: Variant = m.get("mushroom_type")
		if str(mt) == "ONE_UP" or (mt is int and int(mt) == 1):
			found = true
	assert_true(found, "level_2 must contain secret ONE_UP reward")


func test_f17_flagpole_castle_and_next_level() -> void:
	var h := _get_helpers()
	var lvl := _require_and_instantiate(PATH_LEVEL_2)
	if lvl == null or h == null:
		return
	assert_ne(h.call("find_node_by_name_or_script", lvl, "Flagpole", "flagpole.gd"), null)
	assert_true(_has_texture_suffix(lvl, "castle.png"))
	assert_eq(str(lvl.get("next_scene_path")), PATH_LEVEL_3)


# --- Feature #18: Level 1-3 ---

func test_f18_castle_stone_and_bridge_tiles() -> void:
	var lvl := _require_and_instantiate(PATH_LEVEL_3)
	if lvl == null:
		return
	var g := lvl.get_node_or_null("GroundLayer") as TileMapLayer
	assert_ne(g, null)
	if g != null:
		assert_true(_tilemap_has_atlas_coords(g, [Vector2i(3, 0), Vector2i(4, 0)]), "level_3 must use stone/bridge tiles (3,0)/(4,0)")


func test_f18_lava_tiles_covered_by_hazard_zone() -> void:
	var lvl := _require_and_instantiate(PATH_LEVEL_3)
	if lvl == null:
		return
	var g := lvl.get_node_or_null("GroundLayer") as TileMapLayer
	assert_ne(g, null)
	if g != null:
		assert_true(_tilemap_has_atlas_coords(g, [Vector2i(0, 1), Vector2i(1, 1)]), "level_3 must have lava tiles (0,1)/(1,1)")
	var hz_found := false
	for n in _descendants(lvl):
		if n is Area2D and String(n.name).begins_with("HazardZone"):
			hz_found = true
			assert_eq((n as Area2D).collision_layer, 16)
			assert_eq((n as Area2D).collision_mask, 2)
	assert_true(hz_found, "level_3 must have HazardZone")


func test_f18_castle_bgm_configured() -> void:
	var lvl := _require_and_instantiate(PATH_LEVEL_3)
	if lvl == null:
		return
	assert_eq(str(lvl.get("bgm_track")), "castle")
	_assert_runtime_case("f18_castle_bgm_configured")


func test_f18_moving_platforms_and_mixed_enemies() -> void:
	var h := _get_helpers()
	var lvl := _require_and_instantiate(PATH_LEVEL_3)
	if lvl == null or h == null:
		return
	assert_gt((h.call("collect_nodes_with_script_suffix", lvl, "moving_platform.gd") as Array).size(), 0)
	assert_gt((h.call("collect_nodes_with_script_suffix", lvl, "walker_enemy.gd") as Array).size(), 0)
	assert_gt((h.call("collect_nodes_with_script_suffix", lvl, "shell_enemy.gd") as Array).size(), 0)
	assert_gt((h.call("collect_nodes_with_script_suffix", lvl, "question_block.gd") as Array).size(), 0)


func test_f18_final_flagpole_routes_to_end_screen() -> void:
	_assert_runtime_case("f18_final_flagpole_routes_to_end_screen")


# --- Feature #19: HUD ---

func test_f19_scene_theme_and_arabic_labels() -> void:
	var hud := _require_and_instantiate(PATH_HUD)
	if hud == null:
		return
	assert_true(_uses_theme(hud, "res://assets/ui/arabic_theme.tres"))
	var joined := " | ".join(_collect_texts(hud))
	for word in ["النقاط", "العملات", "المحاولات", "المرحلة", "الوقت"]:
		assert_contains(joined, word)


func test_f19_updates_on_gamestate_signals() -> void:
	_assert_runtime_case("f19_updates_on_gamestate_signals")


func test_f19_update_time_formats_seconds() -> void:
	_assert_runtime_case("f19_update_time_formats_seconds")


func test_f19_show_tip_displays_arabic_banner() -> void:
	_assert_runtime_case("f19_show_tip_displays_arabic_banner")


func test_f19_pause_button_emits_and_fits_640x360() -> void:
	var hud := _require_and_instantiate(PATH_HUD)
	if hud == null:
		return
	for n in _descendants(hud):
		if n is Control and (n as Control).size.x > 0:
			assert_true((n as Control).size.x <= 640.0, "HUD control exceeds 640px width")
	_assert_runtime_case("f19_pause_button_emits_and_fits_640x360")


# --- Feature #20: PauseMenu ---

func test_f20_process_mode_always_and_hidden_init() -> void:
	var pm := _require_and_instantiate(PATH_PAUSE_MENU)
	if pm == null:
		return
	assert_eq(pm.process_mode, Node.PROCESS_MODE_ALWAYS)
	_assert_runtime_case("f20_process_mode_always_and_hidden_init")


func test_f20_toggle_pause_pauses_and_ducks() -> void:
	_assert_runtime_case("f20_toggle_pause_pauses_and_ducks")


func test_f20_resume_unpauses_and_unducks() -> void:
	_assert_runtime_case("f20_resume_unpauses_and_unducks")


func test_f20_arabic_four_buttons_present() -> void:
	var pm := _require_and_instantiate(PATH_PAUSE_MENU)
	if pm == null:
		return
	var joined := " | ".join(_collect_texts(pm))
	assert_contains(joined, "استئناف")
	assert_contains(joined, "إعادة المرحلة")
	assert_contains(joined, "القائمة الرئيسية")
	assert_true(joined.find("الصوت") != -1 or joined.find("كتم") != -1)


func test_f20_mute_button_toggles_audiomanager() -> void:
	_assert_runtime_case("f20_mute_button_toggles_audiomanager")


# --- Feature #21: Title Screen ---

func test_f21_arabic_title_and_theme() -> void:
	var ts := _require_and_instantiate(PATH_MAIN)
	if ts == null:
		return
	assert_true(_uses_theme(ts, "res://assets/ui/arabic_theme.tres"))
	var joined := " | ".join(_collect_texts(ts))
	assert_contains(joined, "ابدأ المغامرة")


func test_f21_start_adventure_launches_level_1() -> void:
	_assert_runtime_case("f21_start_adventure_launches_level_1")


func test_f21_level_select_buttons_1_2_3() -> void:
	var ts := _require_and_instantiate(PATH_MAIN)
	if ts == null:
		return
	var joined := " | ".join(_collect_texts(ts))
	assert_contains(joined, "1-1")
	assert_contains(joined, "1-2")
	assert_contains(joined, "1-3")
	_assert_runtime_case("f21_level_select_buttons_1_2_3")


func test_f21_displays_best_score() -> void:
	_assert_runtime_case("f21_displays_best_score")


func test_f21_mute_toggle_and_pixel_scenery() -> void:
	var ts := _require_and_instantiate(PATH_MAIN)
	if ts == null:
		return
	var joined := " | ".join(_collect_texts(ts))
	assert_true(joined.find("الصوت") != -1 or joined.find("كتم") != -1)
	_assert_runtime_case("f21_mute_toggle_and_pixel_scenery")


# --- Feature #22: EndScreen ---

func test_f22_win_state_arabic_heading() -> void:
	_assert_runtime_case("f22_win_state_arabic_heading")


func test_f22_loss_state_arabic_heading_and_sfx() -> void:
	_assert_runtime_case("f22_loss_state_arabic_heading_and_sfx")


func test_f22_displays_final_and_best_scores() -> void:
	_assert_runtime_case("f22_displays_final_and_best_scores")


func test_f22_play_again_button_resets_and_restarts() -> void:
	var es := _require_and_instantiate(PATH_END_SCREEN)
	if es == null:
		return
	var joined := " | ".join(_collect_texts(es))
	assert_contains(joined, "إعادة اللعب")
	_assert_runtime_case("f22_play_again_button_resets_and_restarts")


func test_f22_main_menu_button_returns_to_title() -> void:
	var es := _require_and_instantiate(PATH_END_SCREEN)
	if es == null:
		return
	var joined := " | ".join(_collect_texts(es))
	assert_contains(joined, "القائمة الرئيسية")
	_assert_runtime_case("f22_main_menu_button_returns_to_title")
