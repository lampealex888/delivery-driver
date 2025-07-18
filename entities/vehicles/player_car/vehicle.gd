extends VehicleBody3D

const STEER_SPEED := 1.5
const STEER_LIMIT := 0.4
const BRAKE_STRENGTH := 2.0

@export var engine_force_value := 40.0

var previous_speed := linear_velocity.length()
var steer_target := 0.0
var disabled := false
var brake_lights_on := false


@onready var brake_light_left: MeshInstance3D = $BrakeLightLeftMesh
@onready var brake_light_right: MeshInstance3D = $BrakeLightRightMesh
@onready var desired_engine_pitch: float = $EngineSound.pitch_scale

var brake_light_material: StandardMaterial3D

func _ready():
	await get_tree().process_frame
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		game_manager.game_started.connect(enable_vehicle)
		disabled = true
	brake_light_material = brake_light_right.get_active_material(0)
	brake_light_material.emission = Color(0.941, 0.012, 0.196)
	brake_light_material.emission_energy_multiplier = 2.85


func enable_vehicle():
	disabled = false


func _physics_process(delta: float):
	if disabled:
		return
	
	steer_target = Input.get_axis(&"turn_right", &"turn_left")
	steer_target *= STEER_LIMIT

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
	var reverse_pressed = Input.is_action_pressed(&"reverse")
	if reverse_pressed:
		var speed := linear_velocity.length()
		if speed < 5.0 and not is_zero_approx(speed):
			engine_force = -clampf(engine_force_value * 5.0 / speed, 0.0, 100.0)
		else:
			engine_force = -engine_force_value

		engine_force *= Input.get_action_strength(&"reverse")
		if not brake_lights_on and brake_light_material:
			brake_lights_on = true
			brake_light_material.emission_energy_multiplier = 2.85
	else:
		if brake_light_material:
			brake_light_material.emission_energy_multiplier = 0
			brake_lights_on = false

	steering = move_toward(steering, steer_target, STEER_SPEED * delta)
	previous_speed = linear_velocity.length()
