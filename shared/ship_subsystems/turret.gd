extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var type = "turret"
var latest_data = {}
const FIRE_RATE = 1000000 #in microseconds (usec)
const RANGE = 1000

var last_fired = 0

var server_side = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if (OS.get_ticks_usec() - last_fired) > FIRE_RATE*1:
		last_fired = OS.get_ticks_usec()
		var space_state =  get_world_2d().direct_space_state
		var result = space_state.intersect_ray(
			global_position, global_position + Vector2(RANGE,0).rotated(global_rotation), [self],	0b10,true, true)
		if position in result:
			var new_line = Line2D.new()
			result.position
	if "rotation" in latest_data:
		set_rotation(latest_data.rotation)
		if latest_data.is_firing:
			$muzzle_blast.emitting = true
