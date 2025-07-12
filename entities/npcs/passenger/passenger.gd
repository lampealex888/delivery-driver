extends CharacterBody3D	

var destination_building
var current_building
var fare: int = 50
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var destination_arrow: Node3D = $DestinationArrow
@onready var pickup_area: Area3D = $PickupArea3D
@onready var mesh = $"character-q2"

signal destination_set(destination: String)

func _ready():
	pickup_area.body_entered.connect(_on_pickup_area_entered)


func _on_pickup_area_entered(body):
	# Check if the body is the player car (by group)
	if body.is_in_group("player_car"):
		for child in body.get_children():
			if child.is_in_group("passengers"):
				return
		collision_shape.disabled = true
		mesh.visible = false
		pickup_area.visible = false
		get_parent().call_deferred("remove_child", self)
		body.call_deferred("add_child", self)
		call_deferred("_set_up_trip", body)

func _set_up_trip(body):
	global_position = body.global_position
	var buildings = get_tree().get_nodes_in_group("buildings")
	buildings.erase(current_building)
	destination_building = buildings[randi() % buildings.size()]
	if destination_arrow and destination_building:
		destination_arrow.activate(destination_building.global_position, self)
		destination_arrow.visible = true
	destination_set.emit(destination_building.building_name)
	


func dropoff_at_building(building) -> bool:
	if building == destination_building:
		queue_free()
		return true
	return false
