extends CharacterBody2D

signal died
signal power_state_changed(is_big: bool)
signal level_clear_finished

const WALK_SPEED: float = 175.0
const SPRINT_SPEED: float = 265.0
const GROUND_ACCEL: float = 1200.0
const GROUND_FRICTION: float = 1400.0
const AIR_ACCEL: float = 900.0
const AIR_FRICTION: float = 200.0
const JUMP_VELOCITY: float = -630.0
const GRAVITY: float = 1400.0
const FALL_GRAVITY: float = 1800.0
const MAX_FALL_SPEED: float = 650.0
const COYOTE_TIME: float = 0.10
const JUMP_BUFFER_TIME: float = 0.12
const INVULN_DURATION: float = 1.5

const SMALL_FRAMES: SpriteFrames = preload("res://assets/sprites/player_small_frames.tres")
const BIG_FRAMES: SpriteFrames = preload("res://assets/sprites/player_big_frames.tres")

var _is_big: bool = false
var _dead: bool = false
var _invulnerable: bool = false
var _level_cleared: bool = false
var _sliding_flagpole: bool = false
var _flag_bottom_y: float = 0.0

var _coyote_left: float = 0.0
var _jump_buffer_left: float = 0.0
var _invuln_left: float = 0.0
var _blink_accum: float = 0.0


func _ready() -> void:
	if not is_in_group("player"):
		add_to_group("player")
	var gs := _game_state()
	if gs != null and int(gs.get("player_power")) == 1:
		_is_big = true
		_apply_power_shape(true)
	else:
		_is_big = false
		_apply_power_shape(false)


func is_big() -> bool:
	return _is_big


func is_dead() -> bool:
	return _dead


func is_invulnerable() -> bool:
	return _invulnerable


func is_level_cleared() -> bool:
	return _level_cleared


func collect_powerup() -> void:
	if _dead or _level_cleared:
		return
	var was_big := _is_big
	_is_big = true
	_apply_power_shape(true)
	var gs := _game_state()
	if gs != null and gs.has_method("set_power"):
		gs.call("set_power", 1)
	_play_sfx("powerup_collect")
	if not was_big:
		power_state_changed.emit(true)


func take_damage(lethal: bool = false) -> void:
	if _dead or _level_cleared:
		return
	if lethal:
		_die()
		return
	if _invulnerable:
		return
	if _is_big:
		_is_big = false
		_apply_power_shape(false)
		var gs := _game_state()
		if gs != null and gs.has_method("set_power"):
			gs.call("set_power", 0)
		_invulnerable = true
		_invuln_left = INVULN_DURATION
		_blink_accum = 0.0
		_play_sfx("hurt")
		power_state_changed.emit(false)
	else:
		_die()


func bounce(boost: bool = false) -> void:
	if _dead or _level_cleared:
		return
	var jump_held := Input.is_action_pressed("jump") if InputMap.has_action("jump") else false
	velocity.y = -360.0 if (boost or jump_held) else -260.0
	_coyote_left = 0.0


func start_flagpole_slide(pole_x: float, bottom_y: float) -> void:
	if _dead:
		return
	_level_cleared = true
	_sliding_flagpole = true
	_invulnerable = false
	_invuln_left = 0.0
	_set_sprite_alpha(1.0)
	global_position.x = pole_x
	_flag_bottom_y = bottom_y
	velocity = Vector2.ZERO
	_play_anim(&"jump")


func finish_level_clear() -> void:
	_level_cleared = true
	_sliding_flagpole = false
	velocity = Vector2.ZERO
	_play_anim(&"idle")
	level_clear_finished.emit()


func _die() -> void:
	if _dead:
		return
	_dead = true
	_invulnerable = false
	_invuln_left = 0.0
	_is_big = false
	_set_sprite_alpha(1.0)

	var gs := _game_state()
	if gs != null:
		if gs.has_method("set_power"):
			gs.call("set_power", 0)
		if gs.has_method("lose_life"):
			gs.call("lose_life")

	velocity = Vector2(0.0, -340.0)
	var body_col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body_col != null:
		body_col.set_deferred("disabled", true)
	var hitbox := get_node_or_null("Hitbox") as Area2D
	if hitbox != null:
		hitbox.set_deferred("monitoring", false)
		hitbox.set_deferred("monitorable", false)

	_play_sfx("hurt")
	_play_anim(&"hurt")
	died.emit()


