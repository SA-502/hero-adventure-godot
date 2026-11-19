extends CharacterBody2D

enum MushroomType { GROW, ONE_UP }

const MOVE_SPEED: float = 70.0
const GRAVITY: float = 1200.0
const MAX_FALL_SPEED: float = 550.0

@export var mushroom_type: MushroomType = MushroomType.GROW:
	set(value):
		mushroom_type = value
		_update_region()

var _direction: float = 1.0
var _collected: bool = false


func _ready() -> void:
	_update_region()
	var pickup := get_node_or_null("PickupArea") as Area2D
	if pickup != null and not pickup.body_entered.is_connected(_on_pickup_body_entered):
		pickup.body_entered.connect(_on_pickup_body_entered)


func _physics_process(delta: float) -> void:
	if _collected:
		return

	velocity.x = MOVE_SPEED * _direction
	velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
	move_and_slide()

	if is_on_wall():
		_direction = -_direction

	if global_position.y > 1200.0:
		queue_free()
		return

	var pickup := get_node_or_null("PickupArea") as Area2D
	if pickup != null:
		for body in pickup.get_overlapping_bodies():
			if _try_collect(body):
				return


func _on_pickup_body_entered(body: Node) -> void:
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
	if mushroom_type == MushroomType.ONE_UP:
		if gs != null:
			if gs.has_method("add_life"):
				gs.call("add_life", 1)
			if gs.has_method("add_score"):
				gs.call("add_score", 1000)
		_play_sfx("one_up")
	else:
		if body.has_method("collect_powerup"):
			body.call("collect_powerup")
		if gs != null and gs.has_method("add_score"):
			gs.call("add_score", 1000)

	queue_free()
	return true


func _update_region() -> void:
	var spr := get_node_or_null("Sprite2D") as Sprite2D
	if spr != null:
		spr.region_enabled = true
		if mushroom_type == MushroomType.ONE_UP:
			spr.region_rect = Rect2(32.0, 0.0, 32.0, 32.0)
		else:
			spr.region_rect = Rect2(0.0, 0.0, 32.0, 32.0)


func _game_state() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/GameState")
	return null


func _play_sfx(key: String) -> void:
	if is_inside_tree():
		var am := get_node_or_null("/root/AudioManager")
		if am != null and am.has_method("play_sfx"):
			am.call("play_sfx", key)
