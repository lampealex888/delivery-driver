extends PathFollow3D

signal path_end_reached
const PATH_TRANSMITTER = 4
@export var car_velocity: float = 2.0
var _new_path
@onready var _raycast = $RayCast3D

func _process(delta):
	# Movement
	progress += car_velocity * delta
	# Check for next path
	if _raycast.is_colliding():
		_check_raycast_collisions()
	# Check if we've reached the end (progress_ratio goes from 0 to 1)
	if progress_ratio >= 1.0:
		_on_path_end_reached()


func _on_path_end_reached() -> void:
	# Remove current path when end is reached
	var old_path = get_parent()
	old_path.remove_child(self)
	# Get new path
	if _new_path != null:
		_new_path.add_child(self)
	# Reset progress for smooth transition
	progress = 0.1


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