func _physics_process(delta: float) -> void:
	if _dead:
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
		position += velocity * delta
		_play_anim(&"hurt")
		return

	if _sliding_flagpole:
		global_position.y = move_toward(global_position.y, _flag_bottom_y, 140.0 * delta)
		if absf(global_position.y - _flag_bottom_y) <= 1.0:
			_sliding_flagpole = false
			_play_anim(&"idle")
		else:
			_play_anim(&"jump")
		return

	if _level_cleared:
		return

	if _invulnerable:
		_invuln_left -= delta
		_blink_accum += delta
		if _invuln_left <= 0.0:
			_invulnerable = false
			_invuln_left = 0.0
			_set_sprite_alpha(1.0)
		else:
			var visible_phase := int(_blink_accum * 16.0) % 2 == 0
			_set_sprite_alpha(0.35 if visible_phase else 1.0)

	var axis := Input.get_axis("move_left", "move_right")
	var sprinting := Input.is_action_pressed("sprint")
	var max_speed := SPRINT_SPEED if sprinting else WALK_SPEED
	var on_floor := is_on_floor()

	if axis != 0.0:
		var accel := GROUND_ACCEL if on_floor else AIR_ACCEL
		velocity.x = move_toward(velocity.x, axis * max_speed, accel * delta)
		var spr := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		if spr != null:
			spr.flip_h = axis < 0.0
	else:
		var friction := GROUND_FRICTION if on_floor else AIR_FRICTION
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	if on_floor:
		_coyote_left = COYOTE_TIME
	else:
		_coyote_left = maxf(0.0, _coyote_left - delta)

	if Input.is_action_just_pressed("jump"):
		_jump_buffer_left = JUMP_BUFFER_TIME
	else:
		_jump_buffer_left = maxf(0.0, _jump_buffer_left - delta)

	if _jump_buffer_left > 0.0 and _coyote_left > 0.0:
		velocity.y = JUMP_VELOCITY
		_coyote_left = 0.0
		_jump_buffer_left = 0.0
		_play_sfx("jump_big" if _is_big else "jump")

	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= 0.45

	var g := GRAVITY if velocity.y < 0.0 else FALL_GRAVITY
	velocity.y = minf(velocity.y + g * delta, MAX_FALL_SPEED)

	var was_rising := velocity.y < 0.0
	move_and_slide()

	if was_rising:
		_check_ceiling_bumps()

	_update_animation()


func _check_ceiling_bumps() -> void:
	var hit_bodies: Array[Object] = []
	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		if col.get_normal().y > 0.5:
			var collider := col.get_collider()
			if collider != null and collider.has_method("hit_from_below") and not hit_bodies.has(collider):
				hit_bodies.append(collider)
				collider.call("hit_from_below", self)

	var hc := get_node_or_null("HeadChecker") as Area2D
	if hc != null:
		for body in hc.get_overlapping_bodies():
			if body != null and body.has_method("hit_from_below") and not hit_bodies.has(body):
				if body is Node2D and (body as Node2D).global_position.y < global_position.y - 16.0:
					hit_bodies.append(body)
					body.call("hit_from_below", self)


func _update_animation() -> void:
	if not is_on_floor():
		_play_anim(&"jump")
	elif absf(velocity.x) > 10.0:
		_play_anim(&"run")
	else:
		_play_anim(&"idle")


func _play_anim(anim_name: StringName) -> void:
	var spr := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if spr != null and spr.sprite_frames != null and spr.sprite_frames.has_animation(anim_name):
		if spr.animation != anim_name or not spr.is_playing():
			spr.play(anim_name)


func _apply_power_shape(big: bool) -> void:
	var spr := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	var body_col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	var hitbox_col := get_node_or_null("Hitbox/CollisionShape2D") as CollisionShape2D
	var head_checker := get_node_or_null("HeadChecker") as Area2D

	if big:
		if spr != null:
			spr.sprite_frames = BIG_FRAMES
			spr.position = Vector2(0.0, -24.0)
		if body_col != null:
			var r := body_col.shape as RectangleShape2D
			if r != null:
				r.size = Vector2(22.0, 44.0)
			body_col.position = Vector2(0.0, -22.0)
		if hitbox_col != null:
			var hr := hitbox_col.shape as RectangleShape2D
			if hr != null:
				hr.size = Vector2(24.0, 42.0)
			hitbox_col.position = Vector2(0.0, -22.0)
		if head_checker != null:
			head_checker.position = Vector2(0.0, -45.0)
	else:
		if spr != null:
			spr.sprite_frames = SMALL_FRAMES
			spr.position = Vector2(0.0, -16.0)
		if body_col != null:
			var r := body_col.shape as RectangleShape2D
			if r != null:
				r.size = Vector2(20.0, 28.0)
			body_col.position = Vector2(0.0, -14.0)
		if hitbox_col != null:
			var hr := hitbox_col.shape as RectangleShape2D
			if hr != null:
				hr.size = Vector2(22.0, 26.0)
			hitbox_col.position = Vector2(0.0, -14.0)
		if head_checker != null:
			head_checker.position = Vector2(0.0, -29.0)


func _set_sprite_alpha(alpha: float) -> void:
	var spr := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if spr != null:
		spr.modulate.a = alpha


func _game_state() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/GameState")
	return null


func _play_sfx(key: String) -> void:
	if is_inside_tree():
		var am := get_node_or_null("/root/AudioManager")
		if am != null and am.has_method("play_sfx"):
			am.call("play_sfx", key)
