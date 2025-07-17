extends PathFollow3D

const PATH_TRANSMITTER = 4
const STOP_TRANSMITTER = 9
const AI_VEHICLES = 5
const PLAYER_CAR = 2

@export var max_speed: float = 2.0

var new_path: Path3D
var is_following_path: bool = true
var traffic_ahead: bool

@onready var rigid_body = $RigidBody3D
@onready var ray_cast = rigid_body.get_node("RayCast3D")
@onready var despawn_timer = rigid_body.get_node("DespawnTimer")
@onready var traffic_detector = rigid_body.get_node("TrafficDetector")

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
	rigid_body.body_entered.connect(_on_rigid_body_body_entered)
	despawn_timer.timeout.connect(_on_despawn_timer_timeout)
	traffic_detector.body_entered.connect(_on_traffic_detector_body_entered)
	traffic_detector.body_exited.connect(_on_traffic_detector_body_exited)
		
	var random_vehicle_path = vehicle_paths[randi() % vehicle_paths.size()]
	var vehicle_scene = load(random_vehicle_path)
	var random_vehicle = vehicle_scene.instantiate()
	random_vehicle.rotation.y = deg_to_rad(180)
	rigid_body.add_child(random_vehicle)


func _process(delta):
	if not is_following_path:
		return
	var speed := 0.0
	if traffic_ahead:
		speed = 0.0
	else:
		speed = max_speed
	if ray_cast.is_colliding():
		var transmitter = ray_cast.get_collider()
		if transmitter:
			if transmitter.get_collision_layer_value(STOP_TRANSMITTER):
				speed = 0.0
			elif transmitter.get_collision_layer_value(PATH_TRANSMITTER):
				var paths = transmitter.get_children().filter(func(child): return child is Path3D)
				if paths.size() > 0:
					new_path = paths[randi_range(0, paths.size() - 1)]
	progress += speed * delta
	if progress_ratio >= 1.0:
		switch_to_new_path()


func switch_to_new_path():
	get_parent().remove_child(self)
	if new_path and is_instance_valid(new_path):
		new_path.add_child(self)
		progress = 0.0
	else:
		is_following_path = false
		despawn_timer.start()


func _on_rigid_body_body_entered(body):
	if body.is_in_group("player_car") and is_following_path:
		is_following_path = false
		ray_cast.enabled = false
		traffic_detector.monitoring = false
		print("despawn_timer_started")
		despawn_timer.start()
		call_deferred("handle_collision_cleanup")
		rigid_body.set_collision_layer_value(AI_VEHICLES, true)


func handle_collision_cleanup():
	var pos = rigid_body.global_position
	var rot = rigid_body.global_rotation
	remove_child(rigid_body)
	get_tree().current_scene.add_child(rigid_body)
	rigid_body.contact_monitor = false
	rigid_body.global_position = pos
	rigid_body.global_rotation = rot
	process_mode = Node.PROCESS_MODE_DISABLED

func _on_traffic_detector_body_entered(body):
	var self_forward = -rigid_body.global_transform.basis.z.normalized()
	var other_forward = -body.global_transform.basis.z.normalized()
	var dot = self_forward.dot(other_forward)
	
	if dot > 0.1:
		traffic_ahead = true
		return	
	traffic_ahead = false
	return


func _on_traffic_detector_body_exited(_body):
	traffic_ahead = false


func _on_despawn_timer_timeout():
	if rigid_body and is_instance_valid(rigid_body):
		rigid_body.queue_free()
	queue_free()
