extends RefCounted

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

const ACTIONS := ["move_left", "move_right", "jump", "sprint", "pause"]


func run(tree: SceneTree, host: Node) -> Dictionary:
	var cases: Dictionary = {}

	cases["c01_question_block_coin"] = await _case_c01_question_block_coin(tree, host)
	cases["c02_question_block_mushroom"] = await _case_c02_question_block_mushroom(tree, host)
	cases["c03_question_block_one_up"] = await _case_c03_question_block_one_up(tree, host)
	cases["c04_small_player_brick"] = await _case_c04_small_player_brick(tree, host)
	cases["c05_big_player_brick"] = await _case_c05_big_player_brick(tree, host)
	cases["c06_player_collects_coin"] = await _case_c06_player_collects_coin(tree, host)
	cases["c07_player_collects_grow_mushroom"] = await _case_c07_player_collects_grow_mushroom(tree, host)
	cases["c08_player_collects_one_up"] = await _case_c08_player_collects_one_up(tree, host)
	cases["c09_question_block_bumps_walker"] = await _case_c09_question_block_bumps_walker(tree, host)
	cases["c10_brick_block_bumps_enemy"] = await _case_c10_brick_block_bumps_enemy(tree, host)
	cases["c11_player_stomps_walker"] = await _case_c11_player_stomps_walker(tree, host)
	cases["c12_walker_side_hit"] = await _case_c12_walker_side_hit(tree, host)
	cases["c13_stomp_then_kick_shell"] = await _case_c13_stomp_then_kick_shell(tree, host)
	cases["c14_sliding_shell_kills_walker"] = await _case_c14_sliding_shell_kills_walker(tree, host)
	cases["c15_sliding_shell_rebounds_wall"] = await _case_c15_sliding_shell_rebounds_wall(tree, host)
	cases["c16_player_rides_moving_platform"] = await _case_c16_player_rides_moving_platform(tree, host)
	cases["c17_flagpole_level_base_gamestate"] = await _case_c17_flagpole_level_base_gamestate(tree, host)
	cases["c18_fallzone_kills_big"] = await _case_c18_fallzone_kills_big(tree, host)
	cases["c19_hazard_zone_kills_invuln_big"] = await _case_c19_hazard_zone_kills_invuln_big(tree, host)
	cases["c20_pause_menu_ducking"] = await _case_c20_pause_menu_ducking(tree, host)
	cases["c21_hud_gamestate_signals"] = await _case_c21_hud_gamestate_signals(tree, host)
	cases["c22_title_screen_routing"] = await _case_c22_title_screen_routing(tree, host)
	cases["c23_end_screen_win_vs_loss"] = await _case_c23_end_screen_win_vs_loss(tree, host)
	cases["c24_level_base_stage_bgm"] = await _case_c24_level_base_stage_bgm(tree, host)
	cases["c25_player_spawns_big"] = await _case_c25_player_spawns_big(tree, host)

	return {
		"ok": true,
		"error": "",
		"cases": cases,
	}


func _make_result(passed: bool, detail: String) -> Dictionary:
	return {"passed": passed, "detail": detail}


func _check_required_scenes(paths: Array[String]) -> String:
	for p in paths:
		if not ResourceLoader.exists(p):
			return "Missing required scene/resource: " + p
	return ""


func _instantiate(path: String) -> Node:
	if not ResourceLoader.exists(path):
		return null
	var res := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if res is PackedScene:
		return (res as PackedScene).instantiate()
	return null


func _reset_globals(tree: SceneTree) -> void:
	tree.paused = false
	for act in ACTIONS:
		if InputMap.has_action(act) and Input.is_action_pressed(act):
			Input.action_release(act)
	var gs := tree.root.get_node_or_null("GameState")
	if gs != null and gs.has_method("reset_game"):
		gs.call("reset_game")
	var am := tree.root.get_node_or_null("AudioManager")
	if am != null:
		if am.has_method("stop_bgm"):
			am.call("stop_bgm")
		if am.has_method("set_muted"):
			am.call("set_muted", false)
		if am.has_method("set_paused_duck"):
			am.call("set_paused_duck", false)


func _cleanup_arena(tree: SceneTree, host: Node, arena: Node) -> void:
	_reset_globals(tree)
	if arena != null and is_instance_valid(arena):
		if arena.get_parent() != null:
			arena.get_parent().remove_child(arena)
		arena.queue_free()
	if is_instance_valid(tree.current_scene) and tree.current_scene != host:
		var extra := tree.current_scene
		if extra.get_parent() != null:
			extra.get_parent().remove_child(extra)
		extra.queue_free()
	if is_instance_valid(host):
		tree.current_scene = host
	await tree.process_frame


func _create_arena_with_floor(host: Node, floor_y: float = 200.0, floor_width: float = 800.0) -> Node2D:
	var arena := Node2D.new()
	arena.name = "Tier3Arena"
	var floor_body := StaticBody2D.new()
	floor_body.name = "Floor"
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0
	floor_body.position = Vector2(200.0, floor_y + 16.0)
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(floor_width, 32.0)
	col.shape = rect
	floor_body.add_child(col)
	arena.add_child(floor_body)
	host.add_child(arena)
	return arena


func _add_wall(arena: Node2D, pos: Vector2, size: Vector2 = Vector2(32.0, 128.0)) -> StaticBody2D:
	var wall := StaticBody2D.new()
	wall.name = "Wall"
	wall.collision_layer = 1
	wall.collision_mask = 0
	wall.position = pos
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	col.shape = rect
	wall.add_child(col)
	arena.add_child(wall)
	return wall


func _step_physics(tree: SceneTree, frames: int) -> void:
	for _i in range(frames):
		await tree.physics_frame


func _set_enum_prop(node: Object, prop_names: Array[String], str_val: String, int_val: int) -> void:
	for prop in prop_names:
		var cur: Variant = node.get(prop)
		if cur != null:
			if typeof(cur) == TYPE_STRING or typeof(cur) == TYPE_STRING_NAME:
				node.set(prop, str_val)
			else:
				node.set(prop, int_val)
			return


func _find_button_by_text(root: Node, needle: String) -> Button:
	if root is Button:
		var btn := root as Button
		if btn.text.find(needle) != -1:
			return btn
	for child in root.get_children():
		var found := _find_button_by_text(child, needle)
		if found != null:
			return found
	return null


func _collect_labels_text(root: Node) -> String:
	var parts: PackedStringArray = PackedStringArray()
	_collect_labels_rec(root, parts)
	return " | ".join(parts)


