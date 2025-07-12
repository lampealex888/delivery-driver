# hud.gd
extends Control

@onready var timer_label: Label = $VBoxContainer/TimerLabel
@onready var score_label: Label = $VBoxContainer/ScoreLabel
@onready var destination_label: Label = $VBoxContainer/DestinationLabel
@onready var game_over_panel: Panel = $GameOverPanel
@onready var final_score_label: Label = $GameOverPanel/VBoxContainer/FinalScoreLabel
@onready var restart_button: Button = $GameOverPanel/VBoxContainer/RestartButton
@onready var start_game_panel: Panel = $StartGamePanel
@onready var start_button: Button = $StartGamePanel/VBoxContainer/StartButton

signal start_game

func _ready() -> void:
	await get_tree().process_frame
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	game_manager.timer_updated.connect(_on_timer_updated)
	game_manager.score_updated.connect(_on_score_updated)
	game_manager.game_over.connect(_on_game_over)
	game_manager.game_started.connect(_on_game_started)
	
	# Connect restart button
	restart_button.pressed.connect(_on_restart_pressed)
	start_button.pressed.connect(_on_start_pressed)

# GameManager signal handlers
func _on_timer_updated(time_remaining: float) -> void:
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

func _on_score_updated(new_score: int) -> void:
	score_label.text = "Score: $%d" % new_score

func _on_game_over(final_score: int) -> void:
	final_score_label.text = "Final Score: $%d" % final_score
	game_over_panel.visible = true

func _on_game_started() -> void:
	game_over_panel.visible = false

func _on_restart_pressed() -> void:
	start_game.emit()
	game_over_panel.visible = false

func _on_start_pressed() -> void:
	start_game.emit()
	start_game_panel.visible = false
