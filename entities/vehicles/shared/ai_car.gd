extends PathFollow3D

signal path_end_reached

const PATH_TRANSMITTER = 4
@export var car_velocity: float = 2.0
var _new_path
var _is_following_path: bool = true

@onready var _raycast = $RigidBody3D/RayCast3D
@onready var _rigid_body = $RigidBody3D
@onready var _area3d = $RigidBody3D/Area3D
@onready var despawn_timer = $RigidBody3D/DespawnTimer

func _ready():
	_area3d.body_entered.connect(_on_player_collision)
	despawn_timer.timeout.connect(despawn)


func _process(delta):
	# If we're on the path, follow the path. Otherwise start despawning
	if _is_following_path:
		# Movement
		progress += car_velocity * delta
		# Check for next path
		if _raycast.is_colliding():
			_check_raycast_collisions()
		# Check if we've reached the end (progress_ratio goes from 0 to 1)
		if progress_ratio >= 1.0:
			_on_path_end_reached()


func _on_path_end_reached() -> void:
	if not _is_following_path:
		return
	# Remove current path when end is reached
	var old_path = get_parent()
	old_path.remove_child(self)
	# Get new path
	if _new_path != null:
		_new_path.add_child(self)
	# Reset progress for smooth transition
	progress = 0.0


func _check_raycast_collisions():
	var collision_object = _raycast.get_collider()
	if collision_object and collision_object.get_collision_layer_value(PATH_TRANSMITTER):
		# Ask transmitter for number of paths
		var number_of_paths := 0
		for child in collision_object.get_children():
			if child is Path3D:
				number_of_paths += 1
		# Get random path between 1 and number_of_paths
		var random_path_index = randi_range(1, number_of_paths)
		_new_path = collision_object.get_child(random_path_index)


func _on_player_collision(body):
	# If the player hits an ai car, detach from pathfollow3d and attach 
	# to root as rigid body
	if body.is_in_group("player_car"):
		if not _is_following_path:
			return # Already detached
		_is_following_path = false
		despawn_timer.start()
		var current_global_position = _rigid_body.global_position
		var current_global_rotation = _rigid_body.global_rotation
		var root = get_tree().current_scene
		remove_child(_rigid_body)
		root.add_child(_rigid_body)
		_rigid_body.global_position = current_global_position
		_rigid_body.global_rotation = current_global_rotation
		_raycast.enabled = false
		process_mode = Node.PROCESS_MODE_DISABLED

func despawn():
	if _rigid_body and is_instance_valid(_rigid_body):
		_rigid_body.queue_free()
		# Remove the PathFollow3D node as well
		queue_free()
