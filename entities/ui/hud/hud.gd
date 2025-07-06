# hud.gd
extends Control

@onready var timer_label: Label = $VBoxContainer/TimerLabel
@onready var score_label: Label = $VBoxContainer/ScoreLabel
@onready var passenger_info: Label = $VBoxContainer/PassengerInfo
@onready var destination_label: Label = $VBoxContainer/DestinationLabel
@onready var game_over_panel: Panel = $GameOverPanel
@onready var final_score_label: Label = $GameOverPanel/VBoxContainer/FinalScoreLabel
@onready var restart_button: Button = $GameOverPanel/VBoxContainer/RestartButton
@onready var start_game_panel: Panel = $StartGamePanel
@onready var start_button: Button = $StartGamePanel/VBoxContainer/StartButton

var game_manager: GameManager
var passenger_manager: PassengerManager

func _ready() -> void:
	# Find managers
	game_manager = get_tree().get_first_node_in_group("game_manager")
	passenger_manager = get_tree().get_first_node_in_group("passenger_manager")
	
	if game_manager:
		# Connect to GameManager signals
		game_manager.timer_updated.connect(_on_timer_updated)
		game_manager.score_updated.connect(_on_score_updated)
		game_manager.game_over.connect(_on_game_over)
		game_manager.time_extended.connect(_on_time_extended)
		game_manager.game_started.connect(_on_game_started)
	
	if passenger_manager:
		# Connect to PassengerManager signals
		passenger_manager.passenger_picked_up.connect(_on_passenger_picked_up)
		passenger_manager.passenger_delivered.connect(_on_passenger_delivered)
		passenger_manager.passenger_timeout.connect(_on_passenger_timeout)
	
	# Connect restart button
	restart_button.pressed.connect(_on_restart_pressed)
	start_button.pressed.connect(_on_start_pressed)
	
	# Initial update
	_update_ui()

func _update_ui() -> void:
	if not game_manager:
		return
	
	var time_remaining = game_manager.get_time_remaining()
	var score = game_manager.get_current_score()
	
	# Update timer display
	_update_timer_display(time_remaining)
	
	# Update score display
	score_label.text = "Score: $%d" % score
	
	# Update passenger info
	_update_passenger_info()

func _update_timer_display(time_remaining: float) -> void:
	var minutes = int(time_remaining) / 60
	var seconds = int(time_remaining) % 60
	timer_label.text = "Time: %02d:%02d" % [minutes, seconds]
	
	# Change timer color when low
	if time_remaining <= 10.0:
		timer_label.modulate = Color.RED
	elif time_remaining <= 30.0:
		timer_label.modulate = Color.YELLOW
	else:
		timer_label.modulate = Color.WHITE

func _update_passenger_info() -> void:
	if not passenger_manager:
		passenger_info.text = "No passengers"
		destination_label.text = ""
		return
	
	var current_passenger = passenger_manager.get_current_passenger()
	var active_count = passenger_manager.get_active_passenger_count()
	
	if current_passenger:
		passenger_info.text = "Passenger: %s" % current_passenger.passenger_name
		destination_label.text = "Destination: %s" % current_passenger.destination_building_name
		destination_label.modulate = Color.GREEN
	else:
		passenger_info.text = "Passengers waiting: %d" % active_count
		destination_label.text = "Look for passengers!"
		destination_label.modulate = Color.WHITE
# GameManager signal handlers
func _on_timer_updated(time_remaining: float) -> void:
	_update_timer_display(time_remaining)

func _on_score_updated(new_score: int) -> void:
	score_label.text = "Score: $%d" % new_score

func _on_time_extended(amount: float) -> void:
	# Add a visual effect for time extension
	var tween = create_tween()
	timer_label.modulate = Color.GREEN
	tween.tween_property(timer_label, "modulate", Color.WHITE, 0.5)

func _on_game_over(final_score: int) -> void:
	final_score_label.text = "Final Score: $%d" % final_score
	game_over_panel.visible = true

func _on_game_started() -> void:
	game_over_panel.visible = false
	_update_ui()

func _on_restart_pressed() -> void:
	if game_manager:
		game_manager.start_game()
	game_over_panel.visible = false

func _on_start_pressed() -> void:
	if game_manager:
		game_manager.start_game()
	start_game_panel.visible = false

# PassengerManager signal handlers
func _on_passenger_picked_up(passenger: Passenger) -> void:
	_update_passenger_info()
	
	# Show pickup feedback
	var pickup_label = Label.new()
	pickup_label.text = "Picked up %s!" % passenger.passenger_name
	pickup_label.modulate = Color.GREEN
	pickup_label.position = Vector2(400, 200)
	add_child(pickup_label)
	
	# Animate and remove
	var tween = create_tween()
	tween.parallel().tween_property(pickup_label, "position", Vector2(400, 150), 1.0)
	tween.parallel().tween_property(pickup_label, "modulate", Color.TRANSPARENT, 1.0)
	tween.tween_callback(pickup_label.queue_free)

func _on_passenger_delivered(passenger: Passenger, tip: int) -> void:
	_update_passenger_info()
	
	# Show delivery feedback
	var delivery_label = Label.new()
	delivery_label.text = "Delivered! +$%d" % tip
	delivery_label.modulate = Color.YELLOW
	delivery_label.position = Vector2(400, 200)
	add_child(delivery_label)
	
	# Animate and remove
	var tween = create_tween()
	tween.parallel().tween_property(delivery_label, "position", Vector2(400, 150), 1.0)
	tween.parallel().tween_property(delivery_label, "modulate", Color.TRANSPARENT, 1.0)
	tween.tween_callback(delivery_label.queue_free)
	
func _on_passenger_timeout(passenger: Passenger) -> void:
	_update_passenger_info()
	
	# Show timeout feedback
	var timeout_label = Label.new()
	timeout_label.text = "Passenger left!"
	timeout_label.modulate = Color.RED
	timeout_label.position = Vector2(400, 200)
	add_child(timeout_label)
	
	# Animate and remove
	var tween = create_tween()
	tween.parallel().tween_property(timeout_label, "position", Vector2(400, 150), 1.0)
	tween.parallel().tween_property(timeout_label, "modulate", Color.TRANSPARENT, 1.0)
	tween.tween_callback(timeout_label.queue_free)
