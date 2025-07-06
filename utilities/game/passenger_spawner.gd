# passenger_spawner.gd
extends Node3D
class_name PassengerSpawner

@export var passenger_scene: PackedScene
@export var navigation_region: NavigationRegion3D
@export var spawn_timer: Timer
@export var max_passengers: int = 8
@export var spawn_interval: float = 2.0
@export var spawn_radius: float = 50.0
@export var initial_spawn_count: int = 3
@export var spawn_burst_size: int = 1

var active_passengers: Array[Passenger] = []
var player_car: VehicleBody3D
var is_spawning_enabled: bool = false

signal passenger_spawned(passenger: Passenger)
signal passenger_expired(passenger: Passenger)

func _ready():
	_setup_spawn_timer()
	_find_player_car()


func _setup_spawn_timer():
	if not spawn_timer:
		spawn_timer = Timer.new()
		add_child(spawn_timer)
	
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_try_spawn_passenger)


func _find_player_car():
	var cars = get_tree().get_nodes_in_group("player_car")
	if cars.size() > 0:
		player_car = cars[0]


func _spawn_tick():
	if not is_spawning_enabled:
		return
		
	for i in range(spawn_burst_size):
		if active_passengers.size() >= max_passengers:
			break
		_try_spawn_passenger()


func _try_spawn_passenger():
	if active_passengers.size() >= max_passengers:
		return
	
	var spawn_pos = _get_valid_spawn_position()
	if spawn_pos == Vector3.ZERO:
		return
	
	var destination_pos = _get_destination_position(spawn_pos)
	if destination_pos == Vector3.ZERO:
		return
	
	_spawn_passenger_at(spawn_pos, destination_pos)


func _get_valid_spawn_position() -> Vector3:
	if not navigation_region:
		return Vector3.ZERO
	
	var nav_map = navigation_region.get_navigation_map()
	
	# Try multiple times to find a good spawn position
	for i in range(10):
		# Get random point on navigation mesh
		var random_point = NavigationServer3D.map_get_random_point(nav_map, 1, false)
		
		# Check if it's far enough from player
		if player_car and random_point.distance_to(player_car.global_position) > spawn_radius:
			return random_point
	
	return Vector3.ZERO


func _get_destination_position(spawn_pos: Vector3) -> Vector3:
	if not navigation_region:
		return Vector3.ZERO
	
	var nav_map = navigation_region.get_navigation_map()
	
	# Try to find a destination that's reasonably far from spawn
	for i in range(10):
		var dest_point = NavigationServer3D.map_get_random_point(nav_map, 1, false)
		var distance = spawn_pos.distance_to(dest_point)
		
		# Want destinations that are 20-100 units away
		if distance > 20.0 and distance < 100.0:
			return dest_point
	
	return Vector3.ZERO


func _spawn_passenger_at(spawn_pos: Vector3, dest_pos: Vector3):
	var passenger = passenger_scene.instantiate()
	get_tree().current_scene.add_child(passenger)
	
	passenger.global_position = spawn_pos
	passenger.setup(player_car, dest_pos, "Building " + str(randi() % 100))
	
	# Connect signals
	passenger.passenger_picked_up.connect(_on_passenger_picked_up)
	passenger.passenger_delivered.connect(_on_passenger_delivered)
	passenger.passenger_timeout.connect(_on_passenger_timeout)
	
	active_passengers.append(passenger)
	passenger_spawned.emit(passenger)
	print("Passenger spawned at ", spawn_pos)


func _on_passenger_picked_up(passenger: Passenger):
	# Passenger is now in car, but still tracked
	pass


func _on_passenger_delivered(passenger: Passenger, tip: int):
	active_passengers.erase(passenger)
	# Handle scoring logic here or emit signal to game manager


func _on_passenger_timeout(passenger: Passenger):
	active_passengers.erase(passenger)
	passenger_expired.emit(passenger)


func spawn_initial_passengers():
	if not is_spawning_enabled:
		return
		
	print("Spawning initial passengers...")
	for i in range(initial_spawn_count):
		_try_spawn_passenger()
		# Small delay between spawns to avoid clustering
		await get_tree().process_frame


# Public methods for external control
func enable_spawning():
	is_spawning_enabled = true
	spawn_timer.start()
	# Spawn initial passengers immediately
	call_deferred("spawn_initial_passengers")



func disable_spawning():
	is_spawning_enabled = false
	spawn_timer.stop()


func set_spawn_rate(interval: float):
	spawn_interval = interval
	if spawn_timer:
		spawn_timer.wait_time = interval


func set_spawn_burst_size(size: int):
	spawn_burst_size = clamp(size, 1, 3)


func cleanup_all_passengers():
	for passenger in active_passengers:
		if is_instance_valid(passenger):
			passenger.queue_free()

	active_passengers.clear()
