extends CharacterBody3D

@export var max_speed = 20.0
@export var acceleration = 10.0
@export var friction = 5.0
@export var turn_speed = 3.0

@onready var front_left_wheel = $WheelFrontLeft
@onready var front_right_wheel = $WheelFrontLeft
@onready var rear_left_wheel = $WheelBackLeft
@onready var rear_right_wheel = $WheelBackRight

var current_speed = 0.0
var turn_input = 0.0

func _physics_process(delta):
	# Get input
	var gas_input = 0.0
	if Input.is_action_pressed("ui_up"):
		gas_input = 1.0
	elif Input.is_action_pressed("ui_down"):
		gas_input = -1.0
	
	turn_input = 0.0
	if Input.is_action_pressed("ui_left"):
		turn_input = -1.0
	elif Input.is_action_pressed("ui_right"):
		turn_input = 1.0
	
	# Apply acceleration/friction
	if gas_input != 0:
		current_speed += gas_input * acceleration * delta
		current_speed = clamp(current_speed, -max_speed, max_speed)
	else:
		current_speed = move_toward(current_speed, 0, friction * delta)
	
	# Turn the car
	if abs(current_speed) > 0.1:
		rotation.y += turn_input * turn_speed * delta * (current_speed / max_speed)
	
	# Move the car
	velocity = -transform.basis.z * current_speed
	move_and_slide()
	
	# Rotate wheels (visual effect)
	rotate_wheels(delta)

func rotate_wheels(delta):
	var wheel_rotation = current_speed * delta * 2
	front_left_wheel.rotation.x += wheel_rotation
	front_right_wheel.rotation.x += wheel_rotation
	rear_left_wheel.rotation.x += wheel_rotation
	rear_right_wheel.rotation.x += wheel_rotation
