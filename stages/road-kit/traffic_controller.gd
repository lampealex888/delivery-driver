extends StaticBody3D

const PATH_TRANSMITTER = 4
const STOP_TRANSMITTER = 9

@export var west_transmitter: Area3D
@export var south_transmitter: Area3D
@export var east_transmitter: Area3D
@export var north_transmitter: Area3D

@onready var traffic_timer: Timer = $TrafficTimer
@onready var switch_timer: Timer = $SwitchTimer

enum TrafficPhase { EAST_WEST, NORTH_SOUTH, ALL_RED }
var current_phase = TrafficPhase.EAST_WEST
var next_phase = TrafficPhase.NORTH_SOUTH  # keep track of upcoming phase

func _ready():
	traffic_timer.timeout.connect(_on_traffic_timer_timeout)
	switch_timer.timeout.connect(_on_switch_timer_timeout)
	set_phase(TrafficPhase.EAST_WEST)
	traffic_timer.start()

func _on_traffic_timer_timeout():
	# Begin ALL_RED buffer
	if current_phase == TrafficPhase.EAST_WEST:
		next_phase = TrafficPhase.NORTH_SOUTH
	else:
		next_phase = TrafficPhase.EAST_WEST
	set_phase(TrafficPhase.ALL_RED)
	switch_timer.start()  # wait briefly during all-red

func _on_switch_timer_timeout():
	# Switch to the queued next phase
	set_phase(next_phase)
	traffic_timer.start()

func set_phase(phase):
	current_phase = phase
	var enable_east_west = phase == TrafficPhase.EAST_WEST
	var enable_north_south = phase == TrafficPhase.NORTH_SOUTH

	if east_transmitter:
		_set_transmitter_state(east_transmitter, enable_east_west)
	if west_transmitter:
		_set_transmitter_state(west_transmitter, enable_east_west)
	if north_transmitter:
		_set_transmitter_state(north_transmitter, enable_north_south)
	if south_transmitter:
		_set_transmitter_state(south_transmitter, enable_north_south)

	if phase == TrafficPhase.ALL_RED:
		if east_transmitter:
			_set_transmitter_state(east_transmitter, false)
		if west_transmitter:
			_set_transmitter_state(west_transmitter, false)
		if north_transmitter:
			_set_transmitter_state(north_transmitter, false)
		if south_transmitter:
			_set_transmitter_state(south_transmitter, false)

func _set_transmitter_state(transmitter: Area3D, allow: bool):
	transmitter.set_collision_layer_value(PATH_TRANSMITTER, allow)
	transmitter.set_collision_layer_value(STOP_TRANSMITTER, not allow)
