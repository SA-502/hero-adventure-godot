@tool
extends McpTestSuite

const HELPERS_PATH := "res://tests/helpers/e2e_test_helpers.gd"

const SCENE_MAIN := "res://scenes/main.tscn"
const SCENE_PLAYER := "res://scenes/player/player.tscn"
const SCENE_QBLOCK := "res://scenes/objects/question_block.tscn"
const SCENE_BRICK := "res://scenes/objects/brick_block.tscn"
const SCENE_COIN := "res://scenes/objects/coin.tscn"
const SCENE_MUSHROOM := "res://scenes/objects/mushroom.tscn"
const SCENE_PLATFORM := "res://scenes/objects/moving_platform.tscn"
const SCENE_FLAGPOLE := "res://scenes/objects/flagpole.tscn"
const SCENE_WALKER := "res://scenes/enemies/walker_enemy.tscn"
const SCENE_SHELL := "res://scenes/enemies/shell_enemy.tscn"
const SCENE_HUD := "res://scenes/ui/hud.tscn"
const SCENE_PAUSE := "res://scenes/ui/pause_menu.tscn"
const SCENE_END := "res://scenes/ui/end_screen.tscn"
const SCENE_LEVEL_1 := "res://scenes/levels/level_1.tscn"
const SCENE_LEVEL_2 := "res://scenes/levels/level_2.tscn"
const SCENE_LEVEL_3 := "res://scenes/levels/level_3.tscn"

var _helpers: Script = null
var _batch: Dictionary = {}


func suite_name() -> String:
	return "e2e_tier3_combinations"


func suite_setup(_ctx: Dictionary) -> void:
	_helpers = _load_helpers()
	if _helpers == null:
		fail_setup("Failed to load helpers script: " + HELPERS_PATH)
		return
	_batch = _helpers.call("run_headless_batch", "e2e_tier3_combinations")