func _collect_labels_rec(node: Node, out: PackedStringArray) -> void:
	if node is Label:
		out.append((node as Label).text)
	elif node is RichTextLabel:
		out.append((node as RichTextLabel).text)
	elif node is Button:
		out.append((node as Button).text)
	for child in node.get_children():
		_collect_labels_rec(child, out)


func _get_anim_name(node: Node) -> String:
	var spr := node.get_node_or_null("AnimatedSprite2D")
	if spr is AnimatedSprite2D:
		return String((spr as AnimatedSprite2D).animation)
	for child in node.get_children():
		if child is AnimatedSprite2D:
			return String((child as AnimatedSprite2D).animation)
	return ""


func _get_bgm_stream_path(am: Node) -> String:
	if am == null:
		return ""
	for child in am.get_children():
		if child is AudioStreamPlayer:
			var p := child as AudioStreamPlayer
			if p.name == "BGMPlayer" or p.name.find("BGM") != -1:
				if p.stream != null:
					return p.stream.resource_path
	return ""


func _find_by_script_suffix(root: Node, suffix: String) -> Array[Node]:
	var out: Array[Node] = []
	if root == null:
		return out
	_find_by_script_suffix_rec(root, suffix, out)
	return out


func _find_by_script_suffix_rec(node: Node, suffix: String, out: Array[Node]) -> void:
	var scr: Variant = node.get_script()
	if scr is Script and (scr as Script).resource_path.ends_with(suffix):
		out.append(node)
	for child in node.get_children():
		_find_by_script_suffix_rec(child, suffix, out)


func _find_first_by_name_or_suffix(root: Node, target_name: String, suffix: String) -> Node:
	if root == null:
		return null
	if not target_name.is_empty() and String(root.name).begins_with(target_name):
		return root
	var scr: Variant = root.get_script()
	if not suffix.is_empty() and scr is Script and (scr as Script).resource_path.ends_with(suffix):
		return root
	for child in root.get_children():
		var found := _find_first_by_name_or_suffix(child, target_name, suffix)
		if found != null:
			return found
	return null


func _jump_player_into_block(tree: SceneTree, player: CharacterBody2D) -> void:
	await _step_physics(tree, 3)
	Input.action_press("jump")
	await _step_physics(tree, 22)
	Input.action_release("jump")
	await _step_physics(tree, 5)


# ---------- 25 Tier 3 Cases ----------

func _case_c01_question_block_coin(tree: SceneTree, host: Node) -> Dictionary:
	var missing := _check_required_scenes([SCENE_PLAYER, SCENE_QBLOCK])
	if not missing.is_empty():
		return _make_result(false, missing)

	_reset_globals(tree)
	var gs := tree.root.get_node_or_null("GameState")
	if gs == null:
		return _make_result(false, "Missing /root/GameState")

	var arena := _create_arena_with_floor(host, 200.0)
	var player := _instantiate(SCENE_PLAYER) as CharacterBody2D
	var qblock := _instantiate(SCENE_QBLOCK) as Node2D
	if player == null or qblock == null:
		await _cleanup_arena(tree, host, arena)
		return _make_result(false, "Failed to instantiate Player or QuestionBlock")

	_set_enum_prop(qblock, ["reward_type", "reward"], "COIN", 0)
	player.position = Vector2(120.0, 200.0)
	qblock.position = Vector2(120.0, 116.0)
	arena.add_child(qblock)
	arena.add_child(player)

	await _jump_player_into_block(tree, player)

	var coins := int(gs.get("coins"))
	var score := int(gs.get("score"))
	var anim := _get_anim_name(qblock)
	await _cleanup_arena(tree, host, arena)

	if coins != 1 or score != 100 or anim != "used":
		return _make_result(false, "Expected coins=1, score=100, anim='used'; got coins=%d, score=%d, anim='%s'" % [coins, score, anim])
	return _make_result(true, "Player head-hit QuestionBlock(COIN) updated GameState & block state")


func _case_c02_question_block_mushroom(tree: SceneTree, host: Node) -> Dictionary:
	var missing := _check_required_scenes([SCENE_PLAYER, SCENE_QBLOCK, SCENE_MUSHROOM])
	if not missing.is_empty():
		return _make_result(false, missing)

	_reset_globals(tree)
	var arena := _create_arena_with_floor(host, 200.0)
	var player := _instantiate(SCENE_PLAYER) as CharacterBody2D
	var qblock := _instantiate(SCENE_QBLOCK) as Node2D
	if player == null or qblock == null:
		await _cleanup_arena(tree, host, arena)
		return _make_result(false, "Failed to instantiate Player or QuestionBlock")

	_set_enum_prop(qblock, ["reward_type", "reward"], "MUSHROOM", 1)
	player.position = Vector2(120.0, 200.0)
	qblock.position = Vector2(120.0, 116.0)
	arena.add_child(qblock)
	arena.add_child(player)

	await _jump_player_into_block(tree, player)
	await _step_physics(tree, 15)

	var mushrooms := _find_by_script_suffix(arena, "mushroom.gd")
	var anim := _get_anim_name(qblock)
	var has_grow_region := false
	if mushrooms.size() > 0:
		var spr := mushrooms[0].get_node_or_null("Sprite2D")
		if spr is Sprite2D:
			has_grow_region = (spr as Sprite2D).region_rect.position.x < 16.0
		else:
			has_grow_region = true

	await _cleanup_arena(tree, host, arena)
	if mushrooms.size() < 1 or anim != "used" or not has_grow_region:
		return _make_result(false, "Expected spawned GROW Mushroom & used anim; mushrooms=%d, anim='%s'" % [mushrooms.size(), anim])
	return _make_result(true, "QuestionBlock(MUSHROOM) spawned GROW Mushroom on player head-hit")


func _case_c03_question_block_one_up(tree: SceneTree, host: Node) -> Dictionary:
	var missing := _check_required_scenes([SCENE_PLAYER, SCENE_QBLOCK, SCENE_MUSHROOM])
	if not missing.is_empty():
		return _make_result(false, missing)

	_reset_globals(tree)
	var arena := _create_arena_with_floor(host, 200.0)
	var player := _instantiate(SCENE_PLAYER) as CharacterBody2D
	var qblock := _instantiate(SCENE_QBLOCK) as Node2D
	if player == null or qblock == null:
		await _cleanup_arena(tree, host, arena)
		return _make_result(false, "Failed to instantiate Player or QuestionBlock")

	_set_enum_prop(qblock, ["reward_type", "reward"], "ONE_UP", 2)
	player.position = Vector2(120.0, 200.0)
	qblock.position = Vector2(120.0, 116.0)
	arena.add_child(qblock)
	arena.add_child(player)

	await _jump_player_into_block(tree, player)
	await _step_physics(tree, 15)

	var mushrooms := _find_by_script_suffix(arena, "mushroom.gd")
	var is_green := false
	if mushrooms.size() > 0:
		var spr := mushrooms[0].get_node_or_null("Sprite2D")
		if spr is Sprite2D:
			is_green = (spr as Sprite2D).region_rect.position.x >= 32.0
		else:
			is_green = true

	await _cleanup_arena(tree, host, arena)
	if mushrooms.size() < 1 or not is_green:
		return _make_result(false, "Expected spawned ONE_UP Green Mushroom; mushrooms=%d, green=%s" % [mushrooms.size(), str(is_green)])
	return _make_result(true, "QuestionBlock(ONE_UP) spawned green 1-UP Mushroom on head-hit")


