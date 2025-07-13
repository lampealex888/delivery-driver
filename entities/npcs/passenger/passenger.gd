extends CharacterBody3D	

@onready var destination_arrow: Node3D = $DestinationArrow
@onready var pickup_area: Area3D = $PickupArea3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var area_mesh: MeshInstance3D = $AreaMesh
@onready var ring_mesh: MeshInstance3D = $RingMesh
@onready var dollar_mesh: MeshInstance3D = $DollarMesh
@onready var patience_timer: Timer = $PatienceTimer

var destination_building: Node3D
var current_building: Node3D
var car_in_range: bool = false
var current_characater: Node3D
var animation_player: AnimationPlayer
var material: StandardMaterial3D
var last_color: Color

static var character_paths: Array[String] = [
	"res://entities/npcs/character_a/character_a.tscn",
	"res://entities/npcs/character_b/character_b.tscn",
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

func _ready():
	pickup_area.body_entered.connect(_on_pickup_area_body_entered)
	pickup_area.body_exited.connect(_on_pickup_area_body_exited)
	
	patience_timer.timeout.connect(queue_free)
	patience_timer.start()
	
	var random_char_path = character_paths[randi() % character_paths.size()]
	var character_scene = load(random_char_path)
	var random_character = character_scene.instantiate()
	add_child(random_character)
	current_characater = random_character
	animation_player = current_characater.get_node("AnimationPlayer")
	if animation_player and animation_player.has_animation("idle"):
		var animation = animation_player.get_animation("idle")
		animation.loop_mode = Animation.LOOP_LINEAR
		animation_player.play("idle")
	
	material = StandardMaterial3D.new()
	material.emission_enabled = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = Color.GREEN
	last_color = Color.GREEN
	
	area_mesh.material_override = material
	ring_mesh.material_override = material
	dollar_mesh.material_override = material


func _process(delta: float):
	var patience_ratio = patience_timer.time_left / patience_timer.wait_time
	var color: Color
	if patience_ratio > 0.66:
		color = Color.GREEN
	elif patience_ratio > 0.33:
		color = Color.YELLOW
	else:
		color = Color.RED
	
	# Only update material if color changed
	if color != last_color:
		material.albedo_color = color
		material.emission = color * 0.3
		last_color = color
	
	ring_mesh.rotation.y += delta
	dollar_mesh.rotation.y += delta
	
	if car_in_range and current_characater:
		var car = get_tree().get_first_node_in_group("player_car")
		if car:
			# Check if there is already a passenger
			var car_children = car.get_children()
			for child in car_children:
				if child.is_in_group("passengers"):
					return
			if car.linear_velocity.length() < 0.5:
				var direction = (car.global_position - current_characater.global_position).normalized()
				var distance_to_car = current_characater.global_position.distance_to(car.global_position)
				if distance_to_car < 1:
					current_characater.visible = false
					area_mesh.visible = false
					ring_mesh.visible = false
					dollar_mesh.visible = false
					get_parent().call_deferred("remove_child", self)
					car.call_deferred("add_child", self)
					call_deferred("_set_up_trip", car)
				else:
					car.engine_force = 0.0
					current_characater.look_at(car.global_position, Vector3.UP)
					current_characater.rotation.y += PI  # Add 180 degrees to face the correct direction
					current_characater.global_position += direction * 2 * delta
					animation_player.clear_queue()
					var animation = animation_player.get_animation("walk")
					animation.loop_mode = Animation.LOOP_LINEAR
					animation_player.play("walk")

func _on_pickup_area_body_entered(body):
	if body.is_in_group("player_car"):
		car_in_range = true
		for child in body.get_children():
			if child.is_in_group("passengers"):
				return


func _on_pickup_area_body_exited(body):
	if body.is_in_group("player_car"):
		car_in_range = false


func _set_up_trip(body):
	collision_shape.disabled = true
	global_position = body.global_position
	var buildings = get_tree().get_nodes_in_group("buildings")
	buildings.erase(current_building)
	destination_building = buildings[randi() % buildings.size()]
	if destination_arrow and destination_building:
		destination_arrow.activate(destination_building.global_position, self)
		destination_arrow.visible = true
	destination_building.get_node("DestinationArea3D/DestinationOutline").visible = true