func _load_helpers() -> Script:
	if _helpers != null:
		return _helpers
	var res := ResourceLoader.load(HELPERS_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	if res is Script:
		_helpers = res as Script
	return _helpers


func _get_helpers() -> Script:
	var h := _load_helpers()
	assert_ne(h, null, "E2E test helpers script must load cleanly")
	return h


func _assert_runtime_case(case_id: String) -> void:
	var h := _get_helpers()
	if h == null:
		return
	var res: Dictionary = h.call("get_case_result", _batch, case_id)
	assert_true(bool(res.get("passed", false)), str(res.get("detail", "Runtime case failed: " + case_id)))


func _assert_scenes_exist(paths: Array[String]) -> void:
	for p in paths:
		assert_true(ResourceLoader.exists(p), "Required scene/resource missing: " + p)


func test_c01_player_hits_question_block_coin_updates_gamestate() -> void:
	_assert_scenes_exist([SCENE_PLAYER, SCENE_QBLOCK])
	_assert_runtime_case("c01_question_block_coin")


func test_c02_player_hits_question_block_mushroom_spawns_grow() -> void:
	_assert_scenes_exist([SCENE_PLAYER, SCENE_QBLOCK, SCENE_MUSHROOM])
	_assert_runtime_case("c02_question_block_mushroom")


func test_c03_player_hits_question_block_one_up_spawns_green() -> void:
	_assert_scenes_exist([SCENE_PLAYER, SCENE_QBLOCK, SCENE_MUSHROOM])
	_assert_runtime_case("c03_question_block_one_up")


func test_c04_small_player_hits_brick_block_stays_intact() -> void:
	_assert_scenes_exist([SCENE_PLAYER, SCENE_BRICK])
	_assert_runtime_case("c04_small_player_brick")


func test_c05_big_player_hits_brick_block_shatters_and_scores() -> void:
	_assert_scenes_exist([SCENE_PLAYER, SCENE_BRICK])
	_assert_runtime_case("c05_big_player_brick")


func test_c06_player_collects_coin_updates_gamestate() -> void:
	_assert_scenes_exist([SCENE_PLAYER, SCENE_COIN])
	_assert_runtime_case("c06_player_collects_coin")


func test_c07_small_player_collects_grow_mushroom() -> void:
	_assert_scenes_exist([SCENE_PLAYER, SCENE_MUSHROOM])
	_assert_runtime_case("c07_player_collects_grow_mushroom")


func test_c08_player_collects_one_up_mushroom() -> void:
	_assert_scenes_exist([SCENE_PLAYER, SCENE_MUSHROOM])
	_assert_runtime_case("c08_player_collects_one_up")


func test_c09_question_block_bump_defeats_walker_above() -> void:
	_assert_scenes_exist([SCENE_PLAYER, SCENE_QBLOCK, SCENE_WALKER])
	_assert_runtime_case("c09_question_block_bumps_walker")


func test_c10_brick_block_bump_defeats_enemy_above() -> void:
	_assert_scenes_exist([SCENE_PLAYER, SCENE_BRICK, SCENE_WALKER])
	_assert_runtime_case("c10_brick_block_bumps_enemy")


func test_c11_player_stomps_walker_enemy() -> void:
	_assert_scenes_exist([SCENE_PLAYER, SCENE_WALKER])
	_assert_runtime_case("c11_player_stomps_walker")


func test_c12_walker_side_hit_shrinks_big_and_kills_small() -> void:
	_assert_scenes_exist([SCENE_PLAYER, SCENE_WALKER])
	_assert_runtime_case("c12_walker_side_hit")


func test_c13_player_stomps_then_kicks_shell_enemy() -> void:
	_assert_scenes_exist([SCENE_PLAYER, SCENE_SHELL])
	_assert_runtime_case("c13_stomp_then_kick_shell")


func test_c14_sliding_shell_kills_walker_chain() -> void:
	_assert_scenes_exist([SCENE_PLAYER, SCENE_SHELL, SCENE_WALKER])
	_assert_runtime_case("c14_sliding_shell_kills_walker")


func test_c15_sliding_shell_rebounds_off_world_wall() -> void:
	_assert_scenes_exist([SCENE_PLAYER, SCENE_SHELL])
	_assert_runtime_case("c15_sliding_shell_rebounds_wall")


func test_c16_player_rides_moving_platform() -> void:
	_assert_scenes_exist([SCENE_PLAYER, SCENE_PLATFORM])
	_assert_runtime_case("c16_player_rides_moving_platform")


func test_c17_player_flagpole_level_base_gamestate() -> void:
	_assert_scenes_exist([SCENE_LEVEL_1, SCENE_FLAGPOLE])
	_assert_runtime_case("c17_flagpole_level_base_gamestate")


func test_c18_fallzone_kills_big_player_and_updates_gamestate() -> void:
	_assert_scenes_exist([SCENE_LEVEL_1])
	_assert_runtime_case("c18_fallzone_kills_big")


func test_c19_hazard_zone_lava_kills_invuln_big_player() -> void:
	_assert_scenes_exist([SCENE_LEVEL_3])
	_assert_runtime_case("c19_hazard_zone_kills_invuln_big")


func test_c20_pause_menu_and_audiomanager_ducking() -> void:
	_assert_scenes_exist([SCENE_PAUSE])
	if ResourceLoader.exists(SCENE_PAUSE):
		var h := _get_helpers()
		if h != null:
			var pm: Node = h.call("instantiate_scene", SCENE_PAUSE)
			assert_ne(pm, null, "pause_menu.tscn must instantiate")
			if pm != null:
				track(pm)
				assert_eq(pm.process_mode, Node.PROCESS_MODE_ALWAYS, "PauseMenu must use PROCESS_MODE_ALWAYS")
	_assert_runtime_case("c20_pause_menu_ducking")


func test_c21_hud_reacts_to_gamestate_signals() -> void:
	_assert_scenes_exist([SCENE_HUD])
	_assert_runtime_case("c21_hud_gamestate_signals")


func test_c22_title_screen_and_gamestate_level_routing() -> void:
	_assert_scenes_exist([SCENE_MAIN, SCENE_LEVEL_1, SCENE_LEVEL_2])
	_assert_runtime_case("c22_title_screen_routing")


func test_c23_end_screen_and_gamestate_win_vs_loss() -> void:
	_assert_scenes_exist([SCENE_END])
	_assert_runtime_case("c23_end_screen_win_vs_loss")


func test_c24_level_base_selects_stage_bgm() -> void:
	_assert_scenes_exist([SCENE_LEVEL_1, SCENE_LEVEL_2, SCENE_LEVEL_3])
	_assert_runtime_case("c24_level_base_stage_bgm")


func test_c25_player_spawns_big_when_gamestate_is_big() -> void:
	_assert_scenes_exist([SCENE_LEVEL_2, SCENE_PLAYER])
	_assert_runtime_case("c25_player_spawns_big")