func _case_c04_small_player_brick(tree: SceneTree, host: Node) -> Dictionary:
	var missing := _check_required_scenes([SCENE_PLAYER, SCENE_BRICK])
	if not missing.is_empty():
		return _make_result(false, missing)

	_reset_globals(tree)
	var gs := tree.root.get_node_or_null("GameState")
	var arena := _create_arena_with_floor(host, 200.0)
	var player := _instantiate(SCENE_PLAYER) as CharacterBody2D
	var brick := _instantiate(SCENE_BRICK) as Node2D
	if player == null or brick == null:
		await _cleanup_arena(tree, host, arena)
		return _make_result(false, "Failed to instantiate Player or BrickBlock")

	player.position = Vector2(120.0, 200.0)
	brick.position = Vector2(120.0, 116.0)
	arena.add_child(brick)
	arena.add_child(player)

	await _jump_player_into_block(tree, player)
	var intact := is_instance_valid(brick) and not brick.is_queued_for_deletion()
	var score := int(gs.get("score")) if gs != null else -1
	await _cleanup_arena(tree, host, arena)

	if not intact or score != 0:
		return _make_result(false, "Expected BrickBlock intact and score=0 for SMALL player; intact=%s, score=%d" % [str(intact), score])
	return _make_result(true, "SMALL Player hitting BrickBlock keeps brick intact and score unchanged")


func _case_c05_big_player_brick(tree: SceneTree, host: Node) -> Dictionary:
	var missing := _check_required_scenes([SCENE_PLAYER, SCENE_BRICK])
	if not missing.is_empty():
		return _make_result(false, missing)

	_reset_globals(tree)
	var gs := tree.root.get_node_or_null("GameState")
	if gs != null and gs.has_method("set_power"):
		gs.call("set_power", 1)

	var arena := _create_arena_with_floor(host, 200.0)
	var player := _instantiate(SCENE_PLAYER) as CharacterBody2D
	var brick := _instantiate(SCENE_BRICK) as Node2D
	if player == null or brick == null:
		await _cleanup_arena(tree, host, arena)
		return _make_result(false, "Failed to instantiate Player or BrickBlock")

	player.position = Vector2(120.0, 200.0)
	brick.position = Vector2(120.0, 116.0)
	arena.add_child(brick)
	arena.add_child(player)
	if player.has_method("is_big") and not bool(player.call("is_big")) and player.has_method("collect_powerup"):
		player.call("collect_powerup")

	await _jump_player_into_block(tree, player)
	await _step_physics(tree, 6)

	var shattered := (not is_instance_valid(brick)) or brick.is_queued_for_deletion()
	var score := int(gs.get("score")) if gs != null else -1
	await _cleanup_arena(tree, host, arena)

	if not shattered or score != 50:
		return _make_result(false, "Expected BrickBlock shattered and score=50; shattered=%s, score=%d" % [str(shattered), score])
	return _make_result(true, "BIG Player head-hit shatters BrickBlock and awards +50 score")


func _case_c06_player_collects_coin(tree: SceneTree, host: Node) -> Dictionary:
	var missing := _check_required_scenes([SCENE_PLAYER, SCENE_COIN])
	if not missing.is_empty():
		return _make_result(false, missing)

	_reset_globals(tree)
	var gs := tree.root.get_node_or_null("GameState")
	var arena := _create_arena_with_floor(host, 200.0)
	var player := _instantiate(SCENE_PLAYER) as CharacterBody2D
	var coin := _instantiate(SCENE_COIN) as Node2D
	if player == null or coin == null:
		await _cleanup_arena(tree, host, arena)
		return _make_result(false, "Failed to instantiate Player or Coin")

	player.position = Vector2(100.0, 200.0)
	coin.position = Vector2(132.0, 186.0)
	arena.add_child(coin)
	arena.add_child(player)

	Input.action_press("move_right")
	await _step_physics(tree, 25)
	Input.action_release("move_right")
	await _step_physics(tree, 3)

	var coins := int(gs.get("coins")) if gs != null else -1
	var score := int(gs.get("score")) if gs != null else -1
	var freed := (not is_instance_valid(coin)) or coin.is_queued_for_deletion()
	await _cleanup_arena(tree, host, arena)

	if coins != 1 or score != 100 or not freed:
		return _make_result(false, "Expected coins=1, score=100, coin freed; got coins=%d, score=%d, freed=%s" % [coins, score, str(freed)])
	return _make_result(true, "Player overlapping Coin updated GameState and freed Coin")


func _case_c07_player_collects_grow_mushroom(tree: SceneTree, host: Node) -> Dictionary:
	var missing := _check_required_scenes([SCENE_PLAYER, SCENE_MUSHROOM])
	if not missing.is_empty():
		return _make_result(false, missing)

	_reset_globals(tree)
	var gs := tree.root.get_node_or_null("GameState")
	var arena := _create_arena_with_floor(host, 200.0)
	var player := _instantiate(SCENE_PLAYER) as CharacterBody2D
	var mush := _instantiate(SCENE_MUSHROOM) as Node2D
	if player == null or mush == null:
		await _cleanup_arena(tree, host, arena)
		return _make_result(false, "Failed to instantiate Player or Mushroom")

	_set_enum_prop(mush, ["mushroom_type", "kind", "type", "reward_type"], "GROW", 0)
	player.position = Vector2(100.0, 200.0)
	mush.position = Vector2(130.0, 200.0)
	arena.add_child(mush)
	arena.add_child(player)

	Input.action_press("move_right")
	await _step_physics(tree, 30)
	Input.action_release("move_right")
	await _step_physics(tree, 3)

	var is_big := bool(player.call("is_big")) if player.has_method("is_big") else false
	var gs_power := int(gs.get("player_power")) if gs != null else -1
	var freed := (not is_instance_valid(mush)) or mush.is_queued_for_deletion()
	await _cleanup_arena(tree, host, arena)

	if not is_big or gs_power != 1 or not freed:
		return _make_result(false, "Expected BIG player, gs.player_power=1, mushroom freed; got big=%s, power=%d, freed=%s" % [str(is_big), gs_power, str(freed)])
	return _make_result(true, "SMALL Player collecting GROW Mushroom grew to BIG and synced GameState")


