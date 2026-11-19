@tool
extends McpTestSuite

const HELPERS_PATH := "res://tests/helpers/e2e_test_helpers.gd"

const SFX_FILES := [
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

const BGM_FILES := [
	"bgm_overworld",
	"bgm_castle",
]

var _helpers: Script = null
var _batch: Dictionary = {}


func suite_name() -> String:
	return "game_core"


func suite_setup(_ctx: Dictionary) -> void:
	_helpers = _load_helpers()
	if _helpers == null:
		fail_setup("Failed to load helpers script: " + HELPERS_PATH)
		return
	_batch = _helpers.call("run_headless_batch", "game_core")


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


func test_project_autoloads_registered() -> void:
	assert_true(ProjectSettings.has_setting("autoload/GameState"), "ProjectSettings missing autoload/GameState")
	assert_true(ProjectSettings.has_setting("autoload/AudioManager"), "ProjectSettings missing autoload/AudioManager")

	var gs_entry := str(ProjectSettings.get_setting("autoload/GameState", ""))
	var am_entry := str(ProjectSettings.get_setting("autoload/AudioManager", ""))
	assert_eq(gs_entry, "*res://scripts/autoload/game_state.gd", "GameState autoload entry mismatch")
	assert_eq(am_entry, "*res://scripts/autoload/audio_manager.gd", "AudioManager autoload entry mismatch")
	assert_true(ResourceLoader.exists("res://scripts/autoload/game_state.gd"), "game_state.gd missing on disk")
	assert_true(ResourceLoader.exists("res://scripts/autoload/audio_manager.gd"), "audio_manager.gd missing on disk")


func test_project_display_and_rendering() -> void:
	assert_eq(int(ProjectSettings.get_setting("display/window/size/viewport_width", 0)), 640, "viewport_width must be 640")
	assert_eq(int(ProjectSettings.get_setting("display/window/size/viewport_height", 0)), 360, "viewport_height must be 360")
	assert_eq(int(ProjectSettings.get_setting("display/window/size/window_width_override", 0)), 1280, "window_width_override must be 1280")
	assert_eq(int(ProjectSettings.get_setting("display/window/size/window_height_override", 0)), 720, "window_height_override must be 720")
	assert_eq(str(ProjectSettings.get_setting("display/window/stretch/mode", "")), "canvas_items", "stretch/mode must be canvas_items")
	assert_eq(str(ProjectSettings.get_setting("display/window/stretch/aspect", "")), "keep", "stretch/aspect must be keep")
	assert_eq(int(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter", -1)), 0, "default_texture_filter must be 0 (Nearest)")


func test_project_physics_layer_names() -> void:
	assert_eq(str(ProjectSettings.get_setting("layer_names/2d_physics/layer_1", "")), "World", "2D physics layer_1 must be World")
	assert_eq(str(ProjectSettings.get_setting("layer_names/2d_physics/layer_2", "")), "Player", "2D physics layer_2 must be Player")
	assert_eq(str(ProjectSettings.get_setting("layer_names/2d_physics/layer_3", "")), "Enemies", "2D physics layer_3 must be Enemies")
	assert_eq(str(ProjectSettings.get_setting("layer_names/2d_physics/layer_4", "")), "Items", "2D physics layer_4 must be Items")
	assert_eq(str(ProjectSettings.get_setting("layer_names/2d_physics/layer_5", "")), "Hazards", "2D physics layer_5 must be Hazards")


func test_input_map_five_actions() -> void:
	var expected_keys := {
		"move_left": [KEY_LEFT, KEY_A],
		"move_right": [KEY_RIGHT, KEY_D],
		"jump": [KEY_SPACE, KEY_W, KEY_UP],
		"sprint": [KEY_SHIFT],
		"pause": [KEY_ESCAPE],
	}
	for action in expected_keys.keys():
		var events: Array = []
		if not Engine.is_editor_hint() and InputMap.has_action(action):
			events = InputMap.action_get_events(action)
		else:
			assert_true(ProjectSettings.has_setting("input/" + action), "InputMap missing action: " + action)
			var cfg: Variant = ProjectSettings.get_setting("input/" + action, {})
			if cfg is Dictionary:
				events = Array((cfg as Dictionary).get("events", []))
		var codes: Array[int] = []
		for ev in events:
			if ev is InputEventKey:
				var kev := ev as InputEventKey
				var code: int = kev.keycode if kev.keycode != KEY_NONE else kev.physical_keycode
				codes.append(code)
		for req_key in expected_keys[action]:
			assert_contains(codes, req_key, "Action '%s' missing keycode %d" % [action, req_key])


func test_legacy_prototype_scripts_deleted() -> void:
	assert_false(FileAccess.file_exists("res://scripts/main.gd"), "Legacy res://scripts/main.gd must be deleted")
	assert_false(FileAccess.file_exists("res://scripts/main.gd.uid"), "Legacy res://scripts/main.gd.uid must be deleted")
	assert_false(FileAccess.file_exists("res://scripts/player.gd"), "Legacy res://scripts/player.gd must be deleted")
	assert_false(FileAccess.file_exists("res://scripts/player.gd.uid"), "Legacy res://scripts/player.gd.uid must be deleted")


func test_audio_manager_exists_and_assets_load() -> void:
	var h := _get_helpers()
	if h == null:
		return

	var am_path := "res://scripts/autoload/audio_manager.gd"
	assert_true(ResourceLoader.exists(am_path), "audio_manager.gd must exist")
	if not ResourceLoader.exists(am_path):
		return

	var am_res: Resource = h.call("load_resource_ignore_cache", am_path)
	assert_true(am_res is Script, "audio_manager.gd must load as Script")
	if not (am_res is Script):
		return

	var am_script := am_res as Script
	for method_name in ["play_sfx", "play_bgm", "stop_bgm", "toggle_mute", "set_muted", "set_paused_duck"]:
		assert_true(h.call("script_has_method", am_script, method_name), "AudioManager missing method: " + method_name)
	for prop_name in ["is_muted", "is_ducked"]:
		assert_true(h.call("script_has_property", am_script, prop_name), "AudioManager missing property: " + prop_name)

	for sfx_name in SFX_FILES:
		var sfx_path := "res://assets/audio/%s.wav" % sfx_name
		assert_true(ResourceLoader.exists(sfx_path), "Missing SFX WAV: " + sfx_path)
		var wav: Resource = h.call("load_resource_ignore_cache", sfx_path)
		assert_true(wav is AudioStreamWAV, "SFX must load as AudioStreamWAV: " + sfx_path)

	for bgm_name in BGM_FILES:
		var bgm_path := "res://assets/audio/%s.wav" % bgm_name
		assert_true(ResourceLoader.exists(bgm_path), "Missing BGM WAV: " + bgm_path)
		var bgm_res: Resource = h.call("load_resource_ignore_cache", bgm_path)
		assert_true(bgm_res is AudioStreamWAV, "BGM must load as AudioStreamWAV: " + bgm_path)
		if bgm_res is AudioStreamWAV:
			assert_eq((bgm_res as AudioStreamWAV).loop_mode, AudioStreamWAV.LOOP_FORWARD, "BGM must loop forward: " + bgm_path)

	_assert_runtime_case("audio_manager_runtime")


func test_game_state_initial_and_score() -> void:
	var gs_path := "res://scripts/autoload/game_state.gd"
	assert_true(ResourceLoader.exists(gs_path), "game_state.gd must exist")
	if not ResourceLoader.exists(gs_path):
		return
	_assert_runtime_case("game_state_initial_and_score")


func test_game_state_coin_rollover_100() -> void:
	var gs_path := "res://scripts/autoload/game_state.gd"
	assert_true(ResourceLoader.exists(gs_path), "game_state.gd must exist")
	if not ResourceLoader.exists(gs_path):
		return
	_assert_runtime_case("game_state_coin_rollover_100")


func test_game_state_reset_preserves_best_score() -> void:
	var gs_path := "res://scripts/autoload/game_state.gd"
	assert_true(ResourceLoader.exists(gs_path), "game_state.gd must exist")
	if not ResourceLoader.exists(gs_path):
		return
	_assert_runtime_case("game_state_reset_preserves_best_score")


func test_main_scene_title_screen_structure() -> void:
	var h := _get_helpers()
	if h == null:
		return

	var main_path := "res://scenes/main.tscn"
	assert_true(ResourceLoader.exists(main_path), "res://scenes/main.tscn must exist")
	if not ResourceLoader.exists(main_path):
		return

	var deps := Array(ResourceLoader.get_dependencies(main_path))
	for dep in deps:
		var dep_str := str(dep)
		assert_eq(dep_str.find("scripts/main.gd"), -1, "main.tscn must not depend on legacy scripts/main.gd")
		assert_eq(dep_str.find("scripts/player.gd"), -1, "main.tscn must not depend on legacy scripts/player.gd")

	var root: Node = h.call("instantiate_scene", main_path)
	assert_ne(root, null, "main.tscn must instantiate cleanly")
	if root == null:
		return
	track(root)

	assert_true(root is Control, "Title screen main.tscn root must be Control")
	var scr: Variant = root.get_script()
	assert_ne(scr, null, "Title screen main.tscn must have a script attached")
	if scr is Script:
		assert_false((scr as Script).resource_path.ends_with("scripts/main.gd"), "main.tscn must not use legacy scripts/main.gd")

	assert_true(_subtree_uses_theme(root, "res://assets/ui/arabic_theme.tres"), "Title screen must apply arabic_theme.tres")

	var texts := _collect_ui_texts(root)
	var joined := " | ".join(texts)
	assert_eq(joined.find("Collect the yellow coins!"), -1, "Legacy prototype hint text must not be in main.tscn")
	assert_contains(joined, "ابدأ المغامرة", "Title screen missing 'ابدأ المغامرة' button")
	assert_contains(joined, "1-1", "Title screen missing level select '1-1'")
	assert_contains(joined, "1-2", "Title screen missing level select '1-2'")
	assert_contains(joined, "1-3", "Title screen missing level select '1-3'")
	assert_contains(joined, "أعلى نتيجة", "Title screen missing 'أعلى نتيجة' label")
	assert_true(joined.find("الصوت") != -1 or joined.find("كتم") != -1, "Title screen missing Mute button")

	_assert_runtime_case("main_scene_runtime")


func test_level_1_scene_structure() -> void:
	var lvl := _verify_common_level_structure("res://scenes/levels/level_1.tscn")
	if lvl == null:
		return
	_assert_runtime_case("level_1_runtime")


func test_level_2_scene_structure() -> void:
	var h := _get_helpers()
	if h == null:
		return
	var lvl := _verify_common_level_structure("res://scenes/levels/level_2.tscn")
	if lvl == null:
		return

	var platforms: Array = h.call("collect_nodes_with_script_suffix", lvl, "moving_platform.gd")
	assert_gt(platforms.size(), 0, "level_2.tscn must contain at least 1 MovingPlatform")

	var shells: Array = h.call("collect_nodes_with_script_suffix", lvl, "shell_enemy.gd")
	assert_gt(shells.size(), 0, "level_2.tscn must contain at least 1 ShellEnemy")

	_assert_runtime_case("level_2_runtime")


func test_level_3_scene_structure() -> void:
	var h := _get_helpers()
	if h == null:
		return
	var lvl := _verify_common_level_structure("res://scenes/levels/level_3.tscn")
	if lvl == null:
		return

	var hazard: Node = h.call("find_node_by_name_or_script", lvl, "HazardZone", "")
	if hazard == null:
		hazard = _find_node_with_name_prefix(lvl, "HazardZone")
	assert_ne(hazard, null, "level_3.tscn must contain HazardZone for lava")
	if hazard != null:
		assert_true(hazard is Area2D, "HazardZone must be Area2D")

	assert_eq(str(lvl.get("bgm_track")), "castle", "level_3.tscn must configure bgm_track == 'castle'")
	_assert_runtime_case("level_3_runtime")


func test_all_level_paths_resolve() -> void:
	var gs_path := "res://scripts/autoload/game_state.gd"
	assert_true(ResourceLoader.exists(gs_path), "game_state.gd must exist")
	if not ResourceLoader.exists(gs_path):
		return

	_assert_runtime_case("all_level_paths_resolve")
	for lvl_path in [
		"res://scenes/levels/level_1.tscn",
		"res://scenes/levels/level_2.tscn",
		"res://scenes/levels/level_3.tscn",
	]:
		assert_true(ResourceLoader.exists(lvl_path), "Level scene must exist: " + lvl_path)


func _verify_common_level_structure(scene_path: String) -> Node:
	var h := _get_helpers()
	if h == null:
		return null

	assert_true(ResourceLoader.exists(scene_path), "Level scene missing: " + scene_path)
	if not ResourceLoader.exists(scene_path):
		return null

	var lvl: Node = h.call("instantiate_scene", scene_path)
	assert_ne(lvl, null, "Failed to instantiate level scene: " + scene_path)
	if lvl == null:
		return null
	track(lvl)

	var ground: Node = h.call("find_node_by_name_or_script", lvl, "GroundLayer", "")
	assert_ne(ground, null, scene_path + " missing GroundLayer")
	if ground != null:
		assert_true(ground is TileMapLayer, scene_path + " GroundLayer must be TileMapLayer")
		if ground is TileMapLayer:
			var tml := ground as TileMapLayer
			assert_ne(tml.tile_set, null, scene_path + " GroundLayer.tile_set must be assigned")
			if tml.tile_set != null:
				assert_eq(tml.tile_set.resource_path, "res://assets/tilesets/world_tileset.tres", scene_path + " must use world_tileset.tres")
			assert_gt(tml.get_used_cells().size(), 0, scene_path + " GroundLayer must have painted cells")

	var player: Node = h.call("find_node_by_name_or_script", lvl, "Player", "player.gd")
	assert_ne(player, null, scene_path + " missing Player")
	if player != null:
		var cams: Array = h.call("collect_nodes_by_class", player, "Camera2D")
		assert_gt(cams.size(), 0, scene_path + " Player must contain Camera2D")

	var flagpole: Node = h.call("find_node_by_name_or_script", lvl, "Flagpole", "flagpole.gd")
	assert_ne(flagpole, null, scene_path + " missing Flagpole")

	var fall_zone: Node = h.call("find_node_by_name_or_script", lvl, "FallZone", "")
	assert_ne(fall_zone, null, scene_path + " missing FallZone")
	if fall_zone != null:
		assert_true(fall_zone is Area2D, scene_path + " FallZone must be Area2D")

	var hud: Node = h.call("find_node_by_name_or_script", lvl, "HUD", "hud.gd")
	assert_ne(hud, null, scene_path + " missing HUD")

	var pause_menu: Node = h.call("find_node_by_name_or_script", lvl, "PauseMenu", "pause_menu.gd")
	assert_ne(pause_menu, null, scene_path + " missing PauseMenu")

	return lvl


func _subtree_uses_theme(root: Node, theme_path: String) -> bool:
	if root is Control:
		var t: Theme = (root as Control).theme
		if t != null and t.resource_path == theme_path:
			return true
	for child in root.get_children():
		if _subtree_uses_theme(child, theme_path):
			return true
	return false


func _collect_ui_texts(root: Node) -> Array[String]:
	var out: Array[String] = []
	if root is Label:
		out.append((root as Label).text)
	elif root is Button:
		out.append((root as Button).text)
	for child in root.get_children():
		out.append_array(_collect_ui_texts(child))
	return out


func _find_node_with_name_prefix(root: Node, prefix: String) -> Node:
	if String(root.name).begins_with(prefix):
		return root
	for child in root.get_children():
		var found := _find_node_with_name_prefix(child, prefix)
		if found != null:
			return found
	return null
