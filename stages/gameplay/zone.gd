extends Node3D

var spawnpoints_index: int = 0

@onready var spawn_timer: Timer = $SpawnTimer
@onready var spawnpoints: Array[Marker3D] = [$SpawnPoint1, $SpawnPoint2]
@onready var passenger_scene: PackedScene = preload("res://entities/npcs/passenger/passenger.tscn")
@onready var destination_area: Area3D = $DestinationArea3D
@onready var destination_outline: CSGBox3D = destination_area.get_node("DestinationOutline")
@export var building_name: String = "Building"

signal passenger_delivered

func _ready():
	spawn_timer.timeout.connect(spawn_passenger)
	spawn_timer.start()
	spawn_passenger()
	destination_area.body_entered.connect(_on_destination_area_entered)


func spawn_passenger():
	if not passenger_scene:
		return
	
	var current_passengers = 0
	for child in get_children():
		if child.is_in_group("passengers"):
			current_passengers += 1
	
	if current_passengers >= spawnpoints.size():
		return
	
	var available_spawn_points: Array[Marker3D] = []
	for spawn_point in spawnpoints:
		if not is_spawn_point_occupied(spawn_point):
			available_spawn_points.append(spawn_point)
	
	if available_spawn_points.is_empty():
		return

	var chosen_spawn_point = available_spawn_points[randi() % available_spawn_points.size()]
	
	var passenger = passenger_scene.instantiate()
	add_child(passenger)
	call_deferred("setup_passenger", passenger, chosen_spawn_point)


func setup_passenger(passenger, chosen_spawn_point):
	passenger.global_position = chosen_spawn_point.global_position
	passenger.global_rotation = chosen_spawn_point.global_rotation
	passenger.rotation.y = deg_to_rad(180)
	passenger.current_building = self


func _on_destination_area_entered(body):
	if body.is_in_group("player_car"):
		var current_passenger = null
		for child in body.get_children():
			if child.is_in_group("passengers"):
				current_passenger = child
		if current_passenger and current_passenger.destination_building == self:
			body.remove_child(current_passenger)
			add_child(current_passenger)
			current_passenger.global_position = body.global_position
			current_passenger.global_rotation = body.global_rotation
			destination_outline.visible = false
			passenger_delivered.emit()


func is_spawn_point_occupied(spawn_point: Marker3D) -> bool:
	for child in get_children():
		if child.is_in_group("passengers"):
			var distance = child.global_position.distance_to(spawn_point.global_position)
			if distance < 1.0:
				return true
	return false