func _case_c08_player_collects_one_up(tree: SceneTree, host: Node) -> Dictionary:
	var missing := _check_required_scenes([SCENE_PLAYER, SCENE_MUSHROOM])
	if not missing.is_empty():
		return _make_result(false, missing)

	_reset_globals(tree)
	var gs := tree.root.get_node_or_null("GameState")
	var arena := _create_arena_with_floor(host, 200.0)
	var player := _instantiate(SCENE_PLAYER) as CharacterBody2D
	var mush := _instantiate(SCENE_MUSHROOM) as Node2D
	if player == null or mush == null:
		await _cleanup_arena(tree, host, arena)
		return _make_result(false, "Failed to instantiate Player or Mushroom")

	_set_enum_prop(mush, ["mushroom_type", "kind", "type", "reward_type"], "ONE_UP", 1)
	player.position = Vector2(100.0, 200.0)
	mush.position = Vector2(130.0, 200.0)
	arena.add_child(mush)
	arena.add_child(player)

	Input.action_press("move_right")
	await _step_physics(tree, 30)
	Input.action_release("move_right")
	await _step_physics(tree, 3)

	var lives := int(gs.get("lives")) if gs != null else -1
	var is_big := bool(player.call("is_big")) if player.has_method("is_big") else true
	var freed := (not is_instance_valid(mush)) or mush.is_queued_for_deletion()
	await _cleanup_arena(tree, host, arena)

	if lives != 4 or is_big or not freed:
		return _make_result(false, "Expected lives=4, is_big=false, mushroom freed; got lives=%d, big=%s, freed=%s" % [lives, str(is_big), str(freed)])
	return _make_result(true, "Player collecting ONE_UP Mushroom gained +1 life without changing power state")


func _case_c09_question_block_bumps_walker(tree: SceneTree, host: Node) -> Dictionary:
	var missing := _check_required_scenes([SCENE_PLAYER, SCENE_QBLOCK, SCENE_WALKER])
	if not missing.is_empty():
		return _make_result(false, missing)

	_reset_globals(tree)
	var arena := _create_arena_with_floor(host, 200.0)
	var player := _instantiate(SCENE_PLAYER) as CharacterBody2D
	var qblock := _instantiate(SCENE_QBLOCK) as Node2D
	var walker := _instantiate(SCENE_WALKER) as Node2D
	if player == null or qblock == null or walker == null:
		await _cleanup_arena(tree, host, arena)
		return _make_result(false, "Failed to instantiate Player, QuestionBlock, or WalkerEnemy")

	_set_enum_prop(qblock, ["reward_type", "reward"], "COIN", 0)
	player.position = Vector2(120.0, 200.0)
	qblock.position = Vector2(120.0, 116.0)
	walker.position = Vector2(120.0, 100.0)
	arena.add_child(qblock)
	arena.add_child(walker)
	arena.add_child(player)

	await _jump_player_into_block(tree, player)
	await _step_physics(tree, 20)

	var walker_defeated := (not is_instance_valid(walker)) or walker.is_queued_for_deletion() or not walker.is_physics_processing()
	await _cleanup_arena(tree, host, arena)

	if not walker_defeated:
		return _make_result(false, "Expected WalkerEnemy atop QuestionBlock to be defeated by bump")
	return _make_result(true, "QuestionBlock hit from below defeated WalkerEnemy standing above")


func _case_c10_brick_block_bumps_enemy(tree: SceneTree, host: Node) -> Dictionary:
	var missing := _check_required_scenes([SCENE_PLAYER, SCENE_BRICK, SCENE_WALKER])
	if not missing.is_empty():
		return _make_result(false, missing)

	_reset_globals(tree)
	var arena := _create_arena_with_floor(host, 200.0)
	var player := _instantiate(SCENE_PLAYER) as CharacterBody2D
	var brick := _instantiate(SCENE_BRICK) as Node2D
	var walker := _instantiate(SCENE_WALKER) as Node2D
	if player == null or brick == null or walker == null:
		await _cleanup_arena(tree, host, arena)
		return _make_result(false, "Failed to instantiate Player, BrickBlock, or WalkerEnemy")

	player.position = Vector2(120.0, 200.0)
	brick.position = Vector2(120.0, 116.0)
	walker.position = Vector2(120.0, 100.0)
	arena.add_child(brick)
	arena.add_child(walker)
	arena.add_child(player)

	await _jump_player_into_block(tree, player)
	await _step_physics(tree, 20)

	var walker_defeated := (not is_instance_valid(walker)) or walker.is_queued_for_deletion() or not walker.is_physics_processing()
	var brick_intact := is_instance_valid(brick) and not brick.is_queued_for_deletion()
	await _cleanup_arena(tree, host, arena)

	if not walker_defeated or not brick_intact:
		return _make_result(false, "Expected walker defeated (%s) and brick intact (%s)" % [str(walker_defeated), str(brick_intact)])
	return _make_result(true, "BrickBlock hit by SMALL Player bumped and defeated enemy above")


func _case_c11_player_stomps_walker(tree: SceneTree, host: Node) -> Dictionary:
	var missing := _check_required_scenes([SCENE_PLAYER, SCENE_WALKER])
	if not missing.is_empty():
		return _make_result(false, missing)

	_reset_globals(tree)
	var gs := tree.root.get_node_or_null("GameState")
	var arena := _create_arena_with_floor(host, 200.0)
	var player := _instantiate(SCENE_PLAYER) as CharacterBody2D
	var walker := _instantiate(SCENE_WALKER) as CharacterBody2D
	if player == null or walker == null:
		await _cleanup_arena(tree, host, arena)
		return _make_result(false, "Failed to instantiate Player or WalkerEnemy")

	walker.position = Vector2(160.0, 200.0)
	player.position = Vector2(160.0, 152.0)
	player.velocity = Vector2(0.0, 120.0)
	arena.add_child(walker)
	arena.add_child(player)

	var bounced := false
	for _i in range(25):
		await tree.physics_frame
		if is_instance_valid(player) and player.velocity.y < -50.0:
			bounced = true
			break

	await _step_physics(tree, 15)
	var score := int(gs.get("score")) if gs != null else 0
	var dead := bool(player.call("is_dead")) if player.has_method("is_dead") else true
	var walker_gone_or_squished := (not is_instance_valid(walker)) or walker.is_queued_for_deletion() or _get_anim_name(walker) == "squished"
	await _cleanup_arena(tree, host, arena)

	if dead or not bounced or score < 200 or not walker_gone_or_squished:
		return _make_result(false, "Expected stomp: dead=%s, bounced=%s, score=%d, walker_handled=%s" % [str(dead), str(bounced), score, str(walker_gone_or_squished)])
	return _make_result(true, "Player stomping WalkerEnemy bounced upward, squished enemy, and gained >=200 score")


