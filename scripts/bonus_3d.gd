extends Node3D

## Playable 3D bonus level built from the Blender-authored prop pack.
## Assets come from Blender via the godot-export contract (GLB, +Y up, floor
## pivots): the crate acts as an obstacle, the rock as scenery, the coin as the
## collectible.

@export var move_speed: float = 5.0
@export var jump_velocity: float = 5.5
@export var camera_offset: Vector3 = Vector3(0.0, 3.4, 6.4)
@export var turn_speed: float = 1.8

@onready var _player: CharacterBody3D = $Player
@onready var _camera: Camera3D = $Camera3D
@onready var _coin: Area3D = $Coin
@onready var _status: Label = $UI/Status

var _gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
var _yaw: float = 0.0
var _elapsed: float = 0.0
var _coin_rest_y: float = 0.0
var _collected: bool = false
var _spawn: Vector3 = Vector3.ZERO


func _ready() -> void:
	_spawn = _player.global_position
	_coin_rest_y = _coin.position.y
	if not _coin.body_entered.is_connected(_on_coin_touched):
		_coin.body_entered.connect(_on_coin_touched)
	_refresh_status()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_back_to_menu()


func _physics_process(delta: float) -> void:
	if _player.global_position.y < -8.0:
		_respawn()
		return

	if not _player.is_on_floor():
		_player.velocity.y -= _gravity * delta

	if Input.is_key_pressed(KEY_Q):
		_yaw += turn_speed * delta
	if Input.is_key_pressed(KEY_E):
		_yaw -= turn_speed * delta

	var input := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input.y += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input.y -= 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input.x += 1.0

	var direction := Vector3(input.x, 0.0, -input.y)
	if direction.length() > 0.0:
		direction = direction.normalized().rotated(Vector3.UP, _yaw)
	_player.velocity.x = direction.x * move_speed
	_player.velocity.z = direction.z * move_speed

	if Input.is_key_pressed(KEY_SPACE) and _player.is_on_floor():
		_player.velocity.y = jump_velocity

	_player.move_and_slide()
	_update_camera()


func _process(delta: float) -> void:
	_elapsed += delta
	$Crate1.rotate_y(0.6 * delta)
	$Crate2.rotate_y(-0.45 * delta)
	$Crate3.rotate_y(0.35 * delta)
	$Rock1.rotate_y(0.25 * delta)
	$Rock2.rotate_y(-0.2 * delta)
	if not _collected:
		_coin.position.y = _coin_rest_y + sin(_elapsed * 2.0) * 0.12
		$Coin/CoinMesh.rotate_y(1.6 * delta)


func _respawn() -> void:
	_player.velocity = Vector3.ZERO
	_player.global_position = _spawn
	if not _collected:
		_status.text = "عدت إلى نقطة البداية"


func _update_camera() -> void:
	var target: Vector3 = _player.global_position
	var offset: Vector3 = camera_offset.rotated(Vector3.UP, _yaw)
	_camera.global_position = target + offset
	_camera.look_at(target + Vector3(0.0, 0.9, 0.0), Vector3.UP)


func _on_coin_touched(body: Node3D) -> void:
	if _collected or body != _player:
		return
	_collected = true
	_coin.visible = false
	_refresh_status()


func _refresh_status() -> void:
	if _collected:
		_status.text = "جمعت العملة الذهبية!  ·  Esc للعودة"
	else:
		_status.text = "اجمع العملة الذهبية"


func _back_to_menu() -> void:
	if is_inside_tree():
		get_tree().change_scene_to_file("res://scenes/main.tscn")
