extends CharacterBody2D

enum State { WALK, SHELL_IDLE, SHELL_SLIDE, DEAD }

const WALK_SPEED: float = 55.0
const SLIDE_SPEED: float = 280.0
const GRAVITY: float = 1400.0
const MAX_FALL_SPEED: float = 650.0
const KICK_GRACE: float = 0.25

@export var start_direction: int = -1

var _state: State = State.WALK
var _direction: float = -1.0
var _kick_grace_left: float = 0.0


func _ready() -> void:
	if not is_in_group("enemies"):
		add_to_group("enemies")
	_direction = -1.0 if start_direction <= 0 else 1.0
	var hb := get_node_or_null("Hitbox") as Area2D
	if hb != null and not hb.body_entered.is_connected(_on_hitbox_body_entered):
		hb.body_entered.connect(_on_hitbox_body_entered)
	_update_sprite()


func is_sliding() -> bool:
	return _state == State.SHELL_SLIDE


func is_shell_idle() -> bool:
	return _state == State.SHELL_IDLE


func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		return

	if _kick_grace_left > 0.0:
		_kick_grace_left = maxf(0.0, _kick_grace_left - delta)

	match _state:
		State.WALK:
			velocity.x = _direction * WALK_SPEED
		State.SHELL_IDLE:
			velocity.x = 0.0
		State.SHELL_SLIDE:
			velocity.x = _direction * SLIDE_SPEED

	velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
	move_and_slide()

	if is_on_wall() and (_state == State.WALK or _state == State.SHELL_SLIDE):
		var wall_norm := get_wall_normal()
		if wall_norm.x != 0.0:
			_direction = 1.0 if wall_norm.x > 0.0 else -1.0
		else:
			_direction = -_direction
		velocity.x = _direction * (SLIDE_SPEED if _state == State.SHELL_SLIDE else WALK_SPEED)
		_update_sprite()
		if _state == State.SHELL_SLIDE:
			_play_sfx("bump")

	if global_position.y > 1200.0:
		queue_free()
		return

	var hb := get_node_or_null("Hitbox") as Area2D
	if hb != null:
		for body in hb.get_overlapping_bodies():
			_handle_overlap(body)
			if _state == State.DEAD:
				return


func _on_hitbox_body_entered(body: Node) -> void:
	_handle_overlap(body)


func _handle_overlap(body: Node) -> void:
	if _state == State.DEAD or body == null or body == self:
		return

	if body.is_in_group("enemies"):
		if _state == State.SHELL_SLIDE and body.has_method("on_hit_by_shell"):
			body.call("on_hit_by_shell", self)
		elif body.has_method("is_sliding") and bool(body.call("is_sliding")):
			on_hit_by_shell(body)
		return

	if not body.is_in_group("player"):
		return
	if body.has_method("is_dead") and bool(body.call("is_dead")):
		return
	if body.has_method("is_level_cleared") and bool(body.call("is_level_cleared")):
		return

	var p2d := body as CharacterBody2D
	var stomped_from_above := p2d != null and p2d.velocity.y > 0.0 and p2d.global_position.y <= global_position.y - 8.0

	match _state:
		State.WALK:
			if stomped_from_above:
				on_stomped(p2d)
			elif body.has_method("take_damage"):
				body.call("take_damage", false)
		State.SHELL_IDLE:
			if stomped_from_above:
				on_stomped(p2d)
			else:
				kick(body)
		State.SHELL_SLIDE:
			if stomped_from_above:
				on_stomped(p2d)
			elif _kick_grace_left <= 0.0 and body.has_method("take_damage"):
				body.call("take_damage", false)


func on_stomped(player: Node = null) -> void:
	if _state == State.DEAD:
		return

	match _state:
		State.WALK:
			_state = State.SHELL_IDLE
			velocity.x = 0.0
			_update_sprite()
			var gs := _game_state()
			if gs != null and gs.has_method("add_score"):
				gs.call("add_score", 200)
			_play_sfx("stomp")
			if player != null and player.has_method("bounce"):
				player.call("bounce", false)
		State.SHELL_IDLE:
			kick(player)
			if player != null and player.has_method("bounce"):
				player.call("bounce", false)
		State.SHELL_SLIDE:
			_state = State.SHELL_IDLE
			velocity.x = 0.0
			_kick_grace_left = 0.0
			_update_sprite()
			_play_sfx("stomp")
			if player != null and player.has_method("bounce"):
				player.call("bounce", false)


func kick(player: Node = null) -> void:
	if _state == State.DEAD:
		return
	if player != null and player is Node2D:
		var dx := global_position.x - (player as Node2D).global_position.x
		_direction = -1.0 if dx < 0.0 else 1.0
	_state = State.SHELL_SLIDE
	_kick_grace_left = KICK_GRACE
	velocity.x = _direction * SLIDE_SPEED
	_update_sprite()
	_play_sfx("kick")


func on_block_bumped() -> void:
	if _state == State.DEAD:
		return
	_state = State.DEAD
	set_physics_process(false)
	_disable_collisions()
	var gs := _game_state()
	if gs != null and gs.has_method("add_score"):
		gs.call("add_score", 200)
	_play_sfx("stomp")
	queue_free()


func on_hit_by_shell(_shell: Node = null) -> void:
	if _state == State.DEAD:
		return
	_state = State.DEAD
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


func _update_sprite() -> void:
	var spr := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if spr == null:
		return
	spr.flip_h = _direction > 0.0
	if _state == State.WALK:
		spr.play(&"walk")
	else:
		spr.play(&"shell")


func _game_state() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/GameState")
	return null


func _play_sfx(key: String) -> void:
	if is_inside_tree():
		var am := get_node_or_null("/root/AudioManager")
		if am != null and am.has_method("play_sfx"):
			am.call("play_sfx", key)
