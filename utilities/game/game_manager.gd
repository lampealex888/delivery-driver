# game_manager.gd
extends Node

const PICKUP_TIME_BONUS := 15.0
const DELIVERY_TIME_BONUS := 10.0
const GAME_DURATION := 90.0
const BASE_FARE := 50

var total_score := 0
var game_time_remaining := GAME_DURATION
var is_game_active := false

@onready var game_timer: Timer = $GameTimer
@onready var update_timer: Timer = $UpdateTimer

signal score_updated(new_score: int)
signal timer_updated(time_remaining: float)
signal game_over(final_score: int)
signal game_started()

func _ready() -> void:
	# Setup game timer
	game_timer.wait_time = GAME_DURATION
	game_timer.timeout.connect(_end_game)
	update_timer.timeout.connect(_on_update_timer_timeout)
	await get_tree().process_frame
	var buildings = get_tree().get_nodes_in_group("buildings")
	for building in buildings:
		if building.has_signal("passenger_delivered"):
			building.passenger_delivered.connect(_on_passenger_delivered)


func _on_update_timer_timeout() -> void:
	if is_game_active:
		game_time_remaining = game_timer.time_left
		timer_updated.emit(game_time_remaining)


func _extend_time(amount: float) -> void:
	if not is_game_active:
		return
	var current_time_left = game_timer.time_left
	game_timer.stop()
	game_timer.wait_time = current_time_left + amount
	game_timer.start()


func _end_game() -> void:
	is_game_active = false
	game_over.emit(total_score)


func _on_passenger_delivered():
	if not is_game_active:
		return
	
	total_score += BASE_FARE
	_extend_time(DELIVERY_TIME_BONUS)
	score_updated.emit(total_score)


func _on_hud_start_game() -> void:
	total_score = 0
	game_time_remaining = GAME_DURATION
	is_game_active = true
	game_timer.wait_time = GAME_DURATION
	game_timer.start()
	score_updated.emit(total_score)
	game_started.emit()
