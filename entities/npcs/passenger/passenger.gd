# passenger.gd
extends RigidBody3D
class_name Passenger

enum State {
	WAITING,
	WALKING_TO_CAR,
	IN_CAR,
	DELIVERED
}

const PATIENCE_TIME := 30.0
const BASE_TIP := 50
const PICKUP_RADIUS := 5.0
const WALK_FORCE := 500.0
const WALK_SPEED := 2.0
const STOPPED_SPEED_THRESHOLD := 0.5
const PICKUP_DISTANCE := 3
const DELIVERY_DISTANCE := 5.0
const MOVEMENT_DAMPING := 0.8  # To prevent sliding
const ROTATION_SPEED := 8.0


@export var passenger_name := "Passenger"
@export var impatience_factor := 1.0
@export var destination_arrow_scene: PackedScene

var state := State.WAITING
var destination_position := Vector3.ZERO
var destination_building_name := ""
var is_in_pickup_range := false
var player_car: VehicleBody3D
var walking_target: Vector3
var original_position: Vector3
var destination_arrow: DestinationArrow
var car_is_available := true
var pickup_tween: Tween

@onready var pickup_area: Area3D = $PickupArea
@onready var animation_player: AnimationPlayer = $"character-q2/AnimationPlayer"

signal passenger_picked_up(passenger: Passenger)
signal passenger_delivered(passenger: Passenger, tip: int)
signal passenger_timeout(passenger: Passenger)


func setup(car: VehicleBody3D, dest_pos: Vector3, building_name: String):
	player_car = car
	destination_position = dest_pos
	destination_building_name = building_name
	original_position = global_position

	if destination_arrow_scene:
		destination_arrow = destination_arrow_scene.instantiate()
		get_tree().current_scene.add_child(destination_arrow)

	pickup_area.body_entered.connect(_on_pickup_area_entered)
	pickup_area.body_exited.connect(_on_pickup_area_exited)


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


func _handle_waiting_state(delta: float) -> void:
	linear_velocity = linear_velocity * (1.0 - MOVEMENT_DAMPING * delta)
	if player_car and is_in_pickup_range and car_is_available:
		var car_speed = player_car.linear_velocity.length()
		if car_speed <= STOPPED_SPEED_THRESHOLD:
			if state != State.WAITING or not car_is_available:
				return
			state = State.WALKING_TO_CAR
			_start_walking_animation()

func _handle_walking_state(delta: float) -> void:
	if not player_car:
		state = State.WAITING
		_stop_walking_animation()
		return

	if not car_is_available:
		_cancel_pickup()
		return
	
	walking_target = player_car.global_position
	var direction = (walking_target - global_position).normalized()
	# Apply force-based movement instead of velocity
	var desired_velocity = direction * WALK_SPEED
	var velocity_change = desired_velocity - linear_velocity
	
	# Limit the force to prevent excessive acceleration
	var force = velocity_change * WALK_FORCE * delta
	apply_central_force(force)
	
	if direction.length() > 0.1:
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, delta * ROTATION_SPEED)
	
	# Apply movement damping
	linear_velocity = linear_velocity * (1.0 - MOVEMENT_DAMPING * delta)
	
	var distance_to_car = global_position.distance_to(player_car.global_position)
	if distance_to_car <= PICKUP_DISTANCE:
		_pickup_passenger()


func _handle_in_car_state(_delta: float) -> void:
	visible = false
	
	if player_car and destination_position != Vector3.ZERO:
		var distance_to_destination = player_car.global_position.distance_to(destination_position)
		var car_speed = player_car.linear_velocity.length()
		
		if distance_to_destination <= DELIVERY_DISTANCE and car_speed <= STOPPED_SPEED_THRESHOLD:
			deliver()

func _start_walking_animation():
	# Play walking animation if available
	if animation_player and animation_player.has_animation("walk"):
		animation_player.play("walk")


func _stop_walking_animation():
	# Stop walking animation and return to idle
	if animation_player and animation_player.has_animation("idle"):
		animation_player.play("idle")


func _pickup_passenger() -> void:
	if state != State.WALKING_TO_CAR or not car_is_available:
		return
	state = State.IN_CAR
	_stop_walking_animation()
	_animate_pickup_to_car()
	if destination_arrow and player_car:
		destination_arrow.activate(destination_position, player_car)
	
	passenger_picked_up.emit(self)

func _animate_pickup_to_car():
	# Smoothly animate the passenger getting into the car
	if pickup_tween:
		pickup_tween.kill()
	
	pickup_tween = create_tween()
	pickup_tween.set_parallel(true)
	
	# Animate position to car
	var car_position = player_car.global_position + Vector3(0, 1, 0)  # Slightly above car
	pickup_tween.tween_property(self, "global_position", car_position, 0.5)
	
	# Animate scale down (getting into car effect)
	pickup_tween.tween_property(self, "scale", Vector3(0.1, 0.1, 0.1), 0.5)
	
	# Disable physics during pickup
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	freeze = true
	
	# Re-enable physics after animation (in case needed)
	pickup_tween.tween_callback(_complete_pickup).set_delay(0.5)

func _complete_pickup():
	# Complete the pickup process
	visible = false
	freeze = false
	freeze_mode = RigidBody3D.FREEZE_MODE_STATIC


func _cancel_pickup() -> void:
	if state == State.WALKING_TO_CAR:
		state = State.WAITING
		global_position = original_position
		_stop_walking_animation()
		
		# Smoothly return to original position
		if pickup_tween:
			pickup_tween.kill()
		
		pickup_tween = create_tween()
		pickup_tween.tween_property(self, "global_position", original_position, 0.3)
		pickup_tween.tween_property(self, "scale", Vector3.ONE, 0.3)

func _on_car_occupied():
	car_is_available = false
	if state == State.WALKING_TO_CAR:
		_cancel_pickup()


func _on_car_available():
	car_is_available = true


func set_destination(pos: Vector3, building_name: String) -> void:
	destination_position = pos
	destination_building_name = building_name


func deliver() -> void:
	if state != State.IN_CAR:
		return
	state = State.DELIVERED
	
	if destination_arrow:
		destination_arrow.deactivate()
	if pickup_tween:
		pickup_tween.kill()
	
	passenger_delivered.emit(self, BASE_TIP)
	queue_free()


func _timeout() -> void:
	state = State.DELIVERED
	if destination_arrow:
		destination_arrow.queue_free()
	if pickup_tween:
		pickup_tween.kill()
	passenger_timeout.emit(self)
	queue_free()


func _on_pickup_area_entered(body: Node3D) -> void:
	if body.is_in_group(&"player_car") and state == State.WAITING:
		is_in_pickup_range = true


func _on_pickup_area_exited(body: Node3D) -> void:
	if body.is_in_group(&"player_car"):
		is_in_pickup_range = false
		
		if state == State.WALKING_TO_CAR:
			state = State.WAITING
			_stop_walking_animation()
			# Smoothly return to original position
			if pickup_tween:
				pickup_tween.kill()
			pickup_tween = create_tween()
			pickup_tween.tween_property(self, "global_position", original_position, 0.3)
			pickup_tween.tween_property(self, "scale", Vector3.ONE, 0.3)


# Additional helper methods for RigidBody3D
func reset_physics():
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	freeze = false
	freeze_mode = RigidBody3D.FREEZE_MODE_STATIC

func _exit_tree():
	# Clean up tween when passenger is removed
	if pickup_tween:
		pickup_tween.kill()
