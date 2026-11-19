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

	cases["s01_title_to_level_1"] = await _case_s01_title_to_level_1(tree, host)
	cases["s02_level_1_playthrough"] = await _case_s02_level_1_playthrough(tree, host)
	cases["s03_hundred_coin_rollover"] = await _case_s03_hundred_coin_rollover(tree, host)
	cases["s04_big_mario_retention"] = await _case_s04_big_mario_retention(tree, host)
	cases["s05_damage_shrink_invuln_death"] = await _case_s05_damage_shrink_invuln_death(tree, host)
	cases["s06_level_2_platform_and_1up"] = await _case_s06_level_2_platform_and_1up(tree, host)
	cases["s07_level_2_shell_multi_kill"] = await _case_s07_level_2_shell_multi_kill(tree, host)
	cases["s08_level_3_lava_lethal_big"] = await _case_s08_level_3_lava_lethal_big(tree, host)
	cases["s09_level_3_castle_to_victory"] = await _case_s09_level_3_castle_to_victory(tree, host)
	cases["s10_pause_then_restart"] = await _case_s10_pause_then_restart(tree, host)
	cases["s11_pause_main_menu_best_score"] = await _case_s11_pause_main_menu_best_score(tree, host)
	cases["s12_game_over_to_play_again"] = await _case_s12_game_over_to_play_again(tree, host)
	cases["s13_brick_shatter_bumps_enemy"] = await _case_s13_brick_shatter_bumps_enemy(tree, host)

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
		gs.set("best_score", 0)
	var am := tree.root.get_node_or_null("AudioManager")
	if am != null:
		if am.has_method("stop_bgm"):
			am.call("stop_bgm")
		if am.has_method("set_muted"):
			am.call("set_muted", false)
		if am.has_method("set_paused_duck"):
			am.call("set_paused_duck", false)


func _cleanup(tree: SceneTree, host: Node, node_to_free: Node) -> void:
	_reset_globals(tree)
	if node_to_free != null and is_instance_valid(node_to_free):
		if node_to_free.get_parent() != null:
			node_to_free.get_parent().remove_child(node_to_free)
		node_to_free.queue_free()
	if is_instance_valid(tree.current_scene) and tree.current_scene != host:
		var cur := tree.current_scene
		if cur.get_parent() != null:
			cur.get_parent().remove_child(cur)
		cur.queue_free()
	if is_instance_valid(host):
		tree.current_scene = host
	await tree.process_frame


func _step_physics(tree: SceneTree, frames: int) -> void:
	for _i in range(frames):
		await tree.physics_frame


func _wait_for_scene_change(tree: SceneTree, prev_scene: Node, expected_path: String, max_frames: int = 240) -> Node:
	for _i in range(max_frames):
		await tree.process_frame
		var cur := tree.current_scene
		if is_instance_valid(cur) and cur != prev_scene:
			if expected_path.is_empty() or cur.scene_file_path == expected_path:
				return cur
	return tree.current_scene


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


func _collect_visible_labels_text(root: Node) -> String:
	var parts: PackedStringArray = PackedStringArray()
	_collect_visible_labels_rec(root, parts)
	return " | ".join(parts)


func _collect_visible_labels_rec(node: Node, out: PackedStringArray) -> void:
	if node is CanvasItem and not (node as CanvasItem).visible:
		return
	if node is Label:
		out.append((node as Label).text)
	elif node is RichTextLabel:
		out.append((node as RichTextLabel).text)
	for child in node.get_children():
		_collect_visible_labels_rec(child, out)


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


func _is_enum_match(node: Object, prop_names: Array[String], expected_str: String, expected_int: int) -> bool:
	for prop in prop_names:
		var val: Variant = node.get(prop)
		if val != null:
			if typeof(val) == TYPE_STRING or typeof(val) == TYPE_STRING_NAME:
				return String(val) == expected_str
			return int(val) == expected_int
	return false


func _find_question_block(root: Node, reward_str: String, reward_int: int) -> Node2D:
	var blocks := _find_by_script_suffix(root, "question_block.gd")
	for b in blocks:
		if _is_enum_match(b, ["reward_type", "reward"], reward_str, reward_int):
			return b as Node2D
	return null


func _hit_block_from_below_with_player(tree: SceneTree, level_node: Node2D, player: CharacterBody2D, block: Node2D) -> void:
	var space := level_node.get_world_2d().direct_space_state
	var from_pt := block.global_position + Vector2(0.0, 20.0)
	var to_pt := from_pt + Vector2(0.0, 140.0)
	var query := PhysicsRayQueryParameters2D.create(from_pt, to_pt, 1)
	var hit := space.intersect_ray(query)
	if not hit.is_empty():
		player.global_position = Vector2(block.global_position.x, (hit["position"] as Vector2).y)
		player.velocity = Vector2.ZERO
		await _step_physics(tree, 3)
		Input.action_press("jump")
		await _step_physics(tree, 22)
		Input.action_release("jump")
	else:
		player.global_position = block.global_position + Vector2(0.0, 56.0)
		player.velocity = Vector2(0.0, -380.0)
		await _step_physics(tree, 18)
	await _step_physics(tree, 5)


