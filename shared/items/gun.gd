extends "res://shared/items/item.gd"

onready var laser_scene = load("res://shared/items/laser.tscn")
const FIRE_DELAY = 0.05
const RANGE = 200
const DAMAGE = 5.0


var current_fire = FIRE_DELAY

var firing = false


func _ready():
	type = "gun"
	slot_number = 0


func _physics_process(delta):

	current_fire += delta

	if firing and current_fire >= FIRE_DELAY and draw_lifetime >= Globals.DRAW_TIME:
		var temp_delta = delta
		current_fire = 0
		fire()
		
		#hopefully will keep firerate up when framerate low
		while temp_delta > FIRE_DELAY: 
			temp_delta -= FIRE_DELAY
			fire()

	current_fire = min(FIRE_DELAY, current_fire)

func fire():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var new_laser = laser_scene.instance()
	player.get_parent().add_child(new_laser)
#	add_child(new_laser)
#	server.add_child(new_laser)
	var a = global_position
	var b = to_global(Vector2(RANGE*rng.randf_range(0.9,1.1),0).rotated(rng.randf_range(-0.1,0.1)))
	var space_state = get_world_2d().direct_space_state
	var result = space_state.intersect_ray(a,b,[player],0b10000,true,true)
#	print(global_transform.xform(b))
	if "position" in result:
		b = result.position
		if result.collider.is_in_group("player"):
			result.collider.health -= DAMAGE
	new_laser.points[0] = player.get_parent().to_local(a)
	new_laser.points[1] = player.get_parent().to_local(b)
	
	
	if server_side:
		server.unprocessed_shots.append({
			"laser_start":player.get_parent().to_local(a),
			"laser_end": player.get_parent().to_local(b),
			"ship": player.get_parent().name
		})
