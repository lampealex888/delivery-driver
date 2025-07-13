extends RigidBody3D

@onready var light = $Light
@onready var area_3d = $Area3D
@onready var despawn_timer = $DespawnTimer

func _ready():
	area_3d.body_entered.connect(turn_off_light)
	despawn_timer.timeout.connect(queue_free)


func turn_off_light(body):
	if body.is_in_group("player_car") or body.is_in_group("ai_car"):
		lock_rotation = false
		light.visible = false
		despawn_timer.start()