func _create_arena_with_floor(host: Node, floor_y: float = 200.0, floor_width: float = 900.0) -> Node2D:
	var arena := Node2D.new()
	arena.name = "Tier4Arena"
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


# ---------- 13 Tier 4 End-to-End Scenarios ----------

func _case_s01_title_to_level_1(tree: SceneTree, host: Node) -> Dictionary:
	var missing := _check_required_scenes([SCENE_MAIN, SCENE_LEVEL_1])
	if not missing.is_empty():
		return _make_result(false, missing)

	_reset_globals(tree)
	var gs := tree.root.get_node_or_null("GameState")
	var am := tree.root.get_node_or_null("AudioManager")
	if gs == null or am == null:
		return _make_result(false, "Missing GameState or AudioManager autoload")

	# Dirty GameState before starting
	gs.call("add_score", 500)
	gs.call("add_coin", 20)
	gs.call("lose_life")
	gs.call("set_power", 1)
	gs.call("set_level", 3)

	var title := _instantiate(SCENE_MAIN)
	if title == null:
		return _make_result(false, "Failed to instantiate main.tscn")
	tree.root.add_child(title)
	tree.current_scene = title
	await tree.process_frame

	var start_btn := _find_button_by_text(title, "ابدأ المغامرة")
	if start_btn == null:
		await _cleanup(tree, host, title)
		return _make_result(false, "Title screen missing 'ابدأ المغامرة' button")

	start_btn.pressed.emit()
	var lvl := await _wait_for_scene_change(tree, title, SCENE_LEVEL_1, 30)
	await tree.process_frame

	var path_ok := is_instance_valid(lvl) and lvl.scene_file_path == SCENE_LEVEL_1
	var gs_reset_ok := int(gs.get("lives")) == 3 and int(gs.get("score")) == 0 and int(gs.get("coins")) == 0 and int(gs.get("player_power")) == 0 and int(gs.get("current_level")) == 1
	var hud := _find_first_by_name_or_suffix(lvl, "HUD", "hud.gd")
	var hud_text := _collect_visible_labels_text(hud) if hud != null else ""
	var has_arabic_hud := hud_text.find("1-1") != -1 or hud_text.find("180") != -1
	var bgm_ok := _get_bgm_stream_path(am).ends_with("bgm_overworld.wav")

	await _cleanup(tree, host, lvl)
	if not path_ok or not gs_reset_ok or not has_arabic_hud or not bgm_ok:
		return _make_result(false, "Onboarding flow failed: path_ok=%s, gs_reset=%s, hud='%s', bgm_ok=%s" % [str(path_ok), str(gs_reset_ok), hud_text, str(bgm_ok)])
	return _make_result(true, "Title -> Start Adventure reset GameState, loaded Level 1-1, HUD, and overworld BGM")


func _case_s02_level_1_playthrough(tree: SceneTree, host: Node) -> Dictionary:
	var missing := _check_required_scenes([SCENE_LEVEL_1, SCENE_LEVEL_2])
	if not missing.is_empty():
		return _make_result(false, missing)

	_reset_globals(tree)
	var gs := tree.root.get_node_or_null("GameState")
	var lvl := _instantiate(SCENE_LEVEL_1) as Node2D
	if lvl == null or gs == null:
		return _make_result(false, "Failed to instantiate level_1.tscn")

	tree.root.add_child(lvl)
	tree.current_scene = lvl
	await tree.process_frame

	var player := _find_first_by_name_or_suffix(lvl, "Player", "player.gd") as CharacterBody2D
	var qblock := _find_question_block(lvl, "COIN", 0)
	var walkers := _find_by_script_suffix(lvl, "walker_enemy.gd")
	var flagpole := _find_first_by_name_or_suffix(lvl, "Flagpole", "flagpole.gd") as Node2D
	if player == null or qblock == null or walkers.is_empty() or flagpole == null:
		await _cleanup(tree, host, lvl)
		return _make_result(false, "level_1.tscn missing Player, COIN QuestionBlock, WalkerEnemy, or Flagpole")

	# 1. Hit COIN QuestionBlock
	await _hit_block_from_below_with_player(tree, lvl, player, qblock)
	var after_block_coins := int(gs.get("coins"))
	var after_block_score := int(gs.get("score"))

	# 2. Stomp WalkerEnemy
	var walker := walkers[0] as Node2D
	player.global_position = walker.global_position + Vector2(0.0, -48.0)
	player.velocity = Vector2(0.0, 120.0)
	await _step_physics(tree, 20)
	var after_stomp_score := int(gs.get("score"))

	# 3. Clear Flagpole -> transition to level_2.tscn
	var cleared_flag := [false]
	if flagpole.has_signal("level_cleared"):
		flagpole.connect("level_cleared", func(_tb: int) -> void: cleared_flag[0] = true)
	player.global_position = flagpole.global_position
	player.velocity = Vector2.ZERO

	var next_scene := await _wait_for_scene_change(tree, lvl, SCENE_LEVEL_2, 240)
	var final_score := int(gs.get("score"))
	var transitioned := is_instance_valid(next_scene) and next_scene.scene_file_path == SCENE_LEVEL_2

	await _cleanup(tree, host, next_scene)
	if after_block_coins < 1 or after_block_score < 100 or after_stomp_score < 300 or not cleared_flag[0] or final_score <= after_stomp_score or not transitioned:
		return _make_result(false, "Playthrough failed: coins=%d, block_score=%d, stomp_score=%d, cleared=%s, final_score=%d, transitioned=%s" % [after_block_coins, after_block_score, after_stomp_score, str(cleared_flag[0]), final_score, str(transitioned)])
	return _make_result(true, "Level 1 playthrough: ? block, enemy stomp, Flagpole bonus, and Level 1-2 transition verified")


