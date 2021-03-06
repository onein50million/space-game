extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var port = 2020
var socket = PacketPeerUDP.new()
var menu

var client_list = {}
var disconnected_client_list = []
var ship_list = {}
var misc_objects = {}
var deleted_misc_objects = []

var misc_id = 0

var time_last_mission_requested = 0
var missions = []

var unprocessed_shots = []

var current_tick = 0
var current_camera = Camera2D.new()

var network_process_accumulator = 0
onready var player_scene = preload("res://shared/player.tscn")
onready var ship_scene = preload("res://shared/ship.tscn")
onready var asteroid_scene = load("res://shared/asteroid.tscn")
onready var alien_scene = load("res://shared/alien.tscn")
onready var world = load("res://shared/world.tscn").instance()
# Called when the node enters the scene tree for the first time.
func _ready():
	add_child(world)
	add_child(current_camera)
	current_camera.make_current()
	print("Socket result: %s " % socket.listen(port))
	for _i in range(0,15):
		spawn_body(alien_scene)
		spawn_body(asteroid_scene)
	AudioServer.set_bus_mute(0,true)
func _process(delta):

	var num_aliens = 0
	for object in misc_objects.values():
		if object.object_type == "alien":
			num_aliens += 1
	if num_aliens < 20:
		for _i in range(0,10):
			spawn_body(alien_scene)
	process_systems()
	network_process_accumulator += delta
	while 	network_process_accumulator > 1.0/Globals.NETWORK_UPDATE_INTERVAL:
		network_process_accumulator -= 1.0/Globals.NETWORK_UPDATE_INTERVAL
		
		network_process()
		current_tick += 1

func network_process():
	for client_key in client_list.keys():
		client_list[client_key].network_process()	
		#if last_known_tick is within 3 seconds of 0, probably still connecting and syncing
		var tick_delta = current_tick - client_list[client_key].last_known_tick
		if client_list[client_key].has_sent_packet and tick_delta > Globals.BUFFER_LENGTH:

			client_list[client_key].has_sent_packet = false
			socket.set_dest_address(client_list[client_key].ip, client_list[client_key].port)
			send_error("connection_dropped")
			client_list[client_key].ip = "no_ip"
			client_list[client_key].port = -1
			
			disconnected_client_list.append(client_list[client_key])
			client_list.erase(client_key)


	while socket.get_available_packet_count() > 0:
		process_packet(socket.get_var())
	send_updates()


func process_systems():
	for ship in ship_list.values():
		for system in ship.systems:
			match system.type:
				"communications":
					system.latest_data.ship_name = ship.name
					system.latest_data.missions = missions
				"_":
					pass
func _physics_process(_delta):
	pass

func process_packet(received):
	var packet_ip = socket.get_packet_ip()
	var packet_port = socket.get_packet_port()
	socket.set_dest_address(packet_ip, packet_port)
	
	
	if typeof(received) != TYPE_DICTIONARY:
		send_error("packet_not_dict")
		return
	if !received.has("command"):
		send_error("invalid_command")
		return
	match received.command:
		"join_lobby":
			handle_join(received)
		"input_update":
			handle_input(received)
		"systems_update":
			handle_systems_update(received)
		"ping":
			send_command("ping_return", "pong")
		_:
			send_error("unknown_command")

func handle_join(received):
	var packet_ip = socket.get_packet_ip()
	var packet_port = socket.get_packet_port()
	var client_id = "%s:%s" % [packet_ip, packet_port]
	if client_list.has(client_id):
		send_error("already_connected")
		return
	for client in client_list.values():
		if client.username == received.data.username:
			send_error("username_taken")
			return
	for i in range(0, disconnected_client_list.size()):
		#check if trying to join as unconnected client
		if disconnected_client_list[i].username == received.data.username:
			client_list[client_id] = disconnected_client_list[i]
			disconnected_client_list.remove(i)
			client_list[client_id].ip = packet_ip
			client_list[client_id].port = packet_port
			client_list[client_id].last_known_tick = current_tick
			$CanvasLayer/playerlist.text += "\n%s" % [client_id]
			send_command("join_accepted", "welcome")
			return
	var new_player = player_scene.instance()
	new_player.color = received.data.color
	new_player.color.a = 1.0
	new_player.username = received.data.username
	new_player.ip = packet_ip
	new_player.port = packet_port
	new_player.server_side = true
	if not ship_list.has(received.data.ship):
		var new_ship = spawn_body(ship_scene, true)
		new_ship.respawn()
		new_ship.ship_type = received.data.ship_type
		new_ship.server_side = true
		new_ship.set_name(received.data.ship)
		ship_list[received.data.ship] = new_ship

		
	ship_list[received.data.ship].add_child(new_player)
	client_list[client_id] = new_player 
	current_camera.get_parent().remove_child(current_camera)
	new_player.add_child(current_camera)

	$CanvasLayer/playerlist.text += "\n%s" % [client_id]
	send_command("join_accepted", "welcome")

func handle_input(received):
	var packet_ip = socket.get_packet_ip()
	var packet_port = socket.get_packet_port()
	var client_id = "%s:%s" % [packet_ip, packet_port]
	if !client_list.has(client_id):
		send_error("not_connected")
		return
	var current_client = client_list[client_id]
	
	if received.data.interact:
		handle_interact(current_client)

	current_client.has_sent_packet = true
	current_client.last_input = received.data.duplicate()
	current_client.last_known_tick = received.tick
	current_client.client_last_known_tick = received.last_received
	current_client.ticks_behind = received.ticks_behind
