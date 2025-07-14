extends CharacterBody3D

enum State { WAITING, WALKING_TO_CAR, IN_CAR, WALKING_TO_DESTINATION }

@onready var destination_arrow: Node3D = $DestinationArrow
@onready var pickup_area: Area3D = $PickupArea3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var area_mesh: MeshInstance3D = $AreaMesh
@onready var ring_mesh: MeshInstance3D = $RingMesh
@onready var dollar_mesh: MeshInstance3D = $DollarMesh
@onready var patience_timer: Timer = $PatienceTimer

var state: State = State.WAITING
var destination_building: Node3D
var current_building: Node3D
var car_in_range: Node3D
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
	
	_spawn_random_character()
	_setup_materials()

func _process(delta: float):
	match state:
		State.WAITING:
			_process_waiting(delta)
		State.WALKING_TO_CAR:
			_process_walking_to_car(delta)
		State.IN_CAR:
			pass
		State.WALKING_TO_DESTINATION:
			_process_walking_to_destination(delta)

func _process_waiting(delta: float):
	var patience_ratio = patience_timer.time_left / patience_timer.wait_time
	var color: Color
	if patience_ratio > 0.66:
		color = Color.GREEN
	elif patience_ratio > 0.33:
		color = Color.YELLOW
	else:
		color = Color.RED
	if color != last_color:
		material.albedo_color = color
		material.emission = color
		last_color = color
	ring_mesh.rotation.y += delta
	dollar_mesh.rotation.y += delta

func _process_walking_to_car(delta: float):
	if not car_in_range:
		_transition_to_waiting()
		return
	
	var car_children = car_in_range.get_children()
	for child in car_children:
		if child.is_in_group("passengers"):
			_transition_to_waiting()
			return
	
	if car_in_range.linear_velocity.length() >= 0.5:
		_play_animation("idle")
		return
	
	var direction = (car_in_range.global_position - current_characater.global_position).normalized()
	var distance_to_car = current_characater.global_position.distance_to(car_in_range.global_position)
	
	if distance_to_car < 1:
		state = State.IN_CAR
		current_characater.visible = false
		area_mesh.visible = false
		ring_mesh.visible = false
		dollar_mesh.visible = false
		get_parent().call_deferred("remove_child", self)
		car_in_range.call_deferred("add_child", self)
		call_deferred("_set_up_trip", car_in_range)
	else:
		_play_animation("walk")
		car_in_range.engine_force = 0.0
		current_characater.look_at(car_in_range.global_position, Vector3.UP)
		current_characater.rotation.y += PI
		current_characater.global_position += direction * 2 * delta


func _process_walking_to_destination(delta: float):
	var direction = (destination_building.global_position - current_characater.global_position).normalized()
	current_characater.look_at(destination_building.global_position, Vector3.UP)
	current_characater.rotation.y += PI
	current_characater.global_position += direction * 2 * delta


func _transition_to_waiting():
	state = State.WAITING
	patience_timer.paused = false
	_play_animation("idle")


func _spawn_random_character():
	var random_char_path = character_paths[randi() % character_paths.size()]
	var character_scene = load(random_char_path)
	var random_character = character_scene.instantiate()
	add_child(random_character)
	current_characater = random_character
	animation_player = current_characater.get_node("AnimationPlayer")
	_play_animation("idle")


func _setup_materials():
	material = StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission = Color.GREEN
	material.emission_energy_multiplier = 2.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = Color.GREEN
	last_color = Color.GREEN
	
	area_mesh.material_override = material
	ring_mesh.material_override = material
	dollar_mesh.material_override = material


func _play_animation(anim_name: String):
	if animation_player and animation_player.has_animation(anim_name):
		var animation = animation_player.get_animation(anim_name)
		animation.loop_mode = Animation.LOOP_LINEAR
		animation_player.play(anim_name)


func _on_pickup_area_body_entered(body):
	if body.is_in_group("player_car") and state == State.WAITING:
		car_in_range = body
		for child in body.get_children():
			if child.is_in_group("passengers"):
				return
		state = State.WALKING_TO_CAR
		patience_timer.paused = true


func _on_pickup_area_body_exited(body):
	if body.is_in_group("player_car") and body == car_in_range:
		car_in_range = null
		if state == State.WALKING_TO_CAR:
			_transition_to_waiting()


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
	destination_building.passenger_delivered.connect(_delivered_to_destination)


func _delivered_to_destination():
	current_characater.visible = true
	area_mesh.visible = false
	ring_mesh.visible = false
	dollar_mesh.visible = false
	if destination_arrow:
		destination_arrow.visible = false
	car_in_range = null
	state = State.WALKING_TO_DESTINATION
	_play_animation("walk")
	patience_timer.wait_time = 5.0
	patience_timer.start()