func _case_s03_hundred_coin_rollover(tree: SceneTree, host: Node) -> Dictionary:
	var missing := _check_required_scenes([SCENE_LEVEL_1])
	if not missing.is_empty():
		return _make_result(false, missing)

	_reset_globals(tree)
	var gs := tree.root.get_node_or_null("GameState")
	var lvl := _instantiate(SCENE_LEVEL_1) as Node2D
	if lvl == null or gs == null:
		return _make_result(false, "Failed to instantiate level_1.tscn")

	tree.root.add_child(lvl)
	tree.current_scene = lvl
	await tree.process_frame

	gs.call("add_coin", 98)
	var player := _find_first_by_name_or_suffix(lvl, "Player", "player.gd") as CharacterBody2D
	var coins := _find_by_script_suffix(lvl, "coin.gd")
	var qblock := _find_question_block(lvl, "COIN", 0)
	var hud := _find_first_by_name_or_suffix(lvl, "HUD", "hud.gd")
	if player == null or coins.is_empty() or qblock == null or hud == null:
		await _cleanup(tree, host, lvl)
		return _make_result(false, "level_1.tscn missing Player, Coin, COIN QuestionBlock, or HUD")

	var coin_node := coins[0] as Node2D
	player.global_position = coin_node.global_position
	player.velocity = Vector2.ZERO
	await _step_physics(tree, 5)
	var mid_coins := int(gs.get("coins"))

	await _hit_block_from_below_with_player(tree, lvl, player, qblock)
	await tree.process_frame

	var end_coins := int(gs.get("coins"))
	var end_lives := int(gs.get("lives"))
	var end_score := int(gs.get("score"))
	var hud_text := _collect_labels_text(hud)

	await _cleanup(tree, host, lvl)
	if mid_coins != 99 or end_coins != 0 or end_lives != 4 or end_score < 200 or hud_text.find("4") == -1:
		return _make_result(false, "100-coin rollover failed: mid=%d, end_coins=%d, lives=%d, score=%d, hud='%s'" % [mid_coins, end_coins, end_lives, end_score, hud_text])
	return _make_result(true, "Mid-level 100-coin rollover wrapped 98->99->0, granted +1 life, and updated HUD")


func _case_s04_big_mario_retention(tree: SceneTree, host: Node) -> Dictionary:
	var missing := _check_required_scenes([SCENE_LEVEL_1, SCENE_LEVEL_2])
	if not missing.is_empty():
		return _make_result(false, missing)

	_reset_globals(tree)
	var gs := tree.root.get_node_or_null("GameState")
	var lvl1 := _instantiate(SCENE_LEVEL_1) as Node2D
	if lvl1 == null or gs == null:
		return _make_result(false, "Failed to instantiate level_1.tscn")

	tree.root.add_child(lvl1)
	tree.current_scene = lvl1
	await tree.process_frame

	var p1 := _find_first_by_name_or_suffix(lvl1, "Player", "player.gd") as CharacterBody2D
	var q_mush := _find_question_block(lvl1, "MUSHROOM", 1)
	var flagpole1 := _find_first_by_name_or_suffix(lvl1, "Flagpole", "flagpole.gd") as Node2D
	if p1 == null or q_mush == null or flagpole1 == null:
		await _cleanup(tree, host, lvl1)
		return _make_result(false, "level_1.tscn missing Player, MUSHROOM QuestionBlock, or Flagpole")

	await _hit_block_from_below_with_player(tree, lvl1, p1, q_mush)
	await _step_physics(tree, 12)
	var mushrooms := _find_by_script_suffix(lvl1, "mushroom.gd")
	if mushrooms.is_empty():
		await _cleanup(tree, host, lvl1)
		return _make_result(false, "MUSHROOM QuestionBlock did not spawn Mushroom in level_1")

	var mush := mushrooms[0] as Node2D
	p1.global_position = mush.global_position
	p1.velocity = Vector2.ZERO
	await _step_physics(tree, 5)
	if not (p1.has_method("is_big") and bool(p1.call("is_big"))):
		await _cleanup(tree, host, lvl1)
		return _make_result(false, "Player did not grow to BIG after collecting Mushroom")

	p1.global_position = flagpole1.global_position
	var lvl2 := await _wait_for_scene_change(tree, lvl1, SCENE_LEVEL_2, 240)
	await tree.process_frame
	await _step_physics(tree, 2)

	if not is_instance_valid(lvl2) or lvl2.scene_file_path != SCENE_LEVEL_2:
		await _cleanup(tree, host, lvl2)
		return _make_result(false, "Failed to transition from 1-1 to 1-2")

	var p2 := _find_first_by_name_or_suffix(lvl2, "Player", "player.gd") as CharacterBody2D
	var bricks := _find_by_script_suffix(lvl2, "brick_block.gd")
	if p2 == null or bricks.is_empty():
		await _cleanup(tree, host, lvl2)
		return _make_result(false, "level_2.tscn missing Player or BrickBlock")

	var retained_big := p2.has_method("is_big") and bool(p2.call("is_big"))
	var brick := bricks[0] as Node2D
	var score_before_brick := int(gs.get("score"))
	await _hit_block_from_below_with_player(tree, lvl2 as Node2D, p2, brick)
	await _step_physics(tree, 5)
	var brick_shattered := (not is_instance_valid(brick)) or brick.is_queued_for_deletion()
	var score_delta := int(gs.get("score")) - score_before_brick

	await _cleanup(tree, host, lvl2)
	if not retained_big or not brick_shattered or score_delta < 50:
		return _make_result(false, "BIG retention failed: retained_big=%s, shattered=%s, score_delta=%d" % [str(retained_big), str(brick_shattered), score_delta])
	return _make_result(true, "BIG Mario retained power from 1-1 into 1-2 and shattered BrickBlock (+50)")