func handle_systems_update(received):
	var packet_ip = socket.get_packet_ip()
	var packet_port = socket.get_packet_port()
	var client_id = "%s:%s" % [packet_ip, packet_port]
	if !client_list.has(client_id):
		send_error("not_connected")
		return
	
	var current_client = client_list[client_id]
	if current_client.at_console == received.data.type:
		match received.data.type:
			"communications":
				if received.data.systems_data.request_mission and OS.get_ticks_usec() - time_last_mission_requested > Globals.MISSION_FREQUENCY:
					time_last_mission_requested = OS.get_ticks_usec()
					new_mission()
			_:
				pass
		for system in current_client.get_parent().systems:
			if system.type == received.data.type:
				system.client_send_data = received.data.systems_data
#fun indent slide
func handle_interact(current_client):
	if current_client.at_console == "none":
		for ship in ship_list.values():
			for system in ship.systems:
				if system.has_node("chair"):
					var chair_collisions = system.get_node("chair").get_overlapping_areas()
					for collision in chair_collisions:
						if collision == current_client:
							current_client.at_console = system.type
							return
	else:
		current_client.at_console = "none"


func send_error(message):
	print("sent error: %s" % [message])
	socket.put_var({
		"command": "error",
		"msg" : message
	})

func send_updates():
	var send_client_data = {
		"clients": [],
		"ships" : [],
		"misc_objects" : [],
		"deleted_misc_objects": [],
		"shots": [],
	}
	for ship in ship_list:
		var subsystem_send = []
		for subsystem in ship_list[ship].systems:
			var data = subsystem.latest_data.duplicate(true)
			subsystem_send.append({
				"type" : subsystem.type,
				"data": data
			})

		send_client_data.ships.append({
			"name" : ship,
			"ship_type":ship_list[ship].ship_type,
			"position" : ship_list[ship].global_position,
			"rotation" : ship_list[ship].global_rotation,
			"velocity" : ship_list[ship].get_linear_velocity(),
			"health": ship_list[ship].health,
			"subsystems" : subsystem_send,
		})
	for object in misc_objects.values():
		send_client_data.misc_objects.append({
			"type" : object.object_type,
			"misc_id": object.misc_id,
			"send_data": object.send_data.duplicate(true),
			"position" : object.global_position,
			"rotation" : object.global_rotation,
		})
		
	#we want to see where disconnected people are standing (no ghosts allowed)
	var iterate_clients = []
	for client_id in client_list:
		iterate_clients.append(client_list[client_id])
	iterate_clients += disconnected_client_list
	
	send_client_data.shots = unprocessed_shots.duplicate(true)
	send_client_data.deleted_misc_objects = deleted_misc_objects.duplicate(true)
	deleted_misc_objects.clear()
	unprocessed_shots = []
	
	for client in iterate_clients:
		send_client_data.clients.append({
			"position" : client.get_position(),
			"rotation" : client.get_node("sprite").get_rotation(),
			"health": client.health,
			"died": client.died,
			"slot": client.last_input.slot,
			"at_console" : client.at_console,
			"ship" : client.get_parent().name,
			"username" : client.username,
			"color" : client.color,
			"last_known_tick" : client.last_known_tick,
		})
		client.died = false

		
	for client in client_list.values():
		socket.set_dest_address(client.ip, client.port)
		send_command("update", send_client_data)
		
func send_command(command,data):
	socket.put_var({
		"command" : command,
		"tick" : current_tick,
		"data" : data
	})

func spawn_body(body, is_ship = false, random_position = true, spawn_position = Vector2(0,0)):
	var new_body = body.instance()
	add_child(new_body)
	new_body.server_side = true
	if not is_ship:
		new_body.misc_id = misc_id
		misc_objects[misc_id] = new_body
		misc_id += 1
		
	new_body.global_position = spawn_position
	if random_position:
		new_body.global_position = get_random_position()
	return new_body

func get_random_position():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	var attempts = 0
	while(true):
		if attempts > 20:
			print("Ran out of attempts when trying to spawn object")
			return Vector2(0,0)
		attempts += 1
		var random_location = Vector2(
			rng.randfn(0, Globals.GAME_AREA),
			rng.randfn(0, Globals.GAME_AREA)
		)
		if is_position_clear(random_location):
			return random_location


func is_position_clear(position, safe_distance = Globals.SAFE_DISTANCE):
		var minimum_distance = INF
		for ship in ship_list.values():
			var distance = position.distance_to(ship.get_position())
			if distance < minimum_distance:
				minimum_distance = distance
		for object in misc_objects.values():
			var distance = position.distance_to(object.get_position())
			if distance < minimum_distance:
				minimum_distance = distance
		if minimum_distance > Globals.SAFE_DISTANCE:
			return true

func delete_misc(given_misc_id):
	misc_objects.erase(given_misc_id)
	deleted_misc_objects.append(given_misc_id)

func new_mission():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var verbs = ["kill", "destroy"]
	var adjectives = ["tasty", "hungry", "ferocious", "evil", "scary"]
	var nouns = ["aliens"]
	
	var verb = verbs[rng.randi_range(0,verbs.size()-1)]
	var number = rng.randi_range(3,15)
	var adjective = adjectives[rng.randi_range(0,adjectives.size()-1)]
	var noun = nouns[rng.randi_range(0,nouns.size()-1)]
	var mission_title = "%s the %s %s %s" %[verb,number,adjective,noun]
	match noun:
		"aliens":
			for _i in range(0,number):
				spawn_body(alien_scene)
	missions.append({
		"title" : mission_title,
		"complete": false
	})


func exit_scene(error):
#	menu.get_parent().remove_child(menu)

	get_tree().get_root().add_child(menu)
	var canvas = CanvasLayer.new()
	menu.add_child(canvas)
	var error_dialog = AcceptDialog.new()
	
	canvas.add_child(error_dialog)
	error_dialog.set_text(error)
	error_dialog.popup_centered()
	
	queue_free()

