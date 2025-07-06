# passenger_manager.gd
extends Node
class_name PassengerManager

@export var passenger_spawner: PassengerSpawner

var current_passenger: Passenger  # Passenger currently in car
var active_passengers: Array[Passenger] = []

signal passenger_picked_up(passenger: Passenger)
signal passenger_delivered(passenger: Passenger, tip: int)
signal passenger_timeout(passenger: Passenger)

func _ready():	
	if passenger_spawner:
		passenger_spawner.passenger_spawned.connect(_on_passenger_spawned)
		passenger_spawner.passenger_expired.connect(_on_passenger_expired)
	else:
		print("passenger spawner not found")

func _on_passenger_spawned(passenger: Passenger):
	active_passengers.append(passenger)
	
	# Connect to passenger signals
	passenger.passenger_picked_up.connect(_on_passenger_picked_up)
	passenger.passenger_delivered.connect(_on_passenger_delivered)
	passenger.passenger_timeout.connect(_on_passenger_timeout)

func _on_passenger_expired(passenger: Passenger):
	active_passengers.erase(passenger)

func _on_passenger_picked_up(passenger: Passenger):
	current_passenger = passenger
	passenger_picked_up.emit(passenger)

func _on_passenger_delivered(passenger: Passenger, tip: int):
	active_passengers.erase(passenger)
	if current_passenger == passenger:
		current_passenger = null
	
	passenger_delivered.emit(passenger, tip)

func _on_passenger_timeout(passenger: Passenger):
	active_passengers.erase(passenger)
	if current_passenger == passenger:
		current_passenger = null
	
	passenger_timeout.emit(passenger)

# Public methods for HUD and other systems
func get_current_passenger() -> Passenger:
	return current_passenger

func get_active_passenger_count() -> int:
	return active_passengers.size()

func get_current_destination() -> Vector3:
	if current_passenger:
		return current_passenger.destination_position
	return Vector3.ZERO

func has_passenger_in_car() -> bool:
	return current_passenger != null

func cleanup_all_passengers():
	# Remove all passengers when game ends/restarts
	for passenger in active_passengers:
		if is_instance_valid(passenger):
			passenger.queue_free()
	
	active_passengers.clear()
	current_passenger = null
