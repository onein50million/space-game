extends RigidBody2D

onready var splat_sound_scene = preload("res://assets/alien/guts/splat_sound.tscn")

var max_health = 50.0
var health = max_health
var misc_id
var object_type = "guts"
var server_side = false

var send_data = {"index": 0}
func _ready():
	linear_damp = 0.0
	angular_damp = 0.0
func _process(_delta):
	if server_side:
		if health <= 0.0:
			die()

func die():
	if server_side:
		var server = get_tree().get_root().get_node("server")
		server.delete_misc(misc_id)
	var new_sound = splat_sound_scene.instance()
	get_parent().add_child(new_sound)
	new_sound.volume_db -= 10
	new_sound.global_position = global_position
	
	var blood = $blood
	remove_child(blood)	
	get_parent().add_child(blood)
	blood.global_position = global_position
	blood.emitting = false
	queue_free()
