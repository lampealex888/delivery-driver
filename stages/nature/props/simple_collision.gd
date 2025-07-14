extends RigidBody3D

@onready var despawn_timer: Timer = $DespawnTimer

func _ready():
	body_entered.connect(handle_collision)
	despawn_timer.timeout.connect(queue_free)

func handle_collision(body):
	if body.is_in_group("player_car"):
		if despawn_timer.is_stopped():
			despawn_timer.start()
