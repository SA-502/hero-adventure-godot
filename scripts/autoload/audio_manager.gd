@tool
extends Node

# Do NOT declare `class_name AudioManager` — it collides with the Autoload singleton name.

signal mute_changed(muted: bool)

const SFX_POOL_SIZE: int = 10
const SFX_VOLUME_DB: float = 0.0
const BGM_VOLUME_DB: float = -6.0
const BGM_DUCK_OFFSET_DB: float = -10.0
const MUTED_DB: float = -80.0

const SFX_STREAMS: Dictionary = {
	"jump": preload("res://assets/audio/jump.wav"),
	"jump_big": preload("res://assets/audio/jump_big.wav"),
	"coin": preload("res://assets/audio/coin.wav"),
	"bump": preload("res://assets/audio/bump.wav"),
	"brick_break": preload("res://assets/audio/brick_break.wav"),
	"powerup_spawn": preload("res://assets/audio/powerup_spawn.wav"),
	"powerup_collect": preload("res://assets/audio/powerup_collect.wav"),
	"stomp": preload("res://assets/audio/stomp.wav"),
	"kick": preload("res://assets/audio/kick.wav"),
	"hurt": preload("res://assets/audio/hurt.wav"),
	"one_up": preload("res://assets/audio/one_up.wav"),
	"stage_clear": preload("res://assets/audio/stage_clear.wav"),
	"game_over": preload("res://assets/audio/game_over.wav"),
}

const BGM_STREAMS: Dictionary = {
	"overworld": preload("res://assets/audio/bgm_overworld.wav"),
	"castle": preload("res://assets/audio/bgm_castle.wav"),
}

var is_muted: bool = false
var is_ducked: bool = false

var _initialized: bool = false
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_cursor: int = 0
var _bgm_player: AudioStreamPlayer = null
var _current_bgm: String = ""


func _ready() -> void:
	_ensure_initialized()


func _ensure_initialized() -> void:
	if _initialized:
		return
	_initialized = true
	process_mode = Node.PROCESS_MODE_ALWAYS

	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "BGMPlayer"
	_bgm_player.bus = &"Master"
	_bgm_player.finished.connect(_on_bgm_finished)
	add_child(_bgm_player)

	for i in range(SFX_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.name = "SFXPlayer_%d" % i
		player.bus = &"Master"
		add_child(player)
		_sfx_players.append(player)

	_apply_volume_state()


func play_sfx(sfx_name: String) -> void:
	_ensure_initialized()
	if not SFX_STREAMS.has(sfx_name):
		push_warning("AudioManager.play_sfx: Unknown SFX key '%s'" % sfx_name)
		return

	var stream: AudioStream = SFX_STREAMS[sfx_name]
	if stream == null:
		push_warning("AudioManager.play_sfx: Missing stream for key '%s'" % sfx_name)
		return

	var player := _acquire_sfx_player()
	player.stream = stream
	player.volume_db = _get_sfx_volume_db()
	if player.is_inside_tree():
		player.play()


func play_bgm(bgm_name: String) -> void:
	_ensure_initialized()
	if not BGM_STREAMS.has(bgm_name):
		push_warning("AudioManager.play_bgm: Unknown BGM key '%s'" % bgm_name)
		return

	if _current_bgm == bgm_name and _bgm_player.playing:
		return

	var stream: AudioStream = BGM_STREAMS[bgm_name]
	if stream == null:
		push_warning("AudioManager.play_bgm: Missing stream for key '%s'" % bgm_name)
		return

	_current_bgm = bgm_name
	_bgm_player.stream = stream
	_bgm_player.volume_db = _get_bgm_volume_db()
	if _bgm_player.is_inside_tree():
		_bgm_player.play()


func stop_bgm() -> void:
	_ensure_initialized()
	_current_bgm = ""
	if _bgm_player.playing:
		_bgm_player.stop()


func toggle_mute() -> bool:
	set_muted(not is_muted)
	return is_muted


func set_muted(muted: bool) -> void:
	_ensure_initialized()
	if is_muted == muted:
		return
	is_muted = muted
	_apply_volume_state()
	mute_changed.emit(is_muted)


func set_paused_duck(ducked: bool) -> void:
	_ensure_initialized()
	if is_ducked == ducked:
		return
	is_ducked = ducked
	_apply_volume_state()


func _acquire_sfx_player() -> AudioStreamPlayer:
	for offset in range(_sfx_players.size()):
		var idx := (_sfx_cursor + offset) % _sfx_players.size()
		var candidate := _sfx_players[idx]
		if not candidate.playing:
			_sfx_cursor = (idx + 1) % _sfx_players.size()
			return candidate

	var fallback := _sfx_players[_sfx_cursor]
	_sfx_cursor = (_sfx_cursor + 1) % _sfx_players.size()
	return fallback


func _get_sfx_volume_db() -> float:
	return MUTED_DB if is_muted else SFX_VOLUME_DB


func _get_bgm_volume_db() -> float:
	if is_muted:
		return MUTED_DB
	return (BGM_VOLUME_DB + BGM_DUCK_OFFSET_DB) if is_ducked else BGM_VOLUME_DB


func _apply_volume_state() -> void:
	if not _initialized:
		return
	var bgm_db := _get_bgm_volume_db()
	var sfx_db := _get_sfx_volume_db()
	_bgm_player.volume_db = bgm_db
	for player in _sfx_players:
		player.volume_db = sfx_db


func _on_bgm_finished() -> void:
	if not _current_bgm.is_empty() and BGM_STREAMS.has(_current_bgm) and _bgm_player != null and _bgm_player.is_inside_tree():
		_bgm_player.play()
