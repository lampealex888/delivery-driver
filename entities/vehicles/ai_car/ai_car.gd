extends PathFollow3D

const PATH_TRANSMITTER = 4
const VEHICLES = 5
const PLAYER_CAR = 2

@export var max_speed: float = 2.0
@export var safe_distance: float = 1.0  # Distance to maintain from other cars
@export var check_ahead_distance: float = 3.0  # How far ahead to check on current path

var new_path: Path3D
var is_following_path: bool = true

@onready var rigid_body = $RigidBody3D
@onready var path_ray_cast = rigid_body.get_node("RayCast3D")
@onready var despawn_timer = rigid_body.get_node("DespawnTimer")

static var vehicle_paths: Array[String] = [
	"res://entities/vehicles/ambulance/ambulance.tscn",
	"res://entities/vehicles/delivery/delivery.tscn",
	"res://entities/vehicles/delivery_flat/delivery_flat.tscn",
	"res://entities/vehicles/firetruck/firetruck.tscn",
	"res://entities/vehicles/garbage_truck/garbage_truck.tscn",
	"res://entities/vehicles/hatchback_sport/hatchback_sports.tscn",
	"res://entities/vehicles/police/police.tscn",
	"res://entities/vehicles/race/race.tscn",
	"res://entities/vehicles/race_future/race_future.tscn",
	"res://entities/vehicles/sedan/sedan.tscn",
	"res://entities/vehicles/sedan_sports/sedan_sports.tscn",
	"res://entities/vehicles/suv/suv.tscn",
	"res://entities/vehicles/suv_luxury/suv_luxury.tscn",
	"res://entities/vehicles/tractor/tractor.tscn",
	"res://entities/vehicles/tractor_police/tractor_police.tscn",
	"res://entities/vehicles/tractor_shovel/tractor_shovel.tscn",
	"res://entities/vehicles/truck/truck.tscn",
	"res://entities/vehicles/truck_flat/truck_flat.tscn",
	"res://entities/vehicles/van/van.tscn"
]

func _ready():
	rigid_body.body_entered.connect(on_player_collision)
	despawn_timer.timeout.connect(queue_free)
	
	var random_vehicle_path = vehicle_paths[randi() % vehicle_paths.size()]
	var vehicle_scene = load(random_vehicle_path)
	var random_vehicle = vehicle_scene.instantiate()
	random_vehicle.rotation.y = deg_to_rad(180)
	rigid_body.add_child(random_vehicle)

func _process(delta):
	if not is_following_path:
		return
	
	var speed := 0.0
	
	# Check for traffic on current path and potential new path
	if should_wait_for_traffic():
		speed = 0.0
	else:
		speed = max_speed
	
	# Check for path transmitter for potential path changes
	if path_ray_cast.is_colliding():
		var transmitter = path_ray_cast.get_collider()
		if transmitter and transmitter.get_collision_layer_value(PATH_TRANSMITTER):
			var paths = transmitter.get_children().filter(func(child): return child is Path3D)
			if paths.size() > 0:
				new_path = paths[randi_range(0, paths.size() - 1)]
	
	progress += speed * delta
	
	if progress_ratio >= 1.0:
		_switch_to_new_path()

func should_wait_for_traffic() -> bool:
	# Check current path for cars ahead
	if is_car_ahead_on_current_path():
		return true
	
	# Check if we're about to switch paths and if the new path has traffic
	if new_path and is_instance_valid(new_path) and progress_ratio > 0.8:
		return is_traffic_on_path(new_path)
	
	return false

func is_car_ahead_on_current_path() -> bool:
	var current_path = get_parent()
	if not current_path is Path3D:
		return false
	
	# Get all cars on the current path
	var cars_on_path = current_path.get_children().filter(func(child): return child != self and child.has_method("_process"))
	
	for car in cars_on_path:
		if car.progress > progress and car.progress - progress < check_ahead_distance:
			return true
	
	return false

func is_traffic_on_path(path: Path3D) -> bool:
	if not path or not is_instance_valid(path):
		return false
	
	# Get all cars on the target path
	var cars_on_path = path.get_children().filter(func(child): return child.has_method("_process"))
	
	# Check if there are any cars near the beginning of the path
	for car in cars_on_path:
		if car.progress < safe_distance:
			return true
	
	return false

func can_safely_enter_path(path: Path3D) -> bool:
	if not path or not is_instance_valid(path):
		return false
	
	# More sophisticated check - ensure there's enough space at the beginning
	var cars_on_path = path.get_children().filter(func(child): return child.has_method("_process"))
	
	for car in cars_on_path:
		# Check if any car is too close to the start of the path
		if car.progress < safe_distance * 2:
			return false
	
	return true

func _switch_to_new_path():
	get_parent().remove_child(self)
	if new_path and is_instance_valid(new_path) and can_safely_enter_path(new_path):
		new_path.add_child(self)
		progress = 0.0
		new_path = null  # Clear the new path reference
	else:
		is_following_path = false
		despawn_timer.start()

func on_player_collision(body):
	if body.is_in_group("player_car") and is_following_path:
		is_following_path = false
		despawn_timer.start()
		call_deferred("handle_collision_cleanup")
		path_ray_cast.enabled = false

func handle_collision_cleanup():
	var pos = rigid_body.global_position
	var rot = rigid_body.global_rotation
	remove_child(rigid_body)
	get_tree().current_scene.add_child(rigid_body)
	rigid_body.global_position = pos
	rigid_body.global_rotation = rot
	process_mode = Node.PROCESS_MODE_DISABLED
