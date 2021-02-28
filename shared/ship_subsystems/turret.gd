extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var type = "turret"
var latest_data = {
	"rotation": 0,
	"is_firing": false,
}
var client_send_data = {}
const FIRE_RATE = 1000000 #in microseconds (usec)
const RANGE = 1000

var last_fired = 0

var server_side = false

onready var bullet_scene = load("res://shared/ship_subsystems/railgun-round.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	var delta_fire = OS.get_ticks_usec() - last_fired
	if delta_fire > FIRE_RATE and latest_data.is_firing:
		$muzzle_blast.emitting = true
		last_fired = OS.get_ticks_usec()
		var space_state =  get_world_2d().direct_space_state
		var final_destination = global_position + Vector2(RANGE,0).rotated(global_rotation)
		var result = space_state.intersect_ray(
			global_position, final_destination, [$"../.."],	0b10,true, true)
		if "position" in result:
			final_destination = result.position
			if result.collider.get_class() == "RigidBody2D":
				var offset = final_destination - result.collider.global_position
				result.collider.apply_impulse(offset,Vector2(100,0).rotated(global_rotation))
		var new_line = bullet_scene.instance()
		$"../../..".add_child(new_line)
		new_line.points = PoolVector2Array([global_position,final_destination])
			
	if "rotation" in latest_data:
		set_rotation(latest_data.rotation)
