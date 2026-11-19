extends StaticBody2D

const SHARD_TEXTURE: Texture2D = preload("res://assets/sprites/brick_shard.png")

var _broken: bool = false


func hit_from_below(player: Node = null) -> void:
	if player == null or _broken:
		return

	_bump_enemies_above()

	var is_player_big := player.has_method("is_big") and bool(player.call("is_big"))
	if is_player_big:
		_broken = true
		var gs := _game_state()
		if gs != null and gs.has_method("add_score"):
			gs.call("add_score", 50)
		_play_sfx("brick_break")
		_spawn_shards()
		queue_free()
	else:
		_play_sfx("bump")
		var spr := get_node_or_null("Sprite2D") as Sprite2D
		if spr != null:
			var tw := create_tween()
			tw.tween_property(spr, "position:y", -8.0, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tw.tween_property(spr, "position:y", 0.0, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _bump_enemies_above() -> void:
	var bumped: Array[Node] = []
	var det := get_node_or_null("TopEnemyDetector") as Area2D
	if det != null:
		for body in det.get_overlapping_bodies():
			if body != null and body.has_method("on_block_bumped") and not bumped.has(body):
				bumped.append(body)
				body.call("on_block_bumped")

	if is_inside_tree():
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy == null or not is_instance_valid(enemy) or bumped.has(enemy):
				continue
			if enemy is Node2D and enemy.has_method("on_block_bumped"):
				var epos := (enemy as Node2D).global_position
				if absf(epos.x - global_position.x) <= 26.0 and epos.y <= global_position.y - 8.0 and epos.y >= global_position.y - 36.0:
					bumped.append(enemy)
					enemy.call("on_block_bumped")


func _spawn_shards() -> void:
	var host := get_parent()
	if host == null:
		return
	var particles := CPUParticles2D.new()
	particles.texture = SHARD_TEXTURE
	particles.amount = 4
	particles.lifetime = 0.65
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.direction = Vector2(0.0, -1.0)
	particles.spread = 75.0
	particles.initial_velocity_min = 120.0
	particles.initial_velocity_max = 220.0
	particles.gravity = Vector2(0.0, 600.0)
	particles.angular_velocity_min = -360.0
	particles.angular_velocity_max = 360.0
	particles.global_position = global_position
	particles.emitting = true
	host.add_child(particles)
	if is_inside_tree():
		var timer := get_tree().create_timer(1.0)
		timer.timeout.connect(particles.queue_free)


func _game_state() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/GameState")
	return null


func _play_sfx(key: String) -> void:
	if is_inside_tree():
		var am := get_node_or_null("/root/AudioManager")
		if am != null and am.has_method("play_sfx"):
			am.call("play_sfx", key)
