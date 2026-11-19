extends Area2D

signal level_cleared(time_bonus: int)

const STAR_TEXTURE: Texture2D = preload("res://assets/sprites/particle_star.png")

var _triggered: bool = false
var _time_remaining: int = 0
var _time_explicit: bool = false


func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func set_time_remaining(seconds: int) -> void:
	_time_remaining = maxi(0, seconds)
	_time_explicit = true


func _physics_process(delta: float) -> void:
	if _triggered:
		var banner := get_node_or_null("FlagBanner") as Sprite2D
		if banner != null and banner.position.y < -28.0:
			banner.position.y = move_toward(banner.position.y, -28.0, 220.0 * delta)
		return
	for body in get_overlapping_bodies():
		if _try_trigger(body):
			return


func _on_body_entered(body: Node) -> void:
	_try_trigger(body)


func _try_trigger(body: Node) -> bool:
	if _triggered or body == null:
		return false
	if not body.is_in_group("player"):
		return false
	if body.has_method("is_dead") and bool(body.call("is_dead")):
		return false

	_triggered = true
	var secs: int = _resolve_remaining_seconds()
	var bonus: int = maxi(0, secs) * 10

	_play_sfx("stage_clear")
	_spawn_particles()

	if body.has_method("start_flagpole_slide"):
		body.call("start_flagpole_slide", global_position.x, global_position.y)

	level_cleared.emit(bonus)
	return true


func _resolve_remaining_seconds() -> int:
	if _time_explicit:
		return _time_remaining
	var p := get_parent()
	while p != null:
		var tr: Variant = p.get("time_remaining")
		if tr != null:
			return maxi(0, int(ceil(float(tr))))
		p = p.get_parent()
	return 0


func _spawn_particles() -> void:
	var particles := CPUParticles2D.new()
	particles.texture = STAR_TEXTURE
	particles.amount = 10
	particles.lifetime = 0.8
	particles.one_shot = true
	particles.explosiveness = 0.85
	particles.spread = 180.0
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 120.0
	particles.gravity = Vector2(0.0, 140.0)
	particles.position = Vector2(0.0, -180.0)
	particles.emitting = true
	add_child(particles)
	if is_inside_tree():
		var timer := get_tree().create_timer(1.0)
		timer.timeout.connect(particles.queue_free)


func _play_sfx(key: String) -> void:
	if is_inside_tree():
		var am := get_node_or_null("/root/AudioManager")
		if am != null and am.has_method("play_sfx"):
			am.call("play_sfx", key)