func _case_s05_damage_shrink_invuln_death(tree: SceneTree, host: Node) -> Dictionary:
	var missing := _check_required_scenes([SCENE_PLAYER, SCENE_WALKER])
	if not missing.is_empty():
		return _make_result(false, missing)

	_reset_globals(tree)
	var gs := tree.root.get_node_or_null("GameState")
	if gs == null:
		return _make_result(false, "Missing /root/GameState")
	gs.call("set_power", 1)

	var arena := _create_arena_with_floor(host, 200.0)
	var player := _instantiate(SCENE_PLAYER) as CharacterBody2D
	var walker := _instantiate(SCENE_WALKER) as CharacterBody2D
	if player == null or walker == null:
		await _cleanup(tree, host, arena)
		return _make_result(false, "Failed to instantiate Player or WalkerEnemy")

	player.position = Vector2(100.0, 200.0)
	walker.position = Vector2(138.0, 200.0)
	arena.add_child(walker)
	arena.add_child(player)
	if player.has_method("is_big") and not bool(player.call("is_big")) and player.has_method("collect_powerup"):
		player.call("collect_powerup")

	# 1. Lateral hit -> shrink + invuln
	Input.action_press("move_right")
	for _i in range(30):
		await tree.physics_frame
		if player.has_method("is_invulnerable") and bool(player.call("is_invulnerable")):
			break
	Input.action_release("move_right")

	var shrunk := player.has_method("is_big") and not bool(player.call("is_big"))
	var invuln_on := player.has_method("is_invulnerable") and bool(player.call("is_invulnerable"))
	var lives_after_hit1 := int(gs.get("lives"))
	if not shrunk or not invuln_on or lives_after_hit1 != 3:
		await _cleanup(tree, host, arena)
		return _make_result(false, "Step 1 shrink failed: shrunk=%s, invuln=%s, lives=%d" % [str(shrunk), str(invuln_on), lives_after_hit1])

	# 2. Immediate 2nd hit during invuln -> ignored
	player.position = walker.position + Vector2(-18.0, 0.0)
	await _step_physics(tree, 8)
	var still_alive := player.has_method("is_dead") and not bool(player.call("is_dead"))
	if not still_alive or int(gs.get("lives")) != 3:
		await _cleanup(tree, host, arena)
		return _make_result(false, "Step 2 invulnerability failed to block 2nd hit")

	# 3. Wait > 1.5s (96 frames at 60fps) while keeping player safe from walker
	player.position = Vector2(40.0, 200.0)
	await _step_physics(tree, 96)
	var invuln_expired := player.has_method("is_invulnerable") and not bool(player.call("is_invulnerable"))
	if not invuln_expired:
		await _cleanup(tree, host, arena)
		return _make_result(false, "Step 3 invulnerability did not expire after 1.6s")

	# 4. Post-invuln lateral hit -> kills SMALL player
	player.position = walker.position + Vector2(-24.0, 0.0)
	Input.action_press("move_right")
	for _i in range(30):
		await tree.physics_frame
		if player.has_method("is_dead") and bool(player.call("is_dead")):
			break
	Input.action_release("move_right")

	var died := player.has_method("is_dead") and bool(player.call("is_dead"))
	var lives_final := int(gs.get("lives"))
	await _cleanup(tree, host, arena)

	if not died or lives_final != 2:
		return _make_result(false, "Step 4 post-invuln hit failed: died=%s, lives=%d" % [str(died), lives_final])
	return _make_result(true, "Damage shrink -> 1.5s invuln protection -> expiry -> lethal death verified")


