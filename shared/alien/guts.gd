extends RigidBody2D

onready var splat_sound_scene = preload("res://assets/alien/guts/splat_sound.tscn")

var max_health = 50.0
var health = max_health
var misc_id
var object_type = "guts"
var server_side = false

var lifetime = 30.0

var send_data = {"index": 0}
func _ready():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	lifetime += rng.randf_range(-10.0,10.0)
	linear_damp = 0.0
	angular_damp = 0.0
	$blood.get_node("blood_explosion").emitting = true
func _process(delta):
	if server_side:
		lifetime -= delta
		if health <= 0.0 or lifetime < 0.0:
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
	blood.get_node("blood_explosion").emitting = true
	queue_free()

func damage(damage):
	var damage_dealt = min(health,damage)
	health -= damage_dealt
	return damage_dealt
