extends Node3D
class_name PassengerManager

const MAX_PASSENGERS := 1
const SPAWN_INTERVAL := 8.0
const DELIVERY_RADIUS := 4.0
const GAME_TIME := 90.0  # 90 seconds like Crazy Taxi
const PICKUP_TIME_BONUS := 15.0  # 15 seconds bonus for picking up passenger
const DELIVERY_TIME_BONUS := 10.0  # 10 seconds bonus for successful delivery

@export var passenger_scene: PackedScene
@export var arrow_scene: PackedScene

var spawn_points: Array[Vector3] = []
var destination_points: Array[Vector3] = []
var building_names: Array[String] = []
var active_passengers: Array[Passenger] = []
var destination_arrow: DestinationArrow
var spawn_timer := 0.0
var player_car: VehicleBody3D
var spawn_point_nodes: Array[Node3D] = []
var destination_point_nodes: Array[Node3D] = []

# Timer system variables
var game_timer := GAME_TIME
var game_active := true
var total_score := 0

signal passenger_spawned(passenger: Passenger)
signal passenger_completed(tip: int)
signal passenger_failed()
signal timer_updated(time_remaining: float)
signal game_over(final_score: int)
signal time_extended(amount: float)

func _ready() -> void:
	_find_player_car()
	_setup_points()
	spawn_timer = SPAWN_INTERVAL
	
	# Initialize timer system
	game_timer = GAME_TIME
	game_active = true
	total_score = 0
	timer_updated.emit(game_timer)


func _physics_process(delta: float) -> void:
	if not game_active:
		return
	
	# Update game timer
	game_timer -= delta
	timer_updated.emit(game_timer)
	
	# Check for game over
	if game_timer <= 0.0:
		_end_game()
		return
	
	# Spawn passengers
	spawn_timer -= delta
	
	if spawn_timer <= 0.0 and active_passengers.size() < MAX_PASSENGERS:
		_spawn_passenger()
		spawn_timer = SPAWN_INTERVAL
	
	_check_deliveries()


func _find_player_car() -> void:
	player_car = get_tree().get_first_node_in_group(&"player_car")
	if not player_car:
		push_warning("No player car found in 'player_car' group")

func _setup_points() -> void:
		# Find all spawn points in the scene
	var spawn_nodes = get_tree().get_nodes_in_group("spawn_points")
	var dest_nodes = get_tree().get_nodes_in_group("destination_points")
	
	spawn_point_nodes.clear()
	destination_point_nodes.clear()
	
	for node in spawn_nodes:
		if node is Node3D:
			spawn_point_nodes.append(node as Node3D)
			print("Found spawn point: ", node.name, " at ", node.global_position)
	
	for node in dest_nodes:
		if node is Node3D:
			destination_point_nodes.append(node as Node3D)
			var dest_name = "Unknown"
			if node.has_method("get_destination_name"):
				dest_name = node.get_destination_name()
			elif "destination_name" in node:
				dest_name = node.destination_name
			print("Found destination: ", node.name, " (", dest_name, ") at ", node.global_position)
	
	if spawn_point_nodes.is_empty():
		push_warning("No spawn points found! Make sure your spawn point nodes are in the 'spawn_points' group")
	
	if destination_point_nodes.is_empty():
		push_warning("No destination points found! Make sure your destination point nodes are in the 'destination_points' group")


func _spawn_passenger() -> void:
	if not passenger_scene:
		push_error("No passenger scene assigned")
		return
	
	var passenger := passenger_scene.instantiate() as Passenger
	if not passenger:
		push_error("Failed to instantiate passenger")
		return
	
	var spawn_pos := _get_random_spawn_point()
	var dest_data  := _get_random_destination(spawn_pos)
	
	passenger.global_position = spawn_pos
	passenger.set_destination(dest_data.position, dest_data.name)
	
	_connect_passenger_signals(passenger)
	
	add_child(passenger)
	active_passengers.append(passenger)
	
	passenger_spawned.emit(passenger)
	print("Passenger spawned, going to: ", dest_data.name)


func _get_random_spawn_point() -> Vector3:
	if spawn_point_nodes.is_empty():
		push_error("No spawn points available!")
		return Vector3.ZERO
	var spawn_node = spawn_point_nodes[randi() % spawn_point_nodes.size()]
	return spawn_node.global_position


