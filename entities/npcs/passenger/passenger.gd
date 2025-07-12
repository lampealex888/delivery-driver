extends CharacterBody3D	

var destination_building
var current_building
var fare: int = 50

@onready var destination_arrow: Node3D = $DestinationArrow
@onready var pickup_area: Area3D = $PickupArea3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var current_characater = null
var character_paths = [
	"res://entities/npcs/character_c/character_c.tscn",
	"res://entities/npcs/character_b/character_b.tscn",
	"res://entities/npcs/character_d/character_d.tscn",
	"res://entities/npcs/character_e/character_e.tscn",
	"res://entities/npcs/character_f/character_f.tscn",
	"res://entities/npcs/character_g/character_g.tscn",
	"res://entities/npcs/character_h/character_h.tscn",
	"res://entities/npcs/character_i/character_i.tscn",
	"res://entities/npcs/character_j/character_j.tscn",
	"res://entities/npcs/character_k/character_k.tscn",
	"res://entities/npcs/character_l/character_l.tscn",
	"res://entities/npcs/character_m/character_m.tscn",
	"res://entities/npcs/character_n/character_n.tscn",
	"res://entities/npcs/character_o/character_o.tscn",
	"res://entities/npcs/character_p/character_p.tscn",
	"res://entities/npcs/character_q/character_q.tscn",
	"res://entities/npcs/character_r/character_r.tscn"
]

signal destination_set(destination: String)

func _ready():
	pickup_area.body_entered.connect(_on_pickup_area_entered)
	var random_char_path = character_paths[randi() % character_paths.size()]
	var character_scene = load(random_char_path)
	var random_character = character_scene.instantiate()
	add_child(random_character)
	current_characater = random_character


func _on_pickup_area_entered(body):
	# Check if the body is the player car (by group)
	if body.is_in_group("player_car"):
		for child in body.get_children():
			if child.is_in_group("passengers"):
				return
		collision_shape.disabled = true
		current_characater.visible = false
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
