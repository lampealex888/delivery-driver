# destination_arrow.gd
extends Node3D
class_name DestinationArrow

const ARROW_HEIGHT := 3.0
const ARROW_DISTANCE := 2.0
const DISTANCE_CLOSE := 30.0
const DISTANCE_MEDIUM := 60.0

@export var target_position := Vector3.ZERO
@export var follow_target: Node3D

@export var green_material: Material
@export var yellow_material: Material
@export var red_material: Material

@onready var arrow_head: MeshInstance3D = $ArrowHead
@onready var arrow_shaft: MeshInstance3D = $ArrowShaft
@onready var distance_label: Label = $SubViewport/Control/DistanceLabel

var is_active := false

func _ready() -> void:
	visible = false


func _process(_delta: float) -> void:
	if not is_active or not follow_target:
		return
	
	update_arrow_position()
	update_arrow_rotation()
	update_arrow_material()
	update_distance_display()


func activate(target_pos: Vector3, car: Node3D) -> void:
	target_position = target_pos
	follow_target = car
	is_active = true
	visible = true


func deactivate() -> void:
	is_active = false
	visible = false


func update_arrow_position() -> void:
	var car_pos := follow_target.global_position
	global_position = car_pos + Vector3.UP * ARROW_HEIGHT


func update_arrow_rotation() -> void:
	if target_position == Vector3.ZERO:
		return
	
	var direction := (target_position - global_position).normalized()
	look_at(global_position + direction, Vector3.UP)


func update_arrow_material() -> void:
	if not follow_target or target_position == Vector3.ZERO:
		return
	
	var distance := follow_target.global_position.distance_to(target_position)
	var material: Material
	
	if distance < DISTANCE_CLOSE:
		material = green_material
	elif distance < DISTANCE_MEDIUM:
		material = yellow_material
	else:
		material = red_material

	if arrow_head:
		arrow_head.material_override = material
	if arrow_shaft:
		arrow_shaft.material_override = material


func update_distance_display() -> void:
	if not follow_target or not distance_label:
		return
	
	var distance := follow_target.global_position.distance_to(target_position)
	distance_label.text = "%.0fm" % distance
