extends Node3D

## Turntable for the Blender-authored prop pack imported from GLB.
## Meshes and materials come from Blender (SM_* / MAT_* naming), exported with
## the godot-export contract: GLB, +Y up, applied transforms, floor pivots.

@export var turn_speed: float = 0.6
@export var bob_height: float = 0.08
@export var bob_speed: float = 2.0

@onready var _crate: Node3D = $Props/Crate
@onready var _coin: Node3D = $Props/Coin
@onready var _rock: Node3D = $Props/Rock

var _elapsed: float = 0.0
var _coin_rest_y: float = 0.0


func _ready() -> void:
	_coin_rest_y = _coin.position.y


func _process(delta: float) -> void:
	_elapsed += delta
	_crate.rotate_y(turn_speed * delta)
	_coin.rotate_y(turn_speed * 2.0 * delta)
	_rock.rotate_y(turn_speed * 0.5 * delta)
	_coin.position.y = _coin_rest_y + sin(_elapsed * bob_speed) * bob_height
