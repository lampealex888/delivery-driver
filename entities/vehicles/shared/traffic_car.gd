extends VehicleBody3D

const STEER_SPEED := 2.0
const STEER_LIMIT := 0.6
const AI_SPEED := 20.0
const WAYPOINT_DISTANCE := 3.0
const PATH_UPDATE_TIME := 2.0

@export var engine_force_value := 30.0

var previous_speed := linear_velocity.length()
var _steer_target := 0.0
var current_path: PackedVector3Array = []
var current_waypoint_index := 0
var path_update_timer := 0.0
var navigation_agent: NavigationAgent3D

@onready var desired_engine_pitch: float = $EngineSound.pitch_scale

func _ready() -> void:
	# Create and setup navigation agent
	navigation_agent = NavigationAgent3D.new()
	add_child(navigation_agent)
	navigation_agent.path_desired_distance = 2.0
	navigation_agent.target_desired_distance = 2.0
	
	# Wait for navigation to be ready
	call_deferred("setup_navigation")

func setup_navigation():
	# Get a random target to start moving
	find_new_destination()

func _physics_process(delta: float):
	ai_drive(delta)
	
	# Engine sound simulation
	desired_engine_pitch = 0.05 + linear_velocity.length() / (engine_force_value * 0.5)
	$EngineSound.pitch_scale = lerpf($EngineSound.pitch_scale, desired_engine_pitch, 0.2)

	if abs(linear_velocity.length() - previous_speed) > 1.0:
		# Sudden velocity change, likely due to a collision
		$ImpactSound.play()

	steering = move_toward(steering, _steer_target, STEER_SPEED * delta)
	previous_speed = linear_velocity.length()

func ai_drive(delta: float):
	path_update_timer += delta
	
	# Update path periodically or if we're stuck
	if path_update_timer > PATH_UPDATE_TIME or linear_velocity.length() < 1.0:
		find_new_destination()
		path_update_timer = 0.0
	
	# Get next position from navigation
	if navigation_agent.is_navigation_finished():
		find_new_destination()
		return
	
	var next_position = navigation_agent.get_next_path_position()
	var direction = (next_position - global_position).normalized()
	
	# Calculate steering
	var forward = -transform.basis.z
	var right = transform.basis.x
	
	var steering_angle = direction.dot(right)
	_steer_target = clamp(steering_angle * 2.0, -STEER_LIMIT, STEER_LIMIT)
	
	# Calculate engine force based on alignment with target
	var forward_alignment = direction.dot(forward)
	if forward_alignment > 0.5:  # Moving in roughly the right direction
		engine_force = engine_force_value
	else:
		engine_force = engine_force_value * 0.3  # Slow down when turning
	
	# Slow down if turning sharply
	if abs(_steer_target) > 0.3:
		engine_force *= 0.7

func find_new_destination():
	# Get a random point on the navigation mesh
	var nav_map = get_world_3d().navigation_map
	var random_point = get_random_road_point()
	
	if random_point != Vector3.ZERO:
		navigation_agent.target_position = random_point

func get_random_road_point() -> Vector3:
	# Try to find a valid point on the navigation mesh
	var attempts = 10
	var nav_map = get_world_3d().navigation_map
	
	for i in attempts:
		# Generate random point in a reasonable range around current position
		var random_offset = Vector3(
			randf_range(-50, 50),
			0,
			randf_range(-50, 50)
		)
		var test_point = global_position + random_offset
		
		# Check if point is on navigation mesh
		var closest_point = NavigationServer3D.map_get_closest_point(nav_map, test_point)
		if closest_point.distance_to(test_point) < 5.0:  # Point is close to nav mesh
			return closest_point
	
	# Fallback: just move forward
	return global_position + (-transform.basis.z * 20.0)
