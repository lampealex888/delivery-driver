extends CharacterBody3D
class_name Passenger

enum State {
	WAITING,
	WALKING_TO_CAR,
	IN_CAR,
	DELIVERED
}

const PATIENCE_TIME := 30.0
const BASE_TIP := 50
const PICKUP_RADIUS := 3.0
const WALK_SPEED := 2.0
const STOPPED_SPEED_THRESHOLD := 0.5  # Speed below which car is considered "stopped"
const PICKUP_DISTANCE := 1.5  # Distance from car when passenger gets in

@export var passenger_name := "Passenger"
@export var impatience_factor := 1.0

var state := State.WAITING
var destination_position := Vector3.ZERO
var destination_building_name := ""
var is_in_pickup_range := false
var player_car: VehicleBody3D
var walking_target: Vector3
var original_position: Vector3

@onready var mesh_instance: Node3D = $"character-q"
@onready var pickup_area: Area3D = $PickupArea
@onready var patience_bar: ProgressBar = $SubViewport/Control/VBoxContainer/PatienceBar
@onready var destination_label: Label = $SubViewport/Control/VBoxContainer/DestinationLabel
@onready var pickup_prompt: Label = $SubViewport/Control/VBoxContainer/PickupPrompt
@onready var patience_timer: Timer = $PatienceTimer

signal passenger_picked_up(passenger: Passenger)
signal passenger_delivered(passenger: Passenger, tip: int)
signal passenger_timeout(passenger: Passenger)

func _ready() -> void:
	_setup_timers()
	_setup_ui()
	_connect_signals()
	original_position = global_position
	_find_player_car()

func _setup_timers() -> void:
	# Setup patience timer
	patience_timer.wait_time = PATIENCE_TIME * impatience_factor
	patience_timer.timeout.connect(_on_patience_timeout)
	patience_timer.start()
	
	# Setup timer to update patience bar
	var update_timer = Timer.new()
	update_timer.wait_time = 0.1  # Update every 0.1 seconds
	update_timer.timeout.connect(_update_patience_bar)
	update_timer.start()
	add_child(update_timer)

func _update_patience_bar() -> void:
	if patience_bar and patience_timer:
		patience_bar.value = patience_timer.time_left
		_update_patience_visual()

func _on_patience_timeout() -> void:
	_timeout()

func _find_player_car() -> void:
	var cars = get_tree().get_nodes_in_group("player_car")
	if cars.size() > 0:
		player_car = cars[0]

func _physics_process(delta: float) -> void:
	match state:
		State.WAITING:
			_handle_waiting_state(delta)
		State.WALKING_TO_CAR:
			_handle_walking_state(delta)
		State.IN_CAR:
			_handle_in_car_state(delta)
		State.DELIVERED:
			pass

func _setup_ui() -> void:
	patience_bar.max_value = PATIENCE_TIME
	patience_bar.value = PATIENCE_TIME
	pickup_prompt.visible = false
	
	if destination_building_name != "":
		destination_label.text = "To: " + destination_building_name
	
	# Position UI elements relative to passenger
	var ui_offset := Vector2(0, -100)
	patience_bar.position = ui_offset + Vector2(-50, 0)
	destination_label.position = ui_offset + Vector2(-75, -30)
	pickup_prompt.position = ui_offset + Vector2(-60, -60)

func _connect_signals() -> void:
	pickup_area.body_entered.connect(_on_pickup_area_entered)
	pickup_area.body_exited.connect(_on_pickup_area_exited)

func _handle_waiting_state(delta: float) -> void:
	# Check if car is stopped nearby
	if player_car and is_in_pickup_range:
		var car_speed = player_car.linear_velocity.length()
		if car_speed <= STOPPED_SPEED_THRESHOLD:
			_start_walking_to_car()

func _handle_walking_state(delta: float) -> void:
	if not player_car:
		state = State.WAITING
		return
	
	# Update walking target to car position
	walking_target = player_car.global_position
	
	# Move towards the car
	var direction = (walking_target - global_position).normalized()
	velocity = direction * WALK_SPEED
	
	# Face the direction we're walking
	if direction.length() > 0.1:
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, delta * 5.0)
	
	move_and_slide()
	
	# Check if we've reached the car
	var distance_to_car = global_position.distance_to(player_car.global_position)
	if distance_to_car <= PICKUP_DISTANCE:
		_pickup_passenger()

func _handle_in_car_state(_delta: float) -> void:
	# Hide passenger while in car
	visible = false

func _start_walking_to_car() -> void:
	if state != State.WAITING:
		return
	
	state = State.WALKING_TO_CAR
	pickup_prompt.text = "Walking to car..."
	pickup_prompt.visible = true
	print("Passenger starting to walk to car")

func _pickup_passenger() -> void:
	if state != State.WALKING_TO_CAR:
		return
	
	state = State.IN_CAR
	_hide_ui()
	passenger_picked_up.emit(self)
	print("Passenger picked up automatically!")

func _update_patience_visual() -> void:
	var patience_ratio := patience_timer.time_left / (PATIENCE_TIME * impatience_factor)
	
	if patience_ratio > 0.6:
		patience_bar.modulate = Color.GREEN
	elif patience_ratio > 0.3:
		patience_bar.modulate = Color.YELLOW
	else:
		patience_bar.modulate = Color.RED

func set_destination(pos: Vector3, building_name: String) -> void:
	destination_position = pos
	destination_building_name = building_name
	
	# Update label if it exists, otherwise it will be set in _ready()
	if destination_label:
		destination_label.text = "To: " + building_name

func deliver() -> void:
	if state != State.IN_CAR:
		return
	
	state = State.DELIVERED
	
	# Calculate tip based on remaining patience
	var time_bonus := int(patience_timer.time_left * 2.0)
	var total_tip := BASE_TIP + time_bonus
	
	passenger_delivered.emit(self, total_tip)
	queue_free()

func _timeout() -> void:
	state = State.DELIVERED
	passenger_timeout.emit(self)
	queue_free()

func _hide_ui() -> void:
	patience_bar.visible = false
	destination_label.visible = false
	pickup_prompt.visible = false

func _on_pickup_area_entered(body: Node3D) -> void:
	if body.is_in_group(&"player_car") and state == State.WAITING:
		is_in_pickup_range = true
		pickup_prompt.text = "Stop to pick up"
		pickup_prompt.visible = true

func _on_pickup_area_exited(body: Node3D) -> void:
	if body.is_in_group(&"player_car"):
		is_in_pickup_range = false
		pickup_prompt.visible = false
		
		# If we were walking to car, go back to waiting
		if state == State.WALKING_TO_CAR:
			state = State.WAITING
			# Return to original position
			global_position = original_position

func get_distance_to_destination(pos: Vector3) -> float:
	return pos.distance_to(destination_position)