func _case_c12_walker_side_hit(tree: SceneTree, host: Node) -> Dictionary:
	var missing := _check_required_scenes([SCENE_PLAYER, SCENE_WALKER])
	if not missing.is_empty():
		return _make_result(false, missing)

	_reset_globals(tree)
	var gs := tree.root.get_node_or_null("GameState")
	if gs != null and gs.has_method("set_power"):
		gs.call("set_power", 1)

	# Part A: BIG player side hit shrinks to SMALL + invuln
	var arena := _create_arena_with_floor(host, 200.0)
	var player := _instantiate(SCENE_PLAYER) as CharacterBody2D
	var walker := _instantiate(SCENE_WALKER) as CharacterBody2D
	if player == null or walker == null:
		await _cleanup_arena(tree, host, arena)
		return _make_result(false, "Failed to instantiate Player or WalkerEnemy")

	player.position = Vector2(100.0, 200.0)
	walker.position = Vector2(138.0, 200.0)
	arena.add_child(walker)
	arena.add_child(player)
	if player.has_method("is_big") and not bool(player.call("is_big")) and player.has_method("collect_powerup"):
		player.call("collect_powerup")

	Input.action_press("move_right")
	for _i in range(30):
		await tree.physics_frame
		if player.has_method("is_invulnerable") and bool(player.call("is_invulnerable")):
			break
	Input.action_release("move_right")

	var shrunk := player.has_method("is_big") and not bool(player.call("is_big"))
	var invuln := player.has_method("is_invulnerable") and bool(player.call("is_invulnerable"))
	var lives_after_shrink := int(gs.get("lives")) if gs != null else -1
	await _cleanup_arena(tree, host, arena)

	if not shrunk or not invuln or lives_after_shrink != 3:
		return _make_result(false, "BIG lateral hit failed: shrunk=%s, invuln=%s, lives=%d" % [str(shrunk), str(invuln), lives_after_shrink])

	# Part B: SMALL player side hit kills
	var arena2 := _create_arena_with_floor(host, 200.0)
	var player2 := _instantiate(SCENE_PLAYER) as CharacterBody2D
	var walker2 := _instantiate(SCENE_WALKER) as CharacterBody2D
	if player2 == null or walker2 == null:
		await _cleanup_arena(tree, host, arena2)
		return _make_result(false, "Failed to instantiate Player or WalkerEnemy for SMALL test")
	player2.position = Vector2(100.0, 200.0)
	walker2.position = Vector2(138.0, 200.0)
	arena2.add_child(walker2)
	arena2.add_child(player2)

	Input.action_press("move_right")
	for _i in range(30):
		await tree.physics_frame
		if player2.has_method("is_dead") and bool(player2.call("is_dead")):
			break
	Input.action_release("move_right")

	var died := player2.has_method("is_dead") and bool(player2.call("is_dead"))
	await _cleanup_arena(tree, host, arena2)

	if not died:
		return _make_result(false, "SMALL lateral hit did not kill Player")
	return _make_result(true, "WalkerEnemy lateral contact shrunk BIG->SMALL (with invuln) and killed SMALL")


func _case_c13_stomp_then_kick_shell(tree: SceneTree, host: Node) -> Dictionary:
	var missing := _check_required_scenes([SCENE_PLAYER, SCENE_SHELL])
	if not missing.is_empty():
		return _make_result(false, missing)

	_reset_globals(tree)
	var arena := _create_arena_with_floor(host, 200.0)
	var player := _instantiate(SCENE_PLAYER) as CharacterBody2D
	var shell := _instantiate(SCENE_SHELL) as CharacterBody2D
	if player == null or shell == null:
		await _cleanup_arena(tree, host, arena)
		return _make_result(false, "Failed to instantiate Player or ShellEnemy")

	shell.position = Vector2(160.0, 200.0)
	player.position = Vector2(160.0, 152.0)
	player.velocity = Vector2(0.0, 120.0)
	arena.add_child(shell)
	arena.add_child(player)

	for _i in range(20):
		await tree.physics_frame
		if shell.has_method("is_shell_idle") and bool(shell.call("is_shell_idle")):
			break

	var is_idle := shell.has_method("is_shell_idle") and bool(shell.call("is_shell_idle"))
	if not is_idle:
		await _cleanup_arena(tree, host, arena)
		return _make_result(false, "First stomp did not put ShellEnemy in SHELL_IDLE")

	# Reposition player slightly left on floor and walk right to kick
	player.position = Vector2(shell.position.x - 28.0, 200.0)
	player.velocity = Vector2.ZERO
	await _step_physics(tree, 4)
	Input.action_press("move_right")
	for _i in range(25):
		await tree.physics_frame
		if shell.has_method("is_sliding") and bool(shell.call("is_sliding")):
			break
	Input.action_release("move_right")

	var is_sliding := shell.has_method("is_sliding") and bool(shell.call("is_sliding"))
	var player_dead := player.has_method("is_dead") and bool(player.call("is_dead"))
	await _cleanup_arena(tree, host, arena)

	if not is_sliding or player_dead:
		return _make_result(false, "Shell kick failed: is_sliding=%s, player_dead=%s" % [str(is_sliding), str(player_dead)])
	return _make_result(true, "Player stomped ShellEnemy to SHELL_IDLE then kicked to SHELL_SLIDE safely")


