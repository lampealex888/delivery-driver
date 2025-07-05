extends Node3D
class_name ArrowManager

@export var arrow_scene: PackedScene
var destination_arrow: DestinationArrow
var player_car: VehicleBody3D

func _ready() -> void:
	_find_player_car()
	
	# Connect to passenger manager signals in the editor:
	# passenger_manager.passenger_picked_up -> _on_passenger_picked_up()
	# passenger_manager.passenger_delivered -> _on_passenger_delivered()
	# passenger_manager.passenger_timeout -> _on_passenger_timeout()

func _find_player_car() -> void:
	player_car = get_tree().get_first_node_in_group(&"player_car")

func _on_passenger_picked_up(passenger: Passenger) -> void:
	_create_arrow(passenger.destination_position)

func _on_passenger_delivered(passenger: Passenger, tip: int) -> void:
	_destroy_arrow()

func _on_passenger_timeout(passenger: Passenger) -> void:
	# Only destroy arrow if passenger was in car
	if passenger.state == Passenger.State.IN_CAR:
		_destroy_arrow()

func _create_arrow(target_position: Vector3) -> void:
	if destination_arrow:
		_destroy_arrow()
	
	if arrow_scene and player_car:
		destination_arrow = arrow_scene.instantiate() as DestinationArrow
		add_child(destination_arrow)
		destination_arrow.set_target(target_position)
		destination_arrow.set_follow_target(player_car)

func _destroy_arrow() -> void:
	if destination_arrow:
		destination_arrow.queue_free()
		destination_arrow = null


func _on_passenger_manager_passenger_picked_up(passenger: Passenger) -> void:
	_on_passenger_picked_up(passenger)


func _on_passenger_manager_passenger_delivered(passenger: Passenger, tip: int) -> void:
	_on_passenger_delivered(passenger, tip)


func _on_passenger_manager_passenger_timeout(passenger: Passenger) -> void:
	_on_passenger_timeout(passenger)
