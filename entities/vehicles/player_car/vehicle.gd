extends VehicleBody3D

const STEER_SPEED := 1.5
const STEER_LIMIT := 0.4
const BRAKE_STRENGTH := 2.0

@export var engine_force_value := 40.0

var previous_speed := linear_velocity.length()
var _steer_target := 0.0
var disabled

@onready var desired_engine_pitch: float = $EngineSound.pitch_scale

func _ready():
	disabled = true
	await get_tree().process_frame
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	game_manager.game_started.connect(enable_vehicle)


func enable_vehicle():
	disabled = false


func _physics_process(delta: float):
	if disabled:
		return
	
	_steer_target = Input.get_axis(&"turn_right", &"turn_left")
	_steer_target *= STEER_LIMIT

	# Engine sound simulation
	desired_engine_pitch = 0.05 + linear_velocity.length() / (engine_force_value * 0.5)
	$EngineSound.pitch_scale = lerpf($EngineSound.pitch_scale, desired_engine_pitch, 0.2)

	if abs(linear_velocity.length() - previous_speed) > 1.0:
		# Sudden velocity change, likely due to a collision
		$ImpactSound.play()
		Input.vibrate_handheld(100)
		for joypad in Input.get_connected_joypads():
			Input.start_joy_vibration(joypad, 0.0, 0.5, 0.1)

	# Handle acceleration
	if DisplayServer.is_touchscreen_available() or Input.is_action_pressed(&"accelerate"):
		var speed := linear_velocity.length()
		if speed < 5.0 and not is_zero_approx(speed):
			engine_force = clampf(engine_force_value * 5.0 / speed, 0.0, 100.0)
		else:
			engine_force = engine_force_value

		if not DisplayServer.is_touchscreen_available():
			engine_force *= Input.get_action_strength(&"accelerate")
	else:
		engine_force = 0.0

	# Handle braking/reversing
	if Input.is_action_pressed(&"reverse"):
		var speed := linear_velocity.length()
		if speed < 5.0 and not is_zero_approx(speed):
			engine_force = -clampf(engine_force_value * 5.0 / speed, 0.0, 100.0)
		else:
			engine_force = -engine_force_value

		engine_force *= Input.get_action_strength(&"reverse")

	steering = move_toward(steering, _steer_target, STEER_SPEED * delta)
	previous_speed = linear_velocity.length()
