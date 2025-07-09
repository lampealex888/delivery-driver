extends PathFollow3D

const PATH_TRANSMITTER = 4
const VEHICLES = 5
const PLAYER_CAR = 2

@export var max_speed: float = 2.0

var new_path
var is_following_path: bool = true

@onready var rigid_body = $RigidBody3D
@onready var path_ray_cast = rigid_body.get_node("PathRayCast3D")
@onready var traffic_ray_cast = rigid_body.get_node("TrafficRayCast3D")
@onready var car_collision_area3d = rigid_body.get_node("CarCollisionArea3D")
@onready var despawn_timer = rigid_body.get_node("DespawnTimer")

func _ready():
	car_collision_area3d.body_entered.connect(on_player_collision)
	despawn_timer.timeout.connect(despawn)

func _process(delta):
	if not is_following_path:
		return
	
	# Stop if traffic ahead, otherwise move at max speed
	var speed
	if traffic_ray_cast.is_colliding() and (traffic_ray_cast.get_collider().get_collision_layer_value(VEHICLES) or traffic_ray_cast.get_collider().get_collision_layer_value(PLAYER_CAR)):
		speed = 0.0
	else:
		speed = max_speed
	
	# Check for path transmitter
	if path_ray_cast.is_colliding():
		var transmitter = path_ray_cast.get_collider()
		if transmitter and transmitter.get_collision_layer_value(PATH_TRANSMITTER):
			var paths = transmitter.get_children().filter(func(child): return child is Path3D)
			if paths.size() > 0:
				new_path = paths[randi_range(0, paths.size() - 1)]
	
	progress += speed * delta
	
	if progress_ratio >= 1.0:
		_switch_to_new_path()

func _switch_to_new_path():
	get_parent().remove_child(self)
	if new_path and is_instance_valid(new_path):
		new_path.add_child(self)
		progress = 0.0
	else:
		is_following_path = false
		despawn_timer.start()

func on_player_collision(body):
	if body.is_in_group("player_car") and is_following_path:
		is_following_path = false
		despawn_timer.start()
		var pos = rigid_body.global_position
		var rot = rigid_body.global_rotation
		remove_child(rigid_body)
		get_tree().current_scene.add_child(rigid_body)
		rigid_body.global_position = pos
		rigid_body.global_rotation = rot
		path_ray_cast.enabled = false
		traffic_ray_cast.enabled = false
		process_mode = Node.PROCESS_MODE_DISABLED

func despawn():
	if rigid_body and is_instance_valid(rigid_body):
		rigid_body.queue_free()
	queue_free()
