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
	
	var passengers = 0
	for child in get_children():
		if child.is_in_group("passengers"):
			passengers += 1
	if passengers >= 2:
		return
	
	var passenger = passenger_scene.instantiate()
	add_child(passenger)
	call_deferred("setup_passenger", passenger)


func setup_passenger(passenger):
	var spawn_point = spawnpoints[spawnpoints_index % spawnpoints.size()]
	spawnpoints_index += 1
	passenger.global_position = spawn_point.global_position
	passenger.global_rotation = spawn_point.global_rotation
	passenger.current_building = self


func _on_destination_area_entered(body):
	if body.is_in_group("player_car"):
		var current_passenger = null
		for child in body.get_children():
			if child.is_in_group("passengers"):
				current_passenger = child
		if current_passenger and current_passenger.destination_building == self:
			body.remove_child(current_passenger)
			current_passenger.queue_free()
			passenger_delivered.emit()
			destination_outline.visible = false
