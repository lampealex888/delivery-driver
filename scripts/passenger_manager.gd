extends Node3D
class_name PassengerManager

const MAX_PASSENGERS := 3
const DELIVERY_RADIUS := 4.0
const PICKUP_TIME_BONUS := 15.0
const DELIVERY_TIME_BONUS := 10.0

@export var passenger_scene: PackedScene

var active_passengers: Array[Passenger] = []
var player_car: VehicleBody3D
var spawn_points: Array[Node] = []
var destination_points: Array[Node] = []
var total_score := 0

@onready var spawn_timer: Timer = $SpawnTimer
@onready var game_timer: Timer = $GameTimer
@onready var delivery_check_timer: Timer = $DeliveryCheckTimer

signal passenger_picked_up(passenger: Passenger)
signal passenger_delivered(passenger: Passenger, tip: int)
signal passenger_timeout(passenger: Passenger)
signal passenger_completed(tip: int)
signal timer_updated(time_remaining: float)
signal game_over(final_score: int)
signal time_extended(amount: float)

func _ready() -> void:
	_find_player_car()
	_setup_points()	
	timer_updated.emit(game_timer.time_left)


func _process(_delta: float) -> void:
	timer_updated.emit(game_timer.time_left)


func _find_player_car() -> void:
	player_car = get_tree().get_first_node_in_group(&"player_car")


func _setup_points() -> void:
	spawn_points = get_tree().get_nodes_in_group("spawn_points")
	destination_points = get_tree().get_nodes_in_group("destination_points")


func _spawn_passenger() -> void:
	if not passenger_scene or active_passengers.size() >= MAX_PASSENGERS:
		return
	
	var passenger := passenger_scene.instantiate() as Passenger
	var spawn_pos := _get_random_spawn_point()
	var dest_data := _get_random_destination(spawn_pos)
	
	passenger.global_position = spawn_pos
	passenger.set_destination(dest_data.position, dest_data.name)
	
	passenger.passenger_picked_up.connect(_on_passenger_picked_up)
	passenger.passenger_delivered.connect(_on_passenger_delivered)
	passenger.passenger_timeout.connect(_on_passenger_timeout)
	
	add_child(passenger)
	active_passengers.append(passenger)


func _get_random_spawn_point() -> Vector3:
	if spawn_points.is_empty():
		return Vector3.ZERO
	return spawn_points[randi() % spawn_points.size()].global_position


func _get_random_destination(spawn_pos: Vector3) -> Dictionary:
	var dest_data := {"position": Vector3.ZERO, "name": "Unknown"}
	
	if destination_points.is_empty():
		return dest_data
	
	for attempt in range(10):
		var dest_node = destination_points[randi() % destination_points.size()]
		dest_data.position = dest_node.global_position
		
		if dest_node.has_method("get_destination_name"):
			dest_data.name = dest_node.get_destination_name()
		else:
			dest_data.name = dest_node.name
		
		if dest_data.position.distance_to(spawn_pos) >= 10.0:
			break
	
	return dest_data

func _check_deliveries() -> void:
	if not player_car:
		return
	
	var passenger_in_car := _get_passenger_in_car()
	if passenger_in_car:
		var distance := player_car.global_position.distance_to(passenger_in_car.destination_position)
		if distance <= DELIVERY_RADIUS:
			passenger_in_car.deliver()

func _get_passenger_in_car() -> Passenger:
	for passenger in active_passengers:
		if passenger.state == Passenger.State.IN_CAR:
			return passenger
	return null

# These relay passenger events to other systems
func _on_passenger_picked_up(passenger: Passenger) -> void:
	game_timer.wait_time += PICKUP_TIME_BONUS
	time_extended.emit(PICKUP_TIME_BONUS)
	passenger_picked_up.emit(passenger)

func _on_passenger_delivered(passenger: Passenger, tip: int) -> void:
	active_passengers.erase(passenger)
	total_score += tip
	game_timer.wait_time += DELIVERY_TIME_BONUS
	passenger_completed.emit(tip)
	time_extended.emit(DELIVERY_TIME_BONUS)
	passenger_delivered.emit(passenger, tip)

func _on_passenger_timeout(passenger: Passenger) -> void:
	active_passengers.erase(passenger)
	passenger_timeout.emit(passenger)


func _end_game() -> void:
	spawn_timer.stop()
	delivery_check_timer.stop()
	game_over.emit(total_score)

# Simple getters for UI
func get_time_remaining() -> float:
	return game_timer.time_left

func get_total_score() -> int:
	return total_score

func restart_game() -> void:
	total_score = 0
	
	game_timer.start()
	spawn_timer.start()
	delivery_check_timer.start()
	
	for passenger in active_passengers:
		passenger.queue_free()
	active_passengers.clear()
	
	timer_updated.emit(game_timer.time_left)


func _on_spawn_timer_timeout() -> void:
	_spawn_passenger()


func _on_game_timer_timeout() -> void:
	_end_game()


func _on_delivery_check_timer_timeout() -> void:
	_check_deliveries()