func _get_random_destination(spawn_pos: Vector3) -> Dictionary:
	var attempts := 0
	var dest_data := {"position": Vector3.ZERO, "name": "Unknown"}
	
	while attempts < 10:
		if destination_point_nodes.is_empty():
			push_error("No destination points available!")
			return dest_data
		
		var dest_node = destination_point_nodes[randi() % destination_point_nodes.size()]
		dest_data.position = dest_node.global_position
		
		# Try to get destination name from the node
		if dest_node.has_method("get_destination_name"):
			dest_data.name = dest_node.get_destination_name()
		elif "destination_name" in dest_node:
			dest_data.name = dest_node.destination_name
		elif dest_node.has_meta("destination_name"):
			dest_data.name = dest_node.get_meta("destination_name")
		else:
			dest_data.name = dest_node.name
		
		# Ensure destination is far enough from spawn
		if dest_data.position.distance_to(spawn_pos) >= 10.0:
			break
			
		attempts += 1
	
	return dest_data



func _connect_passenger_signals(passenger: Passenger) -> void:
	passenger.passenger_picked_up.connect(_on_passenger_picked_up)
	passenger.passenger_delivered.connect(_on_passenger_delivered)
	passenger.passenger_timeout.connect(_on_passenger_timeout)


func _check_deliveries() -> void:
	if not player_car:
		return
	
	var passenger_in_car := _get_passenger_in_car()
	if not passenger_in_car:
		return
	
	var distance := player_car.global_position.distance_to(passenger_in_car.destination_position)
	if distance <= DELIVERY_RADIUS:
		passenger_in_car.deliver()


func _get_passenger_in_car() -> Passenger:
	for passenger in active_passengers:
		if passenger.state == Passenger.State.IN_CAR:
			return passenger
	return null


func has_passenger_in_car() -> bool:
	return _get_passenger_in_car() != null


func _on_passenger_picked_up(passenger: Passenger) -> void:
	print("Passenger picked up: ", passenger.destination_building_name)
	_create_destination_arrow(passenger)
	
	# Add time bonus for picking up passenger
	game_timer += PICKUP_TIME_BONUS
	time_extended.emit(PICKUP_TIME_BONUS)
	print("Time extended by ", PICKUP_TIME_BONUS, " seconds! Time remaining: ", game_timer)

func _on_passenger_delivered(passenger: Passenger, tip: int) -> void:
	print("Passenger delivered! Tip: $", tip)
	active_passengers.erase(passenger)
	passenger_completed.emit(tip)
	_destroy_destination_arrow()
	
	# Add score and time bonus for successful delivery
	total_score += tip
	game_timer += DELIVERY_TIME_BONUS
	time_extended.emit(DELIVERY_TIME_BONUS)
	print("Delivery bonus! +$", tip, " score, +", DELIVERY_TIME_BONUS, " seconds. Total score: $", total_score)

func _on_passenger_timeout(passenger: Passenger) -> void:
	print("Passenger timed out!")
	active_passengers.erase(passenger)
	passenger_failed.emit()
	if passenger.state == Passenger.State.IN_CAR:
		_destroy_destination_arrow()

func _create_destination_arrow(passenger: Passenger) -> void:
	if destination_arrow:
		_destroy_destination_arrow()
	# Create arrow scene or fallback to code-generated arrow
	if arrow_scene:
		destination_arrow = arrow_scene.instantiate() as DestinationArrow
	else:
		destination_arrow = DestinationArrow.new()
	
	if destination_arrow and player_car:
		add_child(destination_arrow)
		destination_arrow.set_target(passenger.destination_position)
		destination_arrow.set_follow_target(player_car)


func _destroy_destination_arrow() -> void:
	if destination_arrow:
		destination_arrow.queue_free()
		destination_arrow = null


func _end_game() -> void:
	game_active = false
	game_over.emit(total_score)
	print("Game Over! Final Score: $", total_score)

# Timer system helper functions
func get_time_remaining() -> float:
	return game_timer

func get_total_score() -> int:
	return total_score

func is_game_active() -> bool:
	return game_active

func restart_game() -> void:
	game_timer = GAME_TIME
	game_active = true
	total_score = 0
	
	# Clear existing passengers
	for passenger in active_passengers:
		passenger.queue_free()
	active_passengers.clear()
	
	# Clear destination arrow
	_destroy_destination_arrow()
	
	# Reset spawn timer
	spawn_timer = SPAWN_INTERVAL
	
	timer_updated.emit(game_timer)
	print("Game restarted! Time: ", game_timer, " seconds")
