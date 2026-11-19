extends Area2D

const STAR_TEXTURE: Texture2D = preload("res://assets/sprites/particle_star.png")

var _collected: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(_delta: float) -> void:
	if _collected:
		return
	for body in get_overlapping_bodies():
		if _try_collect(body):
			return


func _on_body_entered(body: Node) -> void:
	_try_collect(body)


func _try_collect(body: Node) -> bool:
	if _collected or body == null:
		return false
	if not body.is_in_group("player"):
		return false
	if body.has_method("is_dead") and bool(body.call("is_dead")):
		return false

	_collected = true
	var gs := _game_state()
	if gs != null:
		if gs.has_method("add_coin"):
			gs.call("add_coin", 1)
		if gs.has_method("add_score"):
			gs.call("add_score", 100)
	_play_sfx("coin")
	_spawn_sparkle()
	queue_free()
	return true


func _spawn_sparkle() -> void:
	var host := get_parent()
	if host == null:
		return
	var particles := CPUParticles2D.new()
	particles.texture = STAR_TEXTURE
	particles.amount = 6
	particles.lifetime = 0.45
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.spread = 180.0
	particles.initial_velocity_min = 45.0
	particles.initial_velocity_max = 95.0
	particles.gravity = Vector2(0.0, 120.0)
	particles.global_position = global_position
	particles.emitting = true
	host.add_child(particles)
	if is_inside_tree():
		var timer := get_tree().create_timer(0.6)
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
