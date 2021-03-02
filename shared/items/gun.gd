extends "res://shared/items/item.gd"

onready var laser_scene = load("res://shared/items/laser.tscn")
const FIRE_DELAY = 0.05
const RANGE = 200
const DAMAGE = 5.0


var current_fire = FIRE_DELAY

var draw_reconciliation = false

func _ready():
	type = "gun"
	slot_number = 0

func _process(delta):
	update()

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
	var start_saved_location
	var new_laser = laser_scene.instance()
	var saved_locations = []

	if server_side:
		start_saved_location = global_position
#		var ticks_behind = server.current_tick - player.client_last_known_tick
		var ticks_behind = player.ticks_behind
		for client in server.client_list.values():

			saved_locations.append(client.position)
			client.position = client.position_buffer[posmod(client.position_buffer_head- ticks_behind, Globals.BUFFER_LENGTH)]
			client.force_update_transform()
			

	player.get_parent().add_child(new_laser)
#	add_child(new_laser)
#	server.add_child(new_laser)
	var a = global_position
	if server_side:
		a=start_saved_location
	var b = to_global(Vector2(RANGE*rng.randf_range(0.9,1.1),0).rotated(rng.randf_range(-0.1,0.1)))
	var space_state = get_world_2d().direct_space_state
	var result = space_state.intersect_ray(a,b,[player],0b10000,true,true)

	if "position" in result:
		b = result.position
		if result.collider.is_in_group("health"):
			result.collider.health -= DAMAGE
			$hitmarker.play()
		var collider_parent = result.collider.get_parent()
		if collider_parent and collider_parent.is_in_group("health"):
			collider_parent.health -= DAMAGE
			$hitmarker.play()
	new_laser.points[0] = player.get_parent().to_local(a)
	new_laser.points[1] = player.get_parent().to_local(b)
	
	
	if server_side:
		var i = 0
		for client in server.client_list.values():
			client.position = saved_locations[i]
			i += 1
		server.unprocessed_shots.append({
			"laser_start":player.get_parent().to_local(a),
			"laser_end": player.get_parent().to_local(b),
			"ship": player.get_parent().name
		})

func _draw():
	if server_side and server and draw_reconciliation:
#		var ticks_behind = server.current_tick - player.client_last_known_tick
		var ticks_behind = player.ticks_behind
		for client in server.client_list.values():
			var rollback_position = client.get_parent().to_global(client.position_buffer[posmod(client.position_buffer_head- ticks_behind, Globals.BUFFER_LENGTH)])
			draw_circle(to_local(rollback_position),10.0,Color.red)
