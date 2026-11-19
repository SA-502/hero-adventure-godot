extends CharacterBody2D

const GRAVITY: float = 1400.0
const MAX_FALL_SPEED: float = 650.0

@export var speed: float = 55.0
@export var start_direction: int = -1

var _direction: float = -1.0
var _defeated: bool = false


func _ready() -> void:
	if not is_in_group("enemies"):
		add_to_group("enemies")
	_direction = -1.0 if start_direction <= 0 else 1.0
	var hb := get_node_or_null("Hitbox") as Area2D
	if hb != null and not hb.body_entered.is_connected(_on_hitbox_body_entered):
		hb.body_entered.connect(_on_hitbox_body_entered)
	_update_sprite_facing()


func _physics_process(delta: float) -> void:
	if _defeated:
		return

	velocity.x = _direction * speed
	velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
	move_and_slide()

	if is_on_wall():
		var wall_norm := get_wall_normal()
		if wall_norm.x != 0.0:
			_direction = 1.0 if wall_norm.x > 0.0 else -1.0
		else:
			_direction = -_direction
		velocity.x = _direction * speed
		_update_sprite_facing()

	if global_position.y > 1200.0:
		queue_free()
		return

	var hb := get_node_or_null("Hitbox") as Area2D
	if hb != null:
		for body in hb.get_overlapping_bodies():
			_handle_overlap(body)
			if _defeated:
				return


func _on_hitbox_body_entered(body: Node) -> void:
	_handle_overlap(body)


func _handle_overlap(body: Node) -> void:
	if _defeated or body == null or body == self:
		return

	if body.is_in_group("enemies") and body.has_method("is_sliding") and bool(body.call("is_sliding")):
		on_hit_by_shell(body)
		return

	if body.is_in_group("player"):
		if body.has_method("is_dead") and bool(body.call("is_dead")):
			return
		if body.has_method("is_level_cleared") and bool(body.call("is_level_cleared")):
			return
		var p2d := body as CharacterBody2D
		if p2d != null and p2d.velocity.y > 0.0 and p2d.global_position.y <= global_position.y - 8.0:
			on_stomped(p2d)
		elif body.has_method("take_damage"):
			body.call("take_damage", false)


func on_stomped(player: Node = null) -> void:
	if _defeated:
		return
	_defeated = true
	set_physics_process(false)
	_disable_collisions()

	var spr := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if spr != null:
		spr.play(&"squished")

	var gs := _game_state()
	if gs != null and gs.has_method("add_score"):
		gs.call("add_score", 200)
	_play_sfx("stomp")

	if player != null and player.has_method("bounce"):
		player.call("bounce", false)

	if is_inside_tree():
		var timer := get_tree().create_timer(0.4)
		timer.timeout.connect(queue_free)
	else:
		queue_free()


func on_block_bumped() -> void:
	if _defeated:
		return
	_defeated = true
	set_physics_process(false)
	_disable_collisions()

	var gs := _game_state()
	if gs != null and gs.has_method("add_score"):
		gs.call("add_score", 200)
	_play_sfx("stomp")
	queue_free()


func on_hit_by_shell(_shell: Node = null) -> void:
	if _defeated:
		return
	_defeated = true
	set_physics_process(false)
	_disable_collisions()

	var gs := _game_state()
	if gs != null and gs.has_method("add_score"):
		gs.call("add_score", 200)
	_play_sfx("kick")
	queue_free()


func _disable_collisions() -> void:
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col != null:
		col.set_deferred("disabled", true)
	var hb := get_node_or_null("Hitbox") as Area2D
	if hb != null:
		hb.set_deferred("monitoring", false)
		hb.set_deferred("monitorable", false)


func _update_sprite_facing() -> void:
	var spr := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if spr != null:
		spr.flip_h = _direction > 0.0


func _game_state() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/GameState")
	return null


func _play_sfx(key: String) -> void:
	if is_inside_tree():
		var am := get_node_or_null("/root/AudioManager")
		if am != null and am.has_method("play_sfx"):
			am.call("play_sfx", key)