func _case_c14_sliding_shell_kills_walker(tree: SceneTree, host: Node) -> Dictionary:
	var missing := _check_required_scenes([SCENE_PLAYER, SCENE_SHELL, SCENE_WALKER])
	if not missing.is_empty():
		return _make_result(false, missing)

	_reset_globals(tree)
	var arena := _create_arena_with_floor(host, 200.0)
	var player := _instantiate(SCENE_PLAYER) as CharacterBody2D
	var shell := _instantiate(SCENE_SHELL) as CharacterBody2D
	var walker := _instantiate(SCENE_WALKER) as CharacterBody2D
	if player == null or shell == null or walker == null:
		await _cleanup_arena(tree, host, arena)
		return _make_result(false, "Failed to instantiate Player, ShellEnemy, or WalkerEnemy")

	shell.position = Vector2(100.0, 200.0)
	walker.position = Vector2(190.0, 200.0)
	player.position = Vector2(100.0, 152.0)
	player.velocity = Vector2(0.0, 120.0)
	arena.add_child(shell)
	arena.add_child(walker)
	arena.add_child(player)

	for _i in range(20):
		await tree.physics_frame
		if shell.has_method("is_shell_idle") and bool(shell.call("is_shell_idle")):
			break

	player.position = Vector2(72.0, 200.0)
	player.velocity = Vector2.ZERO
	await _step_physics(tree, 3)
	Input.action_press("move_right")
	for _i in range(20):
		await tree.physics_frame
		if shell.has_method("is_sliding") and bool(shell.call("is_sliding")):
			break
	Input.action_release("move_right")
	player.position = Vector2(30.0, 120.0)

	await _step_physics(tree, 45)
	var walker_defeated := (not is_instance_valid(walker)) or walker.is_queued_for_deletion() or not walker.is_physics_processing()
	var shell_sliding := is_instance_valid(shell) and shell.has_method("is_sliding") and bool(shell.call("is_sliding"))
	await _cleanup_arena(tree, host, arena)

	if not walker_defeated or not shell_sliding:
		return _make_result(false, "Sliding shell chain failed: walker_defeated=%s, shell_sliding=%s" % [str(walker_defeated), str(shell_sliding)])
	return _make_result(true, "Sliding ShellEnemy defeated WalkerEnemy while continuing to slide")


func _case_c15_sliding_shell_rebounds_wall(tree: SceneTree, host: Node) -> Dictionary:
	var missing := _check_required_scenes([SCENE_PLAYER, SCENE_SHELL])
	if not missing.is_empty():
		return _make_result(false, missing)

	_reset_globals(tree)
	var arena := _create_arena_with_floor(host, 200.0)
	_add_wall(arena, Vector2(220.0, 160.0), Vector2(32.0, 120.0))
	var player := _instantiate(SCENE_PLAYER) as CharacterBody2D
	var shell := _instantiate(SCENE_SHELL) as CharacterBody2D
	if player == null or shell == null:
		await _cleanup_arena(tree, host, arena)
		return _make_result(false, "Failed to instantiate Player or ShellEnemy")

	shell.position = Vector2(130.0, 200.0)
	player.position = Vector2(130.0, 152.0)
	player.velocity = Vector2(0.0, 120.0)
	arena.add_child(shell)
	arena.add_child(player)

	for _i in range(20):
		await tree.physics_frame
		if shell.has_method("is_shell_idle") and bool(shell.call("is_shell_idle")):
			break

	player.position = Vector2(102.0, 200.0)
	player.velocity = Vector2.ZERO
	await _step_physics(tree, 3)
	Input.action_press("move_right")
	for _i in range(20):
		await tree.physics_frame
		if shell.has_method("is_sliding") and bool(shell.call("is_sliding")):
			break
	Input.action_release("move_right")
	player.position = Vector2(40.0, 80.0)

	var initial_vx := shell.velocity.x
	var reversed := false
	for _i in range(60):
		await tree.physics_frame
		if initial_vx > 0.0 and shell.velocity.x < -10.0:
			reversed = true
			break

	var still_sliding := shell.has_method("is_sliding") and bool(shell.call("is_sliding"))
	await _cleanup_arena(tree, host, arena)

	if not reversed or not still_sliding:
		return _make_result(false, "Shell wall rebound failed: initial_vx=%.1f, final_vx=%.1f, sliding=%s" % [initial_vx, shell.velocity.x, str(still_sliding)])
	return _make_result(true, "Sliding ShellEnemy rebounded off World wall with reversed velocity")


func _case_c16_player_rides_moving_platform(tree: SceneTree, host: Node) -> Dictionary:
	var missing := _check_required_scenes([SCENE_PLAYER, SCENE_PLATFORM])
	if not missing.is_empty():
		return _make_result(false, missing)

	_reset_globals(tree)
	var arena := Node2D.new()
	arena.name = "PlatformArena"
	host.add_child(arena)

	var plat := _instantiate(SCENE_PLATFORM) as AnimatableBody2D
	var player := _instantiate(SCENE_PLAYER) as CharacterBody2D
	if plat == null or player == null:
		await _cleanup_arena(tree, host, arena)
		return _make_result(false, "Failed to instantiate MovingPlatform or Player")

	plat.set("move_offset", Vector2(80.0, 0.0))
	plat.set("duration", 1.0)
	plat.position = Vector2(100.0, 200.0)
	player.position = Vector2(100.0, 188.0)
	arena.add_child(plat)
	arena.add_child(player)

	await _step_physics(tree, 5)
	var start_x := player.position.x
	await _step_physics(tree, 40)
	var end_x := player.position.x
	var on_floor := player.is_on_floor()
	await _cleanup_arena(tree, host, arena)

	if end_x <= start_x + 20.0 or not on_floor:
		return _make_result(false, "Player failed to ride MovingPlatform: start_x=%.1f, end_x=%.1f, on_floor=%s" % [start_x, end_x, str(on_floor)])
	return _make_result(true, "Player rode MovingPlatform smoothly from %.1f to %.1f" % [start_x, end_x])


func _case_c17_flagpole_level_base_gamestate(tree: SceneTree, host: Node) -> Dictionary:
	var missing := _check_required_scenes([SCENE_LEVEL_1])
	if not missing.is_empty():
		return _make_result(false, missing)

	_reset_globals(tree)
	var gs := tree.root.get_node_or_null("GameState")
	var lvl := _instantiate(SCENE_LEVEL_1)
	if lvl == null:
		return _make_result(false, "Failed to instantiate level_1.tscn")

	tree.root.add_child(lvl)
	tree.current_scene = lvl
	await tree.process_frame

	var flagpole := _find_first_by_name_or_suffix(lvl, "Flagpole", "flagpole.gd") as Node2D
	var player := _find_first_by_name_or_suffix(lvl, "Player", "player.gd") as CharacterBody2D
	if flagpole == null or player == null:
		await _cleanup_arena(tree, host, lvl)
		return _make_result(false, "level_1.tscn missing Flagpole or Player")

	var cleared_bonuses: Array[int] = []
	if flagpole.has_signal("level_cleared"):
		flagpole.connect("level_cleared", func(tb: int) -> void: cleared_bonuses.append(tb))

	var score_before := int(gs.get("score")) if gs != null else 0
	player.global_position = flagpole.global_position
	player.velocity = Vector2.ZERO
	await _step_physics(tree, 10)

	var score_after := int(gs.get("score")) if gs != null else 0
	var current_lvl_after := tree.current_scene
	await _cleanup_arena(tree, host, current_lvl_after if current_lvl_after != lvl else lvl)

	if cleared_bonuses.is_empty() or score_after <= score_before:
		return _make_result(false, "Flagpole clear failed: bonuses=%s, score_before=%d, score_after=%d" % [str(cleared_bonuses), score_before, score_after])
	return _make_result(true, "Player touching Flagpole emitted level_cleared(%d) and awarded time bonus" % cleared_bonuses[0])


