# game_manager.gd - Updated to work with new passenger system
extends Node
class_name GameManager

const PICKUP_TIME_BONUS := 15.0
const DELIVERY_TIME_BONUS := 10.0
const GAME_DURATION := 300.0

var total_score := 0
var game_time_remaining := GAME_DURATION
var is_game_active := false

@onready var game_timer: Timer = $GameTimer
@onready var passenger_spawner: PassengerSpawner = $PassengerSpawner
@onready var passenger_manager: PassengerManager = $PassengerManager

signal score_updated(new_score: int)
signal timer_updated(time_remaining: float)
signal game_over(final_score: int)
signal time_extended(amount: float)
signal game_started()

func _ready() -> void:
	# Setup game timer
	game_timer.wait_time = GAME_DURATION
	game_timer.timeout.connect(_end_game)
	
	# Connect to passenger manager events
	if passenger_manager:
		passenger_manager.passenger_picked_up.connect(_on_passenger_picked_up)
		passenger_manager.passenger_delivered.connect(_on_passenger_delivered)
		passenger_manager.passenger_timeout.connect(_on_passenger_timeout)
	
	# Setup spawner
	if passenger_spawner:
		passenger_spawner.pause_spawning()  # Don't spawn until game starts

func _process(delta: float) -> void:
	if is_game_active:
		game_time_remaining = game_timer.time_left
		timer_updated.emit(game_time_remaining)

func start_game() -> void:
	total_score = 0
	game_time_remaining = GAME_DURATION
	is_game_active = true
	
	# Reset timer
	game_timer.wait_time = GAME_DURATION
	game_timer.start()
	
	# Start passenger spawning
	if passenger_spawner:
		passenger_spawner.resume_spawning()
	
	# Clear any existing passengers
	if passenger_manager:
		passenger_manager.cleanup_all_passengers()
	
	# Emit signals
	score_updated.emit(total_score)
	game_started.emit()

func _on_passenger_picked_up(passenger: Passenger) -> void:
	if not is_game_active:
		return
	
	_extend_time(PICKUP_TIME_BONUS)
	
	# Optional: Small score bonus for pickup
	# total_score += 10
	# score_updated.emit(total_score)

func _on_passenger_delivered(passenger: Passenger, tip: int) -> void:
	if not is_game_active:
		return
	
	total_score += tip
	_extend_time(DELIVERY_TIME_BONUS)
	score_updated.emit(total_score)

func _on_passenger_timeout(passenger: Passenger) -> void:
	if not is_game_active:
		return
	
	# Optional: Score penalty for timeout
	# total_score = max(0, total_score - 25)
	# score_updated.emit(total_score)

func _extend_time(amount: float) -> void:
	if not is_game_active:
		return
	
	# Extend the timer
	var current_time_left = game_timer.time_left
	game_timer.stop()
	game_timer.wait_time = current_time_left + amount
	game_timer.start()
	
	time_extended.emit(amount)

func _end_game() -> void:
	is_game_active = false
	
	# Stop passenger spawning
	if passenger_spawner:
		passenger_spawner.pause_spawning()
	
	# Clean up passengers
	if passenger_manager:
		passenger_manager.cleanup_all_passengers()
	
	game_over.emit(total_score)

func get_current_score() -> int:
	return total_score

func get_time_remaining() -> float:
	return game_time_remaining

func is_active() -> bool:
	return is_game_active
