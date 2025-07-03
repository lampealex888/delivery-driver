extends Control

@onready var timer_label: Label = $VBoxContainer/TimerLabel
@onready var score_label: Label = $VBoxContainer/ScoreLabel
@onready var game_over_panel: Panel = $GameOverPanel
@onready var final_score_label: Label = $GameOverPanel/VBoxContainer/FinalScoreLabel
@onready var restart_button: Button = $GameOverPanel/VBoxContainer/RestartButton

var passenger_manager: PassengerManager

func _ready() -> void:
	# Find the passenger manager
	passenger_manager = get_tree().get_first_node_in_group("passenger_manager")
	if passenger_manager:
		passenger_manager.timer_updated.connect(_on_timer_updated)
		passenger_manager.game_over.connect(_on_game_over)
		passenger_manager.passenger_completed.connect(_on_score_updated)
		passenger_manager.time_extended.connect(_on_time_extended)
	
	# Hide game over panel initially
	game_over_panel.visible = false
	
	# Connect restart button
	restart_button.pressed.connect(_on_restart_pressed)
	
	# Initial update
	_update_ui()

func _update_ui() -> void:
	if not passenger_manager:
		return
	
	var time_remaining = passenger_manager.get_time_remaining()
	var score = passenger_manager.get_total_score()
	
	# Update timer display
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
	
	# Update score display
	score_label.text = "Score: $%d" % score

func _on_timer_updated(time_remaining: float) -> void:
	_update_ui()

func _on_score_updated(tip: int) -> void:
	_update_ui()

func _on_time_extended(amount: float) -> void:
	# Could add a visual effect here for time extension
	_update_ui()

func _on_game_over(final_score: int) -> void:
	final_score_label.text = "Final Score: $%d" % final_score
	game_over_panel.visible = true

func _on_restart_pressed() -> void:
	if passenger_manager:
		passenger_manager.restart_game()
	game_over_panel.visible = false
	_update_ui() 
