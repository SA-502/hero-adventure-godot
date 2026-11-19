extends AnimatableBody2D

@export var move_offset: Vector2 = Vector2(96.0, 0.0)
@export var duration: float = 2.0

var _origin: Vector2 = Vector2.ZERO
var _elapsed: float = 0.0
var _initialized: bool = false
var _restore_sync: bool = false


func _ready() -> void:
	if sync_to_physics:
		_restore_sync = true
		sync_to_physics = false


func _physics_process(delta: float) -> void:
	if not _initialized:
		_origin = position
		if _restore_sync:
			sync_to_physics = true
			_restore_sync = false
		_initialized = true
		return

	if duration <= 0.0 or is_zero_approx(duration) or move_offset == Vector2.ZERO:
		return

	_elapsed += delta
	var t := pingpong(_elapsed / duration, 1.0)
	position = _origin + move_offset * t
