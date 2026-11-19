@tool
extends McpTestSuite

const HELPERS_PATH := "res://tests/helpers/e2e_test_helpers.gd"

const SCENE_MAIN := "res://scenes/main.tscn"
const SCENE_PLAYER := "res://scenes/player/player.tscn"
const SCENE_BRICK := "res://scenes/objects/brick_block.tscn"
const SCENE_WALKER := "res://scenes/enemies/walker_enemy.tscn"
const SCENE_SHELL := "res://scenes/enemies/shell_enemy.tscn"
const SCENE_END := "res://scenes/ui/end_screen.tscn"
const SCENE_LEVEL_1 := "res://scenes/levels/level_1.tscn"
const SCENE_LEVEL_2 := "res://scenes/levels/level_2.tscn"
const SCENE_LEVEL_3 := "res://scenes/levels/level_3.tscn"

var _helpers: Script = null
var _batch: Dictionary = {}


func suite_name() -> String:
	return "e2e_tier4_scenarios"


func suite_setup(_ctx: Dictionary) -> void:
	_helpers = _load_helpers()
	if _helpers == null:
		fail_setup("Failed to load helpers script: " + HELPERS_PATH)
		return
	_batch = _helpers.call("run_headless_batch", "e2e_tier4_scenarios")


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


func test_s01_title_to_level_1_onboarding_flow() -> void:
	_assert_scenes_exist([SCENE_MAIN, SCENE_LEVEL_1])
	_assert_runtime_case("s01_title_to_level_1")


func test_s02_level_1_playthrough_blocks_enemies_flagpole() -> void:
	_assert_scenes_exist([SCENE_LEVEL_1, SCENE_LEVEL_2])
	_assert_runtime_case("s02_level_1_playthrough")


func test_s03_hundred_coin_rollover_mid_level() -> void:
	_assert_scenes_exist([SCENE_LEVEL_1])
	_assert_runtime_case("s03_hundred_coin_rollover")


func test_s04_big_mario_retention_across_level_1_to_2() -> void:
	_assert_scenes_exist([SCENE_LEVEL_1, SCENE_LEVEL_2])
	_assert_runtime_case("s04_big_mario_retention")


func test_s05_damage_shrink_invuln_window_then_death() -> void:
	_assert_scenes_exist([SCENE_PLAYER, SCENE_WALKER])
	_assert_runtime_case("s05_damage_shrink_invuln_death")


func test_s06_level_2_moving_platform_and_hidden_1up() -> void:
	_assert_scenes_exist([SCENE_LEVEL_2])
	_assert_runtime_case("s06_level_2_platform_and_1up")


func test_s07_level_2_shell_kick_multi_kill_and_rebound() -> void:
	_assert_scenes_exist([SCENE_PLAYER, SCENE_SHELL, SCENE_WALKER])
	_assert_runtime_case("s07_level_2_shell_multi_kill")


func test_s08_level_3_lava_hazard_lethal_when_big() -> void:
	_assert_scenes_exist([SCENE_LEVEL_3])
	_assert_runtime_case("s08_level_3_lava_lethal_big")


func test_s09_level_3_castle_bgm_clear_to_victory_screen() -> void:
	_assert_scenes_exist([SCENE_LEVEL_3, SCENE_END])
	_assert_runtime_case("s09_level_3_castle_to_victory")


func test_s10_pause_then_restart_restores_clean_state() -> void:
	_assert_scenes_exist([SCENE_LEVEL_1])
	_assert_runtime_case("s10_pause_then_restart")


func test_s11_pause_then_main_menu_preserves_best_score() -> void:
	_assert_scenes_exist([SCENE_LEVEL_2, SCENE_MAIN, SCENE_LEVEL_1])
	_assert_runtime_case("s11_pause_main_menu_best_score")


func test_s12_game_over_at_zero_lives_to_play_again() -> void:
	_assert_scenes_exist([SCENE_LEVEL_1, SCENE_END])
	_assert_runtime_case("s12_game_over_to_play_again")


func test_s13_brick_shatter_bumps_enemy_above() -> void:
	_assert_scenes_exist([SCENE_PLAYER, SCENE_BRICK, SCENE_WALKER])
	_assert_runtime_case("s13_brick_shatter_bumps_enemy")
