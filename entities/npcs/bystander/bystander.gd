extends CharacterBody3D

@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var movement_timer: Timer = $MovementTimer
@onready var idle_timer: Timer = $IdleTimer

enum State {
	IDLE,
	WALKING,
	PANICKING
}

var current_state: State = State.IDLE
var normal_speed: float = 2.0
var panic_speed: float = 7.0
var current_speed: float = 2.0
var panic_distance: float = 10.0

func _ready():
	movement_timer.timeout.connect(_on_movement_timeout)
	idle_timer.timeout.connect(_on_idle_timeout)
	
	# Start with random behavior
	if randf() > 0.5:
		start_walking()
	else:
		start_idle()

func _physics_process(delta: float) -> void:
	check_for_vehicles()
	
	match current_state:
		State.IDLE:
			velocity = Vector3.ZERO
		State.WALKING:
			handle_walking()
		State.PANICKING:
			handle_panic()
	
	move_and_slide()

func handle_walking():
	if navigation_agent_3d.is_navigation_finished():
		start_idle()
		return
	
	var destination = navigation_agent_3d.get_next_path_position()
	var direction = (destination - global_position).normalized()
	velocity = direction * current_speed

func handle_panic():
	# Run away from nearest vehicle
	var nearest_vehicle = get_nearest_vehicle()
	if nearest_vehicle:
		var escape_direction = (global_position - nearest_vehicle.global_position).normalized()
		velocity = escape_direction * panic_speed
		
		# Stop panicking when far enough away
		if global_position.distance_to(nearest_vehicle.global_position) > panic_distance * 1.5:
			start_idle()

func start_walking():
	current_state = State.WALKING
	current_speed = normal_speed + randf_range(-0.5, 0.5)  # Vary speed slightly
	
	# Pick a random destination nearby
	var random_position = global_position + Vector3(
		randf_range(-15.0, 15.0),
		0,
		randf_range(-15.0, 15.0)
	)
	navigation_agent_3d.set_target_position(random_position)
	
	# Walk for a random duration
	movement_timer.start(randf_range(5.0, 12.0))

func start_idle():
	current_state = State.IDLE
	velocity = Vector3.ZERO
	# Stay idle for a random duration
	idle_timer.start(randf_range(2.0, 6.0))

func start_panic():
	current_state = State.PANICKING
	current_speed = panic_speed
	movement_timer.stop()
	idle_timer.stop()

func check_for_vehicles():
	var nearest_vehicle = get_nearest_vehicle()
	if nearest_vehicle and current_state != State.PANICKING:
		var distance = global_position.distance_to(nearest_vehicle.global_position)
		
		if distance < panic_distance:
			start_panic()

func get_nearest_vehicle() -> Node3D:
	var vehicles = get_tree().get_nodes_in_group("vehicles")
	var nearest_vehicle = null
	var min_distance = INF
	
	for vehicle in vehicles:
		var distance = global_position.distance_to(vehicle.global_position)
		if distance < min_distance:
			min_distance = distance
			nearest_vehicle = vehicle
	
	return nearest_vehicle

func _on_movement_timeout():
	start_idle()

func _on_idle_timeout():
	start_walking()