func _case_s06_level_2_platform_and_1up(tree: SceneTree, host: Node) -> Dictionary:
	var missing := _check_required_scenes([SCENE_LEVEL_2])
	if not missing.is_empty():
		return _make_result(false, missing)

	_reset_globals(tree)
	var gs := tree.root.get_node_or_null("GameState")
	var lvl2 := _instantiate(SCENE_LEVEL_2) as Node2D
	if lvl2 == null or gs == null:
		return _make_result(false, "Failed to instantiate level_2.tscn")

	tree.root.add_child(lvl2)
	tree.current_scene = lvl2
	await tree.process_frame

	var player := _find_first_by_name_or_suffix(lvl2, "Player", "player.gd") as CharacterBody2D
	var platforms := _find_by_script_suffix(lvl2, "moving_platform.gd")
	if player == null or platforms.is_empty():
		await _cleanup(tree, host, lvl2)
		return _make_result(false, "level_2.tscn missing Player or MovingPlatform")

	var plat := platforms[0] as Node2D
	player.global_position = plat.global_position + Vector2(0.0, -12.0)
	player.velocity = Vector2.ZERO
	await _step_physics(tree, 5)
	var p_start := player.global_position
	await _step_physics(tree, 40)
	var p_end := player.global_position
	var rode_ok := p_start.distance_to(p_end) > 4.0 and player.is_on_floor() and not (player.has_method("is_dead") and bool(player.call("is_dead")))

	# Find hidden 1-UP QuestionBlock or Mushroom
	var one_up_q := _find_question_block(lvl2, "ONE_UP", 2)
	var got_1up := false
	if one_up_q != null:
		await _hit_block_from_below_with_player(tree, lvl2, player, one_up_q)
		await _step_physics(tree, 12)
		for m in _find_by_script_suffix(lvl2, "mushroom.gd"):
			player.global_position = (m as Node2D).global_position
			player.velocity = Vector2.ZERO
			await _step_physics(tree, 5)
		got_1up = int(gs.get("lives")) == 4
	else:
		for m in _find_by_script_suffix(lvl2, "mushroom.gd"):
			if _is_enum_match(m, ["mushroom_type", "kind", "type", "reward_type"], "ONE_UP", 1):
				player.global_position = (m as Node2D).global_position
				player.velocity = Vector2.ZERO
				await _step_physics(tree, 5)
				got_1up = int(gs.get("lives")) == 4
				break

	var still_small := player.has_method("is_big") and not bool(player.call("is_big"))
	await _cleanup(tree, host, lvl2)

	if not rode_ok or not got_1up or not still_small:
		return _make_result(false, "Level 2 platform/1-UP failed: rode=%s, got_1up=%s, still_small=%s" % [str(rode_ok), str(got_1up), str(still_small)])
	return _make_result(true, "Level 1-2 MovingPlatform carry and hidden 1-UP collection verified")


func _case_s07_level_2_shell_multi_kill(tree: SceneTree, host: Node) -> Dictionary:
	var missing := _check_required_scenes([SCENE_PLAYER, SCENE_SHELL, SCENE_WALKER])
	if not missing.is_empty():
		return _make_result(false, missing)

	_reset_globals(tree)
	var gs := tree.root.get_node_or_null("GameState")
	var arena := _create_arena_with_floor(host, 200.0, 900.0)
	_add_wall(arena, Vector2(360.0, 160.0), Vector2(32.0, 120.0))

	var player := _instantiate(SCENE_PLAYER) as CharacterBody2D
	var shell := _instantiate(SCENE_SHELL) as CharacterBody2D
	var w1 := _instantiate(SCENE_WALKER) as CharacterBody2D
	var w2 := _instantiate(SCENE_WALKER) as CharacterBody2D
	if player == null or shell == null or w1 == null or w2 == null:
		await _cleanup(tree, host, arena)
		return _make_result(false, "Failed to instantiate Player, ShellEnemy, or WalkerEnemys")

	shell.position = Vector2(120.0, 200.0)
	w1.position = Vector2(205.0, 200.0)
	w2.position = Vector2(255.0, 200.0)
	player.position = Vector2(120.0, 152.0)
	player.velocity = Vector2(0.0, 120.0)

	arena.add_child(shell)
	arena.add_child(w1)
	arena.add_child(w2)
	arena.add_child(player)

	for _i in range(20):
		await tree.physics_frame
		if shell.has_method("is_shell_idle") and bool(shell.call("is_shell_idle")):
			break
	if not (shell.has_method("is_shell_idle") and bool(shell.call("is_shell_idle"))):
		await _cleanup(tree, host, arena)
		return _make_result(false, "ShellEnemy did not enter SHELL_IDLE on stomp")

	# Kick right (and confirm kick grace keeps player alive)
	player.position = Vector2(shell.position.x - 26.0, 200.0)
	player.velocity = Vector2.ZERO
	await _step_physics(tree, 3)
	Input.action_press("move_right")
	for _i in range(20):
		await tree.physics_frame
		if shell.has_method("is_sliding") and bool(shell.call("is_sliding")):
			break
	Input.action_release("move_right")

	var player_safe := player.has_method("is_dead") and not bool(player.call("is_dead"))
	# Move player out of rebound path while shell clears walkers & rebounds
	player.position = Vector2(30.0, 80.0)

	var rebounded := false
	for _i in range(90):
		await tree.physics_frame
		if is_instance_valid(shell) and shell.velocity.x < -10.0:
			rebounded = true
			break

	var w1_dead := (not is_instance_valid(w1)) or w1.is_queued_for_deletion() or not w1.is_physics_processing()
	var w2_dead := (not is_instance_valid(w2)) or w2.is_queued_for_deletion() or not w2.is_physics_processing()
	var still_sliding := is_instance_valid(shell) and shell.has_method("is_sliding") and bool(shell.call("is_sliding"))
	var score := int(gs.get("score")) if gs != null else 0
	await _cleanup(tree, host, arena)

	if not player_safe or not w1_dead or not w2_dead or not rebounded or not still_sliding:
		return _make_result(false, "Shell multi-kill failed: safe=%s, w1=%s, w2=%s, rebounded=%s, sliding=%s, score=%d" % [str(player_safe), str(w1_dead), str(w2_dead), str(rebounded), str(still_sliding), score])
	return _make_result(true, "Shell kick spared player via grace, defeated 2 walkers, and rebounded off wall")


