extends StaticBody2D

enum RewardType { COIN, MUSHROOM, ONE_UP }

const MUSHROOM_SCENE: PackedScene = preload("res://scenes/objects/mushroom.tscn")
const COIN_FRAMES: SpriteFrames = preload("res://assets/sprites/coin_frames.tres")
const STAR_TEXTURE: Texture2D = preload("res://assets/sprites/particle_star.png")

@export var reward_type: RewardType = RewardType.COIN

var _used: bool = false


func hit_from_below(player: Node = null) -> void:
	if player == null:
		return

	var spr := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if _used:
		_play_sfx("bump")
		if spr != null:
			spr.play(&"used")
		return

	_used = true
	if spr != null:
		spr.play(&"used")
		var tw := create_tween()
		tw.tween_property(spr, "position:y", -8.0, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(spr, "position:y", 0.0, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	_bump_enemies_above()

	match reward_type:
		RewardType.COIN:
			var gs := _game_state()
			if gs != null:
				if gs.has_method("add_coin"):
					gs.call("add_coin", 1)
				if gs.has_method("add_score"):
					gs.call("add_score", 100)
			_play_sfx("coin")
			_spawn_coin_popup()
		RewardType.MUSHROOM:
			_spawn_mushroom(0)
		RewardType.ONE_UP:
			_spawn_mushroom(1)


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


func _spawn_coin_popup() -> void:
	var host := get_parent()
	if host == null:
		return
	var popup := AnimatedSprite2D.new()
	popup.sprite_frames = COIN_FRAMES
	popup.animation = &"spin"
	popup.play(&"spin")
	popup.global_position = global_position + Vector2(0.0, -24.0)
	host.add_child(popup)
	var tw := popup.create_tween()
	tw.tween_property(popup, "global_position:y", global_position.y - 54.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(popup, "modulate:a", 0.0, 0.15)
	tw.tween_callback(popup.queue_free)

	var burst := CPUParticles2D.new()
	burst.texture = STAR_TEXTURE
	burst.amount = 6
	burst.lifetime = 0.4
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.spread = 180.0
	burst.initial_velocity_min = 40.0
	burst.initial_velocity_max = 90.0
	burst.gravity = Vector2(0.0, 120.0)
	burst.global_position = global_position + Vector2(0.0, -24.0)
	burst.emitting = true
	host.add_child(burst)
	var timer := get_tree().create_timer(0.6)
	timer.timeout.connect(burst.queue_free)


func _spawn_mushroom(mushroom_kind: int) -> void:
	_play_sfx("powerup_spawn")
	var host := get_parent()
	if host == null:
		return
	var m := MUSHROOM_SCENE.instantiate() as Node2D
	if m == null:
		return
	m.set("mushroom_type", mushroom_kind)
	m.global_position = global_position + Vector2(0.0, -16.0)
	host.add_child(m)


func _game_state() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/GameState")
	return null


func _play_sfx(key: String) -> void:
	if is_inside_tree():
		var am := get_node_or_null("/root/AudioManager")
		if am != null and am.has_method("play_sfx"):
			am.call("play_sfx", key)