func _case_c18_fallzone_kills_big(tree: SceneTree, host: Node) -> Dictionary:
	var missing := _check_required_scenes([SCENE_LEVEL_1])
	if not missing.is_empty():
		return _make_result(false, missing)

	_reset_globals(tree)
	var gs := tree.root.get_node_or_null("GameState")
	if gs != null and gs.has_method("set_power"):
		gs.call("set_power", 1)

	var lvl := _instantiate(SCENE_LEVEL_1)
	if lvl == null:
		return _make_result(false, "Failed to instantiate level_1.tscn")

	tree.root.add_child(lvl)
	tree.current_scene = lvl
	await tree.process_frame

	var fall_zone := _find_first_by_name_or_suffix(lvl, "FallZone", "") as Node2D
	var player := _find_first_by_name_or_suffix(lvl, "Player", "player.gd") as CharacterBody2D
	if fall_zone == null or player == null:
		await _cleanup_arena(tree, host, lvl)
		return _make_result(false, "level_1.tscn missing FallZone or Player")

	if player.has_method("is_big") and not bool(player.call("is_big")) and player.has_method("collect_powerup"):
		player.call("collect_powerup")

	player.global_position = fall_zone.global_position
	for _i in range(20):
		await tree.physics_frame
		if not is_instance_valid(player) or (player.has_method("is_dead") and bool(player.call("is_dead"))):
			break

	var is_dead := (not is_instance_valid(player)) or (player.has_method("is_dead") and bool(player.call("is_dead")))
	var lives := int(gs.get("lives")) if gs != null else 3
	var power := int(gs.get("player_power")) if gs != null else 1
	await _cleanup_arena(tree, host, tree.current_scene)

	if not is_dead or lives >= 3 or power != 0:
		return _make_result(false, "FallZone BIG death failed: dead=%s, lives=%d, power=%d" % [str(is_dead), lives, power])
	return _make_result(true, "FallZone killed BIG Player, decremented lives, and reset player_power to SMALL")


func _case_c19_hazard_zone_kills_invuln_big(tree: SceneTree, host: Node) -> Dictionary:
	var missing := _check_required_scenes([SCENE_LEVEL_3])
	if not missing.is_empty():
		return _make_result(false, missing)

	_reset_globals(tree)
	var gs := tree.root.get_node_or_null("GameState")
	if gs != null and gs.has_method("set_power"):
		gs.call("set_power", 1)

	var lvl := _instantiate(SCENE_LEVEL_3)
	if lvl == null:
		return _make_result(false, "Failed to instantiate level_3.tscn")

	tree.root.add_child(lvl)
	tree.current_scene = lvl
	await tree.process_frame

	var hazard := _find_first_by_name_or_suffix(lvl, "HazardZone", "") as Node2D
	var player := _find_first_by_name_or_suffix(lvl, "Player", "player.gd") as CharacterBody2D
	if hazard == null or player == null:
		await _cleanup_arena(tree, host, lvl)
		return _make_result(false, "level_3.tscn missing HazardZone or Player")

	if player.has_method("is_big") and not bool(player.call("is_big")) and player.has_method("collect_powerup"):
		player.call("collect_powerup")
	# Trigger invulnerability via non-lethal hit, then restore BIG while invuln window is active
	if player.has_method("take_damage"):
		player.call("take_damage", false)
	if player.has_method("collect_powerup"):
		player.call("collect_powerup")

	var was_big_and_invuln := (player.has_method("is_big") and bool(player.call("is_big"))) and (player.has_method("is_invulnerable") and bool(player.call("is_invulnerable")))
	player.global_position = hazard.global_position
	for _i in range(20):
		await tree.physics_frame
		if not is_instance_valid(player) or (player.has_method("is_dead") and bool(player.call("is_dead"))):
			break

	var is_dead := (not is_instance_valid(player)) or (player.has_method("is_dead") and bool(player.call("is_dead")))
	await _cleanup_arena(tree, host, tree.current_scene)

	if not was_big_and_invuln or not is_dead:
		return _make_result(false, "HazardZone lethal failed: was_big_invuln=%s, is_dead=%s" % [str(was_big_and_invuln), str(is_dead)])
	return _make_result(true, "HazardZone (lava) bypassed invulnerability and killed BIG Player")


func _case_c20_pause_menu_ducking(tree: SceneTree, host: Node) -> Dictionary:
	var missing := _check_required_scenes([SCENE_PAUSE])
	if not missing.is_empty():
		return _make_result(false, missing)

	_reset_globals(tree)
	var am := tree.root.get_node_or_null("AudioManager")
	if am == null:
		return _make_result(false, "Missing /root/AudioManager")

	var pause_menu := _instantiate(SCENE_PAUSE)
	if pause_menu == null:
		return _make_result(false, "Failed to instantiate pause_menu.tscn")
	host.add_child(pause_menu)
	await tree.process_frame

	am.call("play_bgm", "overworld")
	if not pause_menu.has_method("toggle_pause"):
		await _cleanup_arena(tree, host, pause_menu)
		return _make_result(false, "PauseMenu missing toggle_pause() method")

	pause_menu.call("toggle_pause")
	var paused_state := tree.paused
	var ducked_state := bool(am.get("is_ducked"))
	var visible_paused := bool((pause_menu as CanvasItem).visible) if pause_menu is CanvasItem else true

	pause_menu.call("toggle_pause")
	var unpaused_state := not tree.paused
	var unducked_state := not bool(am.get("is_ducked"))

	await _cleanup_arena(tree, host, pause_menu)
	if not paused_state or not ducked_state or not visible_paused or not unpaused_state or not unducked_state:
		return _make_result(false, "PauseMenu/AudioManager ducking mismatch: paused=%s, ducked=%s, visible=%s, unpaused=%s, unducked=%s" % [str(paused_state), str(ducked_state), str(visible_paused), str(unpaused_state), str(unducked_state)])
	return _make_result(true, "PauseMenu.toggle_pause() toggled SceneTree pause and AudioManager ducking")


