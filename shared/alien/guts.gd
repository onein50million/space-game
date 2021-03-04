extends RigidBody2D

onready var splat_sound_scene = preload("res://assets/alien/guts/splat_sound.tscn")

var max_health = 10.0
var health = max_health
var misc_id
var object_type = "guts"
var server_side = false

var send_data = {"index": 0}
func _ready():
	pass
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
	new_sound.global_position = global_position
	queue_free()