func _case_s08_level_3_lava_lethal_big(tree: SceneTree, host: Node) -> Dictionary:
	var missing := _check_required_scenes([SCENE_LEVEL_3])
	if not missing.is_empty():
		return _make_result(false, missing)

	_reset_globals(tree)
	var gs := tree.root.get_node_or_null("GameState")
	if gs == null:
		return _make_result(false, "Missing /root/GameState")
	gs.call("set_power", 1)

	var lvl3 := _instantiate(SCENE_LEVEL_3) as Node2D
	if lvl3 == null:
		return _make_result(false, "Failed to instantiate level_3.tscn")

	tree.root.add_child(lvl3)
	tree.current_scene = lvl3
	await tree.process_frame

	var player := _find_first_by_name_or_suffix(lvl3, "Player", "player.gd") as CharacterBody2D
	var hazard := _find_first_by_name_or_suffix(lvl3, "HazardZone", "") as Node2D
	if player == null or hazard == null:
		await _cleanup(tree, host, lvl3)
		return _make_result(false, "level_3.tscn missing Player or HazardZone")

	if player.has_method("is_big") and not bool(player.call("is_big")) and player.has_method("collect_powerup"):
		player.call("collect_powerup")
	if player.has_method("take_damage"):
		player.call("take_damage", false)
	if player.has_method("collect_powerup"):
		player.call("collect_powerup")

	player.global_position = hazard.global_position
	for _i in range(20):
		await tree.physics_frame
		if not is_instance_valid(player) or (player.has_method("is_dead") and bool(player.call("is_dead"))):
			break

	var is_dead := (not is_instance_valid(player)) or (player.has_method("is_dead") and bool(player.call("is_dead")))
	var lives := int(gs.get("lives"))
	var power := int(gs.get("player_power"))
	await _cleanup(tree, host, tree.current_scene)

	if not is_dead or lives != 2 or power != 0:
		return _make_result(false, "Lava lethal check failed: dead=%s, lives=%d, power=%d" % [str(is_dead), lives, power])
	return _make_result(true, "Level 1-3 lava HazardZone instantly killed invulnerable BIG Mario")


func _case_s09_level_3_castle_to_victory(tree: SceneTree, host: Node) -> Dictionary:
	var missing := _check_required_scenes([SCENE_LEVEL_3, SCENE_END])
	if not missing.is_empty():
		return _make_result(false, missing)

	_reset_globals(tree)
	var gs := tree.root.get_node_or_null("GameState")
	var am := tree.root.get_node_or_null("AudioManager")
	var lvl3 := _instantiate(SCENE_LEVEL_3) as Node2D
	if lvl3 == null or gs == null or am == null:
		return _make_result(false, "Failed to instantiate level_3.tscn or missing autoloads")

	tree.root.add_child(lvl3)
	tree.current_scene = lvl3
	await tree.process_frame

	var castle_bgm := _get_bgm_stream_path(am).ends_with("bgm_castle.wav")
	var player := _find_first_by_name_or_suffix(lvl3, "Player", "player.gd") as CharacterBody2D
	var flagpole := _find_first_by_name_or_suffix(lvl3, "Flagpole", "flagpole.gd") as Node2D
	if player == null or flagpole == null:
		await _cleanup(tree, host, lvl3)
		return _make_result(false, "level_3.tscn missing Player or Flagpole")

	player.global_position = flagpole.global_position
	var end_scr := await _wait_for_scene_change(tree, lvl3, SCENE_END, 240)
	await tree.process_frame

	var reached_end := is_instance_valid(end_scr) and end_scr.scene_file_path == SCENE_END
	var won := bool(gs.get("game_won"))
	var score := int(gs.get("score"))
	var best := int(gs.get("best_score"))
	var end_texts := _collect_labels_text(end_scr) if is_instance_valid(end_scr) else ""
	var has_score_text := end_texts.find(str(score)) != -1 and end_texts.find(str(best)) != -1

	await _cleanup(tree, host, end_scr)
	if not castle_bgm or not reached_end or not won or best < score or not has_score_text:
		return _make_result(false, "Castle victory failed: castle_bgm=%s, reached_end=%s, won=%s, score=%d, best=%d, texts='%s'" % [str(castle_bgm), str(reached_end), str(won), score, best, end_texts])
	return _make_result(true, "Level 1-3 castle BGM -> final Flagpole -> EndScreen victory & best_score verified")


