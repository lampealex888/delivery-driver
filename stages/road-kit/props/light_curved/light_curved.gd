extends RigidBody3D

@onready var light = $Light
@onready var despawn_timer = $DespawnTimer

func _ready():
	body_entered.connect(turn_off_light)
	despawn_timer.timeout.connect(queue_free)


func turn_off_light(body):
	if body.is_in_group("player_car"):
		lock_rotation = false
		light.visible = false
		despawn_timer.start()
