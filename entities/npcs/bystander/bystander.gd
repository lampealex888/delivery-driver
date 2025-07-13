extends PathFollow3D

const SIDEWALK_TRANSMITTER: int = 7
const PLAYER_CAR: int = 2

@export var max_speed: float = 1.0

var new_path: Path3D
var is_following_path: bool = true

@onready var rigid_body: RigidBody3D = $RigidBody3D
@onready var path_ray_cast: RayCast3D = rigid_body.get_node("PathRayCast3D")
@onready var car_collision_area3d = rigid_body.get_node("CarCollisionArea3D")
@onready var despawn_timer = rigid_body.get_node("DespawnTimer")

static var bystander_paths: Array[String] = [
	"res://entities/npcs/character_a/character_a.tscn",
	"res://entities/npcs/character_b/character_b.tscn",
	"res://entities/npcs/character_c/character_c.tscn",
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
	car_collision_area3d.body_entered.connect(on_player_collision)
	despawn_timer.timeout.connect(despawn)
	
	var random_bystander_path = bystander_paths[randi() % bystander_paths.size()]
	var bystander_scene = load(random_bystander_path)
	var random_bystander = bystander_scene.instantiate()
	rigid_body.add_child(random_bystander)

func _process(delta):
	if not is_following_path:
		return
	
	# Check for path transmitter
	if path_ray_cast.is_colliding():
		var transmitter = path_ray_cast.get_collider()
		if transmitter and transmitter.get_collision_layer_value(SIDEWALK_TRANSMITTER):
			var paths = transmitter.get_children().filter(func(child): return child is Path3D)
			if paths.size() > 0:
				new_path = paths[randi_range(0, paths.size() - 1)]
	
	# Always move at max speed
	progress += max_speed * delta
	
	# Switch to new path when reaching the end
	if progress_ratio >= 1.0:
		_switch_to_new_path()


func _switch_to_new_path():
	get_parent().remove_child(self)
	if new_path and is_instance_valid(new_path):
		new_path.add_child(self)
		progress = 0.0
	else:
		queue_free()  # Remove if no new path found


func on_player_collision(body):
	if body.is_in_group("player_car") and is_following_path:
		is_following_path = false
		despawn_timer.start()
		call_deferred("handle_collision_cleanup")
		path_ray_cast.enabled = false


func handle_collision_cleanup():
	var pos = rigid_body.global_position
	var rot = rigid_body.global_rotation
	remove_child(rigid_body)
	get_tree().current_scene.add_child(rigid_body)
	rigid_body.global_position = pos
	rigid_body.global_rotation = rot
	process_mode = Node.PROCESS_MODE_DISABLED


func despawn():
	if rigid_body and is_instance_valid(rigid_body):
		rigid_body.queue_free()
	queue_free()