func _case_c21_hud_gamestate_signals(tree: SceneTree, host: Node) -> Dictionary:
	var missing := _check_required_scenes([SCENE_HUD])
	if not missing.is_empty():
		return _make_result(false, missing)

	_reset_globals(tree)
	var gs := tree.root.get_node_or_null("GameState")
	var hud := _instantiate(SCENE_HUD)
	if hud == null or gs == null:
		return _make_result(false, "Failed to instantiate HUD or missing GameState")

	host.add_child(hud)
	await tree.process_frame

	gs.call("add_score", 150)
	gs.call("add_coin", 2)
	gs.call("add_life", 1)
	gs.call("set_level", 2)
	if hud.has_method("update_time"):
		hud.call("update_time", 142)
	await tree.process_frame

	var joined := _collect_labels_text(hud)
	await _cleanup_arena(tree, host, hud)

	if joined.find("150") == -1 or joined.find("2") == -1 or joined.find("4") == -1 or joined.find("142") == -1:
		return _make_result(false, "HUD did not reflect all GameState updates; labels='%s'" % joined)
	return _make_result(true, "HUD synchronized score, coins, lives, stage, and time from GameState signals")


func _case_c22_title_screen_routing(tree: SceneTree, host: Node) -> Dictionary:
	var missing := _check_required_scenes([SCENE_MAIN, SCENE_LEVEL_1, SCENE_LEVEL_2])
	if not missing.is_empty():
		return _make_result(false, missing)

	_reset_globals(tree)
	var gs := tree.root.get_node_or_null("GameState")
	var title := _instantiate(SCENE_MAIN)
	if title == null:
		return _make_result(false, "Failed to instantiate main.tscn")

	tree.root.add_child(title)
	tree.current_scene = title
	await tree.process_frame

	var btn_1_2 := _find_button_by_text(title, "1-2")
	if btn_1_2 == null:
		await _cleanup_arena(tree, host, title)
		return _make_result(false, "Title screen missing '1-2' level select button")

	btn_1_2.pressed.emit()
	for _i in range(20):
		await tree.process_frame
		if tree.current_scene != title:
			break

	var loaded_path := tree.current_scene.scene_file_path if is_instance_valid(tree.current_scene) else ""
	var lvl_num := int(gs.get("current_level")) if gs != null else -1
	await _cleanup_arena(tree, host, tree.current_scene)

	if loaded_path != SCENE_LEVEL_2 or lvl_num != 2:
		return _make_result(false, "Title 1-2 routing failed: scene='%s', current_level=%d" % [loaded_path, lvl_num])
	return _make_result(true, "Title Screen button routed to level_2.tscn and updated GameState.current_level")


func _case_c23_end_screen_win_vs_loss(tree: SceneTree, host: Node) -> Dictionary:
	var missing := _check_required_scenes([SCENE_END])
	if not missing.is_empty():
		return _make_result(false, missing)

	_reset_globals(tree)
	var gs := tree.root.get_node_or_null("GameState")
	if gs == null:
		return _make_result(false, "Missing /root/GameState")

	gs.set("best_score", 0)

	# Win case
	gs.call("add_score", 750)
	gs.call("mark_victory")
	var win_screen := _instantiate(SCENE_END)
	if win_screen == null:
		return _make_result(false, "Failed to instantiate end_screen.tscn (win)")
	host.add_child(win_screen)
	await tree.process_frame
	var win_texts := _collect_labels_text(win_screen)
	await _cleanup_arena(tree, host, win_screen)

	# Loss case
	gs.call("reset_game")
	gs.call("add_score", 400)
	gs.call("mark_game_over")
	var loss_screen := _instantiate(SCENE_END)
	if loss_screen == null:
		return _make_result(false, "Failed to instantiate end_screen.tscn (loss)")
	host.add_child(loss_screen)
	await tree.process_frame
	var loss_texts := _collect_labels_text(loss_screen)
	await _cleanup_arena(tree, host, loss_screen)

	var distinct := win_texts != loss_texts
	var has_win_score := win_texts.find("750") != -1
	var has_loss_and_best := loss_texts.find("400") != -1 and loss_texts.find("750") != -1
	if not distinct or not has_win_score or not has_loss_and_best:
		return _make_result(false, "EndScreen win vs loss failed: distinct=%s, win='%s', loss='%s'" % [str(distinct), win_texts, loss_texts])
	return _make_result(true, "EndScreen distinguished win vs loss headings and displayed score & best_score")


func _case_c24_level_base_stage_bgm(tree: SceneTree, host: Node) -> Dictionary:
	var missing := _check_required_scenes([SCENE_LEVEL_1, SCENE_LEVEL_2, SCENE_LEVEL_3])
	if not missing.is_empty():
		return _make_result(false, missing)

	var am := tree.root.get_node_or_null("AudioManager")
	if am == null:
		return _make_result(false, "Missing /root/AudioManager")

	var expected := {
		SCENE_LEVEL_1: "bgm_overworld.wav",
		SCENE_LEVEL_2: "bgm_overworld.wav",
		SCENE_LEVEL_3: "bgm_castle.wav",
	}
	for path in expected.keys():
		_reset_globals(tree)
		var lvl := _instantiate(path)
		if lvl == null:
			return _make_result(false, "Failed to instantiate " + path)
		host.add_child(lvl)
		await tree.process_frame
		var stream_path := _get_bgm_stream_path(am)
		await _cleanup_arena(tree, host, lvl)
		if not stream_path.ends_with(expected[path]):
			return _make_result(false, "%s expected BGM ending in '%s', got '%s'" % [path, expected[path], stream_path])

	return _make_result(true, "LevelBase selected overworld BGM for 1-1/1-2 and castle BGM for 1-3")


func _case_c25_player_spawns_big(tree: SceneTree, host: Node) -> Dictionary:
	var missing := _check_required_scenes([SCENE_LEVEL_2])
	if not missing.is_empty():
		return _make_result(false, missing)

	_reset_globals(tree)
	var gs := tree.root.get_node_or_null("GameState")
	if gs == null:
		return _make_result(false, "Missing /root/GameState")
	gs.call("set_power", 1)
	gs.call("set_level", 2)

	var lvl := _instantiate(SCENE_LEVEL_2)
	if lvl == null:
		return _make_result(false, "Failed to instantiate level_2.tscn")
	host.add_child(lvl)
	await tree.process_frame
	await tree.physics_frame

	var player := _find_first_by_name_or_suffix(lvl, "Player", "player.gd")
	var is_big := player != null and player.has_method("is_big") and bool(player.call("is_big"))
	await _cleanup_arena(tree, host, lvl)

	if not is_big:
		return _make_result(false, "Player did not spawn in BIG state when GameState.player_power == BIG")
	return _make_result(true, "Player spawned in BIG state when GameState.player_power == BIG")