func _case_s10_pause_then_restart(tree: SceneTree, host: Node) -> Dictionary:
	var missing := _check_required_scenes([SCENE_LEVEL_1])
	if not missing.is_empty():
		return _make_result(false, missing)

	_reset_globals(tree)
	var am := tree.root.get_node_or_null("AudioManager")
	var lvl1 := _instantiate(SCENE_LEVEL_1)
	if lvl1 == null or am == null:
		return _make_result(false, "Failed to instantiate level_1.tscn")

	tree.root.add_child(lvl1)
	tree.current_scene = lvl1
	await tree.process_frame
	await _step_physics(tree, 70)

	var pause_menu := _find_first_by_name_or_suffix(lvl1, "PauseMenu", "pause_menu.gd")
	if pause_menu == null or not pause_menu.has_method("toggle_pause"):
		await _cleanup(tree, host, lvl1)
		return _make_result(false, "level_1.tscn missing PauseMenu with toggle_pause()")

	pause_menu.call("toggle_pause")
	var paused_ok := tree.paused and bool(am.get("is_ducked"))
	var restart_btn := _find_button_by_text(pause_menu, "إعادة المرحلة")
	if restart_btn == null:
		await _cleanup(tree, host, lvl1)
		return _make_result(false, "PauseMenu missing 'إعادة المرحلة' button")

	restart_btn.pressed.emit()
	var reloaded := await _wait_for_scene_change(tree, lvl1, SCENE_LEVEL_1, 30)
	await tree.process_frame

	var unpaused_ok := not tree.paused and not bool(am.get("is_ducked"))
	var hud := _find_first_by_name_or_suffix(reloaded, "HUD", "hud.gd") if is_instance_valid(reloaded) else null
	var hud_text := _collect_labels_text(hud) if hud != null else ""
	var timer_reset := hud_text.find("180") != -1

	await _cleanup(tree, host, reloaded)
	if not paused_ok or not unpaused_ok or not timer_reset:
		return _make_result(false, "Pause->Restart failed: paused_ok=%s, unpaused_ok=%s, hud='%s'" % [str(paused_ok), str(unpaused_ok), hud_text])
	return _make_result(true, "PauseMenu -> Restart unpaused tree, unducked audio, and restored 180s timer")


func _case_s11_pause_main_menu_best_score(tree: SceneTree, host: Node) -> Dictionary:
	var missing := _check_required_scenes([SCENE_LEVEL_2, SCENE_MAIN, SCENE_LEVEL_1])
	if not missing.is_empty():
		return _make_result(false, missing)

	_reset_globals(tree)
	var gs := tree.root.get_node_or_null("GameState")
	var lvl2 := _instantiate(SCENE_LEVEL_2)
	if lvl2 == null or gs == null:
		return _make_result(false, "Failed to instantiate level_2.tscn")

	tree.root.add_child(lvl2)
	tree.current_scene = lvl2
	await tree.process_frame
	gs.call("add_score", 800)

	var pause_menu := _find_first_by_name_or_suffix(lvl2, "PauseMenu", "pause_menu.gd")
	if pause_menu == null or not pause_menu.has_method("toggle_pause"):
		await _cleanup(tree, host, lvl2)
		return _make_result(false, "level_2.tscn missing PauseMenu")

	pause_menu.call("toggle_pause")
	var mm_btn := _find_button_by_text(pause_menu, "القائمة الرئيسية")
	if mm_btn == null:
		await _cleanup(tree, host, lvl2)
		return _make_result(false, "PauseMenu missing 'القائمة الرئيسية' button")

	mm_btn.pressed.emit()
	var title := await _wait_for_scene_change(tree, lvl2, SCENE_MAIN, 30)
	await tree.process_frame

	var at_main := is_instance_valid(title) and title.scene_file_path == SCENE_MAIN and not tree.paused
	var title_text := _collect_labels_text(title) if is_instance_valid(title) else ""
	var shows_best := title_text.find("800") != -1

	var start_btn := _find_button_by_text(title, "ابدأ المغامرة") if is_instance_valid(title) else null
	if start_btn == null:
		await _cleanup(tree, host, title)
		return _make_result(false, "Main menu missing 'ابدأ المغامرة' after returning from pause")

	start_btn.pressed.emit()
	var new_lvl1 := await _wait_for_scene_change(tree, title, SCENE_LEVEL_1, 30)
	await tree.process_frame

	var new_score_zero := int(gs.get("score")) == 0
	var kept_best := int(gs.get("best_score")) >= 800

	await _cleanup(tree, host, new_lvl1)
	if not at_main or not shows_best or not new_score_zero or not kept_best:
		return _make_result(false, "Pause->MainMenu failed: at_main=%s, shows_best=%s, score_zero=%s, kept_best=%s" % [str(at_main), str(shows_best), str(new_score_zero), str(kept_best)])
	return _make_result(true, "Pause -> Main Menu preserved best_score>=800 while new adventure reset score=0")


