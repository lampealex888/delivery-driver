extends Node3D
class_name DestinationArrow

const ARROW_HEIGHT := 3.0
const ARROW_DISTANCE := 2.0
const COLOR_CLOSE := Color.GREEN
const COLOR_MEDIUM := Color.YELLOW  
const COLOR_FAR := Color.RED
const DISTANCE_CLOSE := 20.0
const DISTANCE_MEDIUM := 50.0

@export var target_position := Vector3.ZERO
@export var follow_target: Node3D

# References to the arrow parts (will be set in editor)
@onready var arrow_head: MeshInstance3D = $ArrowHead
@onready var arrow_shaft: MeshInstance3D = $ArrowShaft
@onready var distance_label: Label = $SubViewport/Control/DistanceLabel

var head_material: StandardMaterial3D
var shaft_material: StandardMaterial3D

func _ready() -> void:
	_setup_materials()

func _process(_delta: float) -> void:
	if follow_target:
		_update_arrow_position()
		_update_arrow_rotation()
		_update_arrow_color()
		_update_distance_display()

func _setup_materials() -> void:
	# Create materials for both arrow parts
	head_material = StandardMaterial3D.new()
	head_material.albedo_color = COLOR_FAR
	head_material.emission_enabled = true
	head_material.emission = COLOR_FAR * 0.3
	head_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	shaft_material = StandardMaterial3D.new()
	shaft_material.albedo_color = COLOR_FAR
	shaft_material.emission_enabled = true
	shaft_material.emission = COLOR_FAR * 0.3
	shaft_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	# Apply materials to mesh instances
	if arrow_head:
		arrow_head.material_override = head_material
	if arrow_shaft:
		arrow_shaft.material_override = shaft_material

func _update_arrow_position() -> void:
	if not follow_target:
		return
	
	# Position arrow directly above the car
	var car_pos := follow_target.global_position
	global_position = car_pos + Vector3.UP * ARROW_HEIGHT

func _update_arrow_rotation() -> void:
	if target_position == Vector3.ZERO:
		return
	
	# Point arrow toward destination
	var direction := (target_position - global_position).normalized()
	
	# Use look_at to orient the arrow
	look_at(global_position - direction, Vector3.UP)

func _update_arrow_color() -> void:
	if not follow_target or target_position == Vector3.ZERO:
		return
	
	var distance := follow_target.global_position.distance_to(target_position)
	var color: Color
	
	if distance < DISTANCE_CLOSE:
		color = COLOR_CLOSE
	elif distance < DISTANCE_MEDIUM:
		# Interpolate between green and yellow
		var t := (distance - DISTANCE_CLOSE) / (DISTANCE_MEDIUM - DISTANCE_CLOSE)
		color = COLOR_CLOSE.lerp(COLOR_MEDIUM, t)
	else:
		# Interpolate between yellow and red
		var t = clamp((distance - DISTANCE_MEDIUM) / 50.0, 0.0, 1.0)
		color = COLOR_MEDIUM.lerp(COLOR_FAR, t)
	
	# Update both materials
	if head_material:
		head_material.albedo_color = color
		head_material.emission = color * 0.3
	if shaft_material:
		shaft_material.albedo_color = color
		shaft_material.emission = color * 0.3

func _update_distance_display() -> void:
	if not follow_target or not distance_label:
		return
	
	var distance := follow_target.global_position.distance_to(target_position)
	distance_label.text = "%.0fm" % distance

func set_target(pos: Vector3) -> void:
	target_position = pos

func set_follow_target(target: Node3D) -> void:
	follow_target = target
