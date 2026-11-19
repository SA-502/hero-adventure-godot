@tool
extends Node

# Do NOT declare `class_name GameState` — it collides with the Autoload singleton name.

enum PowerState { SMALL, BIG }

const DEFAULT_LIVES: int = 3
const COINS_PER_EXTRA_LIFE: int = 100
const MAX_LEVEL: int = 3
const LEVEL_SCENES: Dictionary = {
	1: "res://scenes/levels/level_1.tscn",
	2: "res://scenes/levels/level_2.tscn",
	3: "res://scenes/levels/level_3.tscn",
}

signal score_changed(new_score: int)
signal coins_changed(new_coins: int)
signal lives_changed(new_lives: int)
signal power_changed(new_power: int)
signal level_changed(new_level: int)

var score: int = 0
var coins: int = 0
var lives: int = DEFAULT_LIVES
var player_power: PowerState = PowerState.SMALL
var current_level: int = 1
var best_score: int = 0
var game_won: bool = false
var game_over: bool = false


func reset_game() -> void:
	score = 0
	coins = 0
	lives = DEFAULT_LIVES
	player_power = PowerState.SMALL
	current_level = 1
	game_won = false
	game_over = false

	score_changed.emit(score)
	coins_changed.emit(coins)
	lives_changed.emit(lives)
	power_changed.emit(player_power)
	level_changed.emit(current_level)


func add_score(points: int) -> void:
	if points <= 0:
		return
	score += points
	if score > best_score:
		best_score = score
	score_changed.emit(score)


func add_coin(amount: int = 1) -> void:
	if amount <= 0:
		return
	coins += amount
	var extra_lives: int = coins / COINS_PER_EXTRA_LIFE
	if extra_lives > 0:
		coins = coins % COINS_PER_EXTRA_LIFE
		add_life(extra_lives)
		if is_inside_tree():
			var am := get_node_or_null("/root/AudioManager")
			if am != null and am.has_method("play_sfx"):
				am.play_sfx("one_up")
	coins_changed.emit(coins)


func add_life(amount: int = 1) -> void:
	if amount <= 0:
		return
	lives += amount
	lives_changed.emit(lives)


func lose_life() -> void:
	lives = maxi(0, lives - 1)
	lives_changed.emit(lives)
	if lives <= 0:
		mark_game_over()


func set_power(power: PowerState) -> void:
	player_power = power
	power_changed.emit(player_power)


func set_level(level_num: int) -> void:
	current_level = clampi(level_num, 1, MAX_LEVEL)
	level_changed.emit(current_level)


func get_level_scene_path(level_num: int = -1) -> String:
	var target_level: int = current_level if level_num <= 0 else level_num
	target_level = clampi(target_level, 1, MAX_LEVEL)
	return LEVEL_SCENES.get(target_level, "res://scenes/levels/level_1.tscn")


func mark_victory() -> void:
	game_won = true
	game_over = false


func mark_game_over() -> void:
	game_over = true
	game_won = false