func _case_s12_game_over_to_play_again(tree: SceneTree, host: Node) -> Dictionary:
	var missing := _check_required_scenes([SCENE_LEVEL_1, SCENE_END])
	if not missing.is_empty():
		return _make_result(false, missing)

	_reset_globals(tree)
	var gs := tree.root.get_node_or_null("GameState")
	var lvl1 := _instantiate(SCENE_LEVEL_1) as Node2D
	if lvl1 == null or gs == null:
		return _make_result(false, "Failed to instantiate level_1.tscn")

	tree.root.add_child(lvl1)
	tree.current_scene = lvl1
	await tree.process_frame

	gs.call("lose_life")
	gs.call("lose_life")
	gs.call("add_score", 350)
	if int(gs.get("lives")) != 1:
		await _cleanup(tree, host, lvl1)
		return _make_result(false, "Failed to stage lives=1")

	var player := _find_first_by_name_or_suffix(lvl1, "Player", "player.gd") as CharacterBody2D
	var fall_zone := _find_first_by_name_or_suffix(lvl1, "FallZone", "") as Node2D
	if player == null or fall_zone == null:
		await _cleanup(tree, host, lvl1)
		return _make_result(false, "level_1.tscn missing Player or FallZone")

	player.global_position = fall_zone.global_position
	var end_scr := await _wait_for_scene_change(tree, lvl1, SCENE_END, 240)
	await tree.process_frame

	var reached_end := is_instance_valid(end_scr) and end_scr.scene_file_path == SCENE_END
	var is_game_over := int(gs.get("lives")) == 0 and bool(gs.get("game_over"))
	var kept_best := int(gs.get("best_score")) >= 350

	var play_again := _find_button_by_text(end_scr, "إعادة اللعب") if is_instance_valid(end_scr) else null
	if not reached_end or not is_game_over or not kept_best or play_again == null:
		await _cleanup(tree, host, end_scr)
		return _make_result(false, "GameOver flow failed: reached_end=%s, game_over=%s, kept_best=%s, btn=%s" % [str(reached_end), str(is_game_over), str(kept_best), str(play_again != null)])

	play_again.pressed.emit()
	var restarted := await _wait_for_scene_change(tree, end_scr, SCENE_LEVEL_1, 30)
	await tree.process_frame

	var reset_ok := is_instance_valid(restarted) and restarted.scene_file_path == SCENE_LEVEL_1 and int(gs.get("lives")) == 3 and int(gs.get("score")) == 0 and int(gs.get("coins")) == 0 and int(gs.get("player_power")) == 0
	await _cleanup(tree, host, restarted)

	if not reset_ok:
		return _make_result(false, "Play Again did not reset GameState cleanly onto level_1.tscn")
	return _make_result(true, "0-lives Game Over -> EndScreen -> Play Again reset lives=3, score=0, SMALL on Level 1")


func _case_s13_brick_shatter_bumps_enemy(tree: SceneTree, host: Node) -> Dictionary:
	var missing := _check_required_scenes([SCENE_PLAYER, SCENE_BRICK, SCENE_WALKER])
	if not missing.is_empty():
		return _make_result(false, missing)

	_reset_globals(tree)
	var gs := tree.root.get_node_or_null("GameState")
	if gs == null:
		return _make_result(false, "Missing /root/GameState")
	gs.call("set_power", 1)

	var arena := _create_arena_with_floor(host, 200.0)
	var player := _instantiate(SCENE_PLAYER) as CharacterBody2D
	var brick := _instantiate(SCENE_BRICK) as Node2D
	var walker := _instantiate(SCENE_WALKER) as Node2D
	if player == null or brick == null or walker == null:
		await _cleanup(tree, host, arena)
		return _make_result(false, "Failed to instantiate Player, BrickBlock, or WalkerEnemy")

	player.position = Vector2(120.0, 200.0)
	brick.position = Vector2(120.0, 116.0)
	walker.position = Vector2(120.0, 100.0)
	arena.add_child(brick)
	arena.add_child(walker)
	arena.add_child(player)
	if player.has_method("is_big") and not bool(player.call("is_big")) and player.has_method("collect_powerup"):
		player.call("collect_powerup")

	await _step_physics(tree, 3)
	Input.action_press("jump")
	await _step_physics(tree, 22)
	Input.action_release("jump")
	await _step_physics(tree, 15)

	var brick_shattered := (not is_instance_valid(brick)) or brick.is_queued_for_deletion()
	var walker_defeated := (not is_instance_valid(walker)) or walker.is_queued_for_deletion() or not walker.is_physics_processing()
	var score := int(gs.get("score"))
	await _cleanup(tree, host, arena)

	if not brick_shattered or not walker_defeated or score < 50:
		return _make_result(false, "Brick shatter + enemy bump failed: shattered=%s, walker_defeated=%s, score=%d" % [str(brick_shattered), str(walker_defeated), score])
	return _make_result(true, "BIG Mario shattered BrickBlock (+50) and defeated WalkerEnemy above in one hit")
